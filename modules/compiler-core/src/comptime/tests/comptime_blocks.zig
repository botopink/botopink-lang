//! Decision 788 — a top-level `comptime { … }` through the same
//! `comptime.compile` the CLI runs: the blocks run at build in the order
//! written, a function whose every parameter is `comptime` is expanded at the
//! call, and what they print is the module's build output
//! (`OkData.build_output`, which `botopink build` / `run` write to stdout).
//! `botopink cell check` records no build output until 789 (B-160), so the
//! cell `module_comptime_block` holds the run and these tests the build.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;

/// The one module's build output, or its type error's message as `error: …`.
fn buildOutput(gpa: std.mem.Allocator, source: []const u8) ![]u8 {
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = source, .srcPath = "src/main.bp", .root = true }}, std.testing.io, null, null);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| if (std.mem.eql(u8, o.name, "main")) switch (o.outcome) {
        .ok => |ok| return gpa.dupe(u8, ok.build_output),
        .typeError => |te| {
            const m = try te.message(gpa);
            defer gpa.free(m);
            return std.fmt.allocPrint(gpa, "error: {s}", .{m});
        },
        else => return error.Unexpected,
    };
    return error.Unexpected;
}

test "decision 788: two top-level blocks print at build in the order written, the expanded function's prints in each" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\fn f(comptime n: string) -> void {
        \\    print("build " + n);
        \\    compiler.init({ -> print("init " + n) });
        \\}
        \\
        \\comptime {
        \\    print("first block");
        \\    f("a");
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("main");
        \\}
        \\
        \\comptime {
        \\    f("b");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("first block\nbuild a\nbuild b\n", got);
}

test "decision 788: a block writes to no declaration — `compiler.setMeta` is refused there" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    compiler.setMeta(1);
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("main");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "error: compiler-output-outside-decorator: `compiler.setMeta`"));
}

test "decision 788: a block is read onto a decorator over an anchor, and a private function every call of which it expanded leaves the program" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(
        \\import {compiler, io.terminal.print} from "std";
        \\fn f(comptime n: string) -> void {
        \\    compiler.init({ -> print(n) });
        \\}
        \\fn g(comptime n: string) -> void {
        \\    print(n);
        \\}
        \\comptime {
        \\    f("a");
        \\    g("b");
        \\}
        \\pub fn main() -> void {}
    );
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| try names.append(arena, f.name),
        .val => |v| try names.append(arena, v.name),
        else => {},
    };
    // `f` was expanded and leaves; `g` writes no `compiler.init`, is called
    // at build as a decorator body calls a function, and stays.
    const want = [_][]const u8{ "g", "__bp_comptime_0", "__bp_comptime_0_at", "main" };
    try std.testing.expectEqual(want.len, names.items.len);
    for (want, names.items) |w, n| try std.testing.expectEqualStrings(w, n);
}
