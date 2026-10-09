//! Decision 280 — typed comptime decorator arguments (`01-checker` step 24):
//! a `comptime` parameter takes a default, a decorator's argument is one
//! expression kept as its source span and located, and an annotation list
//! written one per line may end with a comma.

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

test "decision 280: a comptime parameter takes a default and is located" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\fn mark(comptime decl: @Decl, comptime n: i32 = 3, size: i32 = 4) { }
    );
    const params = program.decls[0].@"fn".params;
    try std.testing.expect(params[1].modifier == .@"comptime");
    try std.testing.expect(params[1].default != null);
    try std.testing.expectEqual(@as(usize, 31), params[1].loc.col);
    try std.testing.expectEqual(@as(usize, 52), params[2].loc.col);
}

test "decision 280: a decorator argument is one expression, spanned and located" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\#[mark([1, 2], Cache<Item[]>("items"), env("X"), at: .confirm, -20)]
        \\type A(x: i32)
    );
    const ann = program.decls[0].type_.annotations[0];
    try std.testing.expectEqual(@as(usize, 5), ann.args.len);
    try std.testing.expectEqualStrings("[1, 2]", ann.args[0]);
    try std.testing.expectEqualStrings("Cache<Item[]>(\"items\")", ann.args[1]);
    try std.testing.expectEqualStrings("env(\"X\")", ann.args[2]);
    try std.testing.expectEqualStrings(".confirm", ann.args[3]);
    try std.testing.expectEqualStrings("at", ann.labelOf(3).?);
    try std.testing.expectEqualStrings("-20", ann.args[4]);
    try std.testing.expectEqual(@as(usize, 8), ann.argLoc(0).?.col);
    try std.testing.expectEqual(@as(usize, 40), ann.argLoc(2).?.col);
    try std.testing.expectEqual(@as(usize, 54), ann.argLoc(3).?.col);
}

test "decision 280: an annotation list may end with a comma" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\#[
        \\    check("a", at: .confirm),
        \\    check("b"),
        \\]
        \\type Account(confirm: string)
    );
    const anns = program.decls[0].type_.annotations;
    try std.testing.expectEqual(@as(usize, 2), anns.len);
    try std.testing.expectEqual(@as(usize, 2), anns[0].argLoc(1).?.line);
    try std.testing.expectEqual(@as(usize, 20), anns[0].argLoc(1).?.col);
}
