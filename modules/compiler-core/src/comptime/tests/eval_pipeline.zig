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

test "eval pipeline: comptime record lit" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val f = comptime RecordField(name: "x", typeName: i32);
    );
}
