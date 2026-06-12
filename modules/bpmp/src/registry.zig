/// GitHub API client surface — bpmp talks to `api.github.com` and
/// `github.com/<owner>/<repo>/archive/<commit>.tar.gz`.
///
/// This file is the **shape** of the registry layer: every other module
/// reaches for a stable interface (`listTags`, `releaseAsset`, …) so the
/// HTTP path can be stubbed in tests by swapping the implementation.
///
/// The live HTTP path is intentionally narrow in this initial drop:
/// `bpmp install` (no args) replays the lockfile and goes through
/// `download.fetchCommitTarball`. The `listTags` resolution path used by
/// `bpmp sync` / `bpmp install <name>@<spec>` returns `error.OnlineUnavailable`
/// when no offline tag list is provided — see the spec §"Cross-spec
/// coordination". The hermetic test path drives a synthetic tag list.
const std = @import("std");
const semver = @import("./semver.zig");
const download = @import("./download.zig");

pub const Error = error{
    OnlineUnavailable,
    BadRepoSpec,
    BadApiResponse,
} || std.mem.Allocator.Error;

/// `github.com/<owner>/<repo>` shape.
pub const RepoSpec = struct {
    owner: []const u8,
    repo: []const u8,

    /// Parse `github.com/<owner>/<repo>` or `<owner>/<repo>` into its parts.
    /// The protocol prefix (`https://`) is allowed and silently dropped.
    pub fn parse(s: []const u8) Error!RepoSpec {
        var rest = s;
        const protos = [_][]const u8{ "https://", "http://", "git@" };
        for (protos) |p| {
            if (std.mem.startsWith(u8, rest, p)) rest = rest[p.len..];
        }
        if (std.mem.startsWith(u8, rest, "github.com/")) rest = rest["github.com/".len..]
        else if (std.mem.startsWith(u8, rest, "github.com:")) rest = rest["github.com:".len..];

        const slash = std.mem.indexOfScalar(u8, rest, '/') orelse return error.BadRepoSpec;
        const owner = rest[0..slash];
        var repo = rest[slash + 1 ..];
        if (std.mem.endsWith(u8, repo, ".git")) repo = repo[0 .. repo.len - 4];
        if (owner.len == 0 or repo.len == 0) return error.BadRepoSpec;
        return .{ .owner = owner, .repo = repo };
    }

    /// The commit-addressed tarball URL — used by lockfile replay (§D5b).
    pub fn commitTarballUrl(self: RepoSpec, gpa: std.mem.Allocator, commit: []const u8) ![]u8 {
        return std.fmt.allocPrint(gpa, "https://github.com/{s}/{s}/archive/{s}.tar.gz", .{
            self.owner, self.repo, commit,
        });
    }

    /// `api.github.com` URL for the repo's tag list.
    pub fn tagsApiUrl(self: RepoSpec, gpa: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(gpa, "https://api.github.com/repos/{s}/{s}/tags", .{
            self.owner, self.repo,
        });
    }

    /// The release asset download URL for `bpmp self update` /
    /// `bpmp use botopink <ver>`.
    pub fn releaseAssetUrl(
        self: RepoSpec,
        gpa: std.mem.Allocator,
        tag: []const u8,
        asset_name: []const u8,
    ) ![]u8 {
        return std.fmt.allocPrint(
            gpa,
            "https://github.com/{s}/{s}/releases/download/{s}/{s}",
            .{ self.owner, self.repo, tag, asset_name },
        );
    }
};

/// Stable signature so a test can drop in a synthetic tag list. The default
/// implementation reaches for `api.github.com` via `download.fetchBytes`.
pub const ListTags = struct {
    pub const Fn = *const fn (
        ctx: ?*anyopaque,
        gpa: std.mem.Allocator,
        spec: RepoSpec,
    ) Error![]const semver.Tag;

    /// Built-in: returns OnlineUnavailable. Tests inject their own; real
    /// callers wire `liveTags` (which carries an `io` + token).
    pub fn unavailable(
        ctx: ?*anyopaque,
        gpa: std.mem.Allocator,
        spec: RepoSpec,
    ) Error![]const semver.Tag {
        _ = ctx;
        _ = gpa;
        _ = spec;
        return error.OnlineUnavailable;
    }
};

/// One release on a GitHub repo — `tag_name` is what `bpmp self update`
/// compares against the running version.
pub const Release = struct {
    tag_name: []const u8,
    name: []const u8 = "",
};

/// Live HTTP context for the `liveTags` provider — see `bpmp sync` / `bpmp
/// install <name>@<spec>`. The token is sent as `Authorization: Bearer` so
/// CI hits the auth'd GitHub rate limit (5k/hr vs 60/hr unauth).
pub const LiveCtx = struct {
    io: std.Io,
    auth_token: ?[]const u8 = null,
    max_retries: u8 = 3,
};

/// Live `ListTags.Fn` implementation. Pulls from `api.github.com/repos/.../
/// tags` and parses `[{"name": "<tag>", "commit": {"sha": "<commit>"}}, …]`.
/// Tags are returned in API order (newest first); `semver.pickHighest`
/// already handles ordering, so caller doesn't need a sort.
pub fn liveTags(
    ctx: ?*anyopaque,
    gpa: std.mem.Allocator,
    spec: RepoSpec,
) Error![]const semver.Tag {
    const live: *const LiveCtx = @ptrCast(@alignCast(ctx orelse return error.OnlineUnavailable));
    const url = try spec.tagsApiUrl(gpa);
    defer gpa.free(url);
    const body = download.fetchBytes(gpa, live.io, url, live.auth_token, live.max_retries) catch
        return error.OnlineUnavailable;
    defer gpa.free(body);
    return parseTagsJson(gpa, body) catch return error.BadApiResponse;
}

/// Pull `releases/latest` for `spec`. Used by `bpmp self update` to learn
/// which tag is current without listing every tag first.
pub fn fetchLatestRelease(
    gpa: std.mem.Allocator,
    io: std.Io,
    spec: RepoSpec,
    auth_token: ?[]const u8,
) !Release {
    const url = try std.fmt.allocPrint(
        gpa,
        "https://api.github.com/repos/{s}/{s}/releases/latest",
        .{ spec.owner, spec.repo },
    );
    defer gpa.free(url);
    const body = try download.fetchBytes(gpa, io, url, auth_token, 3);
    defer gpa.free(body);
    return parseLatestRelease(gpa, body);
}

fn parseTagsJson(gpa: std.mem.Allocator, body: []const u8) ![]const semver.Tag {
    var arena = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();
    const tree = try std.json.parseFromSliceLeaky(std.json.Value, a, body, .{});
    if (tree != .array) return error.BadApiResponse;

    var out = try gpa.alloc(semver.Tag, tree.array.items.len);
    var count: usize = 0;
    for (tree.array.items) |entry| {
        if (entry != .object) continue;
        const name_v = entry.object.get("name") orelse continue;
        if (name_v != .string) continue;
        const commit_v = entry.object.get("commit") orelse continue;
        if (commit_v != .object) continue;
        const sha_v = commit_v.object.get("sha") orelse continue;
        if (sha_v != .string) continue;
        out[count] = .{
            .name = try gpa.dupe(u8, name_v.string),
            .commit = try gpa.dupe(u8, sha_v.string),
        };
        count += 1;
    }
    // arena owned the temporary parse tree; out owns dup'd slices.
    arena.deinit();
    if (count < out.len) {
        // Shrink to exact count to keep ownership semantics clean.
        const shrunk = try gpa.realloc(out, count);
        return shrunk;
    }
    return out;
}

fn parseLatestRelease(gpa: std.mem.Allocator, body: []const u8) !Release {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();
    const tree = try std.json.parseFromSliceLeaky(std.json.Value, a, body, .{});
    if (tree != .object) return error.BadApiResponse;
    const tag = tree.object.get("tag_name") orelse return error.BadApiResponse;
    if (tag != .string) return error.BadApiResponse;
    const name_v = tree.object.get("name");
    return .{
        .tag_name = try gpa.dupe(u8, tag.string),
        .name = if (name_v) |v| (if (v == .string) try gpa.dupe(u8, v.string) else "") else "",
    };
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "RepoSpec.parse: short form" {
    const s = try RepoSpec.parse("botopink/erika");
    try testing.expectEqualStrings("botopink", s.owner);
    try testing.expectEqualStrings("erika", s.repo);
}

test "RepoSpec.parse: github.com/<o>/<r>" {
    const s = try RepoSpec.parse("github.com/botopink/erika");
    try testing.expectEqualStrings("erika", s.repo);
}

test "RepoSpec.parse: https URL with trailing .git" {
    const s = try RepoSpec.parse("https://github.com/botopink/erika.git");
    try testing.expectEqualStrings("erika", s.repo);
}

test "RepoSpec.parse: malformed rejected" {
    try testing.expectError(error.BadRepoSpec, RepoSpec.parse("just-a-name"));
    try testing.expectError(error.BadRepoSpec, RepoSpec.parse(""));
}

test "RepoSpec.commitTarballUrl: produces the commit-addressed URL (NOT tag)" {
    const s = try RepoSpec.parse("botopink/erika");
    const u = try s.commitTarballUrl(testing.allocator, "abcdef0123456789");
    defer testing.allocator.free(u);
    try testing.expectEqualStrings(
        "https://github.com/botopink/erika/archive/abcdef0123456789.tar.gz",
        u,
    );
    // Crucially, the URL is `/archive/<commit>.tar.gz`, NOT
    // `/archive/refs/tags/<tag>.tar.gz` — the lockfile pins by commit so
    // a moving feat tag never drifts the replay.
    try testing.expect(std.mem.indexOf(u8, u, "refs/tags") == null);
}

test "RepoSpec.releaseAssetUrl: standard releases download path" {
    const s = try RepoSpec.parse("botopink/botopink-lang");
    const u = try s.releaseAssetUrl(testing.allocator, "v0.0.1", "bpmp-v0.0.1-linux-x86_64.tar.gz");
    defer testing.allocator.free(u);
    try testing.expectEqualStrings(
        "https://github.com/botopink/botopink-lang/releases/download/v0.0.1/bpmp-v0.0.1-linux-x86_64.tar.gz",
        u,
    );
}

test "ListTags.unavailable returns OnlineUnavailable" {
    try testing.expectError(error.OnlineUnavailable, ListTags.unavailable(
        null,
        testing.allocator,
        try RepoSpec.parse("botopink/erika"),
    ));
}

test "parseTagsJson: shapes the GH /tags response into semver.Tag rows" {
    const body =
        \\[{"name":"v0.0.2","commit":{"sha":"bbb"}},
        \\ {"name":"v0.0.1","commit":{"sha":"aaa"}}]
    ;
    const tags = try parseTagsJson(testing.allocator, body);
    defer {
        for (tags) |t| {
            testing.allocator.free(t.name);
            testing.allocator.free(t.commit);
        }
        testing.allocator.free(tags);
    }
    try testing.expectEqual(@as(usize, 2), tags.len);
    try testing.expectEqualStrings("v0.0.2", tags[0].name);
    try testing.expectEqualStrings("bbb", tags[0].commit);
    try testing.expectEqualStrings("v0.0.1", tags[1].name);
}

test "parseTagsJson: skips malformed rows without erroring out" {
    const body =
        \\[{"name":"good","commit":{"sha":"x"}},
        \\ {"name":42,"commit":{"sha":"y"}},
        \\ "not-an-object"]
    ;
    const tags = try parseTagsJson(testing.allocator, body);
    defer {
        for (tags) |t| {
            testing.allocator.free(t.name);
            testing.allocator.free(t.commit);
        }
        testing.allocator.free(tags);
    }
    try testing.expectEqual(@as(usize, 1), tags.len);
    try testing.expectEqualStrings("good", tags[0].name);
}

test "parseLatestRelease: extracts tag_name" {
    const body = "{\"tag_name\":\"v0.0.5\",\"name\":\"v0.0.5 release\"}";
    const r = try parseLatestRelease(testing.allocator, body);
    defer testing.allocator.free(r.tag_name);
    defer testing.allocator.free(r.name);
    try testing.expectEqualStrings("v0.0.5", r.tag_name);
}
