//! commonJS-only fixtures (front `01-compiler/04-js`): behaviour this backend
//! answers alone, run under node with `assertJsRunLog` so no other backend's
//! snapshot directory moves.

const std = @import("std");
const h = @import("helpers.zig");

// A `default fn` of a primitive behavior (`behavior String`, std's
// `primitives.bp` or a program's own) becomes a prototype patch
// (`String.prototype.m = function () { … }`), and its body is lowered with no
// per-call answer from inference: the checker does not type it. The receiver
// is still known — it is the behavior's own primitive — so a call on `self`
// lowers as the same call on a typed `string` would. `self.length()` was
// written as it stands: `TypeError: self.length is not a function`, because
// JavaScript's `length` is a property.
test "js: primitive behavior default fn ---- a call on self lowers as on the declared receiver" {
    try h.assertJsRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn twiceLength(self: Self) -> i32 {
        \\        return self.length() * 2;
        \\    }
        \\
        \\    default fn firstChar(self: Self) -> ?string {
        \\        return self.at(0);
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    @print("abc".twiceLength());
        \\    @print("".twiceLength());
        \\    @print("xy".firstChar());
        \\    @print("".firstChar());
        \\}
    ,
        \\6
        \\0
        \\x
        \\null
        \\
    );
}

// The same body answering a `@Result`: its `return` and `throw` build the
// `{ ok }` / `{ error }` object every `@Result` is on this backend. The body
// is checked against its signature (`01-checker`), so it builds the value with
// `return` / `throw` — `Ok(v)` / `Error(e)` are never constructors in an
// expression (decision 208).
test "js: primitive behavior default fn ---- return and throw build the @Result" {
    try h.assertJsRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn nonEmpty(self: Self) -> @Result<string, string> {
        \\        if (self == "") throw "empty";
        \\        return self;
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    @print("ab".nonEmpty().isOk());
        \\    @print("".nonEmpty().isError());
        \\    @print(case "ab".nonEmpty() {
        \\        Ok(v) -> v;
        \\        Error(e) -> e;
        \\    });
        \\    @print(case "".nonEmpty() {
        \\        Ok(v) -> v;
        \\        Error(e) -> e;
        \\    });
        \\}
    ,
        \\true
        \\true
        \\ab
        \\empty
        \\
    );
}

// Decision 214 — the NaN half of `f64`'s total-order `==`, which the
// four-target cell `modules/f64_equality_total_order` cannot carry (erlang and
// beam never produce a NaN): `NaN == NaN` is `true` bare and inside a record,
// a tuple, an array and a variant (`Object.is`, and the per-type equality's
// field compare), `NaN != NaN` is `false`, and NaN against a number is
// unequal. `<` stays IEEE (`NaN < 1.0` is `false`).
test "js: f64 ---- NaN equals NaN under ==, bare and inside composites" {
    try h.assertJsRunLog(std.testing.allocator,
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

test "js: a library's enum class is its closure's alone, whatever its consumer declares" {
    // Decision 509 (2), 144 B-66: `shelf`'s `Square(side)` reads `side` by
    // name — `shelf`'s closure declares one `Square`. `rival`'s
    // `Square(side, color)` is not in it; the variant table used to be the
    // whole program's, so under `crowded` alone the class gained `get $0()`
    // and the `case` destructured `{ $0: side }`.
    try h.assertLibrarySameUnder(std.testing.allocator, .commonJS, &.{ "shelf", "rival" }, "shelf", &h.closure_plain, &h.closure_crowded);
}

// 144 B-78: JavaScript has one number type, so a float written as text lost its
// decimal part (`"${5.0}"` was `5`, `1e21` was `1e+21`). A template hole, a
// `string + f64` and `toString()` on a float now go through `__bp_f64`, the
// formatter `@print` shares: erlang, beam and wasm's text.
test "js: f64 text ---- a template hole, toString and a string + keep the decimal part" {
    try h.assertJsRunLog(std.testing.allocator,
        \\pub fn main() {
        \\    val five = 5.0;
        \\    @print("${5.0}");
        \\    @print(5.0.toString());
        \\    @print("x" + 2.0);
        \\    @print("${1.0e21}");
        \\    @print("${-3.0}");
        \\    @print("${0.25}");
        \\    @print("v=${five}");
        \\    @print(five.toString());
        \\    @print(1.0e-7);
        \\    @print(7);
        \\    @print("${7}");
        \\}
    ,
        \\5.0
        \\5.0
        \\x2.0
        \\1.0e21
        \\-3.0
        \\0.25
        \\v=5.0
        \\5.0
        \\1.0e-7
        \\7
        \\7
        \\
    );
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

test "js: decision 346 ---- Bytes is a Uint8Array, its methods patched on its prototype" {
    try h.assertJsRunLog(std.testing.allocator, bytes_src, bytes_log);
}
