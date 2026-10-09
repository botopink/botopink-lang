/// Dispatch for materialising a list of `DepEntry` into the store + linking
/// them under `<project>/.botopinkbuild/deps/<name>`. Walks the entries,
/// asks `clone.materialise` for each, then writes / updates the per-project
/// symlinks. The lockfile entries it returns are passed verbatim into
/// `lock.write` by the caller.
const std = @import("std");
const spec = @import("./spec.zig");
const clone = @import("./clone.zig");
const lock = @import("../lock.zig");
const manifest = @import("manifest");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");

pub const Plan = struct {
    arena: std.heap.ArenaAllocator,
    actions: []Action,

    pub fn deinit(self: *Plan) void {
        self.arena.deinit();
    }
};

pub const Action = struct {
    name: []const u8,
    kind: Kind,
    store_path: []const u8,
    rev: []const u8 = "",
    git: []const u8 = "",
    path: ?[]const u8 = null,
    /// The ref a `.clone` checks out: the entry's own `branch:`/`tag:`/`rev:`,
    /// or `.rev` of the lockfile pin when the store no longer holds it. Without
    /// it a first install of a `branch:`/`tag:` dep would clone default HEAD.
    ref: spec.DepRef = .none,
    /// The entry's `"subdir"` (decision 344): the package is this directory of
    /// the checkout, not its root.
    subdir: ?[]const u8 = null,
    /// The store directory of the repository (`repoKey(git)`): every git
    /// dependency on one repository lands in `<store>/<repo_key>/<rev>/`, so
    /// two dependencies on it at one ref share one checkout.
    repo_key: []const u8 = "",

    /// `skip_workspace`: a `{ "workspace": true }` entry — the sibling member
    /// of the enclosing workspace, which the compiler resolves from the tree;
    /// there is nothing to fetch or link. `share_checkout`: a git entry whose
    /// repository an earlier `.clone` of the same plan checks out — it takes
    /// that checkout instead of cloning the repository a second time.
    pub const Kind = enum { clone, reuse_cas, share_checkout, path_symlink, skip_workspace };

    /// The `DepSpec` the cloner materialises for this action — git source plus
    /// the ref the action carries.
    pub fn cloneSpec(self: Action) spec.DepSpec {
        return .{ .git = self.git, .ref = self.ref };
    }
};

pub const Options = struct {
    /// When true: never spawn git; instead, expect every git dep to have a
    /// `rev:` already in `lock_in.find(name)` (or fail). Drives the
    /// snapshot / dry-run path.
    offline: bool = false,
    /// Optional pre-loaded lockfile from the previous install. Lets the
    /// planner re-use CAS hits and skip already-resolved deps when `frozen`.
    lock_in: ?*const lock.Lockfile = null,
    /// When true: refuse to clone anything; every git dep must already have
    /// a lockfile entry (or a spec `rev:`) whose commit is in the store.
    /// Drives `bpmp install --frozen`.
    frozen: bool = false,
    /// Set to the offending dependency's name when `plan` fails with
    /// `FrozenMissingEntry` or `FrozenStoreMiss`, so the caller can name it.
    failed_name: ?*[]const u8 = null,
    /// With `LockDivergent`: `failed_name` is the first dependency, this the
    /// second one the lockfile pins at another commit of the same repository.
    failed_other: ?*[]const u8 = null,
};

pub const Error = error{
    /// `botopink.lock` pins two dependencies on one repository at two commits
    /// — one repository is one checkout (decision 344).
    LockDivergent,
    FrozenMissingEntry,
    /// `--frozen` and the pinned commit is not in the store: installing would
    /// need a clone, which `--frozen` forbids. Never a dangling symlink.
    FrozenStoreMiss,
    StoreRootMissing,
    DryrunNoOp,
} || clone.TypedError || std.mem.Allocator.Error;

fn storeHas(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

fn dupeRef(a: std.mem.Allocator, ref: spec.DepRef) !spec.DepRef {
    return switch (ref) {
        .branch => |b| .{ .branch = try a.dupe(u8, b) },
        .tag => |t| .{ .tag = try a.dupe(u8, t) },
        .rev => |r| .{ .rev = try a.dupe(u8, r) },
        .none => .none,
    };
}

/// The store directory of a git repository: the last segment of its URL
/// (without `.git`, reduced to `[A-Za-z0-9._-]`) and 12 hex digits of the
/// SHA-256 of `manifest.repositoryUrl(url)` — readable, and two repositories
/// with one last segment never share a directory.
pub fn repoKey(a: std.mem.Allocator, url: []const u8) std.mem.Allocator.Error![]const u8 {
    const repo = manifest.repositoryUrl(url);
    var base = repo;
    if (std.mem.lastIndexOfAny(u8, base, "/:")) |at| base = base[at + 1 ..];
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(repo, &digest, .{});
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (base) |c| try out.append(a, if (std.ascii.isAlphanumeric(c) or c == '.' or c == '_' or c == '-') c else '_');
    if (out.items.len == 0) try out.appendSlice(a, "repo");
    const hex = std.fmt.bytesToHex(digest[0..6].*, .lower);
    try out.append(a, '-');
    try out.appendSlice(a, &hex);
    return out.toOwnedSlice(a);
}

/// Plan one action per entry. The only disk access is probing the store for
/// pinned commits (`<store>/<name>/<rev>/`): a pin is `.reuse_cas` only when
/// that directory exists, otherwise it is cloned — or, under `frozen`, the
/// plan fails with `FrozenStoreMiss`. Used by `--dry-run` and by the actual
/// installer (which then executes the plan).
pub fn plan(
    gpa: std.mem.Allocator,
    io: std.Io,
    entries: []const spec.DepEntry,
    store_root: []const u8,
    opts: Options,
) Error!Plan {
    var arena = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();

    // One repository is one checkout (decision 344): the lockfile's pin of any
    // dependency on a repository is the pin of every dependency on it, and two
    // dependencies it pins at two commits are refused, naming both.
    var group_pin: std.StringArrayHashMapUnmanaged(struct { name: []const u8, rev: []const u8 }) = .empty;
    if (opts.lock_in) |lf_in| for (entries) |entry| {
        const g = entry.spec.git orelse continue;
        const le = lf_in.find(entry.name) orelse continue;
        if (le.rev.len != 40) continue;
        const gop = try group_pin.getOrPut(a, manifest.repositoryUrl(g));
        if (!gop.found_existing) {
            gop.value_ptr.* = .{ .name = entry.name, .rev = le.rev };
        } else if (!std.mem.eql(u8, gop.value_ptr.rev, le.rev)) {
            if (opts.failed_name) |out| out.* = gop.value_ptr.name;
            if (opts.failed_other) |out| out.* = entry.name;
            return Error.LockDivergent;
        }
    };
    // The first `.clone` of each repository; a later entry on it shares it.
    var first_clone: std.StringArrayHashMapUnmanaged(void) = .empty;

    var actions = try a.alloc(Action, entries.len);
    var i: usize = 0;
    for (entries) |entry| {
        const sp = entry.spec;
        if (sp.workspace) {
            // A sibling member of the enclosing workspace: the compiler reads
            // it from the tree (decision 75); nothing to materialise.
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = .skip_workspace,
                .store_path = "",
            };
            i += 1;
            continue;
        }

        if (sp.isPath()) {
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = .path_symlink,
                .store_path = "", // filled in at execute time once we know project_root
                .path = try a.dupe(u8, sp.path.?),
            };
            i += 1;
            continue;
        }

        if (!sp.isGit()) return clone.TypedError.NoGitOrPath;
        if (store_root.len == 0) return Error.StoreRootMissing;

        const git_url = try a.dupe(u8, sp.git.?);
        const repo_key = try repoKey(a, git_url);
        const subdir: ?[]const u8 = if (sp.subdir) |d| try a.dupe(u8, d) else null;
        const repo_url = manifest.repositoryUrl(git_url);

        // A pinned commit — the lockfile's (of any dependency on this
        // repository), else the spec's own `rev:`. CAS hit only when the store
        // really holds it; otherwise clone that exact commit, which `--frozen`
        // forbids.
        const lock_rev: ?[]const u8 = if (group_pin.get(repo_url)) |gp| gp.rev else null;
        const pinned_rev: ?[]const u8 = lock_rev orelse if (sp.ref == .rev) sp.ref.rev else null;
        if (pinned_rev) |rev| {
            const cas = try std.fs.path.join(a, &.{ store_root, repo_key, rev });
            const hit = storeHas(io, cas);
            if (!hit and opts.frozen) {
                if (opts.failed_name) |out| out.* = entry.name;
                return Error.FrozenStoreMiss;
            }
            const rev_owned = try a.dupe(u8, rev);
            const shared = !hit and (try first_clone.getOrPut(a, repo_url)).found_existing;
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = if (hit) .reuse_cas else if (shared) .share_checkout else .clone,
                .store_path = if (hit) cas else "",
                .rev = rev_owned,
                .git = git_url,
                .ref = .{ .rev = rev_owned },
                .subdir = subdir,
                .repo_key = repo_key,
            };
            i += 1;
            continue;
        }

        if (opts.frozen) {
            if (opts.failed_name) |out| out.* = entry.name;
            return Error.FrozenMissingEntry;
        }

        // Fresh clone of the declared branch / tag (or default HEAD when the
        // entry names no ref): the rev is unknown until we shell out.
        const shared = (try first_clone.getOrPut(a, repo_url)).found_existing;
        actions[i] = .{
            .name = try a.dupe(u8, entry.name),
            .kind = if (shared) .share_checkout else .clone,
            .store_path = "",
            .git = git_url,
            .ref = try dupeRef(a, sp.ref),
            .subdir = subdir,
            .repo_key = repo_key,
        };
        i += 1;
    }

    return Plan{ .arena = arena, .actions = actions[0..i] };
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

const test_rev = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef";

/// Empty a scratch directory under the test cwd (`modules/bpmp`);
/// `.botopinkbuild/` is git-ignored.
fn resetDir(dir: []const u8) void {
    std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
}

fn lockWith(rev: []const u8) !lock.Lockfile {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const a = arena.allocator();
    const ent = try a.alloc(lock.Entry, 1);
    ent[0] = .{
        .name = "j",
        .git = "https://e/j.git",
        .rev = try a.dupe(u8, rev),
        .fetched_at = "2026-06-19T00:00:00Z",
    };
    return lock.Lockfile{ .arena = arena, .generated_by = "bpmp test", .lockfile_version = 1, .entries = ent };
}

test "plan: a workspace member skips — the compiler resolves it from the tree" {
    const entries = [_]spec.DepEntry{.{ .name = "x", .spec = .{ .workspace = true } }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(@as(usize, 1), p.actions.len);
    try testing.expectEqual(Action.Kind.skip_workspace, p.actions[0].kind);
}

test "plan: path: → path_symlink" {
    const entries = [_]spec.DepEntry{.{ .name = "x", .spec = .{ .path = "/abs/x" } }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.path_symlink, p.actions[0].kind);
    try testing.expectEqualStrings("/abs/x", p.actions[0].path.?);
}

test "plan: git+branch with no lockfile → clone that carries the branch" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    const s = p.actions[0].cloneSpec();
    try testing.expectEqualStrings("https://e/j.git", s.git.?);
    try testing.expectEqualStrings("feat", s.ref.branch);
}

test "plan: git+tag with no lockfile → clone that carries the tag" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .tag = "v1.2.0" } },
    }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    try testing.expectEqualStrings("v1.2.0", p.actions[0].cloneSpec().ref.tag);
}

test "plan: git with no ref → clone of default HEAD (ref .none)" {
    const entries = [_]spec.DepEntry{.{ .name = "j", .spec = .{ .git = "https://e/j.git" } }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(spec.DepRef.none, p.actions[0].cloneSpec().ref);
}

/// `<store>/<repoKey("https://e/j.git")>/<rev>` — where the fixture
/// dependency `j` lands. Owned by `testing.allocator`.
fn jCheckout(store: []const u8, rev: []const u8) ![]u8 {
    const key = try repoKey(testing.allocator, "https://e/j.git");
    defer testing.allocator.free(key);
    return std.fs.path.join(testing.allocator, &.{ store, key, rev });
}

test "repoKey: the URL's last segment plus a digest of the repository URL" {
    const a = testing.allocator;
    const k1 = try repoKey(a, "https://github.com/botopink/rakun.git");
    defer a.free(k1);
    const k2 = try repoKey(a, "https://github.com/botopink/rakun/");
    defer a.free(k2);
    const k3 = try repoKey(a, "https://gitlab.com/other/rakun.git");
    defer a.free(k3);
    const k4 = try repoKey(a, "git@github.com:botopink/rakun.git");
    defer a.free(k4);
    try testing.expect(std.mem.startsWith(u8, k1, "rakun-"));
    try testing.expectEqual(@as(usize, "rakun-".len + 12), k1.len);
    try testing.expectEqualStrings(k1, k2);
    try testing.expect(!std.mem.eql(u8, k1, k3));
    try testing.expect(std.mem.startsWith(u8, k4, "rakun-"));
}

test "plan: two dependencies on one repository — the second shares the first's clone" {
    const entries = [_]spec.DepEntry{
        .{ .name = "web", .spec = .{ .git = "https://e/rakun.git", .ref = .{ .tag = "v1" }, .subdir = "modules/web" } },
        .{ .name = "core", .spec = .{ .git = "https://e/rakun", .ref = .{ .tag = "v1" }, .subdir = "modules/core" } },
        .{ .name = "other", .spec = .{ .git = "https://e/other.git" } },
    };
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    try testing.expectEqual(Action.Kind.share_checkout, p.actions[1].kind);
    try testing.expectEqual(Action.Kind.clone, p.actions[2].kind);
    try testing.expectEqualStrings(p.actions[0].repo_key, p.actions[1].repo_key);
    try testing.expectEqualStrings("modules/web", p.actions[0].subdir.?);
    try testing.expectEqualStrings("modules/core", p.actions[1].subdir.?);
    try testing.expect(p.actions[2].subdir == null);
}

test "plan: the lockfile's pin of one dependency on a repository pins every dependency on it" {
    const entries = [_]spec.DepEntry{
        .{ .name = "j", .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" }, .subdir = "a" } },
        .{ .name = "k", .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" }, .subdir = "b" } },
    };
    var lf = try lockWith(test_rev);
    defer lf.deinit();
    var p = try plan(testing.allocator, testing.io, &entries, "/store-that-holds-nothing", .{ .lock_in = &lf });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    try testing.expectEqualStrings(test_rev, p.actions[0].cloneSpec().ref.rev);
    try testing.expectEqual(Action.Kind.share_checkout, p.actions[1].kind);
    try testing.expectEqualStrings(test_rev, p.actions[1].rev);
}

test "plan: a lockfile pinning one repository at two commits is refused, naming both" {
    const entries = [_]spec.DepEntry{
        .{ .name = "j", .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" }, .subdir = "a" } },
        .{ .name = "k", .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" }, .subdir = "b" } },
    };
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const a = arena.allocator();
    const ent = try a.alloc(lock.Entry, 2);
    ent[0] = .{ .name = "j", .git = "https://e/j.git", .rev = test_rev, .fetched_at = "2026-06-19T00:00:00Z" };
    ent[1] = .{ .name = "k", .git = "https://e/j.git", .rev = "feedfacefeedfacefeedfacefeedfacefeedface", .fetched_at = "2026-06-19T00:00:00Z" };
    var lf = lock.Lockfile{ .arena = arena, .generated_by = "bpmp test", .lockfile_version = 1, .entries = ent };
    defer lf.deinit();
    var first: []const u8 = "";
    var other: []const u8 = "";
    try testing.expectError(Error.LockDivergent, plan(testing.allocator, testing.io, &entries, "/store", .{
        .lock_in = &lf,
        .failed_name = &first,
        .failed_other = &other,
    }));
    try testing.expectEqualStrings("j", first);
    try testing.expectEqualStrings("k", other);
}

test "plan: git+rev, commit in the store → reuse_cas (frozen or not)" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-rev-hit");
    resetDir(store);
    defer std.Io.Dir.cwd().deleteTree(testing.io, store) catch {};
    const cas = try jCheckout(store, test_rev);
    defer testing.allocator.free(cas);
    try std.Io.Dir.cwd().createDirPath(testing.io, cas);

    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = test_rev } },
    }};
    for ([_]bool{ false, true }) |frozen| {
        var p = try plan(testing.allocator, testing.io, &entries, store, .{ .frozen = frozen });
        defer p.deinit();
        try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
        try testing.expectEqualStrings(cas, p.actions[0].store_path);
    }
}

test "plan: git+rev, empty store → clone of that rev" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-rev-miss");
    resetDir(store);
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = test_rev } },
    }};
    var p = try plan(testing.allocator, testing.io, &entries, store, .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    try testing.expectEqualStrings(test_rev, p.actions[0].cloneSpec().ref.rev);
}

test "plan: frozen + git+rev + empty store → FrozenStoreMiss naming the dep" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-frozen-rev-miss");
    resetDir(store);
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = test_rev } },
    }};
    var failed: []const u8 = "";
    const r = plan(testing.allocator, testing.io, &entries, store, .{ .frozen = true, .failed_name = &failed });
    try testing.expectError(Error.FrozenStoreMiss, r);
    try testing.expectEqualStrings("j", failed);
}

test "plan: frozen + missing lockfile entry → FrozenMissingEntry" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var failed: []const u8 = "";
    const r = plan(testing.allocator, testing.io, &entries, "/store", .{ .frozen = true, .failed_name = &failed });
    try testing.expectError(Error.FrozenMissingEntry, r);
    try testing.expectEqualStrings("j", failed);
}

test "plan: lock_in hit with the commit in the store → reuse_cas" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-lock-hit");
    resetDir(store);
    defer std.Io.Dir.cwd().deleteTree(testing.io, store) catch {};
    const cas = try jCheckout(store, test_rev);
    defer testing.allocator.free(cas);
    try std.Io.Dir.cwd().createDirPath(testing.io, cas);

    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var lf = try lockWith(test_rev);
    defer lf.deinit();

    var p = try plan(testing.allocator, testing.io, &entries, store, .{ .lock_in = &lf });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
    try testing.expectEqualStrings(cas, p.actions[0].store_path);
}

test "plan: lock_in hit, pruned store → clone of the locked rev, not the branch" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-lock-pruned");
    resetDir(store);
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var lf = try lockWith(test_rev);
    defer lf.deinit();

    var p = try plan(testing.allocator, testing.io, &entries, store, .{ .lock_in = &lf });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
    try testing.expectEqualStrings(test_rev, p.actions[0].cloneSpec().ref.rev);
}

test "plan: frozen + lock_in hit + pruned store → FrozenStoreMiss (no dangling symlink)" {
    const store = test_scratch.path(testing.io, "bpmp-tests/resolver-frozen-lock-pruned");
    resetDir(store);
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var lf = try lockWith(test_rev);
    defer lf.deinit();

    const r = plan(testing.allocator, testing.io, &entries, store, .{ .frozen = true, .lock_in = &lf });
    try testing.expectError(Error.FrozenStoreMiss, r);
}
