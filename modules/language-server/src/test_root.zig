// Entry point for all LSP engine tests.
// Each file is imported here so `zig build test` discovers every test.
comptime {
    _ = @import("./tests/messages.zig");
    _ = @import("./tests/diagnostics.zig");
    _ = @import("./tests/formatting.zig");
    _ = @import("./tests/hover.zig");
    _ = @import("./tests/definition.zig");
    _ = @import("./tests/symbols.zig");
    _ = @import("./tests/completion.zig");
    _ = @import("./tests/references.zig");
    _ = @import("./tests/rename.zig");
    _ = @import("./tests/signature_help.zig");
    _ = @import("./tests/folding_range.zig");
    _ = @import("./tests/prepare_rename.zig");
    _ = @import("./tests/code_actions.zig");
    _ = @import("./tests/type_definition.zig");
    _ = @import("./tests/semantic_tokens.zig");
    _ = @import("./tests/inlay_hints.zig");
    _ = @import("./tests/sublanguage.zig");
    _ = @import("./tests/lifecycle.zig");
    _ = @import("./tests/cross_module.zig");
    _ = @import("./tests/project_graph.zig");
}
