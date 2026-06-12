//! First-thing-to-run pre-warm: trigger the lazy `stdlib_template` init.
//!
//! See `modules/compiler-core/src/test_warmup.zig` for the full rationale.
//! The LSP test binary builds its own copy of the compiler-core library,
//! so its `stdlib_template` is a separate process-lifetime instance and
//! needs its own pre-warm.

const std = @import("std");
const bp = @import("botopink");

test "_warmup: lazy-init the stdlib template once" {
    _ = try bp.comptime_pipeline.getStdlibTemplate(std.testing.allocator);
}

test "_warmup: pre-spawn the persistent node runner" {
    try bp.comptime_pipeline.warmPersistentNodeRunner(std.testing.io, std.testing.allocator);
}

test "_warmup: pre-init the wasm3 runtime" {
    try bp.comptime_pipeline.warmWasm3Runtime(std.testing.io, std.testing.allocator);
}
