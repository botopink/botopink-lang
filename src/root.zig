//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Pulls in all tests defined in sub-modules.
// The Zig test runner only discovers test blocks reachable from the root of
// the module under test; without these lines, `zig build test` finds nothing.
test {
    _ = @import("./lexer/tests.zig");
    _ = @import("./parser/tests.zig");
}
