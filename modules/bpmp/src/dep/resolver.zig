/// Dispatch for materialising a list of `DepEntry` into the store + linking
/// them under `<project>/.botopinkbuild/deps/<name>`. Walks the entries,
/// asks `clone.materialise` for each, then writes / updates the per-project
/// symlinks. The lockfile entries it returns are passed verbatim into
/// `lock.write` by the caller.
const std = @import("std");
const spec = @import("./spec.zig");
const clone = @import("./clone.zig");
const lock = @import("../lock.zig");

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

    pub const Kind = enum { clone, reuse_cas, path_symlink, skip_legacy };

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
};

pub const Error = error{
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

    var actions = try a.alloc(Action, entries.len);
    var i: usize = 0;
    for (entries) |entry| {
        const sp = entry.spec orelse {
            // Legacy bare-name entry — `bpmp install` skips, the resolver
            // still finds it through `libs/<name>/` lookup.
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = .skip_legacy,
                .store_path = "",
            };
            i += 1;
            continue;
        };

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

        // A pinned commit — the lockfile's, else the spec's own `rev:`. CAS hit
        // only when the store really holds it; otherwise clone that exact
        // commit, which `--frozen` forbids.
        const lock_rev: ?[]const u8 = if (opts.lock_in) |lf_in|
            if (lf_in.find(entry.name)) |le| (if (le.rev.len == 40) le.rev else null) else null
        else
            null;
        const pinned_rev: ?[]const u8 = lock_rev orelse if (sp.ref == .rev) sp.ref.rev else null;
        if (pinned_rev) |rev| {
            const cas = try std.fs.path.join(a, &.{ store_root, entry.name, rev });
            const hit = storeHas(io, cas);
            if (!hit and opts.frozen) {
                if (opts.failed_name) |out| out.* = entry.name;
                return Error.FrozenStoreMiss;
            }
            const rev_owned = try a.dupe(u8, rev);
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = if (hit) .reuse_cas else .clone,
                .store_path = if (hit) cas else "",
                .rev = rev_owned,
                .git = git_url,
                .ref = .{ .rev = rev_owned },
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
        actions[i] = .{
            .name = try a.dupe(u8, entry.name),
            .kind = .clone,
            .store_path = "",
            .git = git_url,
            .ref = try dupeRef(a, sp.ref),
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

test "plan: legacy bare-name skips" {
    const entries = [_]spec.DepEntry{.{ .name = "x" }};
    var p = try plan(testing.allocator, testing.io, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(@as(usize, 1), p.actions.len);
    try testing.expectEqual(Action.Kind.skip_legacy, p.actions[0].kind);
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

test "plan: git+rev, commit in the store → reuse_cas (frozen or not)" {
    const store = ".botopinkbuild/bpmp-tests/resolver-rev-hit";
    resetDir(store);
    defer std.Io.Dir.cwd().deleteTree(testing.io, store) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, store ++ "/j/" ++ test_rev);

    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = test_rev } },
    }};
    for ([_]bool{ false, true }) |frozen| {
        var p = try plan(testing.allocator, testing.io, &entries, store, .{ .frozen = frozen });
        defer p.deinit();
        try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
        try testing.expectEqualStrings(store ++ "/j/" ++ test_rev, p.actions[0].store_path);
    }
}

test "plan: git+rev, empty store → clone of that rev" {
    const store = ".botopinkbuild/bpmp-tests/resolver-rev-miss";
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
    const store = ".botopinkbuild/bpmp-tests/resolver-frozen-rev-miss";
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
    const store = ".botopinkbuild/bpmp-tests/resolver-lock-hit";
    resetDir(store);
    defer std.Io.Dir.cwd().deleteTree(testing.io, store) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, store ++ "/j/" ++ test_rev);

    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var lf = try lockWith(test_rev);
    defer lf.deinit();

    var p = try plan(testing.allocator, testing.io, &entries, store, .{ .lock_in = &lf });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
    try testing.expectEqualStrings(store ++ "/j/" ++ test_rev, p.actions[0].store_path);
}

test "plan: lock_in hit, pruned store → clone of the locked rev, not the branch" {
    const store = ".botopinkbuild/bpmp-tests/resolver-lock-pruned";
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
    const store = ".botopinkbuild/bpmp-tests/resolver-frozen-lock-pruned";
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
