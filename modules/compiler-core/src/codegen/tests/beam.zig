//! codegen: the BEAM assembly backend's own rows (front 03-beam). Every
//! fixture here assembles and runs the emitted module (`assertBeamRunLog`) —
//! a beam row whose other backends answer differently, or are still open,
//! is pinned by its RUN LOG without moving another backend's snapshot.

const std = @import("std");
const h = @import("helpers.zig");

// ── step 1 — a pattern in binding position, and list patterns ───────────────

test "beam: a list pattern binds every element and its spread's tail" {
    // A `case` arm's list pattern walked the elements without binding any of
    // them (`[a] -> a` answered `{unresolved_identifier, a}`) and, with no
    // spread, accepted any longer list. Each element is now tested or bound
    // from a copy of the subject, and the length is exact unless a spread
    // follows (`emitSubPattern`'s `.list`).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn describe(xs: i32[]) -> string {
        \\    return case xs {
        \\        [] -> "empty";
        \\        [a] -> "one " + a.toString();
        \\        [a, b] -> "two " + (a + b).toString();
        \\        [first, _, ..rest] -> "many " + first.toString() + " +" + rest.length.toString();
        \\    };
        \\}
        \\fn main() {
        \\    @print(describe([]));
        \\    @print(describe([7]));
        \\    @print(describe([2, 5]));
        \\    @print(describe([1, 2, 3, 4]));
        \\    @print(describe([9, 8, 7]));
        \\}
    ,
        \\empty
        \\one 7
        \\two 7
        \\many 1 +2
        \\many 9 +1
        \\
    , &.{ "{test, is_nil, ", "{get_list, " });
}

test "beam: a number in a list pattern is a test of that element" {
    // `[1, b]` takes a two-element list whose head is 1 only; `[2, 5]`
    // reaches the next arm. (commonJS answers `105` for `sum([2, 5])` — it
    // does not test the literal, `04-js`'s row — so this is a beam fixture,
    // not a four-backend snapshot.)
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn sum(xs: i32[]) -> i32 {
        \\    return case xs {
        \\        [] -> 0;
        \\        [a] -> a;
        \\        [1, b] -> 100 + b;
        \\        [a, b] -> a + b;
        \\        [a, _, ..rest] -> a + sum(rest);
        \\    };
        \\}
        \\fn main() {
        \\    @print(sum([]));
        \\    @print(sum([7]));
        \\    @print(sum([1, 5]));
        \\    @print(sum([2, 5]));
        \\    @print(sum([1, 2, 3, 4, 5]));
        \\}
    ,
        \\0
        \\7
        \\105
        \\7
        \\9
        \\
    , &.{"{test, is_eq, {f, "});
}

// ── a lambda a `case` arm answers ────────────────────────────────────────────

test "beam: a lambda literal that ends a case arm is the arm's value" {
    // `_ { { x -> x * n } }` — the arm block's tail is a lambda, so it is the
    // value the `case` answers (decision 525). It ran as a statement, the arm
    // answered `ok`, and applying it was `{badfun, ok}`
    // (`modules/case_arm_lambda_value`).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn scaleBy(n: i32) -> fn(x: i32) -> i32 {
        \\    val f = case n {
        \\        _ {
        \\            { x -> x * n }
        \\        }
        \\    };
        \\    return f;
        \\}
        \\fn main() {
        \\    @print(scaleBy(3)(10));
        \\}
    , "30\n", &.{"{make_fun3, "});
}

// ── a behavior's adopted `default fn` ────────────────────────────────────────

test "beam: a type adopts its behavior's default fns as methods of its module" {
    // `Sq(s: 3).twice()` — `twice` is a `default fn` of `Shape`, which `Sq`
    // implements without declaring it. The type's module had no such
    // function and the call aborted `{unresolved_method, twice, 1}`; the
    // default is now emitted into `Sq`'s module beside `area`
    // (`adoptedDefaults`), one default calling another, a type's own method
    // winning over the default, and a behavior-typed receiver dispatching on
    // the value. Two types adopt `twice`, so a call names the method and the
    // value's module answers it (`lowerDynamicMethodCall`). (erlang refuses this module — `function twice/1 undefined`
    // — `02-erlang`'s row; commonJS prints the same lines.)
    try h.assertBeamRunLog(std.testing.allocator,
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
        \\type Rect(w: i32, h: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.w * self.h;
        \\    }
        \\    fn label(self: Self) -> string {
        \\        return "rect";
        \\    }
        \\}
        \\fn show(x: Shape) -> i32 {
        \\    return x.twice();
        \\}
        \\fn main() {
        \\    @print(Sq(s: 3).twice());
        \\    @print(Sq(s: 3).label());
        \\    @print(Rect(w: 2, h: 5).twice());
        \\    @print(Rect(w: 2, h: 5).label());
        \\    @print(show(Sq(s: 1)));
        \\    @print(show(Rect(w: 1, h: 7)));
        \\}
    ,
        \\18
        \\area 18
        \\20
        \\rect
        \\2
        \\14
        \\
    , &.{"{move, {atom, twice}, {x, 1}}"});
}

// ── `?.` through a tuple label ───────────────────────────────────────────────

test "beam: ?. on an absent tuple element answers absent before the label is read" {
    // Decision 45 rewrites `?.b` to the element's position (`._1`), and the
    // tuple-index read came before the `?.` test: `es.at(0)?.b` read
    // `element(2, undefined)` and raised `badarg`. A beam fixture: commonJS
    // and erlang print the same four lines; wasm answers `8` for both absent
    // `?.a ?? …` reads (`05-wasm`'s row).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn rows() -> #(a: i32, b: string)[] {
        \\    return [#(1, "x"), #(2, "y")];
        \\}
        \\fn main() {
        \\    val es: #(a: i32, b: string)[] = [];
        \\    @print(es.at(0)?.b ?? "none");
        \\    @print(es.at(3)?.a ?? 0);
        \\    val rs = rows();
        \\    @print(rs.at(1)?.b ?? "none");
        \\    @print(rs.at(5)?.a ?? -1);
        \\}
    ,
        \\none
        \\0
        \\y
        \\-1
        \\
    , &.{"{extfunc, erlang, element, 2}"});
}

// ── `-x` on a float ──────────────────────────────────────────────────────────

test "beam: -x is the unary minus, so -0.0 is negative zero" {
    // `-z` lowered to `0 - z`, which is `+0.0` for `z = 0.0` where `z * -1.0`
    // (and the erlang backend's `-Z`) is `-0.0`. It is the `'-'/1` BIF now,
    // as `erlc` writes `-X`. (commonJS prints `-0` and `0.0` for the first
    // two lines — `04-js`'s row — so this is a beam fixture.)
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn neg(x: f64) -> f64 {
        \\    return -x;
        \\}
        \\fn negi(x: i32) -> i32 {
        \\    return -x;
        \\}
        \\fn main() {
        \\    val z = 0.0;
        \\    @print(-z);
        \\    @print(z * -1.0);
        \\    @print(neg(0.0));
        \\    @print(neg(2.5));
        \\    @print(negi(3) + 1);
        \\    @print(-(z + 0.0));
        \\}
    ,
        \\-0.0
        \\-0.0
        \\-0.0
        \\-2.5
        \\-2
        \\-0.0
        \\
    , &.{"{gc_bif, '-', {f, 0}, "});
}

// ── a bare `break` ends a `for` ──────────────────────────────────────────────

test "beam: a bare break in a for's body ends the loop" {
    // A loop's body is a fun (`lists:foldl` when it reassigns the frame's
    // names, `lists:foreach` otherwise), and `break` returned from it: the
    // next element ran, so `visited` reached 3 and the search answered the
    // last match (`conformance/test/loop_collection.bp`). The fun now
    // throws `{'__bp_break', V}` and the call site answers `V`
    // (`guardLoopBreak`).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn main() {
        \\    var doubled = 0;
        \\    var visited = 0;
        \\    for ([1, 2, 3]) { x ->
        \\        visited = visited + 1;
        \\        doubled = x * 2;
        \\        break;
        \\    }
        \\    @print(visited);
        \\    @print(doubled);
        \\    var found = 0;
        \\    for ([4, 5, 6, 7]) { y ->
        \\        if (y > 5) {
        \\            found = y;
        \\            break;
        \\        }
        \\    }
        \\    @print(found);
        \\    for ([8, 9]) { z ->
        \\        @print(z);
        \\        break;
        \\    }
        \\}
    ,
        \\1
        \\2
        \\6
        \\8
        \\
    , &.{"{atom, '__bp_break'}"});
}

// ── the keyword form of an `@External.Erlang` template ──────────────────────

test "beam: the keyword form's method is a template compiled at build time" {
    // `#[@External.Erlang(module: "erlang", method: "max($args)")]` carries
    // a template, which erlang renders as written (`max(1, 2)`); beam refused
    // every call — "has no `#[@External.<Target>(…)]` for the beam backend"
    // (`conformance/test/external_markers.bp`). It is compiled like any
    // template now (`evalTemplate`), and so is the `pub` wrapper.
    try h.assertBeamRunLog(std.testing.allocator,
        \\#[@External.Erlang(module: "erlang", method: "max($args)")]
        \\declare fn biggest(a: i32, b: i32) -> i32;
        \\#[@External.Erlang(module: "erlang", method: "min($0, $1)")]
        \\pub declare fn smallest(a: i32, b: i32) -> i32;
        \\fn main() {
        \\    @print(biggest(1, 2));
        \\    @print(smallest(9, 4));
        \\}
    , "2\n4\n", &.{"{function, smallest, 2, "});
}

test "beam: a refused template's reason outlives the emitter that refused it" {
    // Decision 141's refusal names the construct (`macros (`?NAME`)`). The
    // reason lived in the emitter's `atom_arena`, which `em.deinit` freed
    // before the caller rendered the diagnostic: the message read freed memory
    // — the right text on glibc, garbage on macos-14
    // (`conformance/modules/external_template_refused_on_beam`). Under
    // `std.testing.allocator` freed memory is poisoned, so this reads it.
    try h.assertBeamRefusedAt(std.testing.allocator,
        \\#[@External.Erlang("""length(atom_to_list(?MODULE)) > 0""")]
        \\declare fn moduleNamed() -> bool;
        \\fn main() {
        \\    @print(moduleNamed());
        \\}
    , "`moduleNamed`'s `#[@External.Erlang(…)]` template does not compile for the beam backend: macros (`?NAME`)", 4, 12);
}

// ── step 2 — C-07's beam tails: decision 8 §2, §4, §5, §6 on beam ───────────
//
// The beam twins of the erlang fixtures `02-erlang` added for the tuple, `..`
// and type-pattern shapes, each RUN LOG the value the assembled module prints
// (the same lines `assertErlangRunLog` pins for erlang).

test "beam: unknown ---- `is`, type arms and `==` answer by value" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn show(x: unknown) {
        \\  case x { i32 { n -> @print(n) } f64 { f -> @print(f) } _ { @print("other") } };
        \\}
        \\fn main() {
        \\  val a: unknown = 2.0;
        \\  val c: unknown = 2.5;
        \\  @print(a == 2, a != 2, c == 2);
        \\  val i: i32 = 2;
        \\  val j: i32 = 2;
        \\  @print(i == j);
        \\  if (a is i32) { @print(a + 1); };
        \\  @print(a is i32, a is f64, c is i32, c is f64);
        \\  show(a);
        \\  show(c);
        \\  show("s");
        \\}
    , "true false false\ntrue\n3\ntrue true false true\n2\n2.5\nother\n", &.{});
}

test "beam: case ---- `A...B` inside a tuple pattern, and with a binder" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn grade(n: i32) -> string {
        \\  return case n { 1...9 { d -> "digit " + d.toString() } 10...99 { "two" } _ { "other" } };
        \\}
        \\fn main() {
        \\  @print(grade(0), grade(1), grade(9), grade(10), grade(99), grade(100));
        \\  val t = #(5, "x");
        \\  case t { #(1...3, _) { @print("low") } #(4...6, s) { @print("mid " + s) } _ { @print("hi") } };
        \\}
    , "other digit 1 digit 9 two two other\nmid x\n", &.{});
}

test "beam: case ---- true and false inside a tuple pattern are matched, not bound" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn tag(t: #(bool, i32)) -> string {
        \\    return case t {
        \\        #(true, n) { "yes " + n.toString() }
        \\        #(false, n) { "no " + n.toString() }
        \\    };
        \\}
        \\fn first(t: #(bool, i32, i32)) -> i32 {
        \\    return case t {
        \\        #(false, ..) { 0 }
        \\        #(true, n, ..) { n }
        \\    };
        \\}
        \\fn main() {
        \\    @print(tag(#(false, 1)));
        \\    @print(tag(#(true, 2)));
        \\    @print(first(#(false, 7, 8)));
        \\    @print(first(#(true, 7, 8)));
        \\}
    , "no 1\nyes 2\n0\n7\n", &.{});
}

test "beam: case ---- a record's constructor pattern tests the record's own tag" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\type Point(x: i32, y: i32)
        \\fn f(p: Point) -> i32 {
        \\    return case p {
        \\        Point(x: 0, y: y) { y }
        \\        Point(x: x, y: _) { x }
        \\    };
        \\}
        \\fn onAxis(p: Point) -> string {
        \\    return case p {
        \\        Point(x: 0, ..) { "on y" }
        \\        Point(y: 0, ..) { "on x" }
        \\        _ { "off" }
        \\    };
        \\}
        \\fn main() {
        \\    @print(f(Point(x: 0, y: 5)));
        \\    @print(f(Point(x: 3, y: 0)));
        \\    @print(onAxis(Point(x: 0, y: 5)));
        \\    @print(onAxis(Point(x: 3, y: 0)));
        \\    @print(onAxis(Point(x: 3, y: 4)));
        \\}
    , "5\n3\non y\non x\noff\n", &.{});
}

test "beam: case ---- a tuple under `..` bounds the arity from below" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn main() {
        \\  val t = #(4, 5, 6);
        \\  case t { #(a, ..) { @print(a) } };
        \\}
    , "4\n", &.{"{bif, element, "});
}

test "beam: is ---- §4.1 × §4.2, one mark per value (a tuple type tests each element)" {
    // `02-erlang`'s `test/is_truth_table` as a program. `v is #(i32, string)`
    // tested the arity alone, so it held for a record and a variant of two
    // slots too (`.......TT.`); each element is now tested.
    try h.assertBeamRunLog(std.testing.allocator,
        \\type Point(x: i32, y: i32)
        \\type Box<T>(item: T)
        \\type Shape { Dot, Circle(r: i32) }
        \\fn values() -> unknown[] {
        \\    val int: unknown = 1;
        \\    val integral: unknown = 2.0;
        \\    val fraction: unknown = 2.5;
        \\    val wide: unknown = 300;
        \\    val text: unknown = "s";
        \\    val flag: unknown = true;
        \\    val point: unknown = Point(x: 1, y: 2);
        \\    val shape: unknown = Shape.Circle(r: 3);
        \\    val pair: unknown = #(1, "a");
        \\    val box: unknown = Box(item: 1);
        \\    return [int, integral, fraction, wide, text, flag, point, shape, pair, box];
        \\}
        \\fn marks(holds: bool[]) -> string {
        \\    var text = "";
        \\    for (holds) { h ->
        \\        val mark = if (h) "T" else ".";
        \\        text = text + mark;
        \\    }
        \\    return text;
        \\}
        \\fn main() {
        \\    @print(marks(values().map({ v -> v is i32 })));
        \\    @print(marks(values().map({ v -> v is i8 })));
        \\    @print(marks(values().map({ v -> v is f64 })));
        \\    @print(marks(values().map({ v -> v is string })));
        \\    @print(marks(values().map({ v -> v is bool })));
        \\    @print(marks(values().map({ v -> v is Point })));
        \\    @print(marks(values().map({ v -> v is Shape })));
        \\    @print(marks(values().map({ v -> v is Box<unknown> })));
        \\    @print(marks(values().map({ v -> v is #(i32, string) })));
        \\}
    ,
        \\TT.T......
        \\TT........
        \\TTTT......
        \\....T.....
        \\.....T....
        \\......T...
        \\.......T..
        \\.........T
        \\........T.
        \\
    , &.{});
}

// ── the entry point's standard_io ────────────────────────────────────────────

test "beam: an entry point sets standard_io to unicode before anything prints" {
    // The beam twin of erlang's fixture of the same name (02-erlang step 5's
    // "under `LANG=C` beam still writes latin1"): `erl` opens `standard_io` in
    // the host locale's encoding, so `@print("é")` wrote the latin1 byte `0xE9`
    // and `"\u{1F600}"` the text `\x{1F600}`. `'_botopink_main'/0` now calls
    // `io:setopts/2` first, in a frame of its own (`run/
    // string_literal_unicode_escape` run with `LANG=C` is the measurement; this
    // harness has the host's locale).
    try h.assertBeamRunLog(std.testing.allocator,
        \\pub fn main() {
        \\    @print("é", "\u{1F600}");
        \\}
    , "é 😀\n", &.{
        \\    {allocate, 0, 0}.
        \\    {move, {atom, standard_io}, {x, 0}}.
        \\    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
        \\    {call_ext, 2, {extfunc, io, setopts, 2}}.
        \\    {call_last, 0, {f,
    });
}

// ── a `??` before a loop closure ─────────────────────────────────────────────

test "beam: a loop closure does not capture the register of an earlier `??`" {
    // `var out = xs.at(0) ?? ""` desugars to `if (…) { v -> v }`; its binding
    // `v` lives in a y-register only the present arm assigns. The `for` body
    // is a closure, and its own `??` mentions the same `v`: the free-name walk
    // took it for the outer binding and `make_fun3` read an unassigned `{y, N}`
    // (the OTP compiler refused styled's `spliced`, 144 B-34).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn joined(texts: string[], parts: string[]) -> string {
        \\    var out = texts.at(0) ?? "";
        \\    var k = 0;
        \\    for (parts) { s ->
        \\        out = out + s + texts.at(k + 1) ?? "";
        \\        k = k + 1;
        \\    }
        \\    return out;
        \\}
        \\fn main() {
        \\    @print(joined(["<", "|", "|", ">"], ["a", "b", "c"]));
        \\}
    , "<a|b|c>\n", &.{"{make_fun3, "});
}

test "beam: a member call through a library's default handle is a call into the library" {
    // `qlib.make(5)` after `import {qlib} from "qlib"`: the handle is a comptime
    // fn with no run-time binding, so the receiver used to lower as an unbound
    // name and the call aborted with `{unresolved_method, make, 1}`. It is the
    // remote call into the module that declares `make` (144 B-50;
    // `conformance/modules/default_handle_member` runs it).
    try h.assertConsumerBeam(std.testing.allocator, &.{
        .{ .path = "qlib/qlib", .source =
        \\pub fn make(x: i32) -> i32 {
        \\    return x + 1;
        \\}
        \\
        \\pub fn qlib(comptime e: @Expr<string>) -> @Expr<i32> {
        \\    return e.build("99");
        \\}
        },
        .{ .path = "", .source =
        \\import {qlib} from "qlib";
        \\
        \\fn main() {
        \\    @print(qlib.make(5));
        \\}
        },
    }, &.{"{extfunc, test@qlib@qlib, make, 1}"}, &.{"unresolved_method"});
}

test "beam: a library's field read is its closure's alone, whatever its consumer declares" {
    // Decision 509 (2), 144 B-65 — `erlang.zig`'s row on beam: the read of
    // `q.size` in `shelf` is a `get_tuple_element` under both consumers.
    try h.assertLibrarySameUnder(std.testing.allocator, .beam, &.{ "shelf", "rival" }, "shelf", &h.closure_plain, &h.closure_crowded);
}

// Decision 346 — `Bytes` on this backend: in and out of text, length, slice,
// concat, `==`, and the `Error` of bytes that are not UTF-8.
const bytes_src =
    \\pub fn main() {
    \\    val b = Bytes.fromUtf8("héllo");
    \\    @print(b.length());
    \\    @print(b.slice(1, 3).toUtf8().unwrapOr("?"));
    \\    @print(b.slice(1, 2).toUtf8().isError());
    \\    val j = Bytes.fromUtf8("ab").concat(Bytes.fromUtf8("cd"));
    \\    @print(j[2..].toUtf8().unwrapOr("?"));
    \\    @print(j == Bytes.fromUtf8("abcd"));
    \\}
;
const bytes_log = "6\né\ntrue\ncd\ntrue\n";

test "beam: decision 346 ---- Bytes is a binary, its methods std's templates" {
    try h.assertBeamRunLog(std.testing.allocator, bytes_src, bytes_log, &.{});
}
