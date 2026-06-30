/// Generic comptime evaluation interface.
///
/// `ComptimeEntry`  — one expression to evaluate, with its generated ID.
/// `RunResult`      — what the unified runtime returns.
/// `evaluate()`     — routes through the persistent erl subprocess.
///
/// History note: prior to v0.beta.21 (`wasm3-unified-runtime` spec) this module
/// dispatched across 4 runtimes (node / erlang / wasm / beam). The four-runtime
/// architecture was a cross-backend semantic-parity oracle that the user
/// explicitly de-prioritised once snapshot coverage made the oracle redundant.
/// Today every comptime val expression runs through the persistent erl
/// subprocess; target-specific rendering happens in the codegen backends
/// (`commonJS.zig`/`erlang.zig`/`wat.zig`/`beam_asm.zig`).
const std = @import("std");
const ast = @import("../ast.zig");
const beam = @import("./runtime/beam.zig");

// ── Shared types ──────────────────────────────────────────────────────────────

/// A single comptime expression to be evaluated, paired with its generated ID.
pub const ComptimeEntry = struct {
    id: []const u8, // "ct_0", "ct_1", …
    expr: ast.TypedExpr,
};

/// The result that the runtime produces.
pub const RunResult = struct {
    /// The generated Erlang source (for debug/snapshot purposes).
    script: []u8,
    /// Evaluated values: id → JS/Erlang-shaped literal string.
    values: std.StringHashMap([]const u8),
};

// ── Dispatch ──────────────────────────────────────────────────────────────────

/// Evaluate `entries` via the persistent erl subprocess.
///
/// Returns a `RunResult` with the generated script and evaluated values.
/// The result is fully owned by the caller (allocated from `allocator`).
pub fn evaluate(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const ComptimeEntry,
    build_root: []const u8,
) !RunResult {
    return beam.run(allocator, io, entries, build_root);
}
