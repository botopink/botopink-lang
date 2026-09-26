//! codegen: WAT backend codegen (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

test "wat: record construct two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn make() -> Point {
        \\    return Point(x: 3, y: 4);
        \\}
    );
}

test "wat: tuple construct then destructure" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val t = #(10, 20);
        \\    val #(a, b) = t;
        \\    @print(a + b);
        \\}
    );
}

test "wat: enum payload construct as tagged struct" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(r: i32),
        \\    Square(side: i32),
        \\}
        \\fn makeCircle() -> Shape {
        \\    return Shape.Circle(r: 5);
        \\}
    );
}

test "wat: string concat via linear memory" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn greeting() -> string {
        \\    return "Hello, " + "World";
        \\}
    );
}

test "wat: string compare via byte loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sameWord() -> bool {
        \\    return "foo" == "bar";
        \\}
    );
}

test "wat: string len reads length prefix" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn n() -> i32 {
        \\    val s = "hello";
        \\    return s.len;
        \\}
    );
}

test "wat: string slice copies bytes into a new buffer" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn first3() -> string {
        \\    val s = "hello";
        \\    return s.slice(0, 3);
        \\}
    );
}

// C-04 (01 step 7, N1) closed the documented skip this test used to pin.
// `libs/std/src/primitives.bp` declares `default fn slice(self, start: i32,
// end: ?i32 = null)`, so the one-argument call is legal — and now the checker
// fills the declared default in, so all four snapshots hold the same lowering
// as the two-argument call and a RUN LOG of `3`. No backend changed: the
// argument reaches them written out, and `end` is the `null` the declaration
// gives it.
test "wat: string slice without end arg slices to source length" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    val tail = s.slice(2);
        \\    @print(tail.len);
        \\}
    );
}

test "wat: string len participates in arithmetic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    @print(s.len + 1);
        \\}
    );
}

test "wat: string slice result length is readable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "abcdef";
        \\    val mid = s.slice(1, 5);
        \\    @print(mid.len);
        \\}
    );
}

// F1 — anonymous record literal lowering. The literal allocates `fields.len * 4`
// bytes in the bump heap, stores each value at offset `i * 4` in source-text
// order, then leaves the base pointer on the stack. Field-by-name read across
// untyped receivers is the separate uniqueFieldOffset heuristic (below).
test "wat: anon record literal two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn make() -> #(i32, i32) {
        \\    val r = #(7, 11);
        \\    return r;
        \\}
    );
}

test "wat: anon record literal nested" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn make() -> #(#(i32, i32), i32) {
        \\    val outer = #(#(1, 2), 3);
        \\    return outer;
        \\}
    );
}

// F1 — field-by-name read via the unique-field-offset heuristic. wat.zig is
// untyped; this fixture pins that an unambiguous field name on the receiver
// lowers to an `i32.load offset=N` against the standalone record's slot
// layout. A second record sharing no field names doesn't perturb the lookup.
test "wat: record field access via unique name" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn first(p: Point) -> i32 {
        \\    return p.x;
        \\}
        \\fn second(p: Point) -> i32 {
        \\    return p.y;
        \\}
    );
}

test "wat: record returned then field read on call result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Span(start: i32, end: i32, line: i32)
        \\fn span() -> Span {
        \\    return Span(start: 4, end: 9, line: 2);
        \\}
        \\fn lineNo() -> i32 {
        \\    return span().line;
        \\}
    );
}

// wat-refactor F2 — type-recovered field access by name (`local_types` +
// `recordTypeOfExpr`). Same spec scenario, runs under wasmtime + prints `11`.
test "wat: record field access by name loads at declared offset" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(a: i32, b: i32)
        \\fn main() {
        \\    val r = R(a: 7, b: 11);
        \\    @print(r.b);
        \\}
    );
}

// wat-refactor F3 — `?.field` on a null receiver short-circuits to
// `i32.const 0`; on a non-null pointer it loads the named slot via the
// `local.tee` + `i32.eqz` + `(if (result i32) ...)` guard.
test "wat: optional chaining on record null returns zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(a: i32, b: i32)
        \\fn pick(maybe: ?R) -> ?i32 {
        \\    return maybe?.b;
        \\}
    );
}

// F1 tail — anon record let-bound to a local then field-read by name. The
// synthetic `__anon_L*_C*` registration in `ensureAnonRecord` lets
// `recordTypeOfExpr` resolve the receiver back to its anon layout so
// `r.kind` lowers to `i32.load offset=4` (slot 1, not the legacy stub).
test "wat: anon record let-bound then field read by name" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val code = 7;
        \\    val kind = 11;
        \\    val r = #(code, kind);
        \\    @print(r.kind);
        \\}
    );
}

// F1 tail — nested anon record reads through the chained type slot. The
// outer literal records its `span` field's type as the inner anon's
// synthetic name; `outer.span.start` therefore lowers to a real
// `i32.load` chain instead of the legacy `i32.const 0` stub.
test "wat: nested anon record chained field read" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val start = 5;
        \\    val end = 9;
        \\    val span = #(start, end);
        \\    val kind = 3;
        \\    val outer = #(span, kind);
        \\    @print(outer.span.start);
        \\}
    );
}

// F2 — Optionals `?T`. Carrier shape on WAT: a reference-typed value is
// non-zero when present, `i32.const 0` when absent. The four fixtures
// below pin the four common shapes the F0 audit identified in template
// bodies:
//
//   1. local `?T = null` round-trips through equality check.
//   2. `?T` from a fn return — null path.
//   3. `?T` from a fn return — value path with `?.`.
//   4. `if x == null` branch + non-null deref via `?.`.

// F2.1 — Optional local initialised to null, equality test against null.
test "wat: optional local equals null" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x: ?i32 = null;
        \\    if (x == null) {
        \\        @print(1);
        \\    } else {
        \\        @print(0);
        \\    }
        \\}
    );
}

// F2.2 — Optional fn return — null arm.
test "wat: optional fn return null path" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn choose(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() {
        \\    @print(choose(false)?.kind);
        \\}
    );
}

// F2.3 — Optional fn return — value path with `?.`.
test "wat: optional fn return present path with optional chaining" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn choose(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() {
        \\    @print(choose(true)?.kind);
        \\}
    );
}

// F2.4 — Branch on `x == null`, deref through `?.` on the present arm.
test "wat: optional branch on equality and chained deref" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn main() {
        \\    val r = R(kind: 11);
        \\    val maybe: ?R = r;
        \\    if (maybe == null) {
        \\        @print(0);
        \\    } else {
        \\        @print(maybe?.kind);
        \\    }
        \\}
    );
}

// F3 — String operations. WAT strings are length-prefixed buffers in
// linear memory (4-byte little-endian length, then raw bytes). The
// existing `__str_concat` / `__str_eq` / `__str_slice` runtime helpers
// already cover concat/equality/slice; `.len` reads the prefix word.
// The 5 fixtures below pin the full surface the F0 audit identified.

// F3.1 — concat of two literals via `+`.
test "wat: string concat of two literals" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hi " + "there";
        \\    @print(s.len);
        \\}
    );
}

// F3.2 — equality compares content, not identity. `left` is built at runtime,
// so it is not the interned "foo" pointer; `diff` is the false case. Expected
// RUN LOG `1` then `0`. beam's RUN LOG is empty while string `+` lowers to an
// arithmetic `'+'` (04-beam B3) — known-wrong output, pinned until that lands.
test "wat: string equality compares content not identity" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val left = "fo" + "o";
        \\    val same = left == "foo";
        \\    val diff = "foo" == "bar";
        \\    if (same) {
        \\        @print(1);
        \\    } else {
        \\        @print(0);
        \\    };
        \\    if (diff) {
        \\        @print(1);
        \\    } else {
        \\        @print(0);
        \\    }
        \\}
    );
}

// F3.3 — slice with both bounds.
test "wat: string slice both bounds" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    val mid = s.slice(1, 4);
        \\    @print(mid.len);
        \\}
    );
}

// F3.4 — length of a runtime concat (composes with `+`).
test "wat: string length after concat" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "ab" + "cdef";
        \\    @print(s.len);
        \\}
    );
}

// F3.5 — `if (s == lit)` branch lights up the equality path inside an if. `s`
// is built at runtime so a pointer-identity compare could not pass. Expected
// RUN LOG `42`; beam's is empty while string `+` is arithmetic (04-beam B3).
test "wat: string equality drives if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "ye" + "s";
        \\    if (s == "yes") {
        \\        @print(42);
        \\    } else {
        \\        @print(0);
        \\    }
        \\}
    );
}

// F4 — List literals over linear memory. Layout: `[len i32][elem0]...`
// (same prefix convention as strings, so `.len` is uniform). The four
// fixtures below pin the F0 audit's list-literal shapes.

// F4.1 — `[1, 2, 3].len` → 3.
test "wat: list literal len reads length prefix" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    @print(xs.len);
        \\}
    );
}

// F4.2 — `[].len` → 0.
test "wat: empty list literal len is zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs: i32[] = [];
        \\    @print(xs.len);
        \\}
    );
}

// F4.3 — list literal of strings (each element is a heap pointer).
test "wat: list literal of strings len" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val labels = ["a", "bb", "ccc"];
        \\    @print(labels.len);
        \\}
    );
}

// F4.4 — list literal of records (each element is a base pointer).
test "wat: list literal of records len" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type P(x: i32, y: i32)
        \\fn main() {
        \\    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
        \\    @print(pts.len);
        \\}
    );
}

// F5 — Structured throw/catch surface. WAT models `@Result`-style
// try/catch over a `[tag, payload]` linear-memory pair (tag 0 = Ok,
// non-zero = Error). `@panic`/`@todo`/`throw` collapse to `unreachable`
// — the backend does not use the exceptions proposal. The 3 fixtures
// below pin the `@Result`-based shape.

// F5.1 — try a `#[@result]` fn, catch the error and yield a default.
test "wat: try catch on result with default fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn maybeFail(should_fail: bool) -> @Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "boom";
        \\    } else {
        \\        return 42;
        \\    }
        \\}
        \\fn main() {
        \\    val v = try maybeFail(false) catch -1;
        \\    @print(v);
        \\}
    );
}

// F5.2 — try expression with catch handler — the error path runs.
test "wat: try catch returns handler value on error" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn maybeFail(should_fail: bool) -> @Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "boom";
        \\    } else {
        \\        return 42;
        \\    }
        \\}
        \\fn main() {
        \\    val v = try maybeFail(true) catch -1;
        \\    @print(v);
        \\}
    );
}

// F5.3 — `try` propagation: the inner Error variant propagates up.
test "wat: try propagation in result fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn inner(should_fail: bool) -> @Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "inner-fail";
        \\    } else {
        \\        return 7;
        \\    }
        \\}
        \\fn outer(should_fail: bool) -> @Result<i32, string> {
        \\    val v = try inner(should_fail);
        \\    return v + 1;
        \\}
        \\fn main() {
        \\    val r = try outer(false) catch -1;
        \\    @print(r);
        \\    val r2 = try outer(true) catch -1;
        \\    @print(r2);
        \\}
    );
}

// ── decision 8 §5: the three defects `01-checker` handed to the backends ─────
//
// Each of the four fixtures below answered wrongly on wasm before front 05's
// case row, and the ones the remaining backends have not taken still do —
// recorded, not hidden, so the next front's commit shows the move. `04-js` took
// its half at `f1757f41`, which is why every commonJS log below is now right.

// §5.1 P8 — a pattern's variant name reaches the backend with the path it was
// **written** with (`Shape.Circle`), while the constructor stores the bare
// `Circle`, so a dotted arm never matched: wasm answered `0` for a `Circle`.
// Every backend has since taken its half — `04-js` at `f1757f41`, `02-erlang`
// and `03-beam` in the `f8d97f95` window — so all four now print `7` then `0`:
// the dotted arm matches a `Circle`, and a `Rect` is not one. erlang answered `0`
// twice; beam left an empty RUN LOG, lifting each arm body into a
// `-main/0-fun-N-` closure it never applied.
test "wat: case ---- a variant pattern written as a dotted path" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() {
        \\    val c = Shape.Circle(radius: 7);
        \\    case c {
        \\        Shape.Circle(r) { @print(r); }
        \\        _ { @print(0); }
        \\    };
        \\    val q = Shape.Rect(width: 2, height: 5);
        \\    case q {
        \\        Shape.Circle(r) { @print(r); }
        \\        _ { @print(0); }
        \\    };
        \\}
    );
}

// §5.1 P8 — the dot shorthand `.Circle(r)`, whose enum comes from the matched
// value. The leading `.` is what tells a variant path from a binding, so it
// stays in the name. All four print `7`; erlang answered `0` and beam printed
// nothing, both since fixed.
test "wat: case ---- the dot-shorthand variant pattern" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() {
        \\    val c = Shape.Circle(radius: 7);
        \\    case c {
        \\        .Circle(r) { @print(r); }
        \\        _ { @print(0); }
        \\    };
        \\}
    );
}

// §5.1 P3 — an arm written `Pattern { … }` arrives as a lambda whose last
// expression is the arm's value. wasm lifted it into the function table and
// left the arm answering a closure-cell address, so the body never ran: this
// program printed nothing at all. All four now print `circle`; beam's log was
// empty until `03-beam` landed, the lifted-closure shape above.
test "wat: case ---- an arm body's statements run and its last expression is its value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() {
        \\    val s = Shape.Circle(radius: 3);
        \\    case s {
        \\        Circle(r) { @print("circle"); }
        \\        Rect(w, h) { @print("rect"); }
        \\    };
        \\}
    );
}

// §5.1 P1 — a one-parameter arm binder binds the whole matched value. All four
// print `7`. erlang did not assemble at all (`main.erl:10:27: variable 'N' is
// unbound`) and beam's log was empty, until 02 and 03 took their halves.
test "wat: case ---- a one-parameter arm binder binds the matched value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val v = 7;
        \\    case v {
        \\        0 { @print("zero"); }
        \\        _ { n -> @print(n); }
        \\    };
        \\}
    );
}

// §5.3 — a failing guard falls through to the next arm. wasm dropped the guard
// entirely, so a guarded arm matched unconditionally: `classify` answered
// `"positive"` for every `n` (`case_guard_bound_identifier_numeric_guard`
// recorded exactly that).
test "wat: case ---- a failing guard falls through to the next arm" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(n: i32) -> string {
        \\    return case n {
        \\        x if x > 0 -> "positive";
        \\        0 -> "zero";
        \\        _ -> "negative";
        \\    };
        \\}
        \\fn main() {
        \\    @print(classify(5));
        \\    @print(classify(0));
        \\    @print(classify(-3));
        \\}
    );
}

// ── C-02: an index IS a method call (decision 63, amended 2026-09-19) ───────
//
// `15-language-surface` landed `xs[0]` in the parser as the reserved builtin
// call `ast.index_builtin_name` over `(receiver, index)`, and `xs[0..2]` is the
// same node with a `range` where the index goes. Each backend then grew its own
// lowering for that node — and the checker still had no type for it, so `xs[0]`
// was `void` and every front wrote `.at(i)` by hand.
//
// C-02 removed the node instead. The checker rewrites it: `xs[k]` IS `xs.at(k)`,
// `xs[a..b]` is `xs.slice(a, b)`, `xs[1..]` is `xs.slice(1, null)`, and a tuple's
// `t[0]` is `t._0`. The four fixtures below are unchanged on purpose — the same
// programs, re-recorded — because what they now measure is different: not four
// lowerings of an index, but whether `Array.at`, `Array.slice` and `String.slice`
// answer on each target. Two of them do not, and BOTH are reproducible with the
// method written by hand and no index anywhere in the program:
//
//   wasm   `rows.at(1)` on an array OF arrays answers a raw heap address (`308`),
//          and `.at(0)` / `.length` of that is `0`; `s.slice(3, null)` — an open
//          end — traps with `out of bounds memory access`. Decision 47's `?T` on
//          wasm carries a non-scalar badly; that is C-18's row and `05-wasm`'s
//          file, not this one.
//   beam   `xs.slice(1, null)` and `s.slice(1, 3)` do not assemble:
//          `beam_asm` folds `Array.slice`'s `default fn` body to its
//          `end != null` arm with no test emitted (the `.S` calls
//          `lists:sublist/3` on `{atom, undefined}`), and it emits a
//          `String_slice/3` whose labels do not resolve. `codegen/beam_asm.zig`
//          is `fix/identity-half3`'s file right now; reported, not reached into.
//
// The gain is on the same two targets, and it is why the trade is worth taking:
// beam used to RUN these programs at exit 0 and answer the receiver or `ok`
// where an element belongs, and wasm answered `0` for an index past the end. An
// index that fails is a defect that can be found; an index that quietly answers
// the wrong thing is what sent two fronts to `.length()`.
//
// One divergence among the four is nobody's row here: a slice prints `[20, 30]`
// on commonJS and beam against `[20,30]` on wasm and erlang (decision 8 §7's
// separator).
test "wat: index ---- an array element, a string character and a slice" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [10, 20, 30];
        \\    val i = 1;
        \\    @print(xs[0]);
        \\    @print(xs[i + 1]);
        \\    val names = ["ana", "bo"];
        \\    @print(names[1]);
        \\    val s = "hello";
        \\    @print(s[1]);
        \\    @print(s[1..3]);
        \\    @print(s[3..]);
        \\    @print(xs[1..]);
        \\}
    );
}

// An index past the end is `xs.at(9)`, whose type is `?i32`, and decision 47
// spells absent `null`. Three backends print the empty optional as `undefined`
// and wasm prints it as `0` — C-18's row, one row for four targets instead of
// the two different wrong answers this fixture used to hold (wasm answered `0`
// from its own `$__arr_at` while the other three answered `undefined`).
test "wat: index ---- an index past the end answers zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [10, 20, 30];
        \\    @print(xs[9]);
        \\}
    );
}

// A float array's slots are `f32`. `fs[0]` and `fs.at(0)` are now the SAME
// expression — that is the whole of decision 63's amendment in one line — so
// the two prints are one lowering and answer `1.5` on all four targets. The
// fixture used to pin them as two different paths, one of which (`$__print_opt_i32`
// over a `?f32` box) printed `1069547520` for `1.5`.
test "wat: index ---- a float array element is reinterpreted, not read as bits" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val fs = [1.5, 2.5];
        \\    @print(fs[0]);
        \\    @print(fs.at(0));
        \\}
    );
}

// The shapes `tests/language/run/index_expression.bp` asks for that the three
// fixtures above do not reach: an index whose element is itself an array
// (`rows[1][0]`, which is `rows.at(1).at(0)` — a method call on a `?T`
// receiver, which the checker lets flow), a slice's length, and a tuple
// element.
//
// commonJS and erlang answer everything, modulo §7's separator. The two that do
// not are named in this section's header and are the libraries' methods on
// those targets, not the index: on wasm `rows.at(1)` is a heap address and
// `rows.at(0).length` is `0`; on beam the module does not assemble, because
// `String_slice/3` comes out with unresolved labels.
test "wat: index ---- a nested index, a slice's length and a tuple element" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val rows = [[1, 2], [3, 4]];
        \\    @print(rows);
        \\    @print(rows[1]);
        \\    @print(rows[1][0]);
        \\    @print(rows[0]?.length);
        \\    val xs = [10, 20, 30];
        \\    @print(xs[0..2].length);
        \\    val sl = xs[0..2];
        \\    @print(sl.length);
        \\    val ps = [#(1, "a"), #(2, "b")];
        \\    @print(ps[1]);
        \\}
    );
}

// A string slice's length, which belonged in the fixture above and is its own
// because of a beam defect that would otherwise hide all seven of that one's
// claims: with a CHAINED primitive method anywhere in the same module
// (`rows.at(1).at(0)`), `beam_asm` emits `String_slice/3` **twice**, with the
// same two labels, and `erlc +from_asm` refuses the module — so
// `scripts/beam_export_audit.sh` refuses the snapshot. Measured by hand, with
// no index expression in the program at all:
//
//     val rows = [[1, 2], [3, 4]];
//     @print(rows.at(1).at(0));
//     val s = "hello";
//     @print(s.slice(1, 3));     // → two `{function, 'String_slice', 3, …}` forms
//
// Drop either half and one copy is emitted and the module assembles. It is a
// duplicate-emission bug in the `default fn` helper, `codegen/beam_asm.zig`'s
// file — `fix/identity-half3`'s right now — and it is reported rather than
// reached into.
test "wat: index ---- a string slice's length" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    @print(s[1..3].length);
        \\}
    );
}

// ── decision 8 §10 and §6 T6, the two twins of `04-js` steps 3 and 4 ─────────

// Decision 105 — a `while` / `loop` is a statement: the answer a search finds
// lives in a `var` the body reassigns before a bare `break`, and a loop that
// ends without finding one leaves it as it was. A RUN LOG, not a snapshot: the
// other backends' baselines of this program are their own fixtures'.
test "wat: loop ---- a search leaves its answer in a var and ends at break" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    var k = 0;
        \\    var r = 0;
        \\    loop { k = k + 1; if (k > 2) { r = k; break; }; };
        \\    @print(r);
        \\    var i = 0;
        \\    var found = 0;
        \\    while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
        \\    @print(found);
        \\    var m = 0;
        \\    while (m < 3) { m = m + 1; };
        \\    @print(m);
        \\}
    , "3\n8\n3\n");
}

// §6 T6 — a tuple is positional at run time and `==` compares its elements;
// T5 — labels take no part. Both sides are pointers into the bump heap, so the
// `i32.eq` this backend emitted answered `false` for two equal tuples. The
// shape is static (`(is)`), so the comparison is emitted element by element:
// a string element through `$__str_eq` (comparing the words would compare
// addresses), a float as the `f32` its slot holds, a nested tuple by recursing
// through the pointer.
test "wat: tuple ---- equality compares elements, and labels take no part" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val a = #(1, "a");
        \\    val b = #(1, "a");
        \\    @print(a == b);
        \\    @print(a != b);
        \\    val c = #(1, "b");
        \\    @print(a == c);
        \\    val name = "SP";
        \\    val pop = 12;
        \\    val labeled = #(name, pop);
        \\    val plain = #("SP", 12);
        \\    @print(labeled == plain);
        \\    val n1 = #(#(1, 2), "x");
        \\    val n2 = #(#(1, 2), "x");
        \\    val n3 = #(#(1, 3), "x");
        \\    @print(n1 == n2);
        \\    @print(n1 == n3);
        \\    val f1 = #(1.5, true);
        \\    val f2 = #(1.5, true);
        \\    val f3 = #(1.5, false);
        \\    @print(f1 == f2);
        \\    @print(f1 == f3);
        \\}
    );
}

// §6 T4 / §7 — a tuple element is printed by its own shape, not by its address.
// `@print(t.1)` answered `256` where it means `x`, and `@print(row.name)` — a
// label the checker resolves to `row._0` — answered `256` where it means `SP`:
// the tuple's shape was known to `printShapeOf` and to nothing else, so a
// **single** element fell through to the numeric printer with exit 0 and no
// diagnostic. `tupleElemShapeOf` slices element N out of the receiver's shape
// and both readers ask it, which also makes an element that is itself a
// container print as one (`t.0` → `#(1, 2)`, `u.0` → `["a", "b"]`).
//
// A RUN LOG and not a snapshot, the shape a single backend's row uses: the last
// two prints are where commonJS and wasm still disagree, and an all-backend
// fixture would pin commonJS's answer in a directory this front does not own.
// commonJS prints `[1, 2]` for `t.0` — it drops the tuple marker when the shape
// hint is absent, which is `04-js`'s to answer, not this front's. Every other
// line here was run on both and matches.
test "wat: tuple ---- an element prints by its shape, positional and labelled" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn load() -> #(name: string, pop: i32) {
        \\    val name = "SP";
        \\    val pop = 12;
        \\    return #(name, pop);
        \\}
        \\fn main() {
        \\    val t = #(#(1, 2), "x");
        \\    @print(t.1);
        \\    @print(t.0.1);
        \\    val row = load();
        \\    @print(row.name);
        \\    @print(row.pop + 1);
        \\    val a = "RJ";
        \\    val b = 7;
        \\    val local = #(a, b);
        \\    @print(local.a);
        \\    val s = t.1;
        \\    @print(s + "!");
        \\    @print(t.1 == "x");
        \\    val u = #(["a", "b"], 3);
        \\    @print(t.0);
        \\    @print(u.0);
        \\}
    , "x\n2\nSP\n13\nRJ\nx!\ntrue\n#(1, 2)\n[\"a\", \"b\"]\n");
}

// ── step 6: the string case primitives ──────────────────────────────────────

// `"aB".toUpperCase()` trapped on wasm (`prim method not lowered on wasm:
// string.toUpperCase/0`). The language-facing name is `toUpper`; `toUpperCase`
// is the host spelling `primitives.bp` gives it through
// `#[@External.Node("toUpperCase")]`, which commonJS answers because it is
// JavaScript's own. `tests/language/test/string_case_conversion.bp` writes it,
// so both spellings now reach `$__str_case`. KNOWN-WRONG (erlang): the module
// does not assemble — `function toUpperCase/1 undefined` — and KNOWN-WRONG
// (beam): an empty RUN LOG. Both are `02-erlang` step 7.
test "wat: string ---- toUpperCase and toLowerCase answer, under both spellings" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("aB".toUpperCase());
        \\    @print("aB".toLowerCase());
        \\    @print("aB".toUpper());
        \\    @print("aB".toLower());
        \\}
    );
}

// ── step 1, the interim: a record or a variant reaching `@print` traps ───────
//
// §7's F2 (`Point(x: 1, y: 2)`) and F3 (`Shape.Square(side: 4)`) need a value
// that knows which named type it is at run time — `13-module-identity`, not this
// front. Until they land there is no text to write, and the numeric printer
// answered the value's **heap address** with exit 0 and no diagnostic:
// `run/print_formatter.bp` printed `328`, `336`, `344` where §7 wants three
// names. That is the one thing this backend must not do, so it now traps, the
// way the 24 fixtures that record a shape wasm cannot lower already do.
//
// The array is here because the same wrong answer hid one bracket deeper:
// `@print([Point(x: 1, y: 2)])` wrote `[256]`. A tuple holding one is covered by
// the same walk; what is not, and is recorded in `wat/AGENTS.md`, is a *local*
// bound to such a container.
//
// The three prints before the trap are deliberate: they show the trap is the
// record's, not the program's, and the RUN LOG keeps their text.
//
// **commonJS already answers §7's text** — `Point(x: 1, y: 2)`,
// `Shape.Square(side: 4)`, `Shape.Nothing`, `[Point(x: 1, y: 2)]` — which is
// worth recording here: a class instance carries its constructor's name, so that
// backend needed no identity work. **erlang answers it too since
// 13-module-identity half 3**: the value carries the atom of the module that
// declares its type, and `'__bp_tagged'/2` reaches that module's
// `'__bp_format'/1`. KNOWN-WRONG (beam): a record is still a bare map
// (`#{x => 1,y => 2}`) and a variant a tagged tuple or an atom
// (`{'Square',4}`, `'Nothing'`) — half 3's step 15. Neither answers an address,
// so neither has this front's interim to make; wasm is the only one that did.
test "wat: print ---- a record and a variant have no printed form yet, so they trap" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\type Shape { Square(side: i32), Nothing }
        \\fn main() {
        \\    @print("hi");
        \\    @print([1, 2]);
        \\    @print(#(1, "a"));
        \\    @print(Point(x: 1, y: 2));
        \\    @print(Shape.Square(side: 4));
        \\    @print(Shape.Nothing);
        \\    @print([Point(x: 1, y: 2)]);
        \\}
    );
}

// ── step 3: the two halves of `Dict.at` answering the fallback ───────────
//
// `modules/std_import` printed `0` where `1` is stored, exit 0, no diagnostic.
// The suspect named in the step was the closure — a `forEach` writing an outer
// local — and it is innocent: the first two prints below worked before the fix.
// The two that did not, each a `?T` whose writer and reader disagreed about the
// box:
//
//   `var h: ?i32 = null; h = 5;`   the assignment stored the bare `5`; the
//                                  binding that declares the slot boxes, the
//                                  assignment did not. `@print(h)` then read
//                                  offset 5 as a box: `16777216`.
//   `d.at("a").unwrapOr(0)`    `-> ?V` is unboxed (a type parameter is not a
//                                  known scalar) and the reader assumed a box.
//                                  A method's declared return type was not
//                                  registered under the symbol its call emits,
//                                  so the reader had nothing to ask.
//
// Registering it fixes three more readers at once — `hasKey` answered `0`/`1`
// for a `bool` and `values()` answered a **pointer** for an array — and the two
// that remain are the generic-parameter limit, written into `wat/AGENTS.md`:
// `keys()` is `Array<K>` with `K = string`, and `?V` with `V = string`, and
// nothing here monomorphises, so both print an address.
//
// wasm's log is now **byte-identical to erlang's**, and to beam's but for §7's
// separator (`[6,8]` on wasm and erlang, `[6, 8]` on commonJS and beam, which is
// the text §7 wants — this front's step 1 F1 and 02's). The one text where wasm
// is with the majority and commonJS is the outlier: `undefined` for absence on
// three backends against commonJS's `null`, which decision 8 §7 names neither of.
// Reported, not changed here: it is one text on four backends, not this front's.
//
// The `Dict` cells this row was found through live in `std_package.zig`, where
// erlang's and beam's own cross-module rows are pinned.
test "wat: option ---- a value assigned into a declared `?T` is boxed like one" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Box(items: Array<i32>) {
        \\    fn total(self: Self) -> i32 {
        \\        var sum = 0;
        \\        self.items.forEach({ n -> sum = sum + n });
        \\        return sum;
        \\    }
        \\    fn isBig(self: Self) -> bool { return self.items.length > 1; }
        \\    fn doubled(self: Self) -> Array<i32> { return self.items.map({ n -> n * 2 }); }
        \\    fn label(self: Self) -> string { return "box"; }
        \\}
        \\fn main() {
        \\    var seen = 0;
        \\    [1, 2].forEach({ n -> seen = n });
        \\    @print(seen);
        \\    val b = Box(items: [3, 4]);
        \\    @print(b.total());
        \\    var h: ?i32 = null;
        \\    @print(h);
        \\    h = 5;
        \\    @print(h);
        \\    var acc: ?i32 = null;
        \\    [7, 8].forEach({ n -> acc = n });
        \\    @print(acc);
        \\    @print(b.isBig());
        \\    @print(b.doubled());
        \\    @print(b.label());
        \\}
    );
}

// ── step 7: function values ─────────────────────────────────────────────────
//
// The step asked whether to build them or defer, on the reading that "wasm has no
// function values". Measured first, and the reading was wrong: `wat.zig` lifts a
// lambda into `$__lambda{n}(env, …)`, lists it in the module's function table and
// applies it with `call_indirect`, and four of the five ways a function reaches a
// value already worked — a lambda in a local, a lambda passed as a `fn(…)`
// parameter, a top-level fn used as a value, and one bound to a local.
//
// The fifth did not: a function value read out of an **aggregate slot**.
// `lowerValueCall` recognised a record field and nothing else, and a labelled
// tuple element is resolved by the checker to its *position* — `c.set` arrives as
// `_1`, which is not a field name — so the call fell through to the unresolved
// path: `unreachable ;; unresolved call: _1/1`. One helper (`slotOffset`, a record
// field offset or `tupleIndex * 4`) closes it, so there is nothing to defer.
//
// All four prints match commonJS exactly. The three fixtures the step listed as
// this shape's traps were re-read with it: only
// `tuple_a_labeled_element_of_function_type_is_called_like_a_method` was one, and
// it now answers `18` on all four backends. `call_trailing_lambda_block` and
// `call_trailing_lambda_with_multiple_params` trap on the **`@todo()` in the
// function they call** — the program's own trap, not a missing mechanism — and
// neither ever carried a `KNOWN` note saying otherwise.
test "wat: function value ---- a lambda in a tuple slot or a record field is applied" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Ops(step: fn(n: i32) -> i32)
        \\fn mk() -> #(value: i32, set: fn(n: i32) -> i32) {
        \\    val value = 1;
        \\    val set = { n -> return n * 2; };
        \\    return #(value, set);
        \\}
        \\fn main() {
        \\    val c = mk();
        \\    @print(c.value);
        \\    @print(c.set(9));
        \\    val t = #(1, { n -> return n + 100; });
        \\    @print(t._1(2));
        \\    val o = Ops(step: { n -> return n - 1; });
        \\    @print(o.step(10));
        \\}
    );
}

// `String.at` — the reader decision 63's amendment gave every indexable type,
// and what `s[i]` rewrites to. It had no wasm lowering at all: the call fell
// through `primCallRes` and emitted
// `unreachable ;; prim method not lowered on wasm: string.at/1`, so
// `tests/language/run/index_at_optional.bp` died at exit 134 on this backend
// while commonJS, erlang and beam all answered. `$__str_at` is
// `$__str_slice(s, i, i + 1)` behind one `i32.ge_u` bounds test — unsigned, so a
// negative index wraps past any length and is rejected by the same compare.
//
// The absent probes are the half that makes the lowering safe rather than merely
// present: `at` answers a `?string` whose absence is the pointer `0`, and
// `optInfoOf` routes it through `$__print_opt_str`. Printed as a plain string it
// would read a length out of the WASI iovec at address 0 and answer garbage with
// exit 0 — the silent-wrong-answer class this backend refuses to add to.
//
// A RUN LOG and not a snapshot: `String.at` already answers on the other three
// backends, so an all-backend fixture would move
// `snapshots/codegen/{commonJS,erlang,beam}/`, which this front does not own.
// `tests/language/run/string_at.bp` is the cross-backend half.
test "wat: prim method ---- String.at answers a one-character string, and null out of range" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    val s = "abc";
        \\    @print(s.at(0));
        \\    @print(s.at(2));
        \\    @print(s.at(3));
        \\    @print(s.at(0 - 1));
        \\    @print("hello world".at(6));
        \\}
    , "a\nc\nundefined\nundefined\nw\n");
}

// A self-call in `return` position is a branch to the function's own loop head
// (`00 · 05-wasm` step 9). wasm has no tail calls unless the proposal is
// enabled, and wasmtime's default does not enable it: `count(10000, 0)` answered
// and `count(100000, 0)` trapped `call stack exhausted` at exit 134, where the
// other three backends answer. `return f(args)` inside `fn f` now evaluates
// every argument, re-binds the parameters in reverse and `br $__tail`s; the
// body is wrapped in `(loop $__tail (result …))` only when such a call exists,
// so no other function's text moves. `sumTo` pins that the accumulator reads the
// OLD `n` — the arguments are on the stack before any parameter is re-bound.
//
// A RUN LOG and not a snapshot: the depth is the point, and the other three
// backends already answer it. `tests/language/run/tail_self_call.bp` is the
// cross-backend half.
test "wat: tail call ---- a self-call in return position runs in one frame" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn count(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) { return acc; } else { return count(n - 1, acc + 1); }
        \\}
        \\fn sumTo(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) { return acc; };
        \\    return sumTo(n - 1, acc + n);
        \\}
        \\fn main() {
        \\    @print(count(1000000, 0));
        \\    @print(sumTo(1000, 0));
        \\}
    , "1000000\n500500\n");
}
