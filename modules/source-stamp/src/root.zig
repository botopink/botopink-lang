//! `source_stamp` — the content hash of the sources a `botopink` binary is
//! built from, so a library run can refuse a stale binary.
//!
//! ## The defect this exists to make unrepeatable
//!
//! Library threads measure against a compiler binary they rebuilt by hand. A
//! binary one commit behind its checkout compiles the library with yesterday's
//! compiler and reports yesterday's reds — a measurement nobody can tell from
//! a real one. `build.zig` computes `hash(<checkout>)` when it configures the
//! build and embeds it (with the checkout's absolute path) in `botopink`; a library run computes it again over the same files and
//! refuses to start when the two differ (`checkFresh`).
//!
//! ## Why a content hash and not a modification time
//!
//! `zig build` caches by content: touching a source (a `git checkout` of the
//! same bytes) rebuilds nothing, so the installed binary keeps its old mtime
//! and a "binary older than a source" rule would refuse a binary that is
//! current, with no command that fixes it. The hash moves exactly when the
//! bytes the binary is built from move, and `zig build` then rebuilds it.
//!
//! ## The file set
//!
//! `ROOTS` under the checkout, every regular file except `*.md`, skipping
//! hidden directories and the ones in `SKIP_DIRS` (build output, scratch,
//! snapshots, test trees — none of them reaches the binary). Paths are hashed
//! sorted, each as `<path> NUL <bytes> NUL`, so the answer does not depend on
//! the order a directory lists its entries.

const std = @import("std");

/// What the binaries are built from, relative to the checkout root.
pub const ROOTS = [_][]const u8{
    "build.zig",
    "build.zig.zon",
    "modules/compiler-cli/src",
    "modules/compiler-core/src",
    "modules/manifest/src",
    "modules/source-stamp/src",
    "libs",
};

/// Directory names never descended into.
pub const SKIP_DIRS = [_][]const u8{ "tests", "test", "snapshots", "out", "zig-out", "node_modules" };

pub const HEX_LEN = 64;

/// The hex SHA-256 of the file set under `root`.
pub fn hash(gpa: std.mem.Allocator, io: std.Io, root: std.Io.Dir) ![HEX_LEN]u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const files = try fileSet(arena, io, root);
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    for (files) |p| {
        const bytes = try root.readFileAlloc(io, p, arena, .unlimited);
        h.update(p);
        h.update(&.{0});
        h.update(bytes);
        h.update(&.{0});
    }
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// The backend partition (decision 249 of 1.0.11-beta), relative to the
/// checkout: which of the file set's sources belong to one backend.
pub const PARTITION = "modules/compiler-core/src/codegen/backend-partition.txt";

/// The targets a partition line may name.
pub const TARGETS = [_][]const u8{ "commonJS", "erlang", "beam", "wasm" };

/// The hex SHA-256 of the file set under `root` a build for `target` reads
/// (decision 249): every source the partition (`PARTITION`) does not list
/// under a target — the shared ones —, and the ones it lists under `target`.
/// A listed file of another backend is left out, so editing it moves no
/// other target's hash. The code cache's closure key holds it
/// (`compiler-cli` `code_cache.zig`, decision 509 (3)). A checkout without the
/// partition file hashes as if every source were shared.
pub fn partitionHash(gpa: std.mem.Allocator, io: std.Io, root: std.Io.Dir, target: []const u8) ![HEX_LEN]u8 {
    const all = try partitionHashes(gpa, io, root);
    for (TARGETS, all) |t, h| if (std.mem.eql(u8, t, target)) return h;
    return error.UnknownTarget;
}

/// `partitionHash` for every target of `TARGETS`, in that order, each source
/// read once.
pub fn partitionHashes(gpa: std.mem.Allocator, io: std.Io, root: std.Io.Dir) ![TARGETS.len][HEX_LEN]u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // `<path>` → the target that owns it, from the partition.
    var owned: std.StringHashMapUnmanaged([]const u8) = .empty;
    if (root.readFileAlloc(io, PARTITION, arena, .unlimited)) |text| {
        var lines = std.mem.splitScalar(u8, text, '\n');
        while (lines.next()) |raw| {
            const line = std.mem.trim(u8, raw, " \t\r");
            if (line.len == 0 or line[0] == '#') continue;
            var it = std.mem.tokenizeAny(u8, line, " \t");
            const t = it.next() orelse continue;
            const p = it.next() orelse continue;
            for (TARGETS) |known| {
                if (std.mem.eql(u8, known, t)) try owned.put(arena, p, known);
            }
        }
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }

    const files = try fileSet(arena, io, root);
    var hs: [TARGETS.len]std.crypto.hash.sha2.Sha256 = undefined;
    for (&hs, TARGETS) |*h, t| {
        h.* = std.crypto.hash.sha2.Sha256.init(.{});
        h.update("target\x00");
        h.update(t);
        h.update(&.{0});
    }
    for (files) |p| {
        const bytes = try root.readFileAlloc(io, p, arena, .unlimited);
        const owner = owned.get(p);
        for (&hs, TARGETS) |*h, t| {
            if (owner) |o| if (!std.mem.eql(u8, o, t)) continue;
            h.update(p);
            h.update(&.{0});
            h.update(bytes);
            h.update(&.{0});
        }
    }
    var out: [TARGETS.len][HEX_LEN]u8 = undefined;
    for (&hs, &out) |*h, *o| {
        var digest: [32]u8 = undefined;
        h.final(&digest);
        o.* = std.fmt.bytesToHex(digest, .lower);
    }
    return out;
}

/// `ROOTS`' files under `root`, sorted.
fn fileSet(arena: std.mem.Allocator, io: std.Io, root: std.Io.Dir) ![]const []const u8 {
    var files: std.ArrayListUnmanaged([]const u8) = .empty;
    for (ROOTS) |r| {
        const st = root.statFile(io, r, .{}) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (st.kind == .directory) {
            try collect(arena, io, root, r, &files);
        } else if (st.kind == .file) {
            try files.append(arena, r);
        }
    }
    std.mem.sortUnstable([]const u8, files.items, {}, lessThan);
    return files.items;
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

fn skipDir(name: []const u8) bool {
    if (name.len > 0 and name[0] == '.') return true;
    for (SKIP_DIRS) |s| if (std.mem.eql(u8, name, s)) return true;
    return false;
}

fn collect(
    arena: std.mem.Allocator,
    io: std.Io,
    root: std.Io.Dir,
    rel: []const u8,
    files: *std.ArrayListUnmanaged([]const u8),
) !void {
    var dir = try root.openDir(io, rel, .{ .iterate = true });
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        const child = try std.fmt.allocPrint(arena, "{s}/{s}", .{ rel, entry.name });
        switch (entry.kind) {
            .directory => if (!skipDir(entry.name)) try collect(arena, io, root, child, files),
            .file => if (!std.mem.endsWith(u8, entry.name, ".md")) try files.append(arena, child),
            else => {},
        }
    }
}

/// Why `checkFresh` refused.
pub const Stale = struct {
    root: []const u8,
    built: []const u8,
    now: [HEX_LEN]u8,
};

/// Compare the hash a binary was built with (`built`, over the checkout at
/// `root`) with the hash of that checkout now. Null when they agree, or when
/// `root` is not a checkout on this machine (an installed release binary,
/// built elsewhere, has no sources here to be stale against). A checkout that
/// exists but cannot be read is not "fresh": the error is returned.
pub fn checkFresh(gpa: std.mem.Allocator, io: std.Io, root: []const u8, built: []const u8) !?Stale {
    var dir = std.Io.Dir.cwd().openDir(io, root, .{}) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return null,
        else => return err,
    };
    defer dir.close(io);
    dir.access(io, "build.zig", .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    const now = try hash(gpa, io, dir);
    if (std.mem.eql(u8, &now, built)) return null;
    return .{ .root = root, .built = built, .now = now };
}

/// The refusal a library run prints for `s`.
pub fn render(buf: []u8, s: Stale, what: []const u8) []const u8 {
    return std.fmt.bufPrint(buf,
        \\{s} was built from {s} and its sources have changed since (built {s}, now {s}).
        \\A library run against a stale compiler measures the previous compiler; run `zig build` in {s} first.
        \\
    , .{ what, s.root, s.built[0..12], s.now[0..12], s.root }) catch "the compiler binary is stale: run `zig build` in its checkout first\n";
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "the hash moves with a source's bytes, not with the order or a skipped tree" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const d = tmp.dir;
    try d.createDirPath(io, "modules/compiler-core/src/tests");
    try d.createDirPath(io, "libs/std/src");
    try d.writeFile(io, .{ .sub_path = "build.zig", .data = "b" });
    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/a.zig", .data = "a" });
    try d.writeFile(io, .{ .sub_path = "libs/std/src/m.bp", .data = "m" });
    const h0 = try hash(gpa, io, d);

    // A skipped tree, a document and a hidden directory move nothing.
    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/tests/t.zig", .data = "t" });
    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/AGENTS.md", .data = "doc" });
    try d.createDirPath(io, "libs/std/.botopinkbuild");
    try d.writeFile(io, .{ .sub_path = "libs/std/.botopinkbuild/x", .data = "x" });
    try std.testing.expectEqualStrings(&h0, &(try hash(gpa, io, d)));

    // A source's bytes do.
    try d.writeFile(io, .{ .sub_path = "libs/std/src/m.bp", .data = "m2" });
    const h1 = try hash(gpa, io, d);
    try std.testing.expect(!std.mem.eql(u8, &h0, &h1));
}

test "checkFresh: agreeing hashes and a missing checkout are fresh; a moved source is not" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "build.zig", .data = "b" });
    var root_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try tmp.dir.realPath(io, &root_buf);
    const root = root_buf[0..n];

    const built = try hash(gpa, io, tmp.dir);
    try std.testing.expect((try checkFresh(gpa, io, root, &built)) == null);
    try std.testing.expect((try checkFresh(gpa, io, "/nonexistent/botopink-checkout", &built)) == null);

    try tmp.dir.writeFile(io, .{ .sub_path = "build.zig", .data = "b2" });
    const stale = (try checkFresh(gpa, io, root, &built)).?;
    try std.testing.expectEqualStrings(&built, stale.built);
}

test "partitionHash: a backend's file moves its target's hash alone; a shared file moves every one" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const d = tmp.dir;
    try d.createDirPath(io, "modules/compiler-core/src/codegen");
    try d.writeFile(io, .{ .sub_path = "build.zig", .data = "b" });
    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/checker.zig", .data = "c" });
    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/codegen/wat.zig", .data = "w" });
    try d.writeFile(io, .{ .sub_path = PARTITION, .data = "# list\nwasm modules/compiler-core/src/codegen/wat.zig\n" });
    const e0 = try partitionHash(gpa, io, d, "erlang");
    const w0 = try partitionHash(gpa, io, d, "wasm");
    try std.testing.expect(!std.mem.eql(u8, &e0, &w0));

    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/codegen/wat.zig", .data = "w2" });
    try std.testing.expectEqualStrings(&e0, &(try partitionHash(gpa, io, d, "erlang")));
    const w1 = try partitionHash(gpa, io, d, "wasm");
    try std.testing.expect(!std.mem.eql(u8, &w0, &w1));

    try d.writeFile(io, .{ .sub_path = "modules/compiler-core/src/checker.zig", .data = "c2" });
    try std.testing.expect(!std.mem.eql(u8, &e0, &(try partitionHash(gpa, io, d, "erlang"))));
    try std.testing.expect(!std.mem.eql(u8, &w1, &(try partitionHash(gpa, io, d, "wasm"))));
}
