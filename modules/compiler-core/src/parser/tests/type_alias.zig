//! parser: type aliases (decision 118 rule 1) — `[pub] type Name<A, B> = T;`,
//! a declaration of its own (`DeclKind.typeAlias`), told apart from
//! `type Name<G>(fields) { … }` by the `=` after the name and its parameters.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const expectError = @import("helpers.zig").expectErrorAt;

fn parseOne(arena: std.mem.Allocator, src: []const u8) !ast.DeclKind {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(arena);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = try p.parse(arena);
    try std.testing.expectEqual(@as(usize, 1), program.decls.len);
    return program.decls[0];
}

test "type alias: `type Id = i32;` is an alias of a named type" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const d = try parseOne(arena.allocator(), "type Id = i32;");
    try std.testing.expect(d == .typeAlias);
    try std.testing.expectEqualStrings("Id", d.typeAlias.name);
    try std.testing.expect(!d.typeAlias.isPub);
    try std.testing.expectEqual(@as(usize, 0), d.typeAlias.genericParams.len);
    try std.testing.expectEqualStrings("i32", d.typeAlias.target.named);
    try std.testing.expectEqual(ast.Loc{ .line = 1, .col = 1 }, d.typeAlias.loc);
    try std.testing.expectEqual(ast.Loc{ .line = 1, .col = 11 }, d.typeAlias.targetLoc);
}

test "type alias: `pub type Parser<T> = @Result<T, ParseError>;` keeps its parameters and the builtin target" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const d = try parseOne(arena.allocator(), "pub type Parser<T> = @Result<T, ParseError>;");
    const a = d.typeAlias;
    try std.testing.expect(a.isPub);
    try std.testing.expectEqual(@as(usize, 1), a.genericParams.len);
    try std.testing.expectEqualStrings("T", a.genericParams[0].name);
    try std.testing.expect(a.target.generic.is_builtin);
    try std.testing.expectEqualStrings("Result", a.target.generic.name);
    try std.testing.expectEqual(@as(usize, 2), a.target.generic.args.len);
}

test "type alias: two parameters and a structural target" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const d = try parseOne(arena.allocator(), "type Pair<A, B> = #(A, B);");
    try std.testing.expectEqual(@as(usize, 2), d.typeAlias.genericParams.len);
    try std.testing.expectEqual(@as(usize, 2), d.typeAlias.target.tuple_.len);
}

test "type alias: a union and a function type are targets like any other" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const u = try parseOne(arena.allocator(), "type Num = i32 | f64;");
    try std.testing.expect(u.typeAlias.target.unionMembers() != null);
    const f = try parseOne(arena.allocator(), "type Handler = fn(string) -> ?i32;");
    try std.testing.expect(f.typeAlias.target == .function);
}

test "type alias: `type Name<G>(fields)` is still a record, not an alias" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const d = try parseOne(arena.allocator(), "type Box<T>(v: T)");
    try std.testing.expect(d == .type_);
}

test "type alias: the `;` is required" {
    try expectError("type Id = i32\ntype B = i32;", .unexpectedToken, 2, 1);
}

test "type alias: a parameter default is refused at its `=`" {
    try expectError("type P<T = i32> = T[];", .typeAliasGenericDefault, 1, 10);
}

test "type alias: an annotation is refused at the annotation" {
    try expectError("#[deprecated] type Id = i32;", .typeAliasAnnotated, 1, 1);
}
