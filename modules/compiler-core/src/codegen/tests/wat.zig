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

test {
    _ = @import("../wat/host_binding.zig");
}

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
// as the two-argument call and a RUN LOG of `3`. The argument reaches the
// backends written out — `end` is the `null` the declaration gives it — and wasm
// read that `null` as `0` and trapped until `00 · 05-wasm` made it the end.
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
//          end — trapped with `out of bounds memory access` until `00 · 05-wasm`
//          read a `null` end as the end (`a null end, written or at run time,
//          is the end`); it answers `lo` / `[20, 30]` now.
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
// spells absent `null`. commonJS (`__bp_array_at`) and wasm (`$__print_null`)
// print it so since 1.0.10-beta `00 · 04-js` / `05-wasm`; erlang and beam still
// print the atom `undefined` — C-18's row, theirs.
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
// commonJS and erlang answer everything, modulo §7's separator (commonJS
// prints `ps[1]` as `[2, "b"]`, `04-js`'s row). wasm answers erlang's text:
// `rows[1]` and `ps[1]` print by the element's shape (`OptInfo.shape`) — they
// printed the row's and the tuple's heap address at exit 0 until
// `01-compiler/05-wasm` step 1. On beam the module does not assemble, because
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
// `i32.eq` this backend emitted answered `false` for two equal tuples. Since
// decision 210 each tuple type compares through its generated
// `$__eq_Tuple<n>_…`: a string element through `$__str_eq` (comparing the
// words would compare addresses), a float as the `f32` its slot holds, a nested
// tuple through its own equality.
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

// `"aB".toUpper()` reaches `$__str_case` on wasm. The host spellings
// (`toUpperCase`, JavaScript's own, which `primitives.bp` gives `toUpper`
// through `#[@External.Node("toUpperCase")]`) used to be lowered here too; the
// checker refuses them now (pending 0203-a, answered (b):
// `tests/language/reject/primitive_method_undeclared.bp`).
test "wat: string ---- toUpper and toLower answer" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
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
// was with the majority and commonJS the outlier: `undefined` for absence on
// three backends against commonJS's `null`. Decision 47 settles it — absent is
// spelled `null` — and wasm prints `null` since 1.0.10-beta `00 · 05-wasm`
// (`$__print_null`); erlang and beam are C-18's.
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
// `$__str_slice(s, i, i + 1)` behind one `i32.ge_u` bounds test, after a
// negative index has been counted from the end (`i + len`, decision 139) — one
// still negative wraps past any length and is rejected by the same compare.
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
        \\    @print(s.at(0 - 4));
        \\    @print("hello world".at(6));
        \\}
    , "a\nc\nnull\nc\nnull\nw\n");
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

// `00 · 05-wasm` step 6's audit of `primitives.bp` against `primCallRes`: the
// `String` and `Float` members with a byte-level answer are lowered, each
// answering what commonJS answers for the same program (measured side by
// side). `5.0.toString()` is `5`, as on node; `charCodeAt` out of range is
// `-1`, the answer both host templates give; the pad cycles as JavaScript's
// does; an empty pattern matches before every byte.
test "wat: prim method ---- the String and Float members step 6's audit lowered" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    val f = 2.5;
        \\    @print(f.toString());
        \\    val g = 5.0;
        \\    @print(g.toString());
        \\    @print("abc".charCodeAt(1));
        \\    @print("abc".charCodeAt(7));
        \\    @print("a-b-c".lastIndexOf("-"));
        \\    @print("a-b-c".lastIndexOf("z"));
        \\    @print("ab".padStart(5, "*-"));
        \\    @print("ab".padEnd(5, "*-"));
        \\    @print("abcdef".padStart(3, "*"));
        \\    @print("a-b-c".replace("-", "+"));
        \\    @print("a-b-c".replaceAll("-", "+="));
        \\    @print("ab".replaceAll("", "-"));
        \\    @print("xy".chars());
        \\    @print([1, 2, 3].find({ x -> x > 1 }));
        \\    @print([1, 2, 3].find({ x -> x > 5 }));
        \\}
    ,
        \\2.5
        \\5
        \\98
        \\-1
        \\3
        \\-1
        \\*-*ab
        \\ab*-*
        \\abcdef
        \\a+b-c
        \\a+=b+=c
        \\-a-b-
        \\["x", "y"]
        \\2
        \\null
        \\
    );
}

// `01-compiler/05-wasm` step 1: the primitive methods step 6's audit left
// trapping each have a lowering — `$__str_lines` / `$__str_words`, and the
// array helpers `$__arr_unique`, `$__arr_flatten` (`flatMap` is `map` then
// it, as `primitives.bp`'s body is), `$__arr_chunked`, `$__arr_sliding`,
// `$__arr_fill`. The answers are commonJS's, erlang's and beam's for the same
// program (`tests/language/run/string_lines_words.bp`, `array_unique.bp`,
// `array_flat_forms.bp`, `array_windows.bp`, `array_fill.bp`).
test "wat: prim method ---- the methods that trapped lower: lines, words, unique, the flat forms, the windows, fill" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    @print("a b\tc\n d".words());
        \\    @print("a\nb\r\nc\r".lines());
        \\    @print([3, 1, 1, 3].unique());
        \\    @print(["a", "a", "b"].unique());
        \\    @print([true, true, false].unique());
        \\    @print([[1], [2, 3]].flatten());
        \\    @print([["a"], ["b"]].flat());
        \\    @print([1, 2].flatMap({ x -> [x, x] }));
        \\    @print([1, 2, 3].chunked(2));
        \\    @print([1, 2, 3].sliding(2));
        \\    @print([1, 2].fill(0));
        \\}
    ,
        \\["a", "b", "c", "d"]
        \\["a", "b", "c\r"]
        \\[3, 1, 3]
        \\["a", "b"]
        \\[true, false]
        \\[1, 2, 3]
        \\["a", "b"]
        \\[1, 1, 2, 2]
        \\[[1, 2], [3]]
        \\[[1, 2], [2, 3]]
        \\[0, 0]
        \\
    );
}

// What is left of the class is refused by name rather than answered:
// `unique` over records (`$__arr_unique` compares words and strings; decision
// 210's structural answer has no wasm lowering yet), `flatMap` whose function
// answers a scalar (node keeps it, erlang fails), and `flatten` over elements
// no shape says are arrays. Each was a run-time trap; each is a located build
// refusal at the call now (`00 · 110-gate-wasm`).
test "wat: prim method ---- unique over records, flatMap over a scalar and flatten over scalars are refused at the call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type P(x: i32)
        \\fn main() {
        \\    @print([P(x: 1), P(x: 1)].unique().length);
        \\}
    , "`unique` on the wasm backend compares", 3, 31);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn main() {
        \\    @print([1, 2].flatMap({ x -> x + 1 }));
        \\}
    , "`flatMap` on the wasm backend: nothing shows that its function answers an array", 2, 19);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn main() {
        \\    @print([1, 2].flatten());
        \\}
    , "`flatten` on the wasm backend: nothing shows", 2, 19);
}

// `Array.pop` and `Array.lastIndexOf` left the trap list: `pop` answers the
// `?T` `at(-1)` does and rebinds the local to a copy one shorter, as `push`
// rebinds it to a grown one; `lastIndexOf` walks `indexOf`'s equality from
// the last slot down.
test "wat: prim method ---- pop shrinks a local array and lastIndexOf searches from the end" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    var xs = [1, 2, 3];
        \\    val p = xs.pop();
        \\    @print(p);
        \\    @print(xs);
        \\    @print([1, 2, 1].lastIndexOf(1));
        \\    @print(["a", "b"].lastIndexOf("z"));
        \\}
    ,
        \\3
        \\[1, 2]
        \\2
        \\-1
        \\
    );
}

// Decision 8 §11's box on wasm (`00 · 05-wasm` step 2): a value entering an
// `unknown` slot carries a header naming what it holds, and `is`, a type arm,
// `==` and `@print` read it — `tests/language/run/unknown_by_value.bp` pins the
// answers on four targets. What this pins is the one refusal: a value whose
// type nothing proves — here a type parameter's slot, which this backend does
// not monomorphise — is not boxed by a guess. Boxed as the `i32` it is at run
// time, `v is string` answered `false` for `"abc"` at exit 0 (`-1` where the
// other backends answer `3`). The guarded arm answers a literal: a field read
// on that slot (`v.length`) is refused before the module exists — the test
// below pins that diagnostic. The box itself is refused too, where the value
// enters the `unknown` slot (`v is string` boxes `v`): it was a run-time
// trap, and `00 · 110-gate-wasm` makes every lowering that cannot proceed a
// located build refusal.
test "wat: unknown ---- a type parameter's slot is refused, not boxed by a guess" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type Maybe<T> {
        \\    Some(value: T),
        \\    None,
        \\}
        \\fn innerLength(b: unknown) -> i32 {
        \\    return case b {
        \\        Maybe.Some(value: v) when (v is string) { 1 }
        \\        Maybe.Some(value: v) { -1 }
        \\        _ { -2 }
        \\    };
        \\}
        \\fn main() {
        \\    val x: unknown = 1;
        \\    @print(innerLength(x));
        \\    val s: unknown = Maybe.Some(value: "abc");
        \\    @print(innerLength(s));
        \\}
    , "the wasm backend cannot box this value as `unknown`", 7, 36);
}

// `00 · 110-gate-wasm` step 2: a field read this backend cannot place — the
// receiver is a type parameter's slot, which nothing here types — is REFUSED
// where it is written, as every lowering that cannot proceed now is. It used
// to write `i32.const 0` with a `;; note` and go on, so the program ran and
// printed a wrong value at exit 0. commonJS, erlang and beam answer `3`; the
// wasm snapshot records the diagnostic — the guard's, now: `v is string` boxes
// the same untyped slot, and that box is refused first (the test above).
test "wat: unknown ---- a field read on a type parameter's slot is refused" {
    try h.assertJsExpecting(std.testing.allocator, @src(), &.{
        .{
            .path = "",
            .source =
            \\type Maybe<T> {
            \\    Some(value: T),
            \\    None,
            \\}
            \\fn innerLength(b: unknown) -> i32 {
            \\    return case b {
            \\        Maybe.Some(value: v) when (v is string) { v.length }
            \\        Maybe.Some(value: v) { -1 }
            \\        _ { -2 }
            \\    };
            \\}
            \\fn main() {
            \\    val s: unknown = Maybe.Some(value: "abc");
            \\    @print(innerLength(s));
            \\}
            ,
        },
    }, .refused_on_wasm);
}

// A slice's `end: ?i32` written out as `null` — or an optional that is absent
// at run time — means "to the end". Lowered as the `0` a `null` is, the end
// fell before the start and `$__str_slice` read out of bounds (a trap), where
// commonJS and erlang answer `cdef`; an optional `end` was read as its box's
// ADDRESS. (status.md's `slice(2, null)` row.)
test "wat: slice ---- a null end, written or at run time, is the end" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn cut(s: string, end: ?i32) -> string {
        \\    return s.slice(1, end);
        \\}
        \\fn main() {
        \\    @print("abcdef".slice(2, null));
        \\    @print([1, 2, 3, 4].slice(1, null));
        \\    @print(cut("abcdef", 3));
        \\    @print(cut("abcdef", null));
        \\}
    ,
        \\cdef
        \\[2, 3, 4]
        \\bc
        \\bcdef
        \\
    );
}

// `01-compiler/05-wasm` step 3 — C-07's wasm twins, one fixture per pattern
// shape of decision 8 §5, each RUN LOG the value erlang and beam answer for
// the same program (and commonJS, where it answers; the rows it does not are
// named at the fixture). Before this step a tuple pattern in a `case` was
// refused (`` `` names no variant``), every list pattern matched every array
// (`[x]` took a `[]` arm), and `true` / `false` inside a tuple pattern were
// binders, so every arm matched — the last two a wrong value at exit 0.

// §5.1 P6: a tuple pattern is positional; a literal inside it is tested, a
// name binds the element by its own shape (a string prints as text), and a
// labelled tuple type is still matched by position.
test "wat: case ---- a tuple pattern tests its literals and binds its elements" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn classify(p: #(i32, string)) -> string {
        \\    return case p {
        \\        #(0, s) { "zero " + s }
        \\        #(n, "x") { "x " + n.toString() }
        \\        #(_, s) { s }
        \\    };
        \\}
        \\fn capital(r: #(name: string, pop: i32)) -> string {
        \\    return case r {
        \\        #("SP", p) { "capital " + p.toString() }
        \\        #(n, _) { n }
        \\    };
        \\}
        \\fn nested(t: #(#(i32, i32), string)) -> string {
        \\    return case t {
        \\        #(#(0, b), s) { s + b.toString() }
        \\        #(#(a, _), s) { s + "!" + a.toString() }
        \\    };
        \\}
        \\fn main() {
        \\    @print(classify(#(0, "a")));
        \\    @print(classify(#(7, "x")));
        \\    @print(classify(#(7, "y")));
        \\    @print(capital(#("SP", 12)));
        \\    @print(capital(#("Rio", 6)));
        \\    @print(nested(#(#(0, 7), "z")));
        \\    @print(nested(#(#(5, 7), "z")));
        \\}
    ,
        \\zero a
        \\x 7
        \\y
        \\capital 12
        \\Rio
        \\z7
        \\z!5
        \\
    );
}

// §5.1 P7: `..` ignores the rest — of a tuple, a variant's fields and a
// record's — and `true` / `false` in a pattern are the bool literals. commonJS
// emits `const true = _s[2]` for the last (a SyntaxError, `04-js`'s row), and
// erlang binds it (`names(#("a", "b", false))` answers `ba`, `02-erlang`'s).
test "wat: case ---- `..` skips the rest and a bool literal in a tuple pattern is tested" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(w: i32, h: i32),
        \\    Dot,
        \\}
        \\type Point(x: i32, y: i32)
        \\fn first(t: #(i32, i32, i32)) -> i32 {
        \\    return case t {
        \\        #(a, ..) { a }
        \\    };
        \\}
        \\fn width(s: Shape) -> i32 {
        \\    return case s {
        \\        Shape.Rect(w: w, ..) { w }
        \\        Shape.Circle(..) { -1 }
        \\        _ { 0 }
        \\    };
        \\}
        \\fn px(p: Point) -> i32 {
        \\    return case p {
        \\        Point(x: 0, ..) { 0 }
        \\        Point(x: x, ..) { x }
        \\    };
        \\}
        \\fn names(t: #(string, string, bool)) -> string {
        \\    return case t {
        \\        #(a, b, true) { b + a }
        \\        #(a, ..) { a }
        \\    };
        \\}
        \\fn main() {
        \\    @print(first(#(4, 5, 6)));
        \\    @print(width(Shape.Rect(w: 4, h: 5)));
        \\    @print(width(Shape.Circle(radius: 1)));
        \\    @print(width(Shape.Dot));
        \\    @print(px(Point(x: 0, y: 1)));
        \\    @print(px(Point(x: 3, y: 1)));
        \\    @print(names(#("a", "b", true)));
        \\    @print(names(#("a", "b", false)));
        \\}
    ,
        \\4
        \\4
        \\-1
        \\0
        \\0
        \\3
        \\ba
        \\a
        \\
    );
}

// §5.2: an arm naming a type is chosen by the value — a primitive over an
// `unknown` subject by its box (binding the unboxed payload), a record and an
// enum by the value's header. commonJS answers `other` for `Shape { … }` over
// a variant, where erlang and beam answer `shape` (`04-js`'s row).
test "wat: case ---- a type pattern is chosen by the value" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Shape {
        \\    Rect(w: i32, h: i32),
        \\    Dot,
        \\}
        \\type Point(x: i32, y: i32)
        \\fn kind(v: unknown) -> string {
        \\    return case v {
        \\        i32 { n -> "int " + n.toString() }
        \\        string { s -> "string " + s }
        \\        bool { "bool" }
        \\        Point { "point" }
        \\        Shape { "shape" }
        \\        _ { "other" }
        \\    };
        \\}
        \\fn main() {
        \\    @print(kind(1));
        \\    @print(kind("a"));
        \\    @print(kind(true));
        \\    @print(kind(Point(x: 1, y: 2)));
        \\    @print(kind(Shape.Rect(w: 1, h: 1)));
        \\    @print(kind(2.5));
        \\}
    ,
        \\int 1
        \\string a
        \\bool
        \\point
        \\shape
        \\other
        \\
    );
}

// §5.1 list patterns: the length — exactly the elements written, or at least
// them with a spread — then each literal; a binder by the element's shape and
// a named spread bound to the rest. erlang answers the same; commonJS tests no
// literal (`pick([2, 9])` answers `9`) and a brace arm answers a function
// (`04-js`'s rows); beam leaves the binders unresolved (`03-beam`'s).
test "wat: case ---- a list pattern tests its length and literals and binds the rest" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn head(xs: string[]) -> string {
        \\    return case xs {
        \\        [] -> "none";
        \\        [a, ..rest] -> a + "+" + rest.length.toString();
        \\    };
        \\}
        \\fn pick(xs: i32[]) -> i32 {
        \\    return case xs {
        \\        [1, b] -> b;
        \\        [_, _, c, ..] -> c;
        \\        [..] -> -1;
        \\    };
        \\}
        \\fn main() {
        \\    @print(head([]));
        \\    @print(head(["x"]));
        \\    @print(head(["x", "y", "z"]));
        \\    @print(pick([1, 9]));
        \\    @print(pick([2, 9]));
        \\    @print(pick([5, 6, 7, 8]));
        \\}
    ,
        \\none
        \\x+0
        \\x+2
        \\9
        \\-1
        \\7
        \\
    );
}

// Decision 152 refuses a second binding of one name in one body, and decision
// 205 makes the body the whole function: an inner block's `val`, a loop's
// binder and a `case` arm's binder over a name visible there are refused by the
// checker (`reject/binding_shadows_in_inner_block`,
// `reject/case_arm_binder_reuses_name`). What stays legal is a lambda — a
// function of its own — binding a name its enclosing function holds, as a
// parameter or a `val` of its body, and two sibling blocks each binding one
// name. One wasm function is one local namespace and a HOF's lambda is inlined
// into it, so the lambda's `val k = "lambda"` wrote the outer `$k` and every
// read after it answered the inner value (`lambda` where node answers `5`; the
// pre-pass also marked the outer `k` a string). A re-binding is a local of its
// own (`bindTarget`, `<name>__sh<n>`), aliased until its statement list ends
// (`scopeRestore`). The RUN LOG is commonJS's.
test "wat: scope ---- a lambda's binding shadows the outer one only inside it" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() {
        \\    val k = 5;
        \\    [1].forEach({ e ->
        \\        val k = "lambda";
        \\        @print(k);
        \\    });
        \\    @print(k);
        \\    val e = 5;
        \\    [1, 2].forEach({ e -> @print(e) });
        \\    @print(e);
        \\    if (true) { val t = 1; @print(t); }
        \\    if (true) { val t = "two"; @print(t); }
        \\}
    ,
        \\lambda
        \\5
        \\1
        \\2
        \\5
        \\1
        \\two
        \\
    );
}

// Decision 214 — the NaN half of `f64`'s total-order `==`, which the
// four-target cell `run/f64_equality_total_order.bp` cannot carry (erlang and
// beam never produce a NaN): `NaN == NaN` is `true` bare and inside a record,
// a tuple, an array and a variant, `NaN != NaN` is `false`, and NaN against a
// number is unequal. `<` stays IEEE (`NaN < 1.0` is `false`).
test "wat: f64 ---- NaN equals NaN under ==, bare and inside composites" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type F(x: f64)
        \\type V {
        \\    W(x: f64),
        \\    Z,
        \\}
        \\fn zero() -> f64 {
        \\    return 0.0;
        \\}
        \\fn main() {
        \\    val z = zero();
        \\    val nan = z / z;
        \\    @print(nan == nan);
        \\    @print(nan != nan);
        \\    @print(nan == 1.0);
        \\    @print(nan < 1.0);
        \\    @print(F(x: nan) == F(x: z / z));
        \\    val ta = #(nan, 1);
        \\    val tb = #(z / z, 1);
        \\    @print(ta == tb);
        \\    val xs = [nan];
        \\    val ys = [z / z];
        \\    @print(xs == ys);
        \\    @print(V.W(x: nan) == V.W(x: z / z));
        \\    @print(F(x: nan) == F(x: 1.0));
        \\}
    , "true\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\ntrue\nfalse\n");
}

// A behavior `default fn` adopted by two types, one of which calls a primitive
// method on another default's result (`self.twice().toString()`): inference
// typed the body against `Self`, so the receiver had no recorded lowering and
// `Sq_label` trapped (`unresolved call: toString/0`). The callee's declared
// return answers it. The RUN LOG is commonJS's and erlang's for the program.
test "wat: behavior ---- a primitive method on a default's result inside an adopted default" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Shape {
        \\    fn area(self: Self) -> i32;
        \\    default fn twice(self: Self) -> i32 {
        \\        return self.area() * 2;
        \\    }
        \\    default fn label(self: Self) -> string {
        \\        return "area " + self.twice().toString();
        \\    }
        \\}
        \\type Sq(s: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.s * self.s;
        \\    }
        \\}
        \\fn main() {
        \\    @print(Sq(s: 3).label());
        \\}
    , "area 18\n");
}

// A program's own `default fn` of a primitive behavior: a copy with `Self`
// written as the receiver's primitive, called with the receiver as `self`
// (`lowerPrimDefault`). It trapped (`prim method not lowered on wasm`). The
// RUN LOG is commonJS's and erlang's for the program.
test "wat: behavior ---- a program's default fn on a primitive behavior is called" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn shout(self: Self) -> string {
        \\        return self + "!";
        \\    }
        \\}
        \\behavior Number {
        \\    default fn twice(self: Self) -> Self {
        \\        return self + self;
        \\    }
        \\}
        \\fn main() {
        \\    @print("hi".shout());
        \\    val n: i32 = 21;
        \\    @print(n.twice());
        \\}
    , "hi!\n42\n");
}

// A program's own `default fn` on `Array<T>`: the copy writes `Self<T>` as the
// receiver's array type and `T` as its element (`ensurePrimDefault`). It
// trapped (`prim method not lowered on wasm`). The RUN LOG is commonJS's and
// erlang's for the program.
test "wat: behavior ---- a program's default fn on Array<T> is called with its element type" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Array<T> {
        \\    default fn tag(self: Self<T>) -> string {
        \\        return "arr";
        \\    }
        \\    default fn pairUp(self: Self<T>, x: T) -> Self<T> {
        \\        return [x, x];
        \\    }
        \\}
        \\fn main() {
        \\    @print([1, 2].tag());
        \\    @print([1].pairUp(7));
        \\    @print(["a"].pairUp("b"));
        \\}
    , "arr\n[7, 7]\n[\"b\", \"b\"]\n");
}

// A lambda stored in a generic record's field (`Box<T>(value: T)`) whose
// parameter nothing types: the record goes through a generic fn and the
// field is called on the result, so no call through the constructor's own
// local and no written type reach the lambda. Its parameter's word may be a
// string or an integer; the lambda is REFUSED where it is written
// (`lambda parameter `s`: nothing gives it a type the wasm backend can see`)
// instead of guessing — it printed `300?` for `"d" + "?"` at exit 0, then
// trapped at the lambda's entry until `00 · 110-gate-wasm`. commonJS answers
// `x%`.
test "wat: function value ---- a lambda in a generic field that nothing types is refused, never guessed" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type Box<T>(value: T)
        \\fn keep<T>(b: Box<T>) -> Box<T> {
        \\    return b;
        \\}
        \\fn main() {
        \\    val esc = keep(Box(value: { s -> s + "%" }));
        \\    val ef = esc.value;
        \\    @print(ef("x"));
        \\}
    , "lambda parameter `s`: nothing gives it a type the wasm backend can see", 6, 31);
}

// ── `00 · 110-gate-wasm`: every lowering that cannot proceed is a located refusal ──
//
// Each program below compiled on wasm and died at run time on an
// `unreachable` the lowering wrote "so the module still loads" — a program the
// other backends run, refused only once it executed. The rule of
// `codegen/wat/AGENTS.md` § Where this backend refuses to answer is that a
// lowering that cannot proceed stops the build where the source is written;
// what keeps an `unreachable` is the program's own semantics (`assert`,
// `@panic`, `@todo`, an uncaught `throw`, a rejected `#[@future]`) and the
// structural end of a dispatch nothing else reaches.

// `is` over an all-unit enum: its values are bare ordinals with no header, so
// there is no run-time test. commonJS answers `false`.
test "wat: refusal ---- is over a type with no descriptor is refused at the test" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type Color { Red, Green }
        \\pub fn main() {
        \\    val c: unknown = 1;
        \\    @print(c is Color);
        \\}
    , "`is Color`: the wasm backend has no run-time test for this type", 4, 14);
}

// A decorator / template builtin written in a program body: nothing on wasm
// runs it. (commonJS emits `__emit("x")` and dies at run time — `04-js`'s row.)
test "wat: refusal ---- a comptime-only builtin in a program body is refused" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\pub fn main() {
        \\    @emit("x");
        \\}
    , "`@emit` is a comptime-only builtin", 2, 5);
}

// `pop` shrinks its receiver in place on the other backends. A local, a module
// `var` and — now — a record's field are rebound to the shorter copy; a call's
// result may be an array another name holds, which a copy would leave whole,
// so it is refused rather than answered.
test "wat: refusal ---- pop on a call's result is refused, pop on a record field shrinks it" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn xs() -> Array<i32> {
        \\    return [1, 2];
        \\}
        \\pub fn main() {
        \\    @print(xs().pop());
        \\}
    , "`pop` on the wasm backend rebinds its receiver", 5, 17);
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Stack(items: Array<i32>)
        \\pub fn main() {
        \\    val s = Stack(items: [1, 2, 3]);
        \\    @print(s.items.pop());
        \\    @print(s.items);
        \\}
    ,
        \\3
        \\[1, 2]
        \\
    );
}

// Dispatch by value tells implementers apart by the header behind the value;
// an all-unit enum's variant is its ordinal and has none, so `show(Color.Red)`
// reached the dispatcher's end and trapped after printing `p`. commonJS prints
// `p` then `c`.
test "wat: refusal ---- dispatch by value over an all-unit enum implementer is refused at the call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\behavior Named {
        \\    fn name(self: Self) -> string;
        \\}
        \\type Color implement Named {
        \\    Red,
        \\    Green,
        \\
        \\    fn name(self: Self) -> string {
        \\        return "c";
        \\    }
        \\}
        \\type P(x: i32) implement Named {
        \\    fn name(self: Self) -> string {
        \\        return "p";
        \\    }
        \\}
        \\fn show(n: Named) -> string {
        \\    return n.name();
        \\}
        \\pub fn main() {
        \\    @print(show(P(x: 1)));
        \\    @print(show(Color.Red));
        \\}
    , "`Color` is an all-unit enum", 18, 14);
}

// A generic body is the one a call reaches when no specialisation bound its
// type parameters. `x is string` over a `T` now asks for a copy per bound type
// (`callsMethodOn`), so `shown(1)` / `shown("s")` / `shown(true)` answer from
// copies; the generic body keeps an `unreachable` no execution meets.
test "wat: refusal ---- is over a type parameter specialises the generic fn per bound type" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn shown<T>(x: T) -> string {
        \\    if (x is string) return "q";
        \\    return "n";
        \\}
        \\pub fn main() {
        \\    @print(shown(1));
        \\    @print(shown("s"));
        \\    @print(shown(true));
        \\}
    ,
        \\n
        \\q
        \\n
        \\
    );
}

// ...and a concrete call that reaches the generic body unspecialised — here
// `$__display_of` printing a `Box<i32>` through the ONE `Box.display`, whose
// `shown(self.value)` binds nothing — is refused where it is written
// (`refuseUnboundTemplateCalls`). It trapped inside `shown`. commonJS prints
// `Box(n)`.
test "wat: refusal ---- a generic body reached with nothing bound is refused at the concrete call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn shown<T>(x: T) -> string {
        \\    if (x is string) return "s";
        \\    return "n";
        \\}
        \\type Box<T>(value: T) implement Display {
        \\    pub fn display(self: Self<T>) -> string {
        \\        return "Box(" + shown(self.value) + ")";
        \\    }
        \\}
        \\pub fn main() {
        \\    @print(Box(value: 1));
        \\}
    , "cannot call the generic `Box.display` here", 11, 12);
}

// Decision 238 — what a `#[@External.Wasm("…")]` binding names: `op:` one
// numeric instruction over the declared parameters, `fn:` a private bodied fn
// of the same module with the same signature, `wasi:` an adapter of
// `wat/host_binding.zig`'s list (docs.md § Host bindings). Each lowers to a
// function of the declared name and signature, so a call is an ordinary call.
test "wat: host binding ---- op:, fn: and wasi: bind a declare fn" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\#[@External.Wasm("op:f64.floor")]
        \\declare fn down(x: f64) -> f64;
        \\#[@External.Wasm("op:i32.add")]
        \\declare fn plus(a: i32, b: i32) -> i32;
        \\#[@External.Wasm("op:f64.lt")]
        \\declare fn below(a: f64, b: f64) -> bool;
        \\#[@External.Wasm("fn:greetBody")]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string) -> string {
        \\    return "hi " + name;
        \\}
        \\#[@External.Wasm("wasi:random_f64")]
        \\declare fn draw() -> f64;
        \\fn main() {
        \\    @print(down(2.75) == 2.0);
        \\    @print(plus(40, 2));
        \\    @print(below(1.0, 2.0));
        \\    @print(greet("wasm"));
        \\    val r = draw();
        \\    @print(r >= 0.0 && r < 1.0);
        \\}
    ,
        \\true
        \\42
        \\true
        \\hi wasm
        \\true
        \\
    );
}

// Anything outside the vocabulary is refused at the annotation — never read
// as text, never lowered to a guess.
test "wat: host binding ---- an unknown form, opcode, signature, fn or adapter is refused at the annotation" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("op:f64.flor")]
        \\declare fn down(x: f64) -> f64;
        \\fn main() { @print(down(1.5)); }
    , "`f64.flor` is not a wasm numeric instruction", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("op:f64.min")]
        \\declare fn least(x: f64) -> f64;
        \\fn main() { @print(least(1.5)); }
    , "`f64.min` is `(f64, f64) -> f64`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("op:f64.lt")]
        \\declare fn below(a: f64, b: f64) -> f64;
        \\fn main() { @print(below(1.0, 2.0)); }
    , "`f64.lt` is `(f64, f64) -> bool`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("fn:greetBdy")]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string) -> string { return name; }
        \\fn main() { @print(greet("x")); }
    , "this module declares no fn `greetBdy`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("fn:greetBody")]
        \\declare fn greet(name: string) -> string;
        \\pub fn greetBody(name: string) -> string { return name; }
        \\fn main() { @print(greet("x")); }
    , "`greetBody` is `pub`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("fn:greetBody")]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string, n: i32) -> string { return name; }
        \\fn main() { @print(greet("x")); }
    , "must take the same parameter types in the same order", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("wasi:clock_time_get")]
        \\declare fn now() -> f64;
        \\fn main() { @print(now()); }
    , "`clock_time_get` is not a WASI adapter", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[@External.Wasm("""(f64.floor $0)""")]
        \\declare fn down(x: f64) -> f64;
        \\fn main() { @print(down(1.5)); }
    , "is none of the three forms", 1, 3);
}

// `wat/host_binding.zig`'s `adapters` is the list `docs.md` § Host bindings
// documents; the test reads the table and fails in both directions — an
// adapter the backend binds that the reference does not list, and a row the
// backend does not bind.
test "wat: host binding ---- the adapter list agrees with docs.md" {
    const hb = @import("../wat/host_binding.zig");
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    const docs = try std.Io.Dir.cwd().readFileAlloc(io, "../../docs.md", alloc, .limited(1 << 22));
    defer alloc.free(docs);
    const head = "| Adapter | Signature | Answers |";
    const at = std.mem.indexOf(u8, docs, head) orelse return error.AdapterTableMissing;
    var rows: usize = 0;
    var lines = std.mem.splitScalar(u8, docs[at + head.len ..], '\n');
    _ = lines.next(); // the rest of the header line
    _ = lines.next(); // the separator
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "| `")) break;
        const end = std.mem.indexOfScalarPos(u8, line, 3, '`') orelse return error.AdapterRowUnreadable;
        const name = line[3..end];
        if (hb.findAdapter(name) == null) {
            std.debug.print("docs.md lists the adapter `{s}` and host_binding.zig binds none\n", .{name});
            return error.AdapterNotBound;
        }
        rows += 1;
    }
    for (hb.adapters) |a| {
        const needle = try std.fmt.allocPrint(alloc, "| `{s}` |", .{a.name});
        defer alloc.free(needle);
        if (std.mem.indexOf(u8, docs[at..], needle) == null) {
            std.debug.print("host_binding.zig binds `{s}` and docs.md does not list it\n", .{a.name});
            return error.AdapterNotDocumented;
        }
    }
    try std.testing.expectEqual(hb.adapters.len, rows);
}
