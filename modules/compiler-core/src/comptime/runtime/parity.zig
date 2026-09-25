//! The invariant between the two comptime runtimes (front 18 step 3): the
//! BEAM runtime and the wat runtime answer every evaluation the same.
//!
//! The codegen snapshot harness asserts it on every fixture
//! (`codegen/tests/helpers.zig` `generate` runs each evaluation on both
//! runtimes through `runtime.parity`); this file pins that the comparison
//! is live — a program with a template and a decorator is evaluated on both,
//! the evaluations are counted — and that it has teeth: the same module with a
//! prelude helper edited on one side is reported, both answers printed.
const std = @import("std");
const codegen = @import("../../codegen.zig");
const runtime = @import("runtime.zig");
const etf = @import("etf.zig");
const Term = @import("../../codegen/beam/term.zig").Term;
const test_scratch = @import("test_scratch");

const program =
    \\pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    \\    val t = q.text().trim();
    \\    val words = t.split(" ").map({ w -> w.toUpper() });
    \\    return q.build("\"" + words.join(",") + "\"");
    \\}
    \\
    \\pub fn describe(comptime decl: @Decl) {
    \\    val names = decl.fields.map({ f -> f.name });
    \\    @emit("pub fn describe" + decl.name + "() -> string { return \"" + names.join("_") + "\"; }");
    \\}
    \\
    \\#[describe]
    \\type User(name: string, age: i32)
    \\
    \\val s = shout " hello big world ";
    \\
    \\fn main() {
    \\    @print(s);
    \\    @print(describeUser());
    \\}
;

test "parity: a template and a decorator answer the same on both runtimes" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var parity: runtime.Parity = .{ .alloc = alloc };
    defer parity.deinit();
    const prev = runtime.parity;
    runtime.parity = &parity;
    defer runtime.parity = prev;
    defer test_scratch.remove(io, "comptime-parity");

    for ([_]codegen.TargetSource{ .commonJS, .erlang }) |target| {
        var outputs = try codegen.generateWith(alloc, &.{.{ .path = "", .source = program }}, io, .{
            .targetSource = target,
            .build_root = test_scratch.path(io, "comptime-parity"),
            .packages = @import("../../codegen/crossModule.zig").test_packages,
        }, .{ .execute = false });
        defer {
            for (outputs.items) |*o| o.result.deinit(alloc);
            outputs.deinit(alloc);
        }
        const r = outputs.items[0].result;
        if (r.failed()) {
            std.debug.print("\n{s}: {any}\n", .{ @tagName(target), r.comptime_err });
            return error.TestUnexpectedResult;
        }
    }
    if (parity.mismatches.items.len > 0) {
        var aw: std.Io.Writer.Allocating = .init(alloc);
        defer aw.deinit();
        try parity.report(&aw.writer);
        std.debug.print("\n{s}\n", .{aw.written()});
        return error.TestUnexpectedResult;
    }
    // At least the template and the decorator on each of the two targets
    // (the comptime pass may evaluate one declaration more than once).
    try std.testing.expect(parity.evaluations >= 4);
}

test "parity: a prelude helper edited on one side is a reported divergence" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const module_of = struct {
        fn text(name: []const u8, helper_body: []const u8) ![]const u8 {
            return std.fmt.allocPrint(std.testing.allocator,
                \\-module({s}).
                \\-export([main/1]).
                \\
                \\double(X) -> {s}.
                \\
                \\main({{Arg0}}) -> json:encode(#{{value => double(Arg0)}}).
                \\
            , .{ name, helper_body });
        }
    }.text;
    const original = try module_of("bp@parity_divergence_a", "X * 2");
    defer alloc.free(original);
    const edited = try module_of("bp@parity_divergence_b", "X * 2 + 1");
    defer alloc.free(edited);
    const arg = try etf.encode(arena, Term.tupleOf(&.{.{ .integer = 20 }}));
    const dir = test_scratch.path(io, "comptime-parity/erl");
    defer test_scratch.remove(io, "comptime-parity");

    const beam = try runtime.evalOn(arena, io, .beam, "parity", dir, "bp@parity_divergence_a", original, arg);
    const wat = try runtime.evalOn(arena, io, .wat, "parity", dir, "bp@parity_divergence_b", edited, arg);
    const same = try runtime.evalOn(arena, io, .wat, "parity", dir, "bp@parity_divergence_a", original, arg);

    var parity: runtime.Parity = .{ .alloc = alloc };
    defer parity.deinit();
    try parity.record("parity", "bp@parity_divergence_a", beam, same);
    try std.testing.expectEqual(@as(usize, 0), parity.mismatches.items.len);
    try parity.record("parity", "bp@parity_divergence", beam, wat);
    try std.testing.expectEqual(@as(usize, 1), parity.mismatches.items.len);

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try parity.report(&aw.writer);
    try std.testing.expect(std.mem.indexOf(u8, aw.written(), "beam: ok: {\"value\":40}") != null);
    try std.testing.expect(std.mem.indexOf(u8, aw.written(), "wat:  ok: {\"value\":41}") != null);
}
