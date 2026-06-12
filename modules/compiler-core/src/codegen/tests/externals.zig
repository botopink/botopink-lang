//! codegen: `#[@external(…)]` FFI declarations (F1, stdlib-gleam).
//! Erlang lowers calls to the remote `module:symbol(…)`; CommonJS imports the
//! host symbol under the fn name via `require`.

const std = @import("std");
const h = @import("helpers.zig");
const codegen = @import("../../codegen.zig");

test "js: external ---- call emits module symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@external(erlang, "string", "length"),
        \\  @external(node, "./gleam_stdlib.mjs", "string_length")]
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
        \\#[@external(erlang, "math", "floor"),
        \\  @external(node, "Math", "floor")]
        \\pub declare fn floor(n: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(floor(1.7));
        \\}
    );
}

test "js: external ---- import binds symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@external(erlang, "erlang", "abs"),
        \\  @external(node, "./stdlib.mjs", "abs")]
        \\pub declare fn abs(n: i32) -> i32;
        \\
        \\fn main() {
        \\    @print(abs(-5));
        \\}
    );
}

// net-new (A1): an `#[@external]` fn that declares a target only for another
// backend (erlang) has NO node target — calling it while generating commonJS
// fails with `MissingExternalTarget`.
test "js: external ---- net-new: no target for the active backend errors" {
    const io = std.testing.io;
    const src =
        \\#[@external(erlang, "string", "length")]
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
