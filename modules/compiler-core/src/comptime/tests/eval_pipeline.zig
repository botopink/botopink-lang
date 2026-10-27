//! comptime: eval pipeline integration tests (Step 5.5)
//!
//! Full pipeline: BP source → infer → evaluateComptime → verify results.

const std = @import("std");
const h = @import("helpers.zig");

test "eval pipeline: simple comptime val arithmetic" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = comptime 10 + 5;
        \\val y = comptime 42;
    );
}

// Decision 331 — a record a `comptime` builds is written into the program as
// its constructor (`block_eval.zig`'s lift): each backend emits its own
// record form from the call, where the 1.0.1-beta folder had only one literal
// text to splice and refused the ctor. The `COMPTIME VALUES` listing shows
// the lifted expression.
test "eval pipeline: comptime record lit" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type RecordField(name: string, typeName: string)
        \\val f = comptime RecordField(name: "x", typeName: "i32");
    );
}

// Decision 1060 (2) — the float texts a block's reply carries, recorded from
// the comptime runtime as it writes them; std's codecs
// (`compiler.bp` § the crossing) are held to this section by
// `modules/compiler-cli/tests/comptime_reply_codecs.sh`.
test "eval pipeline: comptime floats in a block reply" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn half(x: f64) -> f64 {
        \\    return x / 2.0;
        \\}
        \\val f = comptime [half(3.0), half(0.2) + 0.2 + 0.0, 1e21, 1e-7, -0.0];
    );
}

// Decision 1060 (3) — an index out of range in a comptime body answers
// `null` and raises nothing, as in a program; the reply writes it `null`.
test "eval pipeline: comptime index out of range answers null" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val m = comptime {
        \\    val xs = [1, 2, 3];
        \\    xs[9]
        \\};
    );
}
