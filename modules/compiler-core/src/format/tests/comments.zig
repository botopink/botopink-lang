//! format: comments / doc / todo (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: todo ---- simple" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    todo;
        \\}
    );
}

test "format: todo ---- with message" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    @todo("todo with a label");
        \\}
    );
}

test "format: comments ---- single line before fn" {
    try h.assertFormatLossless(std.testing.allocator,
        \\// one
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- multiple lines before fn" {
    try h.assertFormatLossless(std.testing.allocator,
        \\// one
        \\// two
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- inside function" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    // world
        \\    1;
        \\}
    );
}

test "format: comments ---- between statements" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    1;
        \\    // world
        \\    2;
        \\}
    );
}

test "format: comments ---- trailing after function" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    x;
        \\}
        \\// Hello world
        \\// ok!
    );
}

test "format: comments ---- inside list" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    ];
        \\}
    );
}

test "format: comments ---- inside call" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    one(
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    );
        \\}
    );
}

test "format: doc comment ---- before fn" {
    try h.assertFormatLossless(std.testing.allocator,
        \\/// This is a documented function
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: doc comment ---- multiline before fn" {
    try h.assertFormatLossless(std.testing.allocator,
        \\/// First line of documentation
        \\/// Second line of documentation
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "format: doc comment ---- before a record with no fields" {
    try h.assertFormatLossless(std.testing.allocator,
        \\/// User account structure
        \\type Account
    );
}

test "format: doc comment ---- before an enum-shaped type" {
    try h.assertFormatLossless(std.testing.allocator,
        \\/// Color enumeration
        \\type Color { Red, Blue }
    );
}

test "format: doc comment ---- before a behavior" {
    try h.assertFormatLossless(std.testing.allocator,
        \\/// Drawable behavior
        \\behavior Drawable {}
    );
}

test "format: doc comments ---- module level" {
    try h.assertFormatLossless(std.testing.allocator,
        \\//// One
        \\//// Two
        \\//// Three
        \\
        \\pub fn main() {
        \\    val x = 1;
        \\
        \\    x;
        \\}
    );
}

test "format: comments ---- at end of anonymous fn" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    fn() {
        \\        1;
        \\        // a final comment
        \\
        \\        // another final comment
        \\        // at the end of the block
        \\    };
        \\}
    );
}

test "format: comments ---- multiline inside case block" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    case list {
        \\        [] -> acc;
        \\        [_, ..rest] -> rest |> do_len(acc + 1);
        \\        // Even the opposite wouldn't be optimised:
        \\        // { acc + 1 } |> do_len(rest, _);
        \\    }
        \\}
    );
}

test "format: todo ---- with message and comment" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    @todo("wibble");
        \\}
    );
}

test "format: comments ---- member comments and blank lines in a behavior body are kept" {
    try h.assertFormatLossless(std.testing.allocator,
        \\// ── numbers ──
        \\
        \\pub behavior Router {
        \\    // the path the router resolved
        \\    fn pathname(self: Self) -> string;
        \\
        \\    // two lines of
        \\    // explanation
        \\    fn params(self: Self) -> string;
        \\
        \\    default fn describe(self: Self) -> string {
        \\        return self.pathname();
        \\    }
        \\    // a closing note
        \\}
        \\
        \\// ── records ──
        \\
        \\type Point(x: i32, y: i32) {
        \\    // the sum
        \\    fn sum(self: Self) -> i32 {
        \\        return self.x + self.y;
        \\    }
        \\
        \\    fn twice(self: Self) -> i32 {
        \\        return self.sum() * 2;
        \\    }
        \\}
    );
}

test "format: comments ---- an empty module comment line has no trailing space" {
    try h.assertFormatLossless(std.testing.allocator,
        \\//// A module.
        \\////
        \\//// More.
        \\
        \\fn main() {}
    );
}

// ── an `if` branch is printed by the one statement-sequence printer (G6) ─────
// The branches had a second printer of their own that joined with `hardline()`
// and read neither `emptyLinesBefore` nor the trailing-comment flag, so an
// else-branch's blank line — which the parser DID record — was dropped, and a
// trailing comment was moved onto a line of its own. Both survive a round trip
// now that the branches share `fmtStmtSeq` with `fn`, `test` and lambda bodies.

test "format: comments ---- an else-branch keeps a blank line between statements" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(a: bool) -> i32 {
        \\    var n = 0;
        \\    if (a) {
        \\        n = 1;
        \\        n = 2;
        \\    } else {
        \\        n = 3;
        \\
        \\        n = 4;
        \\    }
        \\    return n;
        \\}
    );
}

test "format: comments ---- an else-branch keeps a trailing comment on its line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(a: bool) -> i32 {
        \\    var n = 0;
        \\    if (a) {
        \\        n = 1;
        \\        n = 2;
        \\    } else {
        \\        n = 3; // why three
        \\        n = 4;
        \\    }
        \\    return n;
        \\}
    );
}

// ── member trivia the parser now records (G2, G3, G4) ────────────────────────
// Each of these was a comment the formatter deleted or displaced, and each was
// idempotent afterwards — so `format --check` went green on the thinned file.

test "format: comments ---- an enum variant keeps its leading and trailing comments" {
    try h.assertFormatLossless(std.testing.allocator,
        \\type Color {
        \\    // the warm one
        \\    Red, // warm
        \\    Blue,
        \\}
    );
}

test "format: comments ---- a record field keeps its trailing comment, including the last" {
    try h.assertFormatLossless(std.testing.allocator,
        \\type Point(
        \\    x: i32, // the horizontal coordinate
        \\    y: i32, // the vertical one
        \\)
    );
}

test "format: comments ---- a method keeps its trailing comment on its own line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\type Box(n: i32) {
        \\    fn one(self: Self) -> i32 {
        \\        return 1;
        \\    } // trailing on a method
        \\
        \\    fn two(self: Self) -> i32 {
        \\        return 2;
        \\    }
        \\}
    );
}

// ── the last two blocks: a then-branch and a lambda body (G5's other half) ────
// `parser/exprs.zig` carried two inlined block loops, written before `parseBlock`
// grew `trackEmptyLines`/`handleComments`: they recorded no `emptyLinesBefore` and
// a `//` comment inside them was a **parse error**. They were the `if`
// then-branch and the lambda body — which is every `for (…) { x -> … }` body.
// `15-language-surface`'s `28e447e` routed both through `parseStmtListInBraces`,
// and this printer has read the field since the two statement-sequence printers
// became one, so the round trip closes without a further printer arm. These are
// the cases that say so, and that catch a regression in either half.

test "format: comments ---- a loop body keeps a blank line and a comment" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: Array<i32>) -> i32 {
        \\    var n = 0;
        \\    for (xs) { x ->
        \\        n = n + x;
        \\
        \\        // the second half
        \\        n = n + 1;
        \\    }
        \\    return n;
        \\}
    );
}

test "format: comments ---- an if then-branch keeps a blank line and a comment" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(a: bool) -> i32 {
        \\    var n = 0;
        \\    if (a) {
        \\        n = 1;
        \\
        \\        // and then
        \\        n = 2;
        \\    }
        \\    return n;
        \\}
    );
}

test "format: comments ---- all three blocks of one `if`/`loop` keep theirs at once" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(a: bool, xs: Array<i32>) -> i32 {
        \\    var n = 0;
        \\    if (a) {
        \\        n = 1;
        \\
        \\        // then-branch
        \\        n = 2;
        \\    } else {
        \\        n = 3;
        \\
        \\        // else-branch
        \\        n = 4;
        \\    }
        \\    for (xs) { x ->
        \\        n = n + x;
        \\
        \\        // loop body
        \\        n = n + 1;
        \\    }
        \\    return n;
        \\}
    );
}

// Step 1 re-measured (2026-09-26): the comments written before an enum body's or
// an enum section's closing `}` were deleted — four in emilia's `tokens.bp`
// (`// ── end front 38 ──…` and its siblings). The section's were collected by
// the parser and freed; the enum's were recorded in `TypeDecl.bodyComments` and
// read only by the record path.
test "format: comments ---- a comment before a section's and an enum's closing brace is kept" {
    try h.assertFormatLossless(std.testing.allocator,
        \\pub type T {
        \\    Text {
        \\        A,
        \\        B,
        \\        // end of text
        \\    }
        \\    Empty {
        \\        // nothing yet
        \\    }
        \\
        \\    // end of all
        \\}
    );
}

// C-12's comment column (09's handover: a sibling library's `runtime.bp:13`). A
// comment written at a line's end and continued on the lines below, each
// continuation starting in the column the first one starts in, keeps that
// alignment — under the first comment's PRINTED column, which moves when the
// code before it does. A comment line in another column, or after a blank line,
// is an ordinary comment and prints at the indentation. Before, every
// continuation was re-emitted at the statement's own column.
test "format: comments ---- a trailing comment's continuation stays aligned under it" {
    try h.assertFormatLossless(std.testing.allocator,
        \\import {Response} from "http"; // sibling module — the handler type
        \\                               // `rkRegisterRoute` names in its signature
        \\// a comment of its own
        \\
        \\fn f() -> i32 {
        \\    val x = 1; // first line
        \\               // second line
        \\               // third line
        \\    // not a continuation
        \\    return x;
        \\}
    );
}

test "format: comments ---- a continuation follows its comment when the code before it moves" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn f() -> i32 {
        \\    val x   =   1; // first line
        \\                   // second line
        \\    return x;
        \\}
    ,
        \\fn f() -> i32 {
        \\    val x = 1; // first line
        \\               // second line
        \\    return x;
        \\}
    );
}
