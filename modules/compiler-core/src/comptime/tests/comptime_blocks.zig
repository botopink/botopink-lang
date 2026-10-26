//! Decision 788 — a top-level `comptime { … }` through the same
//! `comptime.compile` the CLI runs: the blocks run at build in the order
//! written, a function whose every parameter is `comptime` is expanded at the
//! call, and what they print is the module's build output
//! (`OkData.build_output`, which `botopink build` / `run` write to stdout).
//! The CLI's former `cell check` recorded no build output (796), so the cells
//! `module_comptime_block` and `module_comptime_block_rules` hold the run and
//! these tests the build — decision 793 (1)'s `throw`, (5)'s prints of a
//! `comptime` in a function body; (4)'s replay is `level_b.zig`'s test —
//! and decision 808's: a function writing `compiler.init` expanded at a
//! run-time call, in a `comptime { … }` of a function body, refused in a
//! decorator's (`comptime_init_at_call_site` holds the run).

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const ast = @import("../../ast.zig");

/// The one module's build output, or its type error's message as `error: …`.
fn buildOutput(gpa: std.mem.Allocator, source: []const u8) ![]u8 {
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = source, .srcPath = "src/main.bp", .root = true }}, std.testing.io, null);
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

test "decision 789 (4): a handled load that returns is read as a `case` on its answer, so the block expands the function" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(
        \\import {compiler, io.terminal.print} from "std";
        \\fn runCase(comptime name: string) -> void {
        \\    val loaded = try comptime compiler.load("cases/" + name) catch { r ->
        \\        compiler.init({ -> print("refused " + name) });
        \\        return;
        \\    };
        \\    compiler.init({ -> print(try loaded.run() catch { f -> f.message }) });
        \\}
        \\comptime {
        \\    runCase("fine");
        \\}
        \\pub fn main() -> void {}
    );
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    var block: ?[]const ast.Stmt = null;
    for (program.decls) |d| switch (d) {
        // `runCase` was expanded and leaves the program.
        .@"fn" => |f| if (std.mem.eql(u8, f.name, "runCase")) return error.TestUnexpectedResult else if (std.mem.eql(u8, f.name, "__bp_comptime_0")) {
            block = f.body;
        },
        else => {},
    };
    // The call is the block of the body; its one statement the `case` on the
    // load's answer, `Ok(loaded)` holding what followed and `Error(r)` the
    // handler without its `return`.
    const call = block.?[0].expr.collection.kind.case.arms[0].body.function.kind.body;
    try std.testing.expectEqual(@as(usize, 1), call.len);
    const lifted = call[0].expr.collection.kind.case;
    try std.testing.expect(!lifted.isBlock);
    try std.testing.expectEqual(@as(usize, 2), lifted.arms.len);
    for (lifted.arms) |arm| {
        try std.testing.expectEqual(@as(usize, 1), arm.body.function.kind.body.len);
        try std.testing.expect(!ast.exprMayExitEarly(arm.body.function.kind.body[0].expr));
    }
}

test "decision 793 (1): a `throw` inside a top-level block is refused `comptime-block-exit`" {
    const gpa = std.testing.allocator;
    const src =
        \\import {io.terminal.print} from "std";
        \\
        \\comptime {
        \\    print("block");
        \\    throw "stop";
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("main");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "error: comptime-block-exit: "));
}

test "decision 904: a block refused by `compiler.fail` after a print keeps the print as the refused module's build output" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    print("building");
        \\    compiler.fail("stopped");
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true }}, std.testing.io, null);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| if (std.mem.eql(u8, o.name, "main")) {
        try std.testing.expect(o.outcome == .typeError);
        const trace = o.target_trace orelse return error.Unexpected;
        try std.testing.expectEqualStrings("building\n", trace.build_output);
        return;
    };
    return error.Unexpected;
}

test "decision 793 (1): a `return` inside a lambda of a block is the lambda's, not the block's" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    compiler.init({ ->
        \\        print("init");
        \\        return;
        \\    });
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("main");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("", got);
}

test "decision 793 (5): a `comptime { … }` inside a function body writes its prints as build output, a `void` one and one that answers a value" {
    const gpa = std.testing.allocator;
    const src =
        \\import {io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    comptime {
        \\        print("first");
        \\    };
        \\    val n = comptime {
        \\        print("second");
        \\        1 + 1
        \\    };
        \\    print("main " + n.toString());
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("first\nsecond\n", got);
}

// Decisions 788 (2), 793 (5), 789 (1): a function body's `comptime { … }` prints once also
// in a module holding a top-level block, whose own print and `compiler.init` are not re-run.
test "body_block_prints_once_beside_top_level_block" {
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
        \\    print("top");
        \\    f("a");
        \\}
        \\
        \\pub fn main() -> void {
        \\    comptime {
        \\        print("body");
        \\    };
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("top\nbuild a\nbody\n", got);
}

test "decision 808 (4): a `comptime { … }` in a function body runs its lines and the expanded function's at build, in order; the executor is the run's" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\fn check(comptime name: string) -> void {
        \\    print("build " + name);
        \\    compiler.init({ -> print("case " + name) });
        \\}
        \\
        \\pub fn main() -> void {
        \\    comptime {
        \\        print("before");
        \\        check("x");
        \\        print("after");
        \\    }
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("before\nbuild x\nafter\n", got);
}

test "decision 808 (1), (2): a `pub` function writing `compiler.init` type-checks in its own module; a run-time call runs its build-only lines at build and prints nothing there" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn check(comptime name: string) -> void {
        \\    val label = "case " + name;
        \\    compiler.init({ -> print(label) });
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("antes");
        \\    check("soma");
        \\    print("depois");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expectEqualStrings("", got);
}

test "decision 808 (3): a decorator's body calling a function that writes `compiler.init` is refused at the call" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\fn check(comptime name: string) -> void {
        \\    compiler.init({ -> print(name) });
        \\}
        \\
        \\fn mark(syntax decl: unknown) -> void {
        \\    check("decorator");
        \\}
        \\
        \\#[mark]
        \\pub fn main() -> void {
        \\    print("main");
        \\}
        \\
    ;
    const got = try buildOutput(gpa, src);
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "error: compiler-output-outside-decorator: `check` writes `compiler.init`"));
}
