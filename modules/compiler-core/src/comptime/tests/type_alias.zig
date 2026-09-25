//! comptime: type aliases (decision 118 rule 1) — `type Name<A> = Target;` is a
//! transparent name: the checker substitutes the target wherever the alias is
//! written, checks its arity, refuses a recursive one, and keeps the written
//! spelling for the effect checker (`Env.aliasedWrapper`).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const inferMod = @import("../infer.zig");
const h = @import("helpers.zig");

/// Inference refuses `src`; the message carries `code` and the error is
/// located at `line:col` (1-based).
fn expectRefused(src: []const u8, code: []const u8, line: usize, col: usize) !void {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = lexerMod.Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(alloc);
    var env = try inferMod.freshEnv(alloc, gpa);
    defer env.deinit();
    try std.testing.expectError(error.TypeError, inferMod.inferProgram(&env, program));
    const err = env.lastError orelse return error.TestExpectedError;
    const msg = try err.message(alloc);
    if (std.mem.indexOf(u8, msg, code) == null) {
        std.debug.print("\nexpected `{s}` in: {s}\n", .{ code, msg });
        return error.TestUnexpectedResult;
    }
    const loc = err.loc orelse return error.TestExpectedLocation;
    try std.testing.expectEqual(line, loc.line);
    try std.testing.expectEqual(col, loc.col);
}

// ── accepted ─────────────────────────────────────────────────────────────────

test "type alias: a plain alias types params, returns and val annotations" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Id = i32;
        \\fn next(x: Id) -> Id { return x + 1; }
        \\val n: Id = next(1);
        \\val m: i32 = n;
    );
}

test "type alias: generic parameters are substituted" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Pair<A, B> = #(A, B);
        \\fn swap(p: Pair<i32, string>) -> Pair<string, i32> { return #(p.1, p.0); }
        \\val s: #(string, i32) = swap(#(1, "a"));
    );
}

test "type alias: a record field names an alias declared further down" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Box(v: Id)
        \\type Id = i32;
        \\val b = Box(v: 3);
        \\val n: i32 = b.v;
    );
}

test "type alias: an alias of an alias" {
    try h.assertInfersOk(std.testing.allocator,
        \\type List<T> = T[];
        \\type Ints = List<i32>;
        \\fn total(xs: Ints) -> i32 { return xs.length; }
        \\val n = total([1, 2, 3]);
    );
}

test "type alias: the target does not see the caller's generics" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Box<T> = T[];
        \\fn size<U>(xs: Box<U>) -> i32 { return xs.length; }
        \\val n = size(["a"]);
    );
}

test "type alias: an alias of @Result returned by a function that only passes the value along" {
    try h.assertInfersOk(std.testing.allocator,
        \\type ParseError { Empty }
        \\pub type Parser<T> = @Result<T, ParseError>;
        \\#[@result]
        \\fn parsePort(s: string) -> @Result<i32, ParseError> {
        \\    if (s == "") { throw ParseError.Empty; };
        \\    return 8080;
        \\}
        \\fn port(s: string) -> Parser<i32> { return parsePort(s); }
    );
}

// ── refused ──────────────────────────────────────────────────────────────────

test "type alias: the alias is the target — a mismatch against it is a mismatch against the target" {
    try expectRefused(
        \\type Id = i32;
        \\fn f(x: Id) -> Id { return x; }
        \\val s = f("x");
    , "", 3, 11);
}

test "type alias: an unknown target is refused at the target" {
    try expectRefused("type A = Nope;", "Nope", 1, 10);
}

test "type alias: more arguments than parameters" {
    try expectRefused(
        \\type P<T> = T[];
        \\fn f(x: P<i32, i32>) -> i32 { return 0; }
    , "type-alias-arity", 2, 9);
}

test "type alias: a generic alias written bare" {
    try expectRefused(
        \\type P<T> = T[];
        \\fn f(x: P) -> i32 { return 0; }
    , "type-alias-arity", 2, 9);
}

test "type alias: an alias that names itself" {
    try expectRefused("type A = A[];", "type-alias-recursive", 1, 10);
}

test "type alias: two aliases that name each other" {
    try expectRefused(
        \\type A = B;
        \\type B = #(A, i32);
    , "type-alias-recursive", 1, 10);
}

test "type alias: a name a type already has" {
    try expectRefused(
        \\type Point(x: i32)
        \\type Point = i32;
    , "type-alias-name-taken", 2, 1);
}

// ── the effect checker's reading ─────────────────────────────────────────────

test "type alias: aliasedWrapper sees the wrapper behind a return alias" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src =
        \\type E { Bad }
        \\type Parser<T> = @Result<T, E>;
        \\type Again<T> = Parser<T>;
        \\type Id = i32;
        \\fn a() -> Parser<i32> { return b(); }
        \\fn b() -> Again<i32> { return c(); }
        \\#[@result]
        \\fn c() -> @Result<i32, E> { return 1; }
        \\fn d() -> Id { return 1; }
    ;
    var lx = lexerMod.Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(alloc);
    var env = try inferMod.freshEnv(alloc, gpa);
    defer env.deinit();
    _ = try inferMod.inferProgram(&env, program);

    const ret = struct {
        fn of(prog: ast.Program, i: usize) ast.TypeRef {
            return prog.decls[i].@"fn".returnType.?;
        }
    }.of;
    // The declared return keeps the alias spelling.
    try std.testing.expectEqualStrings("Parser", ret(program, 4).generic.name);
    const a = env.aliasedWrapper(ret(program, 4)).?;
    try std.testing.expectEqualStrings("Parser", a.alias);
    try std.testing.expectEqualStrings("Result", a.wrapper);
    const b = env.aliasedWrapper(ret(program, 5)).?;
    try std.testing.expectEqualStrings("Again", b.alias);
    try std.testing.expectEqualStrings("Result", b.wrapper);
    // The wrapper written literally is not behind an alias; nor is an alias
    // of a plain type.
    try std.testing.expect(env.aliasedWrapper(ret(program, 6)) == null);
    try std.testing.expect(env.aliasedWrapper(ret(program, 7)) == null);
}
