//! Decision 956 — the collection loop is 105's: the sources after `for`, the
//! body a block opening with one parameter per source. One source is written
//! bare or in parentheses (`bare` keeps the spelling); a bare source takes no
//! trailing lambda, so its `{` is the body's. Several sources (or one open
//! range) are the loop they mean, the written one kept in `forWritten`.
//! `for x in xs` is `for-in-loop`; a count other than the sources' is
//! `for-parameter-count` at the block.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const helpers = @import("helpers.zig");

fn parse(arena: std.mem.Allocator, src: []const u8) !ast.Program {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(arena);
    var p = parserMod.Parser.init(tokens);
    return p.parse(arena);
}

/// The loop that is the first statement of `fn f`'s body.
fn firstLoop(program: ast.Program) !ast.LoopExpr {
    const body = program.decls[0].@"fn".body;
    try std.testing.expect(body[0].expr == .loop);
    return body[0].expr.loop;
}

test "decision 956: `for xs { x -> … }` and `for (xs) { x -> … }` are one loop, `bare` keeping the spelling" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const bare = try firstLoop(try parse(arena.allocator(), "fn f() { for xs { x -> g(x); }; }"));
    const paren = try firstLoop(try parse(arena.allocator(), "fn f() { for (xs) { x -> g(x); }; }"));
    try std.testing.expectEqual(ast.LoopKeyword.for_, bare.keyword);
    try std.testing.expectEqual(ast.LoopKeyword.for_, paren.keyword);
    try std.testing.expect(bare.bare);
    try std.testing.expect(!paren.bare);
    try std.testing.expectEqualStrings("xs", bare.iter.identifier.kind.ident);
    try std.testing.expectEqualStrings("x", bare.params[0]);
    try std.testing.expectEqual(@as(usize, 1), bare.body.len);
}

test "decision 956: a bare source's call takes no trailing lambda — `for g.iter() { c -> … }`" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const lp = try firstLoop(try parse(arena.allocator(), "fn f() { for g.iter() { c -> total = total + c; }; }"));
    try std.testing.expectEqual(ast.LoopKeyword.for_, lp.keyword);
    try std.testing.expect(lp.iter.* == .call);
    try std.testing.expectEqual(@as(usize, 0), lp.iter.call.kind.call.trailing.len);
    try std.testing.expectEqualStrings("c", lp.params[0]);
    try std.testing.expectEqual(@as(usize, 1), lp.body.len);
}

test "decision 956: a bare builtin call and a namespaced call leave the `{` to the body" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const builtin = try firstLoop(try parse(arena.allocator(), "fn f() { for @TypeInfo.all(T) { d -> g(d); }; }"));
    try std.testing.expectEqual(ast.LoopKeyword.for_, builtin.keyword);
    try std.testing.expectEqualStrings("d", builtin.params[0]);
    try std.testing.expectEqual(@as(usize, 1), builtin.body.len);
    const ns = try firstLoop(try parse(arena.allocator(), "fn f() { for ns.f(1) { x -> g(x); }; }"));
    try std.testing.expect(ns.iter.* == .call);
    try std.testing.expectEqual(@as(usize, 0), ns.iter.call.kind.call.trailing.len);
    try std.testing.expectEqualStrings("x", ns.params[0]);
    const plain = try firstLoop(try parse(arena.allocator(), "fn f() { for make(2) { x -> g(x); }; }"));
    try std.testing.expect(plain.iter.* == .call);
    try std.testing.expectEqual(@as(usize, 0), plain.iter.call.kind.call.trailing.len);
}

test "decision 956: a bare source's call arguments keep their own lambdas" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const lp = try firstLoop(try parse(arena.allocator(), "fn f() { for pick(xs.map { x -> x * 2 }) { y -> g(y); }; }"));
    try std.testing.expect(lp.bare);
    try std.testing.expect(lp.iter.* == .call);
    try std.testing.expectEqual(@as(usize, 0), lp.iter.call.kind.call.trailing.len);
    try std.testing.expectEqualStrings("y", lp.params[0]);
}

test "decision 956: `for (a).b() { … }` — parentheses that are the source's own make a bare source" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const lp = try firstLoop(try parse(arena.allocator(), "fn f() { for (a).b() { x -> g(x); }; }"));
    try std.testing.expect(lp.bare);
    try std.testing.expect(lp.iter.* == .call);
}

test "decision 956: several sources are the loop they mean, the written one kept" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const lp = try firstLoop(try parse(arena.allocator(), "fn f() { for :outer (xs, g.iter(), 0...) { x, c, i -> h(x, c, i); }; }"));
    try std.testing.expectEqual(ast.LoopKeyword.loop, lp.keyword);
    const fw = lp.forWritten orelse return error.TestExpectedForWritten;
    try std.testing.expect(fw.parenthesised);
    try std.testing.expectEqualStrings("outer", fw.label.?);
    try std.testing.expectEqual(@as(usize, 3), fw.sources.len);
    try std.testing.expect(fw.sources[0] == .value);
    try std.testing.expect(fw.sources[2] == .range);
    try std.testing.expect(fw.sources[2].range.end == null);
    try std.testing.expect(fw.sources[2].range.inclusive);
    try std.testing.expectEqualStrings("i", fw.params[2]);
    try std.testing.expectEqual(@as(usize, 1), fw.body.len);
    // The built loop: the sources bound in order, the walk, the `break`.
    try std.testing.expect(lp.body[lp.body.len - 1].expr == .jump);
    const walk = lp.body[lp.body.len - 2].expr;
    try std.testing.expect(walk == .loop);
    try std.testing.expectEqual(ast.LoopKeyword.for_, walk.loop.keyword);
    try std.testing.expectEqualStrings("outer", walk.loop.label.?);
}

test "decision 956: one open range is the loop it means" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const bare = try firstLoop(try parse(arena.allocator(), "fn f() { for 0... { i -> g(i); }; }"));
    const fw = bare.forWritten orelse return error.TestExpectedForWritten;
    try std.testing.expect(!fw.parenthesised);
    try std.testing.expect(fw.sources[0] == .range);
    const paren = try firstLoop(try parse(arena.allocator(), "fn f() { for (0..) { i -> g(i); }; }"));
    try std.testing.expect(paren.forWritten != null);
}

test "decision 956: the built loop and the written one free cleanly" {
    const alloc = std.testing.allocator;
    const src = "fn f() { for (xs, 0..n, 1..., ys) { x, i, j, y -> if (x) { break; }; h(x, i, j, y); }; }";
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);
    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(alloc);
    program.deinit(alloc);
}

test "decision 956: a refused `for` frees what it read" {
    const alloc = std.testing.allocator;
    try helpers.expectParseFails(alloc, "fn f() { for (xs, ys) { x -> h(x); }; }");
    try helpers.expectParseFails(alloc, "fn f() { for xs, ys { x, y -> h(x); }; }");
    try helpers.expectParseFails(alloc, "fn f() { for x in xs { h(x); }; }");
}

test "decision 956: `for x in xs` is for-in-loop at the binder" {
    try helpers.expectErrorAt("fn f() { for x in xs { h(x); }; }", .forInLoop, 1, 14);
    try helpers.expectErrorAt("fn f() { for #(k, v) in d { h(k); }; }", .forInLoop, 1, 14);
    try helpers.expectErrorAt("fn f() { for (x in xs) { h(x); }; }", .forInLoop, 1, 14);
    try helpers.expectErrorAt("fn f() { for await x in s { h(x); }; }", .forInLoop, 1, 20);
}

test "decision 956: a parameter count other than the sources' is for-parameter-count at the block" {
    try helpers.expectErrorAt("fn f() { for (xs, ys) { x -> h(x); }; }", .forParameterCount, 1, 23);
    try helpers.expectErrorAt("fn f() { for xs { x, i -> h(x); }; }", .forParameterCount, 1, 17);
}

test "decision 956: several sources need their parentheses, and `for await` takes one" {
    try helpers.expectErrorAt("fn f() { for xs, ys { x, y -> h(x); }; }", .forSourcesParenthesised, 1, 16);
    try helpers.expectErrorAt("fn f() { for await (s, t) { x, y -> h(x); }; }", .forAwaitOneSource, 1, 22);
}
