//! Decision 539 — `defer <expr>;` marks a statement (`Stmt.deferred`); the AST
//! dump names the flag only when it is set, and `defer` is no expression.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");

fn parse(arena: std.mem.Allocator, src: []const u8) !ast.Program {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(arena);
    var p = parserMod.Parser.init(tokens);
    return p.parse(arena);
}

test "decision 539: `defer` marks the statement, a block is a block expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\fn f() {
        \\    defer print("a");
        \\    defer { print("b"); }
        \\    print("c");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    const body = program.decls[0].@"fn".body;
    try std.testing.expectEqual(@as(usize, 3), body.len);
    try std.testing.expect(body[0].deferred);
    try std.testing.expect(body[1].deferred);
    try std.testing.expect(!body[2].deferred);
}

test "decision 539: a deferred statement at the end answers no tail" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\fn f() {
        \\    defer print("a")
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    const body = program.decls[0].@"fn".body;
    try std.testing.expect(body[0].deferred);
    try std.testing.expect(body[0].tail == .none);
}

test "decision 539: the dump carries `deferred` only when set" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(), "fn f() { defer g(); h(); }");
    const body = program.decls[0].@"fn".body;
    const first = try std.json.Stringify.valueAlloc(arena.allocator(), body[0], .{});
    const second = try std.json.Stringify.valueAlloc(arena.allocator(), body[1], .{});
    try std.testing.expect(std.mem.indexOf(u8, first, "\"deferred\":true") != null);
    try std.testing.expect(std.mem.indexOf(u8, second, "deferred") == null);
}

test "decision 539: `defer` in expression position is a parse error" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(), "fn f() { val x = defer g(); }"));
}
