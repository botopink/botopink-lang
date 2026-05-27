/// Generic comptime evaluation interface.
///
/// `ComptimeEntry`  — one expression to evaluate, with its generated ID.
/// `Runtime`        — which backend to use (node, erlang, wasm).
/// `RunResult`      — what every backend must return.
/// `evaluate()`     — dispatches to the selected runtime backend.
const std = @import("std");
const ast = @import("../ast.zig");
const node = @import("./runtime/node.zig");
const erlang = @import("./runtime/erlang.zig");
const wasm = @import("./runtime/wasm.zig");
const beam = @import("./runtime/beam.zig");

// ── Shared types ──────────────────────────────────────────────────────────────

/// A single comptime expression to be evaluated, paired with its generated ID.
pub const ComptimeEntry = struct {
    id: []const u8, // "ct_0", "ct_1", …
    expr: ast.TypedExpr,
};

/// The result that every runtime backend must produce.
pub const RunResult = struct {
    /// The generated script source (for debug/snapshot purposes).
    script: []u8,
    /// Evaluated values: id → JS/Erlang literal string.
    values: std.StringHashMap([]const u8),
};

// ── Runtime registry ──────────────────────────────────────────────────────────

/// Supported comptime evaluation runtimes.
/// Add new variants here when a new backend is implemented under `runtime/`.
pub const Runtime = enum {
    node,
    erlang,
    wasm,
    beam,

    pub fn name(self: Runtime) []const u8 {
        return switch (self) {
            .node => "node",
            .erlang => "erlang",
            .wasm => "wasm",
            .beam => "beam",
        };
    }
};

// ── Dispatch ──────────────────────────────────────────────────────────────────

/// Evaluate `entries` using the specified runtime.
///
/// Returns a `RunResult` with the generated script and evaluated values.
/// The result is fully owned by the caller (allocated from `allocator`).
pub fn evaluate(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const ComptimeEntry,
    runtime: Runtime,
    build_root: []const u8,
) !RunResult {
    return switch (runtime) {
        .node => node.run(allocator, io, entries, build_root),
        .erlang => erlang.run(allocator, io, entries, build_root),
        .wasm => wasm.run(allocator, io, entries, build_root),
        .beam => beam.run(allocator, io, entries, build_root),
    };
}
