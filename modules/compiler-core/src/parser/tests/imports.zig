//! parser: import/activate/delegate/star declarations (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: import from root" {
    try h.assertParser(std.testing.allocator, @src(), "import {X};");
}

test "parser: import from module" {
    try h.assertParser(std.testing.allocator, @src(), "import {X} from \"module\";");
}

test "parser: import empty" {
    try h.assertParser(std.testing.allocator, @src(), "import {};");
}

test "parser: import multiple names" {
    try h.assertParser(std.testing.allocator, @src(), "import {alpha, beta, gamma};");
}

test "parser: import trailing comma" {
    try h.assertParser(std.testing.allocator, @src(), "import {a, b,};");
}

test "parser: import dotted path" {
    try h.assertParser(std.testing.allocator, @src(), "import {X.x1.x2.X3};");
}

test "parser: import activate suffix" {
    try h.assertParser(std.testing.allocator, @src(), "import {A, X*};");
}

test "parser: import dotted activate" {
    try h.assertParser(std.testing.allocator, @src(), "import {ducks.PatoNada*} from \"ducks\";");
}

test "parser: import activate with alias" {
    try h.assertParser(std.testing.allocator, @src(), "import {std.List as L, X* as Q};");
}

test "parser: import mixed plain and activate" {
    try h.assertParser(std.testing.allocator, @src(), "import {Pato, PatoNada*, PatoVoa* as Voa, std.List as L} from \"ducks\";");
}

test "parser: activate statement" {
    try h.assertParser(std.testing.allocator, @src(), "X*;");
}

test "parser: activate dotted statement" {
    try h.assertParser(std.testing.allocator, @src(), "ducks.PatoExtra*;");
}

test "parser: multiple import declarations" {
    try h.assertParser(std.testing.allocator, @src(),
        \\import {a};
        \\import {b, c} from "dep";
        \\import {z.W};
    );
}

// ── mod / pub mod declarations ────────────────────────────────────────────────

test "parser: mod decl private" {
    try h.assertParser(std.testing.allocator, @src(), "mod geometry;");
}

test "parser: pub mod decl" {
    try h.assertParser(std.testing.allocator, @src(), "pub mod shapes;");
}

test "parser: multiple mod decls" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub mod geometry;
        \\pub mod shapes;
        \\mod internal;
    );
}

test "parser: mod alongside imports" {
    try h.assertParser(std.testing.allocator, @src(),
        \\import {x} from "geometry";
        \\pub mod geometry;
        \\mod helpers;
    );
}

test "parser: mod requires a semicolon" {
    try h.expectParseFails(std.testing.allocator, "mod geometry");
}

// ── pub default mod (package-default DSL) ─────────────────────────────────────

test "parser: pub default mod decl" {
    try h.assertParser(std.testing.allocator, @src(), "pub default mod query;");
}

test "parser: default mod decl (private)" {
    try h.assertParser(std.testing.allocator, @src(), "default mod query;");
}

test "parser: pub default mod parses at any module top level" {
    // No root-only restriction: it parses alongside ordinary decls anywhere.
    try h.assertParser(std.testing.allocator, @src(),
        \\import {x} from "geometry";
        \\pub default mod query;
        \\pub fn helper() -> i32 { return 1; }
    );
}

test "parser: mod in fn body is a parse error" {
    try h.expectParseFails(std.testing.allocator,
        \\fn main() {
        \\  mod nested;
        \\}
    );
}

test "parser: delegate ---- val form simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val log = declare fn(self: Self);
    );
}

test "parser: delegate ---- val form with return type" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Predicate = declare fn(value: i32) -> bool;
    );
}

test "parser: delegate ---- shorthand simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\declare fn log(self: Self);
    );
}

test "parser: delegate ---- shorthand pub with return type" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub declare fn transform(input: string) -> string;
    );
}

test "parser: star fn ---- async declaration" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn fetch(url: string) -> @Future<Response> {
        \\    return download(url);
        \\}
    );
}

test "parser: star fn ---- generator declaration" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn fib() -> @Iterator<Int> {
        \\    yield 1;
        \\}
    );
}

test "parser: star fn ---- async generator declaration" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub *fn stream() -> @AsyncIterator<Int, Error> {
        \\    yield 1;
        \\}
    );
}

test "parser: star fn ---- label after return type" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<Int> :gen {
        \\    yield :gen 1;
        \\}
    );
}

test "parser: star fn ---- anonymous expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val producer = *fn(n) {
        \\    yield n;
        \\};
    );
}

test "parser: star fn ---- error when body omitted" {
    // `*fn` is sugar for an async/generator function and must have a body.
    try h.expectParseFails(std.testing.allocator, "*fn fetch() -> @Future<Int>;");
}
