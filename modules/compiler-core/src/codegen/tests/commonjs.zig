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
