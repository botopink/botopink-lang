//! Barrel for codegen stage tests. Real tests live in tests/<feature>.zig;
//! the shared harness is tests/helpers.zig. This file only aggregates them
//! so `test_root.zig` (which imports this) discovers every test.

test {
    _ = @import("tests/values.zig");
    _ = @import("tests/aggregates.zig");
    _ = @import("tests/control_flow.zig");
    _ = @import("tests/comptime.zig");
    _ = @import("tests/builtins.zig");
    _ = @import("tests/dispatch.zig");
    _ = @import("tests/features.zig");
    _ = @import("tests/externals.zig");
    _ = @import("tests/std_package.zig");
    _ = @import("tests/wat.zig");
    _ = @import("tests/dts_skips_templates.zig");
    _ = @import("tests/runtime_scratch.zig");
}
