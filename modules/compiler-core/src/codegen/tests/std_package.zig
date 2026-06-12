//! codegen: `"std"` package qualified calls and the builtin `result` namespace.
//! `import {order} from "std"` pulls the embedded std module into the
//! compilation (own output file); `order.reverse(x)` lowers to a remote call
//! (erlang `order:reverse(...)`) / module-object member call (commonJS).
//! `result.map(r, f)` needs NO import — it is a builtin namespace lowered
//! inline to the same `__bp_result_*` ops the method form uses.
//!
//! NOTE: the loose-function std fixtures (`bool`/`list`/`string`/`int`/`float`/
//! `iterator` qualified, `pair` as a module, `array` method-dispatch sugar) were
//! retired with the stdlib-interface migration — those modules were dissolved
//! into `primitives.d.bp` interfaces (`Array<T>`, `String`, `Bool`, numeric
//! tower, `Pair`, `Function`) and the builtin `Iterator<T>`. The method-dispatch
//! API is exercised by the co-located `libs/std` test suites; re-add codegen
//! fixtures once primitive/default-fn method lowering lands (tasks/v0.beta.4
//! carryover, Part A).

const std = @import("std");
const h = @import("helpers.zig");

test "js: builtin result namespace ---- qualified call lowers inline" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parse(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val r = result.map(parse(21), { x -> x * 2 });
        \\    @print(result.unwrap(r, 0));
        \\}
    );
}

test "js: std package ---- order enum module with type export" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {order} from "std";
        \\
        \\fn describe(o: Order) -> string {
        \\    val s = case o {
        \\        Lt -> "less";
        \\        Gt -> "greater";
        \\        _ -> "equal";
        \\    };
        \\    return s;
        \\}
        \\
        \\fn main() {
        \\    @print(order.toInt(order.lt()));
        \\    @print(describe(order.reverse(order.lt())));
        \\}
    );
}
