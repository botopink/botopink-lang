//! comptime: case exhaustiveness (+errors) (split from tests.zig).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

test "exhaustiveness error: missing enum patterns" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\    }
        \\};
    );
}

test "exhaustiveness: all enum patterns covered" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}

test "exhaustiveness: wildcard covers remaining patterns" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        _ -> "other";
        \\    }
        \\};
    );
}

test "exhaustiveness error: missing string patterns (with wildcard)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val categorize = fn(s: string) -> string {
        \\    case s {
        \\        "hello" -> "greeting";
        \\    }
        \\};
    );
}

test "exhaustiveness: nested pattern matching" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T, E> {
        \\    Ok(value: T),
        \\    Err(error: E),
        \\};
        \\val unwrap_or = fn(r: Result<i32, string>, default: i32) -> i32 {
        \\    case r {
        \\        Ok(v) -> v,
        \\        Err(_) -> default,
        \\    }
        \\};
    );
}

test "exhaustiveness: or-pattern covers multiple variants" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val warm = fn(c: Color) -> bool {
        \\    case c {
        \\        Red | Green -> true;
        \\        Blue -> false;
        \\    }
        \\};
    );
}

test "exhaustiveness: guarded arm does not cover its variant" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Blue if false -> "blue";
        \\    }
        \\};
    );
}

test "exhaustiveness error: unreachable arm after wildcard" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        _ -> "other";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}

// ── net-new (v0.beta.13 · A3): pattern matching ──────────────────────────────

// A wildcard `_` arm makes an otherwise-partial case (string scrutinee, which
// can never be matched by literals alone) exhaustive — no diagnostic.
test "infer: net-new ---- wildcard arm makes a partial case exhaustive" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn categorize(s: string) -> string {
        \\    return case s {
        \\        "hello" -> "greeting";
        \\        "bye" -> "farewell";
        \\        _ -> "other";
        \\    };
        \\}
    );
}

// A case can scrutinize a plain `int` literal (non-enum) and a plain `string`
// literal; both bind to a wildcard tail.
test "infer: net-new ---- case over int and string literal scrutinees" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn intName(n: i32) -> string {
        \\    return case n {
        \\        0 -> "zero";
        \\        1 -> "one";
        \\        _ -> "many";
        \\    };
        \\}
        \\fn strKind(s: string) -> string {
        \\    return case s {
        \\        "" -> "empty";
        \\        _ -> "non-empty";
        \\    };
        \\}
    );
}

// A nested record pattern destructures inner fields: matching `Line` binds the
// inner `Point`'s coordinates directly. Note the outer payload is written with a
// leading non-identifier sub-pattern (`_`) so the parser takes its nested-pattern
// branch — an identifier-first outer payload (`Line(Point(x,y), tail)`) only
// accepts flat bindings and is a known parser limitation.
test "infer: net-new ---- nested record destructuring binds inner fields" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Point { x: i32, y: i32 }
        \\record Line { head: Point, tail: Point }
        \\fn endXY(l: Line) -> i32 {
        \\    return case l {
        \\        Line(_, Point(x, y)) -> x + y;
        \\    };
        \\}
    );
}

// A `case` bound to a `val` and the same `case` as the trailing expression
// type-check identically (both yield `string`).
test "infer: net-new ---- case as val vs trailing expr type-check identically" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn asVal(n: i32) -> string {
        \\    val r = case n {
        \\        0 -> "zero";
        \\        _ -> "other";
        \\    };
        \\    return r;
        \\}
        \\fn asTrailing(n: i32) -> string {
        \\    return case n {
        \\        0 -> "zero";
        \\        _ -> "other";
        \\    };
        \\}
    );
}

test "exhaustiveness error: duplicate variant arm" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Red -> "again";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}
