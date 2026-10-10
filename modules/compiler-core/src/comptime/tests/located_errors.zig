//! C-21 — every `TypeError` the checker raises carries a location.
//!
//! Walks every refusal the language tests pin (`tests/language/reject/*.bp`,
//! one program each, refused by `botopink check`) through the same
//! `comptime.compile` the CLI runs, and requires each type error to carry a
//! `loc`. An unlocated error renders as a message with no ` --> file:L:C`
//! line and no source excerpt: the reader is told what is wrong and not
//! where. The checker's own unit tests hold the same line from the other side
//! — `assertTypeErrorSnap` and `typeErrorMessage` refuse an unlocated error.
//!
//! A cell that does not reach the checker (a parse error, a CLI refusal such
//! as an unresolved import) is not a type error and is not counted here; the
//! runner requires its `.expect` to name a location.

const std = @import("std");
const test_scratch = @import("test_scratch");
const comptimeMod = @import("../../comptime.zig");
const hostRuntime = @import("../runtime/runtime.zig");

const reject_dir = "../../tests/language/reject";

test "C-21: every type error a reject cell raises carries a location" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var dir = try std.Io.Dir.cwd().openDir(io, reject_dir, .{ .iterate = true });
    defer dir.close(io);

    var names: std.ArrayList([]u8) = .empty;
    defer {
        for (names.items) |n| gpa.free(n);
        names.deinit(gpa);
    }
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".bp")) continue;
        try names.append(gpa, try gpa.dupe(u8, entry.name));
    }
    std.mem.sort([]u8, names.items, {}, struct {
        fn lt(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);
    // The corpus is the language tests' refusals; an empty walk measures nothing.
    try std.testing.expect(names.items.len > 100);

    const prev_rt = hostRuntime.force(.beam);
    defer _ = hostRuntime.force(prev_rt);
    const build_root = test_scratch.path(io, "comptime/located_errors");

    var type_errors: usize = 0;
    var unlocated: std.ArrayList(u8) = .empty;
    defer unlocated.deinit(gpa);
    for (names.items) |name| {
        const src = try dir.readFileAlloc(io, name, gpa, .unlimited);
        defer gpa.free(src);
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
