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

// The same unchecked body building its `@Result` by name: `Ok(v)` /
// `Error(e)` named nothing on node (`ReferenceError: Ok is not defined`) where
// erlang and beam build the tagged value. It is the `{ ok }` / `{ error }`
// object every `@Result` is on this backend.
test "js: primitive behavior default fn ---- Ok(v) and Error(e) build the @Result" {
    try h.assertJsRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn nonEmpty(self: Self) -> @Result<string, string> {
        \\        if (self == "") return Error("empty");
        \\        return Ok(self);
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
// four-target cell `run/f64_equality_total_order.bp` cannot carry (erlang and
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
