/// Generic comptime evaluation interface.
///
/// `ComptimeEntry`  — one expression to evaluate, with its generated ID.
/// `RunResult`      — what the unified runtime returns.
/// `evaluate()`     — routes through the single wasm3-hosted WASM path.
///
/// History note: prior to v0.beta.21 (`wasm3-unified-runtime` spec) this module
/// dispatched across 4 runtimes (node / erlang / wasm / beam). The four-runtime
/// architecture was a cross-backend semantic-parity oracle that the user
/// explicitly de-prioritised once snapshot coverage made the oracle redundant.
/// Today every comptime val expression runs through the wasm3 interpreter
/// embedded in-process; target-specific rendering happens in the codegen
/// backends (`commonJS.zig`/`erlang.zig`/`wat.zig`/`beam_asm.zig`).
const std = @import("std");
const ast = @import("../ast.zig");
const wasm = @import("./runtime/wasm.zig");

// ── Shared types ──────────────────────────────────────────────────────────────

/// A single comptime expression to be evaluated, paired with its generated ID.
pub const ComptimeEntry = struct {
    id: []const u8, // "ct_0", "ct_1", …
    expr: ast.TypedExpr,
};

/// The result that the runtime produces.
pub const RunResult = struct {
    /// The generated WAT source (for debug/snapshot purposes).
    script: []u8,
    /// Evaluated values: id → JS/Erlang-shaped literal string.
    values: std.StringHashMap([]const u8),
};

// ── Dispatch ──────────────────────────────────────────────────────────────────

/// Evaluate `entries` via the unified wasm3 runtime.
///
/// Returns a `RunResult` with the generated script and evaluated values.
/// The result is fully owned by the caller (allocated from `allocator`).
pub fn evaluate(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const ComptimeEntry,
    build_root: []const u8,
) !RunResult {
    return wasm.run(allocator, io, entries, build_root);
}
