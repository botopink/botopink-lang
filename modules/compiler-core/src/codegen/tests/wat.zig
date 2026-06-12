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
        \\record Point { x: i32, y: i32 }
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
        \\enum Shape {
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
        \\fn make() -> i32 {
        \\    val r = record { a: 7, b: 11 };
        \\    return r;
        \\}
    );
}

test "wat: anon record literal nested" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn make() -> i32 {
        \\    val outer = record { span: record { start: 1, end: 2 }, kind: 3 };
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
        \\record Point { x: i32, y: i32 }
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
        \\record Span { start: i32, end: i32, line: i32 }
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
        \\record R { a: i32, b: i32 }
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
        \\record R { a: i32, b: i32 }
        \\fn pick(maybe: ?R) -> i32 {
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
        \\    val r = record { code: 7, kind: 11 };
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
        \\    val outer = record { span: record { start: 5, end: 9 }, kind: 3 };
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
        \\record R { kind: i32 }
        \\fn pick(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() {
        \\    @print(pick(false)?.kind);
        \\}
    );
}

// F2.3 — Optional fn return — value path with `?.`.
test "wat: optional fn return present path with optional chaining" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record R { kind: i32 }
        \\fn pick(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() {
        \\    @print(pick(true)?.kind);
        \\}
    );
}

// F2.4 — Branch on `x == null`, deref through `?.` on the present arm.
test "wat: optional branch on equality and chained deref" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record R { kind: i32 }
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

// F3.2 — equality of two literals (true case).
test "wat: string equality literals true" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val same = "foo" == "foo";
        \\    if (same) {
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

// F3.5 — `if (s == lit)` branch lights up the equality path inside an if.
test "wat: string equality drives if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "yes";
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
        \\record P { x: i32, y: i32 }
        \\fn main() {
        \\    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
        \\    @print(pts.len);
        \\}
    );
}

// F5 — Structured throw/catch surface. WAT models `@Result`-style
// try/catch over a `[tag, payload]` linear-memory pair (tag 0 = Ok,
// non-zero = Error). `@panic`/`@todo`/`throw` collapse to `unreachable`
// — wasm3 doesn't implement the exceptions proposal, and the F0-audited
// templates use the failRaw pattern through `wat_runtime.zig` (F6),
// not host exceptions. The 3 fixtures below pin the `@Result`-based
// shape that templates actually consume; the unwind-via-runtime path
// lands in F6's prelude.

// F5.1 — try a `#[@result]` fn, catch the error and yield a default.
test "wat: try catch on result with default fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
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
        \\#[@result]
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
        \\#[@result]
        \\fn inner(should_fail: bool) -> @Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "inner-fail";
        \\    } else {
        \\        return 7;
        \\    }
        \\}
        \\#[@result]
        \\fn outer(should_fail: bool) -> @Result<i32, string> {
        \\    val v = try inner(should_fail);
        \\    return v + 1;
        \\}
        \\fn main() {
        \\    val r = try outer(false) catch -1;
        \\    @print(r);
        \\}
    );
}
