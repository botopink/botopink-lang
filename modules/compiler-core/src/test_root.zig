// Entry point for all compiler-core tests.
// Separate from root.zig so that consumers who import botopink as a library
// do not inadvertently pull compiler-core tests into their own test binaries.
const std = @import("std");

test {
    _ = @import("./test_warmup.zig"); // runs first: lazy-inits stdlib_template
    _ = @import("./lexer/tests.zig");
    _ = @import("./parser/tests.zig");
    _ = @import("./format/tests.zig");
    _ = @import("./comptime/tests.zig");
    _ = @import("./codegen/tests.zig");
}
