//! codegen: `#[@External.<Target>(…)]` FFI declarations (F1, stdlib-gleam).
//! Erlang lowers calls to the remote `module:symbol(…)`; CommonJS imports the
//! host symbol under the fn name via `require`.

const std = @import("std");
const h = @import("helpers.zig");
const codegen = @import("../../codegen.zig");

test "js: external ---- call emits module symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("string", "length"),
        \\  @External.Node("./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    @print(str_length("hello"));
        \\}
    );
}

test "js: external ---- global math" {
    // `Math` is a JS global, not a module — the node target must reference
    // it directly (`const floor = Math.floor;`), never `require("Math")`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("math", "floor"),
        \\  @External.Node("Math", "floor")]
        \\pub declare fn floor(n: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(floor(1.7));
        \\}
    );
}

test "js: external ---- import binds symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("erlang", "abs"),
        \\  @External.Node("./stdlib.mjs", "abs")]
        \\pub declare fn abs(n: i32) -> i32;
        \\
        \\fn main() {
        \\    @print(abs(-5));
        \\}
    );
}

// ── External.<Target> typed-enum annotation form ────────────────────────────
// The enum-variant form (`#[@External.Erlang("template")]`) is the only
// form. Codegen reads `annotations[]` directly looking for `External.<target>`.

test "js: External.<Target> ---- template equivalent to @external(target, template)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("string", "length"),
        \\  @External.Node("./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    @print(str_length("hello"));
        \\}
    );
}

test "js: External.<Target> ---- mixed with @external() in one decl" {
    // Migration-friendly: a single decl may use the new form for one target
    // and the legacy form for another while a codebase migrates.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang( "math", "floor"),
        \\  @External.Node("Math", "floor")]
        \\pub declare fn floor(n: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(floor(1.7));
        \\}
    );
}

// net-new (A1): an `#[@External.<targert>(...)]` fn that declares a target only for another
// backend (erlang) has NO node target — calling it while generating commonJS
// fails with `MissingExternalTarget`.
test "js: external ---- net-new: no target for the active backend errors" {
    const io = std.testing.io;
    const src =
        \\#[@External.Erlang( "string", "length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    @print(str_length("hello"));
        \\}
    ;
    // configs[0] is the commonJS/node target.
    const result = codegen.generate(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        h.configs[0],
    );
    try std.testing.expectError(error.MissingExternalTarget, result);
}

// §A2: a chained host-call template (`Buffer.from($0).toString('base64')`)
// renders verbatim at the call site — no aliasing, no receiver-stripping.
// The 2-arg `#\[@External\.node("<template>")]` form is detected by the `$`
// marker; the template body lives in `user_node_templates` and renders
// inline (mirrors the erlang backend's existing template path).
test "js: external ---- A2 chained host call renders verbatim" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("base64:encode($0)"),
        \\  @External.Node("""Buffer.from($0, 'utf8').toString('base64')""")]
        \\pub declare fn b64encode(s: string) -> string;
        \\
        \\fn main() {
        \\    @print(b64encode("hi"));
        \\}
    );
}

// §A2: an `@external(node, …)` template that resolves a method on a
// non-static global keeps the receiver bound (the legacy alias shape
// `const fn = JSON.stringify` would strip `this` on a method-on-class
// chain; the §A2 template renders the chain inline at every call).
// Uses `JSON.stringify($0)` (rather than `performance.now(...)`) so the
// run-log captures a deterministic value.
test "js: external ---- A2 method-on-global template keeps receiver bound" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@External.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"),
        \\  @External.Node("JSON.stringify($0)")]
        \\declare fn stringify(value: i32) -> string;
        \\
        \\fn main() {
        \\    @print(stringify(42));
        \\}
    );
}

// §A3: a `#[@result] declare fn` paired with `@external` accepts the
// effect annotation because the host template owns the wrapper shape.
// The fn's return type is `@Result<R, E>`; the template renders an
// `{ ok: ... } | { error: ... }` shape on Node and `{ok, _} | {error, _}`
// on Erlang. Without §A3 this declare reds at R1 (effect on declare).
test "js: external ---- A3 result-template-owned declare fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\#[@External.Erlang( """(fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)($0)"""),
        \\  @External.Node("""(() => { const __n = Number($0); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })()""")]
        \\pub declare fn parseInt(s: string) -> @Result<i32, string>;
        \\
        \\fn main() {
        \\    val r = parseInt("42");
        \\    @print(r.unwrapOr(-1));
        \\}
    );
}
