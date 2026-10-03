//! Barrel for lexer stage tests. Real tests live in tests/<feature>.zig;
//! this file only aggregates them so `test_root.zig` (which imports this)
//! discovers every test.

test {
    _ = @import("tests/basics.zig");
    _ = @import("tests/errors.zig");
    _ = @import("tests/keywords.zig");
    _ = @import("tests/recognizes.zig");
    _ = @import("tests/strings.zig");
    _ = @import("tests/tokenizes.zig");
}
