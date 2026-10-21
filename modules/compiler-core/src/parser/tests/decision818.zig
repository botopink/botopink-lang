//! Decision 818 (3) — `#[key(k)] x`, the one annotation an expression takes:
//! the `#key` builtin call over `x` and `k` (`ast.key_builtin_name`), located
//! at the `#`, printed back as written. Whether `x` answers a `Component<T>`
//! is the checker's (`key-not-component`, `key-type`).

const std = @import("std");
const ast = @import("../../ast.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");

/// The value of the module-level `val v = …;` that `src` declares.
fn valueOf(arena: std.mem.Allocator, src: []const u8) !ast.Expr {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(arena);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = try p.parse(arena);
    for (program.decls) |d| if (d == .val) return d.val.value.*;
    return error.TestNoVal;
}

test "decision 818: `#[key(k)] x` is the key builtin over x and k, at the `#`" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = #[key(p.id)] Item(p);");
    try std.testing.expect(v == .call);
    const c = v.call.kind.call;
    try std.testing.expect(c.is_builtin);
    try std.testing.expectEqualStrings(ast.key_builtin_name, c.callee);
    try std.testing.expectEqual(@as(usize, 2), c.args.len);
    try std.testing.expectEqualStrings("Item", c.args[0].value.call.kind.call.callee);
    try std.testing.expectEqualStrings("id", c.args[1].value.identifier.kind.identAccess.member);
    try std.testing.expectEqual(@as(usize, 9), v.call.loc.col);
}

test "decision 818: `#[key(k)] x` formats back as written" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const src = "fn f(xs: string[]) -> void {\n    val ys = xs.map({ n -> #[key(n)] Item(n) });\n}";
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(a);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = try p.parse(a);
    const out = try formatMod.format(a, program);
    try std.testing.expectEqualStrings(src, out);
}
