//! Decision 255 — two expression forms (1.0.11-beta `01-compiler/01-checker`).
//!
//!   (1) a type application before a member: `Dict<string, unknown>.empty()`,
//!       `Opt<i32>.None` — decision 8 §1.3's `Box<i32>(value: 1)` extended to a
//!       type's member; elsewhere `<` stays a comparison (Kotlin's rule);
//!   (2) `comptime <expr>`, which means `comptime { break <expr>; }`.
//!
//! What each form means is the checker's; these tests pin the tree.

const std = @import("std");
const ast = @import("../../ast.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");

/// The value of the module-level `val v = …;` that `src` declares, parsed in
/// `arena`.
fn valueOf(arena: std.mem.Allocator, src: []const u8) !ast.Expr {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(arena);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = try p.parse(arena);
    for (program.decls) |d| if (d == .val) return d.val.value.*;
    return error.TestNoVal;
}

/// `botopink format` prints `src` back unchanged — the form round-trips.
fn expectFormatsBack(src: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(a);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = try p.parse(a);
    const out = try formatMod.format(a, program);
    try std.testing.expectEqualStrings(src, out);
}

fn expectTypeArgNames(refs: ?[]ast.TypeRef, names: []const []const u8) !void {
    const list = refs orelse return error.TestExpectedTypeArgs;
    try std.testing.expectEqual(names.len, list.len);
    for (list, names) |r, n| {
        try std.testing.expect(r == .named);
        try std.testing.expectEqualStrings(n, r.named);
    }
}

// ── (1) a type application before a member ───────────────────────────────────

test "decision 255: a type application before a called member" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = Dict<string, unknown>.empty();");
    try std.testing.expect(v == .call);
    const c = v.call.kind.call;
    try std.testing.expectEqualStrings("empty", c.callee);
    try std.testing.expectEqualStrings("Dict", c.receiver.?.identifier.kind.ident);
    try expectTypeArgNames(c.receiverTypeArgs, &.{ "string", "unknown" });
    try std.testing.expect(c.typeArgs == null);
}

test "decision 255: the application belongs to the first link of a chain" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = Box<i32>.make(1).get();");
    const get = v.call.kind.call;
    try std.testing.expectEqualStrings("get", get.callee);
    try std.testing.expect(get.receiverTypeArgs == null);
    const make = get.receiver.?.call.kind.call;
    try std.testing.expectEqualStrings("make", make.callee);
    try expectTypeArgNames(make.receiverTypeArgs, &.{"i32"});
}

test "decision 255: a type application before a member that is not called" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = Opt<i32>.None;");
    const ia = v.identifier.kind.identAccess;
    try std.testing.expectEqualStrings("None", ia.member);
    try expectTypeArgNames(ia.receiverTypeArgs, &.{"i32"});
}

test "decision 255: the member's own type arguments sit beside the type's" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = Dict<string, i32>.fold<i32>(0);");
    const c = v.call.kind.call;
    try expectTypeArgNames(c.receiverTypeArgs, &.{ "string", "i32" });
    try expectTypeArgNames(c.typeArgs, &.{"i32"});
}

test "decision 255: a constructor call keeps decision 8's form" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try valueOf(arena.allocator(), "val v = Box<i32>(value: 1).get();");
    const box = v.call.kind.call.receiver.?.call.kind.call;
    try std.testing.expectEqualStrings("Box", box.callee);
    try expectTypeArgNames(box.typeArgs, &.{"i32"});
    try std.testing.expect(box.receiverTypeArgs == null);
}

test "decision 255: a comparison stays a comparison" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    // Spaced, between values: a comparison.
    try std.testing.expect((try valueOf(a, "val v = a < b;")) == .binaryOp);
    // `&&` does not parse as a type: the list fails and both are comparisons.
    const both = try valueOf(a, "val v = x < y && z > w;");
    try std.testing.expect(both == .binaryOp);
    try std.testing.expect(both.binaryOp.op == .@"and");
    try std.testing.expect(both.binaryOp.lhs.* == .binaryOp and both.binaryOp.lhs.binaryOp.op == .lt);
    try std.testing.expect(both.binaryOp.rhs.* == .binaryOp and both.binaryOp.rhs.binaryOp.op == .gt);
    // Two comparisons as two arguments: `>` is followed by `)`, not `.` / `(`.
    const call = try valueOf(a, "val v = f(a < b, c > d);");
    try std.testing.expectEqual(@as(usize, 2), call.call.kind.call.args.len);
    try std.testing.expect(call.call.kind.call.typeArgs == null);
    for (call.call.kind.call.args) |arg| try std.testing.expect(arg.value.* == .binaryOp);
    // Adjacent, but after a value's name (lower case): `.c` is no member link.
    const lower = try valueOf(a, "val v = a<b>.c;");
    try std.testing.expect(lower == .binaryOp);
    // Adjacent after a type's name, but `>` followed by neither `.` nor `(`.
    const tail = try valueOf(a, "val v = A<B> c;");
    try std.testing.expect(tail == .binaryOp);
}

test "decision 255: botopink format prints a type application back" {
    try expectFormatsBack(
        \\pub fn main() {
        \\    val d = Dict<string, unknown>.empty();
        \\    val b = Box<i32>.make(7).get();
        \\    val o = Opt<i32>.None;
        \\    val f = Dict<string, i32>.fold<i32>(0);
        \\    val r = ctx.resolve<Repo>();
        \\    val c = a < b;
        \\}
    );
    // A chain too long for one line keeps the `<…>` on the root's line.
    try expectFormatsBack(
        \\pub fn main() {
        \\    val e = Dict<string, i32>
        \\        .empty()
        \\        .insert("aaaaaaaaaaaaaaaaaaaaaa", 1)
        \\        .insert("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", 2)
        \\        .insert("c", 3);
        \\}
    );
}

// ── (2) `comptime <expr>` ─────────────────────────────────────────────────────

test "decision 255: comptime <expr> and the block that breaks with it both parse" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    // The shorthand keeps its own node: the comptime transform specialises and
    // unrolls on it (`transform.zig`), so a desugar would move every backend's
    // output — the checker types the two alike instead.
    const short = try valueOf(a, "val v = comptime Dict.empty();");
    try std.testing.expectEqualStrings("empty", short.comptime_.kind.comptimeExpr.call.kind.call.callee);
    const long = try valueOf(a, "val v = comptime { break Dict.empty(); };");
    try std.testing.expectEqual(@as(usize, 1), long.comptime_.kind.comptimeBlock.body.len);
}

test "decision 255: botopink format prints comptime <expr> back as written" {
    try expectFormatsBack(
        \\val top = comptime 2 + 3;
        \\
        \\pub fn main() {
        \\    val d: Dict<string, unknown> = comptime Dict.empty();
        \\    val b = comptime {
        \\        break 3 * 4;
        \\    };
        \\}
    );
}
