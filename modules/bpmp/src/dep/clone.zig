/// Git clone wrapper for `bpmp install`.
///
/// Wraps `git clone --depth 1 [--branch <branch>]` into a tmp dir under
/// `$BPMP_HOME/store/<name>/.tmp-<pid>/`, captures the resolved commit SHA
/// via `git rev-parse HEAD`, then atomically renames the tmp dir to the
/// final `<name>/<full-sha>/`. On any failure the tmp dir is removed so
/// a retry doesn't leave a half-clone behind.
///
/// The `path:` variant takes no clone — it returns the absolute source path
/// directly. The caller (`commands/install.zig`) symlinks it under
/// `.botopinkbuild/deps/<name>` regardless of source.
const std = @import("std");
const spec = @import("./spec.zig");

pub const Error = anyerror;

pub const TypedError = error{
    CloneFailed,
    RevParseFailed,
    NoGitOrPath,
    AbsPathRequired,
    StoreRootMissing,
};

pub const Clone = struct {
    /// Resolved local checkout path (always absolute).
    /// For `git` deps: `$BPMP_HOME/store/<name>/<rev>/`.
    /// For `path` deps: the dep's absolute source path.
    path: []const u8,
    /// Resolved 40-char commit SHA. Empty for `path:` deps.
    rev: []const u8,

    pub fn deinit(self: *Clone, gpa: std.mem.Allocator) void {
        gpa.free(self.path);
        if (self.rev.len > 0) gpa.free(self.rev);
    }
};

/// Materialise a `DepSpec` onto local disk. Returns the resolved checkout
/// path + commit SHA. Caller owns both strings via `gpa`.
///
/// Strategy:
///   - `path:` → resolve to absolute, no IO beyond `realpath`.
///   - `git:` + already-pinned `rev:` → if `<store_root>/<name>/<rev>/`
///     exists, no-op (CAS hit). Otherwise clone.
///   - `git:` + `branch:` (or no ref) → clone, then `rev-parse HEAD` to
///     capture the actual SHA, atomically rename tmp dir to `<rev>/`.
pub fn materialise(
    gpa: std.mem.Allocator,
    io: std.Io,
    name: []const u8,
    dep: spec.DepSpec,
    store_root: []const u8,
    project_root: []const u8,
) Error!Clone {
    if (dep.path) |p| return materialisePath(gpa, p, project_root);
    if (dep.git == null) return TypedError.NoGitOrPath;
    return materialiseGit(gpa, io, name, dep, store_root);
}

fn pathExistsIo(io: std.Io, p: []const u8) bool {
    std.Io.Dir.cwd().access(io, p, .{}) catch return false;
    return true;
}

fn makeDirAllIo(io: std.Io, p: []const u8) !void {
    std.Io.Dir.cwd().createDirPath(io, p) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

fn rmTreeIo(io: std.Io, p: []const u8) void {
    std.Io.Dir.cwd().deleteTree(io, p) catch {};
}

fn materialisePath(gpa: std.mem.Allocator, raw: []const u8, project_root: []const u8) Error!Clone {
    const abs = if (std.fs.path.isAbsolute(raw))
        try gpa.dupe(u8, raw)
    else
        try std.fs.path.resolve(gpa, &.{ project_root, raw });
    return .{ .path = abs, .rev = try gpa.dupe(u8, "") };
}

fn materialiseGit(
    gpa: std.mem.Allocator,
    io: std.Io,
    name: []const u8,
    dep: spec.DepSpec,
    store_root: []const u8,
) Error!Clone {
    if (store_root.len == 0) return TypedError.StoreRootMissing;
    const git_url = dep.git.?;

    // Already pinned to a rev? CAS hit short-circuits.
    if (dep.ref == .rev) {
        const rev = dep.ref.rev;
        const final = try std.fs.path.join(gpa, &.{ store_root, name, rev });
        errdefer gpa.free(final);
        if (pathExistsIo(io, final)) {
            return .{ .path = final, .rev = try gpa.dupe(u8, rev) };
        }
    }

    // Ensure `<store_root>/<name>/` exists.
    const name_dir = try std.fs.path.join(gpa, &.{ store_root, name });
    defer gpa.free(name_dir);
    try makeDirAllIo(io, name_dir);

    // Clone into a tmp dir keyed by a random suffix so two concurrent bpmp's
    // don't collide.
    var rng_buf: [16]u8 = undefined;
    const seed: u64 = @bitCast(@as(i64, @intCast(std.Io.Timestamp.now(io, .real).nanoseconds & 0x7fff_ffff_ffff_ffff)));
    var prng = std.Random.DefaultPrng.init(seed);
    prng.random().bytes(&rng_buf);
    var tmp_name_buf: [64]u8 = undefined;
    const tmp_name = std.fmt.bufPrint(&tmp_name_buf, ".tmp-{x}", .{std.mem.readInt(u128, &rng_buf, .little)}) catch unreachable;
    const tmp_dir = try std.fs.path.join(gpa, &.{ name_dir, tmp_name });
    defer gpa.free(tmp_dir);

    var args: std.ArrayListUnmanaged([]const u8) = .empty;
    defer args.deinit(gpa);
    try args.append(gpa, "git");
    try args.append(gpa, "clone");
    try args.append(gpa, "--depth");
    try args.append(gpa, "1");
    switch (dep.ref) {
        .branch => |b| {
            try args.append(gpa, "--branch");
            try args.append(gpa, b);
        },
        .tag => |t| {
            try args.append(gpa, "--branch");
            try args.append(gpa, t);
        },
        .rev, .none => {},
    }
    try args.append(gpa, "--");
    try args.append(gpa, git_url);
    try args.append(gpa, tmp_dir);

    // For an unpinned `rev:` we need a deeper history — `git clone --depth 1`
    // can't check out an arbitrary commit. Drop `--depth 1` in that case.
    var spawn_args = args.items;
    if (dep.ref == .rev) {
        // strip "--depth", "1" from positions 2..4
        const without_depth = try gpa.alloc([]const u8, args.items.len - 2);
        defer gpa.free(without_depth);
        without_depth[0] = args.items[0];
        without_depth[1] = args.items[1];
        @memcpy(without_depth[2..], args.items[4..]);
        spawn_args = without_depth;
    }

    runGit(io, spawn_args) catch {
        rmTreeIo(io, tmp_dir);
        return TypedError.CloneFailed;
    };

    // For a pinned rev: checkout that rev inside the clone.
    if (dep.ref == .rev) {
        runGit(io, &.{ "git", "-C", tmp_dir, "checkout", dep.ref.rev }) catch {
            rmTreeIo(io, tmp_dir);
            return TypedError.CloneFailed;
        };
    }

    // Capture HEAD sha.
    const rev_full = runGitCapture(gpa, io, &.{ "git", "-C", tmp_dir, "rev-parse", "HEAD" }) catch {
        rmTreeIo(io, tmp_dir);
        return TypedError.RevParseFailed;
    };
    errdefer gpa.free(rev_full);
    const rev_trimmed = std.mem.trim(u8, rev_full, " \t\r\n");

    // Atomically rename `<tmp>` → `<name>/<rev>/`. If a sibling already
    // landed (race), drop tmp and reuse.
    const final = try std.fs.path.join(gpa, &.{ store_root, name, rev_trimmed });
    errdefer gpa.free(final);
    if (pathExistsIo(io, final)) {
        rmTreeIo(io, tmp_dir);
    } else {
        std.Io.Dir.cwd().rename(tmp_dir, std.Io.Dir.cwd(), final, io) catch {
            // Cleanup tmp and the half-created final; let caller retry.
            rmTreeIo(io, tmp_dir);
            rmTreeIo(io, final);
            return TypedError.CloneFailed;
        };
    }

    const rev_owned = try gpa.dupe(u8, rev_trimmed);
    gpa.free(rev_full);
    return .{ .path = final, .rev = rev_owned };
}

fn runGit(io: std.Io, argv: []const []const u8) !void {
    var child = try std.process.spawn(io, .{
        .argv = argv,
        .stdin = .ignore,
        .stdout = .inherit,
        .stderr = .inherit,
    });
    defer child.kill(io);
    const term = try child.wait(io);
    switch (term) {
        .exited => |code| if (code != 0) return error.CloneFailed,
        else => return error.CloneFailed,
    }
}

fn runGitCapture(gpa: std.mem.Allocator, io: std.Io, argv: []const []const u8) ![]u8 {
    const result = try std.process.run(gpa, io, .{ .argv = argv });
    defer gpa.free(result.stderr);
    if (result.term != .exited or result.term.exited != 0) {
        gpa.free(result.stdout);
        return error.RevParseFailed;
    }
    return result.stdout;
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "materialisePath: relative path resolves against project root" {
    var c = try materialisePath(testing.allocator, "../local-lib", "/srv/proj");
    defer c.deinit(testing.allocator);
    try testing.expectEqualStrings("/srv/local-lib", c.path);
    try testing.expectEqualStrings("", c.rev);
}

test "materialisePath: absolute path passes through" {
    var c = try materialisePath(testing.allocator, "/abs/path", "/srv/proj");
    defer c.deinit(testing.allocator);
    try testing.expectEqualStrings("/abs/path", c.path);
}

test "materialise: NoGitOrPath when both null" {
    const s: spec.DepSpec = .{};
    const r = materialise(testing.allocator, std.testing.io, "x", s, "/store", "/proj");
    try testing.expectError(TypedError.NoGitOrPath, r);
}

test "materialise: StoreRootMissing when git without store_root" {
    const s: spec.DepSpec = .{ .git = "https://e/x.git", .ref = .{ .branch = "feat" } };
    const r = materialise(testing.allocator, std.testing.io, "x", s, "", "/proj");
    try testing.expectError(TypedError.StoreRootMissing, r);
}
