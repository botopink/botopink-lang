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

// ── decision 107: the grouped spelling ───────────────────────────────────────
// A group flattens to the same `ImportPath`s the dotted spelling produces —
// the snapshot shows `segments` only, never a group node.

test "parser: import group flattens to dotted paths" {
    try h.assertParser(std.testing.allocator, @src(), "import {io: {fs: {readText, writeText}, clock: {nowMillis}}} from \"std\";");
}

test "parser: import group and dotted path mix in one list" {
    try h.assertParser(std.testing.allocator, @src(), "import {collections.Dict, io: {fs: {readText as read}}, collections: {ArraySets*}} from \"std\";");
}

test "parser: import group prefix is also a leaf when listed" {
    try h.assertParser(std.testing.allocator, @src(), "import {io: {fs, fs: {readText}}} from \"std\";");
}

test "parser: import group without from resolves against the root" {
    try h.assertParser(std.testing.allocator, @src(), "import {html: {Element, tag}, router.pathname};");
}

test "parser: import group nested three deep is a.b.c" {
    try h.assertParser(std.testing.allocator, @src(), "import {a: {b: {c}}, bbb.rr.dd, ee.tt.rr*} from \"modulo\";");
}

test "parser: import star on a group node is refused" {
    try h.expectParseError(std.testing.allocator,
        \\error[import-group-modifier]: `*` and `as` belong to an import leaf, not to a group
        \\ --> <test>:1:11
        \\  |
        \\1 | import {io* : {fs}} from "std";
        \\  |           ^ this node opens braces
        \\  |
        \\  = hint: write the modifier on the leaf: `io: {fs: {readText as read}}`, `collections: {ArraySets*}`
        \\
        \\
    , "import {io* : {fs}} from \"std\";");
}

test "parser: import alias on a group node is refused" {
    try h.expectParseFails(std.testing.allocator, "import {io as x: {fs}} from \"std\";");
}

test "parser: import dotted name before a colon is refused" {
    // A group takes ONE identifier before the colon; `a.b: {…}` is written as
    // `a: {b: {…}}`.
    try h.expectParseFails(std.testing.allocator, "import {a.b: {c}} from \"std\";");
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
        \\declare fn log(message: string);
    );
}

test "parser: delegate ---- shorthand pub with return type" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub declare fn transform(input: string) -> string;
    );
}
