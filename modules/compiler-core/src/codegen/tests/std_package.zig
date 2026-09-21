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
//! into `primitives.bp` behaviors (`Array<T>`, `String`, `Bool`, numeric
//! tower, `Pair`, `Function`) and the builtin `Iterator<T>`. The method-dispatch
//! API is exercised by the co-located `libs/std` test suites; re-add codegen
//! fixtures once primitive/default-fn method lowering lands (tasks/v0.beta.4
//! carryover, Part A).

const std = @import("std");
const h = @import("helpers.zig");

test "js: builtin result namespace ---- qualified call lowers inline" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
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

// A `pub` template external reached through its module object: std's
// `env.write`/`env.read`/`env.clear` are `#[@External.Node("…$0…")]` templates,
// so the owning module has to export a real function for each (it used to
// export nothing: "env.write is not a function"). The behaviour lives in
// `std/env.js`, which the entry's snapshot does not show — so the RUN LOG is
// asserted directly.
test "js: std package ---- env template externals resolve through the module object" {
    try h.assertJsRunLog(std.testing.allocator,
        \\import {env} from "std";
        \\
        \\fn main() {
        \\    env.write("BOTOPINK_F8_ENV", "hi");
        \\    @print(env.read("BOTOPINK_F8_ENV"));
        \\    env.clear("BOTOPINK_F8_ENV");
        \\    @print(env.read("BOTOPINK_F8_ENV"));
        \\}
    , "hi\nnull\n");
}

// 13 half 1 — the sharper half of the same collision: eleven `libs/std` modules
// are named after an OTP module (`base64`, `crypto`, `dict`, `erlang`, `json`,
// `math`, `os`, `queue`, `random`, `sets`, `unicode`). Emitting `-module(math)`
// put that file ahead of `stdlib`'s `math` on the code path, which makes every
// other function of the OTP module `undef` — node-wide, silently. The std module
// is `std@math` now, so the two coexist: this program calls `std@math:ceil/1`
// and the OTP `math:sqrt/1` in the same function, and RUNNING it is the only
// assertion that can see the shadow (a snapshot of unloadable code looks fine).
//
// Erlang-only on purpose: `libs/std`'s `math` does not compile for wasm at all
// (`math.abs` has no `@external` for that target), so a four-backend cell would
// pin that unrelated gap instead of this one.
test "erlang: std package ---- a std math import and the OTP math module in one program" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {math} from "std";
        \\
        \\#[@External.Erlang("math", "sqrt"),
        \\  @External.Beam("math", "sqrt"),
        \\  @External.Node("Math", "sqrt")]
        \\declare fn otpSqrt(x: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(math.ceil(1.2));
        \\    @print(otpSqrt(16.0));
        \\}
    , "2.0\n4.0\n", &.{
        // the std module reached by its atom, and OTP's own `math` beside it
        "std@math:ceil(1.2)",
        "math:sqrt(16.0)",
    });
}

// Decision 64 — a qualified std host call. `import { erlang } from "std"` names
// the MODULE, never the symbol, so the owner-side wrapper predicate that asked
// the bare-name import route (`cross.imported`) never fired: `std@erlang.erl`
// defined nothing and `'std@erlang':node()` was `{undef, …}` at run time — the
// program resolved, type-checked and emitted a correct call. Every `pub`
// host-backed `declare fn` now gets its wrapper and export whether or not the
// build reaches it. RUNNING is the assertion: the snapshot of an attribute-only
// module looks fine. `node/0` is chosen because `erlang.bp` types every
// parameter `any`, a closed type no botopink value unifies with (`erlang.abs(-3)`
// is `expected any, got i32`), and because `nonode@nohost` is deterministic
// where `self()` is not; it is also an auto-imported BIF, so the wrapper is the
// shadow case `erlang.bp` exists to detect.
test "erlang: std package ---- a qualified std host call reaches its owner's wrapper" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {erlang} from "std";
        \\
        \\fn main() {
        \\    @print(erlang.node());
        \\}
    , "nonode@nohost\n", &.{
        "std@erlang:node()",
    });
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

// A method on a type the consumer never names. `import {dict} from "std"` binds
// the MODULE `std/dict`, not a `pub` symbol, so the cross-module index was never
// consulted for `Dict` and erlang emitted a bare local `insert(D, K, V)` —
// `out/main.erl: function insert/3 undefined`, i.e. the program did not compile
// while the same source ran on commonJS. The owner exports `insert/3` and
// `at/2`; the consumer must remote-call them (`dict:insert/3`). The program
// means `1`, then `2` (two distinct keys), which commonJS and erlang both print.
//
// beam calls them remotely too, since `methodOwnerModule` in `beam_asm.zig`
// reads the same link index: `{call_ext, 3, {extfunc, dict, 'Dict_insert', 3}}`.
// It used to read `insert` out of the receiver map and `call_fun` the
// `undefined` it found (`{badfun, #{…}}`), so the module never ran and its RUN
// LOG was empty.
// wasm stays single-module, so `wat.zig` inlines the std module's functions into
// the entry (`$Dict_insert`, `$Dict_at`) and the cross-module index never
// applies — which is why this test says nothing about wasm's resolution. It
// **answered `0` instead of `1`** until front 05 step 3: not the `forEach`
// accumulator, which works, but the *reader* of the `?V` the accumulator
// returns. `Dict.at` is declared `-> ?V`; a type parameter is not a known
// scalar, so the payload is the value itself, while `unwrapOr` assumed a box and
// loaded through the payload as an address. A method's declared return type was
// never registered under the symbol its call emits, so the reader had nothing to
// ask. Both prints are now the value the program means.
test "js: std package ---- methods of a type answered by an imported module resolve in its owner" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {dict} from "std";
        \\
        \\fn main() {
        \\    val d = dict.empty().insert("a", 1);
        \\    @print(d.at("a").unwrapOr(0));
        \\    @print(d.insert("b", 2).size());
        \\}
    );
}
