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

// DOCUMENTED SKIP — `comptime <RecordCtor>(…)` is rejected by
// `comptime/error.zig` `validateComptime`: the folder only evaluates literals
// and arithmetic, so any call inside a `comptime` expression is "a runtime
// identifier". Missing feature: comptime evaluation of record construction;
// owner: spec 02 (checker gaps). The snapshot pins the validation error.
test "eval pipeline: comptime record lit" {
    try h.assertComptimeCompileError(std.testing.allocator, @src(),
        \\record RecordField { name: string, typeName: string }
        \\val f = comptime RecordField(name: "x", typeName: "i32");
    );
}
