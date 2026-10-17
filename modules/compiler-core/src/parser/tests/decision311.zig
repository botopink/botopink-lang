//! Decision 311 — the template annotation `#[f "…"]` (`01-checker` step 29):
//! the template call `f "…"` written as an annotation, a node of its own
//! beside the call form — the literal kept as written and located, alone or
//! inside a `#[a, b]` list; a malformed hole is a parse error at the literal,
//! and a builtin `@` annotation takes no literal.

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

test "decision 311: a template annotation keeps its literal as written, located" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\type Users(n: i32) {
        \\    #[sql "select * from users where id = ${id} limit 1"]
        \\    pub fn find(self: Self, id: i32) -> i32 { return id; }
        \\}
    );
    const ann = program.decls[0].type_.methods[0].annotations[0];
    try std.testing.expectEqualStrings("sql", ann.name);
    try std.testing.expectEqual(@as(usize, 0), ann.args.len);
    try std.testing.expectEqualStrings("\"select * from users where id = ${id} limit 1\"", ann.template.?);
    try std.testing.expectEqual(@as(usize, 2), ann.templateLoc.?.line);
    try std.testing.expectEqual(@as(usize, 11), ann.templateLoc.?.col);
    try std.testing.expectEqual(@as(usize, 7), ann.loc.?.col);
}

test "decision 311: a multiline literal, and the form inside a list" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\#[mark, sql """
        \\    select * from users
        \\""", check("x")]
        \\fn find() { }
    );
    const anns = program.decls[0].@"fn".annotations;
    try std.testing.expectEqual(@as(usize, 3), anns.len);
    try std.testing.expect(anns[0].template == null);
    try std.testing.expectEqualStrings("\"\"\"\n    select * from users\n\"\"\"", anns[1].template.?);
    try std.testing.expect(anns[2].template == null);
    try std.testing.expectEqualStrings("\"x\"", anns[2].args[0]);
}

test "decision 311: the AST dump names the literal" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const program = try parse(arena.allocator(),
        \\#[sql "a ${b}"]
        \\fn f(b: string) { }
    );
    const json = try std.json.Stringify.valueAlloc(arena.allocator(), program.decls[0].@"fn".annotations[0], .{});
    try std.testing.expectEqualStrings("{\"name\":\"sql\",\"args\":[],\"template\":\"\\\"a ${b}\\\"\",\"is_builtin\":false}", json);
}

test "decision 311: a malformed hole is a parse error; a builtin annotation takes no literal" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\#[sql "a ${b +}"]
        \\fn f(b: string) { }
    ));
    try std.testing.expectError(error.UnexpectedToken, parse(arena.allocator(),
        \\#[@External.Node "x"]
        \\fn f() { }
    ));
}
