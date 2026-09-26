//! codegen: `"std"` package qualified calls and the builtin `result` namespace.
//! `import {collections} from "std"` pulls the embedded std module into the
//! compilation (own output file); `order.reverse(x)` lowers to a remote call
//! (erlang `order:reverse(...)`) / module-object member call (commonJS).
//! `result.map(r, f)` needs NO import — it is a builtin namespace lowered
//! inline to the same `__bp_result_*` ops the method form uses.
//!
//! NOTE: the loose-function std fixtures (`bool`/`list`/`string`/`int`/`float`/
//! `iterator` qualified, `pair` as a module, `array` method-dispatch sugar) were
//! retired with the stdlib-interface migration — those modules were dissolved
//! into `primitives.bp` behaviors (`Array<T>`, `String`, `Bool`, numeric
//! tower, `Pair`, `Function`) and the builtin `ResultGenerator<T, E>`. The method-dispatch
//! API is exercised by the co-located `libs/std` test suites; re-add codegen
//! fixtures once primitive/default-fn method lowering lands (tasks/v0.beta.4
//! carryover, Part A).

const std = @import("std");
const h = @import("helpers.zig");

test "js: builtin result namespace ---- qualified call lowers inline" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

// Decision 107 over the std package: `collections.Dict` registers the type
// (its constructor is type-scoped, `Dict.empty()` — decision 111),
// `collections: {gt, reverse, toInt as rank}` binds three leaves of one
// module, the last under its alias — and `collections` is not bound.
// commonJS destructures each leaf from `std/<module>.js` (`{ toInt: rank }`);
// erlang and beam reach the owner remotely through the item's own path,
// which is what tells `url.parse` from `json.parse`; wasm links the std
// module statically and maps the alias back to the declared name at the
// `call`. A pure-bp module on purpose (`collections`): a host-backed leaf
// would pin the wasm gap of that module instead of this rule.
test "js: std package ---- a dotted path and a group bind leaves of std modules" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {collections.Dict, collections: {gt, reverse, toInt as rank}} from "std";
        \\
        \\fn main() {
        \\    val d: Dict<string, i32> = Dict.empty();
        \\    @print(d.insert("a", 1).size());
        \\    @print(rank(reverse(gt())));
        \\}
    );
}

// A `pub` template external reached through its module object: std's
// `env.write`/`env.read`/`env.clear` are `#[@External.Node("…$0…")]` templates,
// so the owning module has to export a real function for each (it used to
// export nothing: "env.write is not a function"). The behaviour lives in
// `std/io/env.js`, which the entry's snapshot does not show — so the RUN LOG is
// asserted directly.
test "js: std package ---- env template externals resolve through the module object" {
    try h.assertJsRunLog(std.testing.allocator,
        \\import {io.env} from "std";
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
        \\import {collections} from "std";
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
        \\    @print(collections.toInt(collections.lt()));
        \\    @print(describe(collections.reverse(collections.lt())));
        \\}
    );
}

// A method on a type answered by an imported module. Under the flat tree the
// consumer never named the type (`import {dict} from "std"; dict.empty()`):
// the import bound the MODULE `std/dict`, not a `pub` symbol, so the
// cross-module index was never consulted for `Dict` and erlang emitted a bare local `insert(D, K, V)` —
// `out/main.erl: function insert/3 undefined`, i.e. the program did not compile
// while the same source ran on commonJS. The owner exports `insert/3` and
// `at/2`; the consumer must remote-call them (`std@collections@@Dict:insert/3`). The program
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
        \\import {collections.Dict} from "std";
        \\
        \\fn main() {
        \\    val d = Dict.empty().insert("a", 1);
        \\    @print(d.at("a").unwrapOr(0));
        \\    @print(d.insert("b", 2).size());
        \\}
    );
}

// ── `from "std"` on the erlang row: the shim, the loader and the dead module ──

// 1.0.10-beta `00 · 02-erlang` — `String.slice` is a primitive-interface
// `default fn` of `primitives.bp`, not a bare-symbol prim-op, so the erlang
// backend reaches it through `collectPreludeInstanceDefaults`. That indexing
// was guarded on `comptime_module != null`, so a `libs/std` module compiled as
// an ordinary DEPENDENCY — which is what `from "std"` makes of it — never had
// `String.slice` in its table and `query.slice(1, query.length)` fell through
// to a bare local `slice/3` the module never defines. Five std modules were
// dead on this row at once (`path`, `querystring`, `queue`, `snapshots`,
// `url`); `erlc` refused each of them with `function slice/3 undefined`.
//
// RUNNING is the assertion: the entry module compiled fine, so a snapshot of it
// showed nothing. `querystring.parse` is the shortest std entry point that
// reaches the shim.
test "erlang: std package ---- a String.slice default fn inside a std module" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {querystring} from "std";
        \\
        \\fn main() {
        \\    @print(querystring.parse("?a=1&b=2").unwrapOr([]).length);
        \\}
    , "2\n", &.{
        "std@querystring:parse(<<\"?a=1&b=2\">>)",
    });
}

// The `botopink test` runner of a module that reaches another one. Two claims
// no `test { }` block can make from the inside, because they are about the
// runner's own preamble:
//
//   1. `from "std"` counts as reaching out. The loader was emitted for
//      `imported_fns` / `imported_types` / a type module only, and a std import
//      fills `std_imports` — so `std@querystring:parse/1` was a remote call
//      into a module the escript never loaded, and the test died `{error,undef}`
//      with the failure pinned to the test rather than to the missing module.
//   2. A sibling that does not compile REFUSES THE RUN (decision 67). It used
//      to be skipped (`_ -> ok`) on the reading that "its own cell reports the
//      error" — true for a module of the project under test, never true for a
//      dependency, which has no cell. That silence is what kept the dead
//      `slice/3` above invisible.
test "erlang: std package ---- the test runner loads a std sibling and refuses a dead one" {
    try h.assertErlangTestModeContains(std.testing.allocator,
        \\import {querystring} from "std";
        \\
        \\test "reaches a std module" {
        \\    assert querystring.parse("?a=1").unwrapOr([]).length == 1;
        \\}
    , &.{
        // 1 — the loader is emitted at all, and `main/1` calls it.
        "'__bp_load_siblings'()",
        "filelib:wildcard(filename:join([Dir, \"**\", \"*.erl\"]))",
        // 2 — a module `compile:file/2` refused is named, reported and halts.
        "Bad -> '__bp_dead_module'(Src, Bad)",
        "refusing to run the tests of",
        "halt(1)",
    }, &.{
        // The skip this replaced. The arm is gone, not demoted to a warning.
        "{ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);\n                        _ -> ok",
    });
}

// Decision 106 — the root of std is pure: a module at `std/<name>` imports
// nothing from `io/`, in either spelling, bare (the std package's own root)
// or `from "std"`. The fixture is a module AT the path `std/probe`, not an
// edit of `libs/std`: the refusal fires at the import item, before the
// `io/` tree (step 3) exists, and holds on all four backends.
test "js: std package ---- a root module importing from io is refused at the item" {
    try h.assertJsExpecting(std.testing.allocator, @src(), &.{
        .{ .path = "std/probe", .source =
        \\import {path: {join}, io.fs.readText};
        \\
        \\pub fn peek(p: string) -> string {
        \\    return readText(join([p, "a"]));
        \\}
        },
    }, .expect_compile_error);
}

test "js: std package ---- a root module importing a group under io from std is refused" {
    try h.assertJsExpecting(std.testing.allocator, @src(), &.{
        .{ .path = "std/probe", .source =
        \\import {io: {env: {read}}} from "std";
        \\
        \\pub fn home() -> ?string {
        \\    return read("HOME");
        \\}
        },
    }, .expect_compile_error);
}
