//! Decision 529 (2) — `..props: R`, a record parameter: told from a variadic
//! `..values: T[]` by its type, a named record-like type against an array.

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

test "decision 529: `..props: R` is a record parameter, `..xs: T[]` a variadic" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\fn Card(..props: CardProps, onClick: fn() -> void) -> string { return ""; }
        \\fn total(label: string, ..values: i32[]) -> i32 { return 0; }
    );
    const card = program.decls[0].@"fn".params;
    try std.testing.expect(card[0].recordParam);
    try std.testing.expect(!card[0].variadic);
    try std.testing.expect(!card[1].recordParam);
    const total = program.decls[1].@"fn".params;
    try std.testing.expect(total[1].variadic);
    try std.testing.expect(!total[1].recordParam);
}

test "decision 529: a record parameter may be followed by other parameters and takes no default" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\fn Card(..props: CardProps = CardProps(title: "a")) -> string { return ""; }
    ));
    // A primitive after `..` stays 267's `variadic-not-array`.
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\fn one(..value: i32) -> i32 { return 0; }
    ));
}
