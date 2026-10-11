//! C-21 — every `TypeError` the checker raises carries a location.
//!
//! Walks every single-file conformance cell every target refuses
//! (`conformance/modules/<cell>/src/main.bp` alone, its
//! `snapshot/output/main.snap` holding a `refused` record — the former
//! `tests/language/reject/` cells) through the same `comptime.compile` the CLI
//! runs, and requires each type error to carry a `loc`. An unlocated error renders as a message with no ` --> file:L:C`
//! line and no source excerpt: the reader is told what is wrong and not
//! where. The checker's own unit tests hold the same line from the other side
//! — `assertTypeErrorSnap` and `typeErrorMessage` refuse an unlocated error.
//!
//! A cell that does not reach the checker (a parse error, a CLI refusal such
//! as an unresolved import) is not a type error and is not counted here; the
//! cell's snapshot names its location (`at <file>:<line>:<col>`).

const std = @import("std");
const test_scratch = @import("test_scratch");
const comptimeMod = @import("../../comptime.zig");

const cells_dir = "../../conformance/modules";

/// The cell's one source when it is a single-file cell every target refuses:
/// `src/` holds `main.bp` alone and `snapshot/output/main.snap` a `refused`
/// record. Null otherwise.
fn refusedSingleFile(gpa: std.mem.Allocator, io: std.Io, cells: std.Io.Dir, name: []const u8) !?[]u8 {
    var cell = cells.openDir(io, name, .{}) catch return null;
    defer cell.close(io);
    const snap = cell.readFileAlloc(io, "snapshot/output/main.snap", gpa, .limited(1024 * 1024)) catch return null;
    defer gpa.free(snap);
    if (std.mem.indexOf(u8, snap, "\nrefused ") == null) return null;
    var src = cell.openDir(io, "src", .{ .iterate = true }) catch return null;
    defer src.close(io);
    var it = src.iterate();
    var count: usize = 0;
    while (try it.next(io)) |e| {
        count += 1;
        if (e.kind != .file or !std.mem.eql(u8, e.name, "main.bp")) return null;
    }
    if (count != 1) return null;
    return try src.readFileAlloc(io, "main.bp", gpa, .unlimited);
}

test "C-21: every type error a reject cell raises carries a location" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var dir = try std.Io.Dir.cwd().openDir(io, cells_dir, .{ .iterate = true });
    defer dir.close(io);

    var names: std.ArrayList([]u8) = .empty;
    defer {
        for (names.items) |n| gpa.free(n);
        names.deinit(gpa);
    }
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .directory) continue;
        try names.append(gpa, try gpa.dupe(u8, entry.name));
    }
    std.mem.sort([]u8, names.items, {}, struct {
        fn lt(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);

    const build_root = test_scratch.path(io, "comptime/located_errors");

    var type_errors: usize = 0;
    var unlocated: std.ArrayList(u8) = .empty;
    defer unlocated.deinit(gpa);
    var walked: usize = 0;
    for (names.items) |name| {
        const src = (try refusedSingleFile(gpa, io, dir, name)) orelse continue;
        defer gpa.free(src);
        walked += 1;
        var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src }}, io, build_root, null);
        defer session.deinit(gpa);
        for (session.outputs.items) |output| switch (output.outcome) {
            .typeError => |te| {
                type_errors += 1;
                if (te.loc == null) {
                    const msg = try te.message(gpa);
                    defer gpa.free(msg);
                    try unlocated.print(gpa, "  {s}: {s}\n", .{ name, msg });
                }
            },
            else => {},
        };
    }
    // The corpus is the conformance suite's refusals; an empty walk measures nothing.
    try std.testing.expect(walked > 100);
    if (unlocated.items.len > 0) {
        std.debug.print("\nC-21: unlocated type errors ({d} type errors walked):\n{s}", .{ type_errors, unlocated.items });
        return error.UnlocatedTypeError;
    }
    try std.testing.expect(type_errors > 50);
}

// An embedded std module is parsed before any program module is read, from
// the source the build embedded. One that does not parse — a reserved word
// used as a name in a `libs/std/src` file — reached the CLI as
// `compilation failed` / `UnexpectedToken`, with no file and no line. It is
// located at the std file it was built from, rendered as any module's parse
// error is, and the build stops with `error.EmbeddedStdRefused`.
test "an embedded std module that does not parse is located at its libs/std/src file" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const src =
        \\pub fn ok() -> i32 {
        \\    return 1;
        \\}
        \\
        \\fn reservedProbe(from: string) -> string {
        \\    return from;
        \\}
        \\
    ;
    var lx = @import("../../lexer.zig").Lexer.init(src);
    var p = @import("../../parser.zig").Parser.init(try lx.scanAll(a));
    try std.testing.expectError(error.UnexpectedToken, p.parse(a));
    const text = try comptimeMod.embeddedStdDiagnostic(a, "std/path", src, null, &p);
    try std.testing.expect(std.mem.indexOf(u8, text, "error[reserved-word-as-name]") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "--> libs/std/src/path.bp:5:18") != null);
    try std.testing.expectError(error.EmbeddedStdRefused, comptimeMod.parseEmbeddedStd(a, "std/path", src));
}
