/// A `.beam`'s record (decision 1007): on erlang and beam a module's `.beam`
/// in the target's folder (`out/erl/`, `out/beam/`) is loaded as it is while
/// the source it was compiled from is unchanged — the package's own modules
/// included. Beside each `<atom>.beam` lies `<atom>.beam.rec`, three lines:
///
///     source <SHA-256 of the .erl / .S bytes, hex>
///     compiler <the compiler's source stamp, `build_stamp.source_hash`>
///     otp <the OTP release, `otp.RELEASE`>
///
/// A compile step (`build.checkErlang`, `run.compileInto`) compiles only the
/// files whose record is missing or differs, or whose `.beam` is gone; the
/// record of a file it compiles is removed first and written once the step
/// succeeded, so a refused or interrupted compile leaves none. No file time is
/// read. `build --cold` recompiles every file (`all`); `run --cold` reuses a
/// matching record (1007 (3)). A dependency's `.beam` still comes from the code
/// cache of decision 509 when it is compiled at all.
const std = @import("std");
const build_stamp = @import("build_stamp");
const otp = @import("./otp.zig");

/// The record's suffix after the `.beam` it describes.
pub const EXT = ".rec";

/// The record a `.beam` compiled from `source` (its bytes) carries.
pub fn text(arena: std.mem.Allocator, source: []const u8) ![]const u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(source, &digest, .{});
    return std.fmt.allocPrint(arena, "source {s}\ncompiler {s}\notp {s}\n", .{ &std.fmt.bytesToHex(digest, .lower), build_stamp.source_hash, otp.RELEASE });
}

/// A source file and the `.beam` its compile writes.
pub const Pair = struct { src: []const u8, beam: []const u8 };

fn recordPath(arena: std.mem.Allocator, beam: []const u8) ![]const u8 {
    return std.mem.concat(arena, u8, &.{ beam, EXT });
}

/// Whether `p.beam` is there and its record is the one `p.src`'s bytes give.
pub fn matches(arena: std.mem.Allocator, io: std.Io, p: Pair) bool {
    const cwd = std.Io.Dir.cwd();
    cwd.access(io, p.beam, .{}) catch return false;
    const held = cwd.readFileAlloc(io, recordPath(arena, p.beam) catch return false, arena, .limited(4096)) catch return false;
    const src = cwd.readFileAlloc(io, p.src, arena, .unlimited) catch return false;
    const want = text(arena, src) catch return false;
    return std.mem.eql(u8, held, want);
}

/// The pairs to compile, in order: every one when `all`, else those that do
/// not match. The record of each is removed.
pub fn stale(arena: std.mem.Allocator, io: std.Io, pairs: []const Pair, all: bool) ![]const Pair {
    var out: std.ArrayListUnmanaged(Pair) = .empty;
    for (pairs) |p| {
        if (!all and matches(arena, io, p)) continue;
        std.Io.Dir.cwd().deleteFile(io, try recordPath(arena, p.beam)) catch {};
        try out.append(arena, p);
    }
    return out.items;
}

/// After a step that succeeded: the record of each compiled pair whose
/// `.beam` it wrote.
pub fn writeAll(arena: std.mem.Allocator, io: std.Io, pairs: []const Pair) void {
    const cwd = std.Io.Dir.cwd();
    for (pairs) |p| {
        cwd.access(io, p.beam, .{}) catch continue;
        const src = cwd.readFileAlloc(io, p.src, arena, .unlimited) catch continue;
        const rec = text(arena, src) catch continue;
        const path = recordPath(arena, p.beam) catch continue;
        cwd.writeFile(io, .{ .sub_path = path, .data = rec }) catch {};
    }
}

/// The sources of `pairs`.
pub fn sources(arena: std.mem.Allocator, pairs: []const Pair) ![]const []const u8 {
    const out = try arena.alloc([]const u8, pairs.len);
    for (pairs, out) |p, *o| o.* = p.src;
    return out;
}
