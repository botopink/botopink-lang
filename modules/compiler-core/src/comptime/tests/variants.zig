//! comptime: variant/record-update/pattern/@print/AST probes (split from tests.zig).

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

test "infer comptime: expressions of multiple types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val pi      = comptime 3.14 * 2.0;
        \\val maxVal  = comptime 100 + 1;
        \\val banner  = comptime "Hello, " + "World";
    );
}

test "assertTypeAst: single module ---- basic val bindings" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "", .source =
        \\val x = 42;
        \\val name = "alice";
        },
    });
}

test "assertTypeAst: import single val from dependency module" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "constants", .source =
        \\pub val MAX = 100;
        },
        .{ .path = "", .source =
        \\import {MAX} from "constants";
        \\val limit = MAX;
        },
    });
}

test "assertTypeAst: import multiple vals from dependency module" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source =
        \\pub val host = "localhost";
        \\pub val port = 8080;
        },
        .{ .path = "", .source =
        \\import {host, port} from "config";
        \\val addr = host;
        \\val p = port;
        },
    });
}

test "assertTypeAst: import fn from dependency module" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "math", .source =
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        },
        .{ .path = "", .source =
        \\import {double} from "math";
        \\val result = double(21);
        },
    });
}

test "assertTypeAst: three-level chain ---- a imports b, b imports c" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "base", .source =
        \\pub val VERSION = 1;
        },
        .{ .path = "mid", .source =
        \\import {VERSION} from "base";
        \\pub val MAJOR = VERSION;
        },
        .{ .path = "", .source =
        \\import {MAJOR} from "mid";
        \\val v = MAJOR;
        },
    });
}

test "assertTypeAst: unused dependency does not pollute main bindings" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "unused", .source =
        \\val secret = "hidden";
        },
        .{ .path = "", .source =
        \\val answer = 42;
        },
    });
}

test "assertTypeAst: import record constructor from dependency" {
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "models", .source =
        \\record Point { x: i32, y: i32 }
        },
        .{ .path = "", .source =
        \\import {Point} from "models";
        \\val origin = Point(0, 0);
        },
    });
}

test "infer ast: case ---- list patterns empty, single, spread" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe() -> string {
        \\    val items = ["a", "b", "c"];
        \\    return case items {
        \\        [] -> "empty";
        \\        [x] -> "one";
        \\        [first, ..rest] -> "many";
        \\    };
        \\}
    );
}

test "infer ast: delegate declaration" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

test "infer ast: case ---- OR patterns with block arm body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _      -> {
        \\        val value = "odd";
        \\        break value;
        \\    };
        \\};
    );
}

test "infer ast: case ---- union return type from mismatched arms" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0    -> "zero";
        \\    _ -> 1;
        \\};
    );
}

test "infer ast: case ---- nested case in block arm" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> {
        \\      case 1 {
        \\          0    -> 54;
        \\          _ -> 1;
        \\      };
        \\   };
        \\   _ -> 1;
        \\};
    );
}

test "variant inference: field access after pattern matching" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val get_value = fn(r: Result) -> i32 {
        \\    case r {
        \\        Ok(v) -> v;
        \\        Error(_) -> 0;
        \\    }
        \\};
    );
}

test "variant inference error: shared field without pattern matching" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val get_value = fn(r: Result) -> i32 {
        \\    r.kind
        \\};
    );
}

test "variant inference error: variant does not escape clause scope" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val test = fn(r: Result) -> i32 {
        \\    case r {
        \\        Ok(_) -> {};
        \\        Error(_) -> {};
        \\    };
        \\    return r.kind;
        \\};
    );
}

test "variant inference: multiple variants with different fields" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Rectangle(width: f64, height: f64),
        \\    Point,
        \\};
        \\val area = fn(s: Shape) -> f64 {
        \\    case s {
        \\        Circle(r) -> 3.14 * r * r;
        \\        Rectangle(w, h) -> w * h;
        \\        Point -> 0.0;
        \\    }
        \\};
    );
}

test "record update: simple field update" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\    city: string,
        \\};
        \\val alice = Person(name: "Alice", age: 30, city: "London");
        \\val bob = Person(..alice, name: "Bob", age: 25);
    );
}

test "record update error: variant mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Subject = enum {
        \\    Person(name: string, age: i32),
        \\    Animal(species: string),
        \\};
        \\val alice = Subject.Person(name: "Alice", age: 30);
        \\val dog = Subject.Animal(..alice);
    );
}

test "record update error: non-existent field" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val alice = Person(name: "Alice", age: 30);
        \\val bob = Person(..alice, nickname: "Bobby");
    );
}

test "record update error: field type mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val alice = Person(name: "Alice", age: 30);
        \\val bob = Person(..alice, age: "thirty");
    );
}

test "pattern: non-empty list pattern" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val first_or_default = fn(list: i32[], default: i32) -> i32 {
        \\    case list {
        \\        [first, ..] -> first;
        \\        [] -> default;
        \\    }
        \\};
    );
}

test "pattern: assign pattern in enum" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Err(message: string),
        \\};
        \\val process = fn(r: Result) -> string {
        \\    case r {
        \\        Ok(v) as result -> "Got: " + v;
        \\        Err(e) as result -> "Error: " + e;
        \\    }
        \\};
    );
}

test "type_unification_does_not_allow_different_variants_to_be_treated_as_safe" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Err(message: string),
        \\};
        \\val process = fn(r: Result) -> string {
        \\    case r {
        \\      Ok(..) as b -> Wibble(..b, value: 1);
        \\      Err(..) as b -> Wobble(..b, message: "a");
        \\    }
        \\};
    );
}

test "pattern: assign pattern in record" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val describe = fn(p: Person) -> string {
        \\    case p {
        \\        Person(name, age) as person -> name + " is " + age;
        \\    };
        \\};
    );
}

test "pattern: complex nested patterns" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T, E> {
        \\    Ok(value: T),
        \\    Err(error: E),
        \\};
        \\val Container = enum {
        \\    Single(Result<i32, string>),
        \\    Multiple(Result<i32, string>[]),
        \\};
        \\val extract = fn(c: Container) -> i32 {
        \\    case c {
        \\        Single(Ok(v)) -> v;
        \\        Multiple([Ok(v), ..]) -> v;
        \\        _ -> 0;
        \\    }
        \\};
    );
}

test "variant inference: access variant-specific field after matching" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\};
        \\val scale = fn(s: Shape, factor: f64) -> Shape {
        \\    case s {
        \\        Circle(r) -> Circle(radius: r * factor);
        \\        Square(s) -> Square(side: s * factor);
        \\    };
        \\};
    );
}

test "variant inference: pattern matching on generic enum" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    Some(value: T),
        \\    None,
        \\};
        \\val map = fn(opt: Option<i32>, f: fn(i32) -> i32) -> Option<i32> {
        \\    case opt {
        \\        Some(v) -> Some(value: f(v));
        \\        None -> None;
        \\    };
        \\};
    );
}

test "@print: single string argument infers void" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("hello");
        \\}
    );
}

test "@print: multiple arguments infers void" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("x =", 42, true);
        \\}
    );
}

test "@print: expression argument infers void" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x = 10;
        \\    @print(x + 5);
        \\}
    );
}

test "@print: in if branch infers void" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn check(x: i32) {
        \\    if x > 0 {
        \\        @print("positive");
        \\    } else {
        \\        @print("non-positive");
        \\    }
        \\}
    );
}

test "@print: string interpolation argument" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: string) {
        \\    @print("Hello, " + name + "!");
        \\}
    );
}

// ── enum sections F1: comptime desugar registers synthesised inner enums ────
// These tests pin that an enum carrying sections type-checks cleanly across
// every backend driver — the synthesised inner enums (`__Token__Text`, …)
// live in the type-def table and are not emitted as user-visible AST decls,
// so the public snapshot only carries `Token`. F2 will pin the path-access
// resolution that makes those inner enums observable from expressions.

test "enum sections: single section + sibling payload variant type-checks" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Token {
        \\    Text {
        \\        Bold,
        \\        Italic,
        \\    }
        \\    Hover(inner: i32),
        \\}
    );
}

test "enum sections: nested sections with numeric leaves type-check" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Token {
        \\    Color {
        \\        Red { 100, 500 }
        \\        Hex(value: string),
        \\    }
        \\}
    );
}

// ── enum sections F2: path-access resolution (`.Color.Red.500`) ─────────────
// F2 lowers a `dotIdent`-rooted chain into nested constructor calls through
// the section tree. Pure-digit leaves match the `_500` mangled variant the F1
// desugar synthesised. These tests pin that the chain TYPE-CHECKS as the
// parent enum (here `Token`) — the typed-AST snapshot captures the lowered
// call shape so a regression on the resolver is caught by snapshot diff.

test "enum sections F2: two-segment path .Hover.Inner resolves to ctor call" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Token {
        \\    Text {
        \\        Bold, Italic,
        \\    }
        \\    Hover(inner: i32),
        \\}
        \\fn pick() -> Token {
        \\    return .Text.Bold;
        \\}
    );
}

test "enum sections F2: three-segment path .Color.Red.500 with numeric leaf" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Token {
        \\    Color {
        \\        Red { 100, 500 }
        \\        Blue { 100, 500 }
        \\    }
        \\}
        \\fn red() -> Token {
        \\    return .Color.Red.500;
        \\}
    );
}

test "enum sections F2: payload sibling .Color.Hex(string) untouched" {
    // A path-access chain stops at the payload variant in `Color`; the parser
    // turns `.Color.Hex("…")` into a call (not an identAccess chain) — F2
    // leaves that path alone. This test pins that an inline color picker
    // mixing bare paths and a payload variant type-checks together.
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Token {
        \\    Color {
        \\        Red { 500 }
        \\        Hex(value: string),
        \\    }
        \\}
        \\fn red() -> Token { return .Color.Red.500; }
    );
}

test "enum sections F3 ES4: path-access with bad tail raises focused error" {
    // The head segment `Color` matches Token's section wrapper, so the
    // resolver knows the user intended a section path — but `Bogus` isn't
    // a variant of `__Token__Color`. F3 ES4 raises with the full chain
    // text and the owning enum name, instead of bubbling the generic
    // fall-through error from the regular identAccess path.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\enum Token {
        \\    Color {
        \\        Red { 500 }
        \\    }
        \\}
        \\fn pick() -> Token {
        \\    return .Color.Bogus.500;
        \\}
    );
}
