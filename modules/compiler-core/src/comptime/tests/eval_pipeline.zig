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

// DOCUMENTED SKIP — `comptime <RecordCtor>(…)` stays rejected by
// `comptime/error.zig` `validateComptime`, on purpose. Decided in the 1.0.1-beta
// comptime wave: a folded value is spliced into the four backends as ONE literal
// text (`eval.zig` `literal`), and a record has no such cross-backend form — JS
// wants `{ name: "x" }`, erlang a map, wasm a heap layout. Folding a ctor call
// would therefore have to splice `null` (what `Value.object` renders), which is
// a silent miscompile; a validation error is the honest answer until the folder
// can hand each backend a structured value instead of one literal string.
// Owner of that change: spec 02 (checker gaps) + the backends.
// The snapshot pins the validation error.
test "eval pipeline: comptime record lit" {
    try h.assertComptimeCompileError(std.testing.allocator, @src(),
        \\record RecordField { name: string, typeName: string }
        \\val f = comptime RecordField(name: "x", typeName: "i32");
    );
}
