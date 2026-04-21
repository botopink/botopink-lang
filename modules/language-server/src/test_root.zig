// Entry point for all LSP engine tests.
// Each file is imported here so `zig build test` discovers every test.
comptime {
    _ = @import("./tests/diagnostics.zig");
    _ = @import("./tests/formatting.zig");
    _ = @import("./tests/hover.zig");
    _ = @import("./tests/definition.zig");
    _ = @import("./tests/symbols.zig");
    _ = @import("./tests/completion.zig");
    _ = @import("./tests/references.zig");
    _ = @import("./tests/rename.zig");
    _ = @import("./tests/signature_help.zig");
}
