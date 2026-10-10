/// `bpmp sync` — re-resolve `requires` to the current highest tag and
/// report each dependency's current commit SHA. Prints drift against
/// `botopink.lock.json` and exits non-zero so CI can flag "the lockfile is
/// stale". It never rewrites the lockfile.
///
/// Each dependency is resolved from its **own declared source**: the `git:`
/// URL of its entry (`dependencies.<name>.git`). A `path:` dependency and a
/// `{ "workspace": true }` member have nothing to re-resolve. Every entry has
/// a source (decision 76), so no org name is built in and none is read from
/// the environment.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");
const registry = @import("../registry.zig");
const semver = @import("../semver.zig");
const dep_spec = @import("../dep/spec.zig");

const HELP =
    \\bpmp sync
    \\
    \\Re-resolves each dependency's `requires` constraint against the tags of
    \\its declared `git:` source and reports drift from botopink.lock.json
    \\(exit 1 on drift). `path:` and `{ "workspace": true }` dependencies
    \\have nothing to re-resolve.
    \\
;

/// Where a dependency's tags are read from.
pub const Source = union(enum) {
    /// A GitHub repository (`registry.liveTags` reads its tag list).
    github: registry.RepoSpec,
    /// A `path:` dependency — nothing to re-resolve.
    path,
    /// A `{ "workspace": true }` dependency — a sibling member, nothing to re-resolve.
    workspace,
    /// A `git:` URL on a host `registry` cannot list tags for.
    unsupported: []const u8,
};

/// Resolve `entry`'s tag source from its own declaration. Strings in the
/// result point into `entry`.
pub fn resolveSource(entry: dep_spec.DepEntry) Source {
    const sp = entry.spec;
    if (sp.workspace) return .workspace;
    if (sp.git) |git| {
        if (!isGithubUrl(git)) return .{ .unsupported = git };
        const repo = registry.RepoSpec.parse(git) catch return .{ .unsupported = git };
        return .{ .github = repo };
    }
    // The parser admits exactly one source per entry; the third is `path`.
    return .path;
}

/// `registry.RepoSpec.parse` accepts any `<a>/<b>`; only a GitHub URL is a
/// repository whose tags `registry.liveTags` can list.
fn isGithubUrl(url: []const u8) bool {
    var rest = url;
    for ([_][]const u8{ "https://", "http://", "ssh://", "git@" }) |p| {
        if (std.mem.startsWith(u8, rest, p)) {
            rest = rest[p.len..];
            break;
        }
    }
    return std.mem.startsWith(u8, rest, "github.com/") or std.mem.startsWith(u8, rest, "github.com:");
}

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    for (args) |a| {
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx, HELP);
            return 0;
        } else if (std.mem.eql(u8, a, "--update")) {
            return common.errMsg("sync: `--update` is not supported — `bpmp sync` only reports drift; it never rewrites the lockfile");
        } else return common.errFmt("sync: unknown flag '{s}'", .{a});
    }

    var arena_inst = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const data = std.Io.Dir.cwd().readFileAlloc(ctx.io, "botopink.json", arena, .limited(64 * 1024)) catch |err| switch (err) {
        error.FileNotFound => return common.errMsg("botopink.json not found"),
        else => return err,
    };
    var diags: std.ArrayListUnmanaged(dep_spec.Diagnostic) = .empty;
    const deps = try dep_spec.parseFromManifest(arena, data, &diags);
    if (diags.items.len > 0) {
        return common.errMsg("sync: botopink.json:dependencies is malformed — run `bpmp install --dry-run` for the diagnostics");
    }

    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found"),
        else => return err,
    };
    defer m.deinit();

    if (deps.len == 0) {
        common.writeStdout(ctx, "bpmp sync: no dependencies declared in botopink.json\n");
        return 0;
    }

    common.printf(ctx, "bpmp sync: {d} dep(s) to re-resolve\n", .{deps.len});

    // Pull existing pins (if any) so drift reporting can compare.
    var lf: ?lockfile.Lockfile = lockfile.read(ctx.gpa, ctx.io, ".") catch null;
    defer if (lf) |*l| l.deinit();

    const env = ctx.env_map;
    const auth = if (env) |e| e.get("GITHUB_TOKEN") else null;
    var live_ctx: registry.LiveCtx = .{ .io = ctx.io, .auth_token = auth };

    var drift_count: usize = 0;
    for (deps) |entry| {
        const d = entry.name;
        const repo = switch (resolveSource(entry)) {
            .github => |r| r,
            .path => {
                common.printf(ctx, "  • {s: <14} path dependency — nothing to re-resolve\n", .{d});
                continue;
            },
            .workspace => {
                common.printf(ctx, "  • {s: <14} workspace member — nothing to re-resolve\n", .{d});
                continue;
            },
            .unsupported => |url| {
                common.printf(ctx, "  • {s: <14} tags can only be listed for GitHub sources ({s}) — skipping\n", .{ d, url });
                continue;
            },
        };
        const c = m.requirement(d) orelse "*";
        const tags = registry.liveTags(&live_ctx, ctx.gpa, repo) catch |err| {
            common.printf(ctx, "  • {s: <14} fetch failed ({s})\n", .{ d, @errorName(err) });
            continue;
        };
        defer {
            for (tags) |t| {
                ctx.gpa.free(t.name);
                ctx.gpa.free(t.commit);
            }
            ctx.gpa.free(tags);
        }
        const constraint = semver.Constraint.parse(c) catch {
            common.printf(ctx, "  • {s: <14} bad constraint '{s}'\n", .{ d, c });
            continue;
        };
        const picked = semver.pickHighest(constraint, tags) orelse {
            common.printf(ctx, "  • {s: <14} no tag satisfies '{s}'\n", .{ d, c });
            continue;
        };

        const prev_commit = if (lf) |*l| if (l.findPackage(d)) |p| p.commit else "" else "";
        if (prev_commit.len > 0 and !std.mem.eql(u8, prev_commit, picked.commit)) {
            common.printf(ctx, "  • {s: <14} drift: {s}@{s} (was {s})\n", .{
                d, picked.name, picked.commit[0..@min(picked.commit.len, 7)], prev_commit[0..@min(prev_commit.len, 7)],
            });
            drift_count += 1;
        } else {
            common.printf(ctx, "  • {s: <14} {s}@{s}\n", .{
                d, picked.name, picked.commit[0..@min(picked.commit.len, 7)],
            });
        }
    }

    if (drift_count > 0) {
        common.printf(ctx, "bpmp sync: {d} drifted pin(s) — botopink.lock.json is stale (sync does not rewrite it).\n", .{drift_count});
        return 1;
    }
    return 0;
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

fn parseDeps(arena: std.mem.Allocator, json: []const u8) ![]const dep_spec.DepEntry {
    var diags: std.ArrayListUnmanaged(dep_spec.Diagnostic) = .empty;
    const deps = try dep_spec.parseFromManifest(arena, json, &diags);
    try testing.expectEqual(@as(usize, 0), diags.items.len);
    return deps;
}

test "resolveSource: a git: dep resolves to its own GitHub owner, not a built-in org" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const deps = try parseDeps(arena.allocator(),
        \\{ "name": "p", "dependencies": {
        \\  "widgets": { "git": "https://github.com/acme/widgets.git", "branch": "main" }
        \\}}
    );
    const src = resolveSource(deps[0]);
    try testing.expectEqualStrings("acme", src.github.owner);
    try testing.expectEqualStrings("widgets", src.github.repo);
}

test "resolveSource: ssh-style GitHub URLs resolve too" {
    const entry: dep_spec.DepEntry = .{ .name = "w", .spec = .{ .git = "git@github.com:acme/widgets.git" } };
    const src = resolveSource(entry);
    try testing.expectEqualStrings("acme", src.github.owner);
    try testing.expectEqualStrings("widgets", src.github.repo);
}

test "resolveSource: a non-GitHub git: host is unsupported, never re-owned" {
    const entry: dep_spec.DepEntry = .{ .name = "w", .spec = .{ .git = "https://gitlab.com/acme/widgets.git" } };
    const src = resolveSource(entry);
    try testing.expectEqualStrings("https://gitlab.com/acme/widgets.git", src.unsupported);
}

test "resolveSource: a path: dep has nothing to sync" {
    const entry: dep_spec.DepEntry = .{ .name = "w", .spec = .{ .path = "../w" } };
    try testing.expectEqual(Source.path, resolveSource(entry));
}

test "resolveSource: a workspace member has nothing to sync" {
    const entry: dep_spec.DepEntry = .{ .name = "w", .spec = .{ .workspace = true } };
    try testing.expectEqual(Source.workspace, resolveSource(entry));
}
