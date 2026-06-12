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

    pub const Kind = enum { clone, reuse_cas, path_symlink, skip_legacy };
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
    /// a lockfile entry. Drives `bpmp install --frozen`.
    frozen: bool = false,
};

pub const Error = error{
    FrozenMissingEntry,
    StoreRootMissing,
    DryrunNoOp,
} || clone.TypedError || std.mem.Allocator.Error;

/// Plan one action per entry without touching disk. Used by `--dry-run`
/// and by the actual installer (which then executes the plan).
pub fn plan(
    gpa: std.mem.Allocator,
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

        // Already in lockfile? CAS hit if the store dir exists.
        if (opts.lock_in) |lf_in| {
            if (lf_in.find(entry.name)) |le| {
                if (le.rev.len == 40) {
                    const cas = try std.fs.path.join(a, &.{ store_root, entry.name, le.rev });
                    actions[i] = .{
                        .name = try a.dupe(u8, entry.name),
                        .kind = .reuse_cas,
                        .store_path = cas,
                        .rev = try a.dupe(u8, le.rev),
                        .git = git_url,
                    };
                    i += 1;
                    continue;
                }
            }
        }

        // Pinned rev in the spec? CAS hit potential.
        if (sp.ref == .rev) {
            const cas = try std.fs.path.join(a, &.{ store_root, entry.name, sp.ref.rev });
            actions[i] = .{
                .name = try a.dupe(u8, entry.name),
                .kind = if (opts.frozen) .reuse_cas else .clone,
                .store_path = cas,
                .rev = try a.dupe(u8, sp.ref.rev),
                .git = git_url,
            };
            i += 1;
            continue;
        }

        if (opts.frozen) return Error.FrozenMissingEntry;

        // Fresh clone: rev unknown until we shell out.
        actions[i] = .{
            .name = try a.dupe(u8, entry.name),
            .kind = .clone,
            .store_path = "",
            .git = git_url,
        };
        i += 1;
    }

    return Plan{ .arena = arena, .actions = actions[0..i] };
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "plan: legacy bare-name skips" {
    const entries = [_]spec.DepEntry{.{ .name = "x" }};
    var p = try plan(testing.allocator, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(@as(usize, 1), p.actions.len);
    try testing.expectEqual(Action.Kind.skip_legacy, p.actions[0].kind);
}

test "plan: path: → path_symlink" {
    const entries = [_]spec.DepEntry{.{ .name = "x", .spec = .{ .path = "/abs/x" } }};
    var p = try plan(testing.allocator, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.path_symlink, p.actions[0].kind);
    try testing.expectEqualStrings("/abs/x", p.actions[0].path.?);
}

test "plan: git+branch with no lockfile → clone" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    var p = try plan(testing.allocator, &entries, "/store", .{});
    defer p.deinit();
    try testing.expectEqual(Action.Kind.clone, p.actions[0].kind);
}

test "plan: git+rev → CAS short-circuit (reuse_cas under frozen)" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" } },
    }};
    var p = try plan(testing.allocator, &entries, "/store", .{ .frozen = true });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
}

test "plan: frozen + missing lockfile entry → FrozenMissingEntry" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};
    const r = plan(testing.allocator, &entries, "/store", .{ .frozen = true });
    try testing.expectError(Error.FrozenMissingEntry, r);
}

test "plan: lock_in hit → reuse_cas" {
    const entries = [_]spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .branch = "feat" } },
    }};

    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const a = arena.allocator();
    const ent = try a.alloc(lock.Entry, 1);
    ent[0] = .{
        .name = "j",
        .git = "https://e/j.git",
        .rev = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
        .fetched_at = "2026-06-19T00:00:00Z",
    };
    var lf = lock.Lockfile{ .arena = arena, .generated_by = "bpmp test", .lockfile_version = 1, .entries = ent };
    defer lf.deinit();

    var p = try plan(testing.allocator, &entries, "/store", .{ .lock_in = &lf });
    defer p.deinit();
    try testing.expectEqual(Action.Kind.reuse_cas, p.actions[0].kind);
    try testing.expectEqualStrings("/store/j/deadbeefdeadbeefdeadbeefdeadbeefdeadbeef", p.actions[0].store_path);
}
