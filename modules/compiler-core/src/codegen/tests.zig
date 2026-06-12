//! Barrel for codegen stage tests. Real tests live in tests/<feature>.zig;
//! the shared harness is tests/helpers.zig. This file only aggregates them
//! so `test_root.zig` (which imports this) discovers every test.

test {
    _ = @import("tests/js_values.zig");
    _ = @import("tests/js_aggregates.zig");
    _ = @import("tests/js_control_flow.zig");
    _ = @import("tests/js_comptime.zig");
    _ = @import("tests/js_builtins.zig");
    _ = @import("tests/js_dispatch.zig");
    _ = @import("tests/js_features.zig");
    _ = @import("tests/externals.zig");
    _ = @import("tests/std_package.zig");
    _ = @import("tests/wat.zig");
}
