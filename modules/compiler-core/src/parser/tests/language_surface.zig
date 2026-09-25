//! Front 15 — the language surface: the forms the documents write, against the
//! grammar that has to accept them.
//!
//! Spec: `specs/1.0.5-beta/15-language-surface/` in the meta workspace
//! (`README.md`, `seven-forms.md`, `surface-gaps.md`).
//!
//! One section per row. A row that **hoists a rule** carries its regressions
//! beside its new forms — the point of hoisting is that the arms which already
//! worked keep working, so the two are asserted together. A form here parses;
//! what it *means* is the checker's and the backends'.

const std = @import("std");
const h = @import("helpers.zig");
const assertParser = h.assertParser;
const expectParseError = h.expectParseError;
const expectErrorAt = h.expectErrorAt;

// ── R1 — the array suffix is the type's, not the arm's ───────────────────────
//
// `parseBaseTypeRef` applied the `T[]` wrap at the end of its named-type path
// and again, copied, inside the `unknown` arm; the tuple arm and the
// builtin-generic arm returned before either. The suffix now runs once, at the
// single exit, so every arm inherits it.

test "surface R1: an array of a labeled tuple, and of an unlabeled one" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(rows: #(a: i32, b: string)[], pairs: #(i32, string)[]) -> i32 {
        \\    return rows.length;
        \\}
    );
}

test "surface R1: an array of a builtin generic" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: @Result<i32, string>[]) -> i32 {
        \\    return xs.length;
        \\}
    );
}

test "surface R1: a parenthesised type, and an array of a union" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(x: (i32), xs: (i32 | string)[], ys: (i32 | string)[][]) -> i32 {
        \\    return xs.length;
        \\}
    );
}

test "surface R1: the arms that already carried the suffix still do" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(
        \\    a: unknown[],
        \\    b: Box<i32>[],
        \\    c: i32[][],
        \\    d: ?i32[],
        \\    e: fn(x: i32) -> i32[],
        \\    g: i32 | string[],
        \\) -> i32 {
        \\    return 1;
        \\}
    );
}

// ── R2 — one postfix chain, reached from every receiver ──────────────────────
//
// The chain existed in four copies. `parsePrimary`'s grouped arm reached none
// of them and `return`ed, so `("ab").length` was `Unexpected token` at the `.`;
// and no copy had a `(` link, so `adder(3)(4)` was `Unexpected token` at the
// second `(`. The identical copy in `parsePrimary`'s identifier path is gone;
// the one in `parseExpr`'s call path stays (it consumes trailing lambdas, which
// `parsePostfixChain` must not) and carries the same `(` link.

test "surface R2: a method on a parenthesised receiver" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: i32, b: i32) -> i32 {
        \\    val n = ("ab").length;
        \\    val s = (a == b).toString();
        \\    val m = (a + b).toString().length;
        \\    return n + m;
        \\}
    );
}

test "surface R2: calling what a call returned" {
    try assertParser(std.testing.allocator, @src(),
        \\fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
        \\fn f() -> i32 {
        \\    val a = adder(3)(4);
        \\    val b = adder(3)(4)(5);
        \\    return a + b;
        \\}
    );
}

test "surface R2: the receivers that already chained still do" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32[], r: Box) -> i32 {
        \\    val a = [1, 2].length;
        \\    val b = "x".toUpperCase().length;
        \\    val c = r.get().length;
        \\    val d = r?.get();
        \\    return a + b + c;
        \\}
    );
}

// ── R3 — a number is a receiver ──────────────────────────────────────────────
//
// `lexer.zig`'s number scanner ate the `.` of `42.toString()`, and the number
// arm of `parsePrimary` did not chain. Both halves are needed: the lexer makes
// the tokens, the parser makes the link.

test "surface R3: a method on a number literal" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> i32 {
        \\    val a = 42.toString().length;
        \\    val b = 3.0.toString().length;
        \\    return a + b;
        \\}
    );
}

test "surface R3: the range and the float forms are unchanged" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> f64 {
        \\    var s = 0;
        \\    loop (0..4) { i -> s = s + i; };
        \\    val a = 1.5;
        \\    val b = 1_000;
        \\    val c = 1e10;
        \\    val d = 0xFF;
        \\    val e = 1_000.5;
        \\    return a;
        \\}
    );
}

// ── R4 — one block body, reached by every block ──────────────────────────────
//
// `parseBlock` grew `handleComments` and `trackEmptyLines`; five blocks never
// reached it, each carrying its own loop written before the options existed.
// A `//` comment was a parse error in an `if` then-branch, a lambda body, a
// `loop` body and a trailing lambda, while the same comment in a fn body, a
// `test` body or an `if` else-branch parsed.

test "surface R4: a comment and a blank line inside an if branch" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(c: bool) -> i32 {
        \\    if (c) {
        \\        // the then-branch
        \\        println("a");
        \\
        \\        println("b");
        \\    } else {
        \\        // the else-branch
        \\        println("c");
        \\    };
        \\    return 1;
        \\}
    );
}

test "surface R4: a comment inside a loop body and a lambda body" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> i32 {
        \\    loop ([1, 2]) { x ->
        \\        // a loop body is not a lambda body — it has its own block
        \\        println("a");
        \\
        \\        println("b");
        \\    };
        \\    val g = { x ->
        \\        // a standalone lambda
        \\        x + 1
        \\    };
        \\    return g(1);
        \\}
    );
}

test "surface R4: an if branch that binds its value still binds it" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(v: ?i32) -> i32 {
        \\    if (v) { x ->
        \\        // the binding is the block's prologue, the comment is its body
        \\        println("has");
        \\    };
        \\    return 1;
        \\}
    );
}

// ── R5 — an index expression (decision 30) ───────────────────────────────────
//
// `xs[0]` was a parse error in every position. It parses as the reserved
// builtin call `ast.index_builtin_name` over `(receiver, index)` — `ast.zig`
// says why a new AST variant is not the shape — and it is a chain link, so it
// composes with `.field` and `(args)`. The index is parsed as a RANGE
// expression, which is what makes `xs[0..2]` the same node.

test "surface R5: an index in every reading position" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32[], d: Dict<string, i32>, s: string, i: i32) -> i32 {
        \\    val a = xs[0];
        \\    val b = d["k"];
        \\    val c = s[0];
        \\    val e = xs[i + 1];
        \\    val g = xs[xs[0]];
        \\    return a + b + e + g;
        \\}
    );
}

test "surface R5: a slice is an index whose index is a range" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32[], i: i32) -> i32 {
        \\    val a = xs[0..2];
        \\    val b = xs[0..];
        \\    val c = xs[i..i + 2];
        \\    return 1;
        \\}
    );
}

test "surface R5: an index composes with the other chain links" {
    try assertParser(std.testing.allocator, @src(),
        \\fn rows(n: i32) -> i32[] { return [n]; }
        \\fn f(xs: i32[]) -> i32 {
        \\    val a = rows(1)[0];
        \\    val b = xs[0].toString().length;
        \\    val c = ([1, 2])[0];
        \\    return a + b + c;
        \\}
    );
}

test "surface R5: an array literal is still an array literal" {
    try assertParser(std.testing.allocator, @src(),
        \\fn g(xs: i32[]) -> i32 { return xs.length; }
        \\fn f() -> i32 {
        \\    val xs = [1, 2];
        \\    val n = g([1, 2]);
        \\    var s = 0;
        \\    loop (0..4) { i -> s = s + i; };
        \\    return n + s;
        \\}
    );
}

// ── R8 — `??`, the nullish default (decision 28) ─────────────────────────────
//
// Decision 14 recorded `??` as deliberately absent because it "duplicates
// `catch` and `?.`". Measured, it does not: `catch` is `@Result`-only
// (`val b = a catch 0;` on an `a: ?i32` reds with "`try` requires a
// @Result<D, E> value, found \'optional\'"), and nothing else gives an optional
// a default. Decision 28 reverses it. `a ?? b` desugars to the optional binding
// form the language already has.

test "surface R8: the nullish default, chained and in a condition" {
    try assertParser(std.testing.allocator, @src(),
        \\fn g(n: i32) -> ?i32 { return n; }
        \\fn f(a: ?i32, b: ?i32, c: ?bool) -> i32 {
        \\    val x = a ?? 0;
        \\    val y = a ?? b ?? 0;
        \\    val z = g(1) ?? 0;
        \\    if (c ?? false) { println("y"); };
        \\    return x + y + z;
        \\}
    );
}

test "surface R8: `??` binds tighter than every other binary operator" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: ?i32, b: ?bool) -> bool {
        \\    val x = a ?? 0 == 1;
        \\    val y = a ?? 0 + 1;
        \\    val z = b ?? false && true;
        \\    return x;
        \\}
    );
}

// ── R7 — a bodyless `fn` declares its return type (decision 33 (b)) ──────────
//
// Measured, the surface was not what the front's document recorded: the
// ARROWLESS form `fn f(x) T` parses (it is the `.d.bp` shortform), and the
// ARROWED one `fn f(x) -> void` did NOT — so decision 33's own remedy, "the
// declarations gain `-> void`", was unwritable. The arrowed form now parses,
// and the form with no return type at all keeps being refused, with a message
// that says what to write.

test "surface R7: a bodyless fn that declares its return type, arrow or not" {
    try assertParser(std.testing.allocator, @src(),
        \\fn emit(source: string) -> void
        \\fn field<T, F>(obj: T, name: string) F
        \\fn quit(code: i32) -> noreturn
        \\declare fn print(message: string);
        \\fn main() -> i32 { return 1; }
    );
}

test "surface R7: a bodyless fn with no return type at all" {
    try expectParseError(std.testing.allocator,
        \\error[bodyless-fn-needs-return-type]: a declaration with no body must say what it answers
        \\ --> <test>:1:23
        \\  |
        \\1 | fn emit(source: string)
        \\  |                       ^ add `-> void`, or give the fn a body
        \\  |
        \\  = note: `fn f(x: string) -> void`, `fn f(x: string) void` and `declare fn f(x: string);` are all declarations; `fn f(x: string)` alone says nothing about the result
        \\  = hint: Write `-> void` when the fn answers nothing, `-> T` when it answers a `T`, or add a `{ … }` body.
        \\
        \\
    ,
        \\fn emit(source: string)
        \\fn main() -> i32 { return 1; }
    );
}

// ── R9 — the catch-all names the token it stopped on ─────────────────────────
//
// `unexpectedToken` is the only one of the 48 kinds with no rule to name, and
// every form the language does not have reaches it. Its old text — "Unexpected
// token" / "Check the syntax around this position." — told a reader nothing
// they could not already see, which is how seven missing forms were routed
// around instead of filed.

test "surface R9: the catch-all names the token and says a refusal looks different" {
    try expectParseError(std.testing.allocator,
        \\error: this token cannot appear here
        \\ --> <test>:1:29
        \\  |
        \\1 | fn main() -> i32 { return 1 @ 2; }
        \\  |                             ^ unexpected `@`
        \\  |
        \\  = hint: The statement before it may be missing its `;`, or an earlier `(`, `[` or `{` may not be closed. A form the language deliberately refuses reports a NAMED error instead of this one, so if you believe this spelling should work, it is a gap worth filing rather than working around.
        \\
        \\
    ,
        \\fn main() -> i32 { return 1 @ 2; }
    );
}

// ── R10 — a decided-against form is refused by name, where it starts ─────────
//
// `surface-gaps.md` § (b) lists the forms the documents do not write and the
// parser met with the catch-all — or, for `&`, `^` and `'a'`, with the lexer's
// "unexpected character", which no parse error can name or locate. Each has a
// `ParseErrorType` now, raised ONCE at the site every spelling reaches: the
// infix forms at `parsePostfixChain`'s exit (every receiver ends there), the
// literal forms in `parsePrimary`, the spread forms in the array literal, the
// label in the tuple literal, the `for` in the type's implement clause. The
// location is the token that starts the form, so a `reject/` cell pins both.

test "surface R10: a ternary is refused at the `?`" {
    try expectErrorAt("fn f(c: bool) -> i32 { return c ? 1 : 2; }", .ternaryAbsent, 1, 33);
    // After a chain, a call, a literal and a grouped expression alike.
    try expectErrorAt("fn f() -> i32 { return a.b ? 1 : 2; }", .ternaryAbsent, 1, 28);
    try expectErrorAt("fn f() -> i32 { return g(1) ? 1 : 2; }", .ternaryAbsent, 1, 29);
    try expectErrorAt("fn f() -> i32 { return (a == b) ? 1 : 2; }", .ternaryAbsent, 1, 33);
}

test "surface R10: the bitwise operators are refused at the operator" {
    try expectErrorAt("fn f() -> i32 { return 1 << 2; }", .bitwiseOperatorAbsent, 1, 26);
    try expectErrorAt("fn f() -> i32 { return 8 >> 2; }", .bitwiseOperatorAbsent, 1, 26);
    try expectErrorAt("fn f(a: i32, b: i32) -> i32 { return a & b; }", .bitwiseOperatorAbsent, 1, 40);
    try expectErrorAt("fn f(a: i32, b: i32) -> i32 { return a ^ b; }", .bitwiseOperatorAbsent, 1, 40);
}

test "surface R10: the boolean operators and the optional forms still parse" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: bool, b: bool, c: ?i32, d: Box<Box<i32>>) -> bool {
        \\    val x = a && b || !a;
        \\    val y = c ?? 0;
        \\    val z = c?.toString();
        \\    return x;
        \\}
    );
}

test "surface R10: a character literal is refused at the literal" {
    try expectErrorAt("fn f() -> string { return 'a'; }", .charLiteralAbsent, 1, 27);
    try expectErrorAt("fn f() -> string { val c = 'ab; return c; }", .charLiteralAbsent, 1, 28);
}

test "surface R10: a named fn inside a body is refused at the `fn`" {
    try expectErrorAt(
        \\fn main() -> i32 {
        \\    fn inner(x: i32) -> i32 { return x + 1; }
        \\    return inner(1);
        \\}
    , .nestedFnDecl, 2, 5);
}

test "surface R10: the anonymous fn expression and the lambda still parse in a body" {
    try assertParser(std.testing.allocator, @src(),
        \\fn main() -> i32 {
        \\    val inner = fn(x) { return x + 1; };
        \\    val twice = { x -> x * 2 };
        \\    return inner(twice(1));
        \\}
    );
}

test "surface R10: a spread that is not last is list-spread-not-last, at the element" {
    try expectErrorAt("fn f(a: i32[]) -> i32[] { return [..a, 3]; }", .listSpreadNotLast, 1, 40);
    try expectErrorAt("fn f(a: i32[]) -> i32[] { return [0, ..a, 3]; }", .listSpreadNotLast, 1, 43);
}

test "surface R10: a three-dot spread is refused at the dots" {
    try expectErrorAt("fn f(a: i32[]) -> i32[] { return [...a, 3]; }", .listSpreadDotDotDot, 1, 35);
    try expectErrorAt("fn f(a: i32[]) -> i32[] { return [1, ...a]; }", .listSpreadDotDotDot, 1, 38);
}

test "surface R10: the spread forms that parse still parse" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: i32[]) -> i32[] {
        \\    val b = [1, 2, ..a];
        \\    val c = [..a];
        \\    val d = [1, ..a,];
        \\    return b;
        \\}
    );
}

test "surface R10: `for` in a bodyless type's implement clause is refused at the `for`" {
    try expectErrorAt(
        \\behavior A { fn f(self: Self) -> i32; }
        \\type P(x: i32)
        \\implement A for P { fn f(self: Self) -> i32 { return self.x; } }
    , .implementClauseFor, 3, 13);
}

test "surface R10: the implement clause, and the named standalone block, still parse" {
    try assertParser(std.testing.allocator, @src(),
        \\behavior A { fn f(self: Self) -> i32; }
        \\type P(x: i32) implement A { fn f(self: Self) -> i32 { return self.x; } }
        \\type Q(x: i32)
        \\Impl implement A for Q { fn f(self: Self) -> i32 { return self.x; } }
    );
}

test "surface R10: a label in a tuple literal is refused at the label" {
    try expectErrorAt("fn f() -> i32 { val t = #(x: 1, y: 2); return t.x; }", .tupleLiteralLabel, 1, 27);
    try expectErrorAt("fn f() -> i32 { val t = #(1, y: 2); return t.0; }", .tupleLiteralLabel, 1, 30);
}

test "surface R10: a decided-against form renders its code, the replacement and the location" {
    try expectParseError(std.testing.allocator,
        \\error[ternary-absent]: there is no `c ? a : b`
        \\ --> <test>:1:33
        \\  |
        \\1 | fn f(c: bool) -> i32 { return c ? 1 : 2; }
        \\  |                                 ^ write `if (c) { a } else { b }`
        \\  |
        \\  = hint: `if` is an expression: `val x = if (c) { a } else { b };` — and `a ?? b` is the default of an optional.
        \\
        \\
    ,
        \\fn f(c: bool) -> i32 { return c ? 1 : 2; }
    );
    try expectParseError(std.testing.allocator,
        \\error[bitwise-operator-absent]: the language has no bitwise operators
        \\ --> <test>:1:26
        \\  |
        \\1 | fn f() -> i32 { return 1 << 2; }
        \\  |                          ^^ not an operator `<<`
        \\  |
        \\  = hint: There is no `<<`, `>>`, `&`, `^` or replacement for them; `&&` and `||` are the boolean operators. A host function behind `#[@External.<Target>(…)]` is the way to a bit operation.
        \\
        \\
    ,
        \\fn f() -> i32 { return 1 << 2; }
    );
}

// ── R11 — the two measured forms (step 4b) ───────────────────────────────────
//
// Both were found by library fronts paying for them, and both are strictly
// accepting: `#[mark(-20)]` reds at the DIGITS because the annotation-argument
// loop took the `-` as the whole argument; a one-line trailing-lambda body
// (`xs.map { x -> f(x) }`, every `loop (xs) { x -> f(x) }`) reds at the `}`
// because that one block kept the `.required` semicolon policy while the same
// lambda as a value parsed. Pre-fix each snapshot below is a parse error.

test "surface R11: a negative literal is one annotation argument" {
    try assertParser(std.testing.allocator, @src(),
        \\#[mark(-20)]
        \\fn f() -> i32 { return 1; }
        \\#[order(-100), tag("x", -1)]
        \\fn g() -> i32 { return 2; }
    );
}

test "surface R11: a one-line trailing lambda body needs no `;`" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32[]) -> i32 {
        \\    val ys = xs.map { x -> x + 1 };
        \\    var acc = 0;
        \\    loop (xs) { x -> acc = acc + x };
        \\    xs.forEach { x -> @print(x.toString()) };
        \\    val z = calcular(fator: 2) { a, b -> a + b };
        \\    val w = memo { -> 42 };
        \\    return acc;
        \\}
    );
}

test "surface R11: a trailing lambda body with several statements keeps its `;`" {
    try expectErrorAt(
        \\fn f(xs: i32[]) -> i32 {
        \\    xs.forEach { x -> @print(x.toString()) @print(x.toString()); };
        \\    return 1;
        \\}
    , .unexpectedToken, 2, 44);
}
