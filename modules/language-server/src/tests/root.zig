// Entry point for all LSP engine tests.
// Each file is imported here so `zig build test` discovers every test.
comptime {
    _ = @import("./diagnostics.zig");
    _ = @import("./formatting.zig");
    _ = @import("./hover.zig");
    _ = @import("./definition.zig");
    _ = @import("./symbols.zig");
    _ = @import("./completion.zig");
    _ = @import("./references.zig");
    _ = @import("./rename.zig");
    _ = @import("./signature_help.zig");
}
