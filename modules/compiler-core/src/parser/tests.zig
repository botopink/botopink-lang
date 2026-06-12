//! Barrel for parser stage tests. Real tests live in tests/<feature>.zig;
//! the shared harness is tests/helpers.zig. This file only aggregates them
//! so `test_root.zig` (which imports this) discovers every test.

test {
    _ = @import("tests/imports.zig");
    _ = @import("tests/declarations.zig");
    _ = @import("tests/expressions.zig");
    _ = @import("tests/destructuring.zig");
    _ = @import("tests/errors.zig");
}
