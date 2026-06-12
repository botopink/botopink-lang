//! Barrel for comptime stage tests. Real tests live in tests/<feature>.zig;
//! the shared harness is tests/helpers.zig. This file only aggregates them
//! so `test_root.zig` (which imports this) discovers every test.

test {
    _ = @import("tests/infer_exprs.zig");
    _ = @import("tests/infer_decls.zig");
    _ = @import("tests/infer_generics.zig");
    _ = @import("tests/infer_errors.zig");
    _ = @import("tests/types.zig");
    _ = @import("tests/variants.zig");
    _ = @import("tests/exhaustiveness.zig");
    _ = @import("tests/effects.zig");
    _ = @import("tests/templates.zig");
    _ = @import("tests/decorators.zig");
    _ = @import("tests/decorator_invocation.zig");
}
