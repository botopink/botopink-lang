//! Decision 579 (1) — `#[builtin] pub default declare val <name>: <Type>;`, the
//! one bodyless value declaration (std's `compiler`): `#[builtin]`, `pub`,
//! `default` and a type each required, no value.

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

test "decision 579: a builtin default value is a declaration of its own, with no value" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\#[builtin]
        \\pub default declare val compiler: Compiler;
    );
    try std.testing.expectEqual(@as(usize, 1), program.decls.len);
    const v = program.decls[0].builtinVal;
    try std.testing.expectEqualStrings("compiler", v.name);
    try std.testing.expectEqualStrings("builtin", v.annotations[0].name);
}

test "decision 579: without `#[builtin]`, with a value or without a type it is refused" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\#[other]
        \\pub default declare val compiler: Compiler;
    ));
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\#[builtin]
        \\pub default declare val compiler: Compiler = 1;
    ));
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\#[builtin]
        \\pub default declare val compiler;
    ));
}
