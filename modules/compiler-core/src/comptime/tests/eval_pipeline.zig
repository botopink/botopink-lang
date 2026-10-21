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
