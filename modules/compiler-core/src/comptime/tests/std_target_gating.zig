//! STD-001 — `from "std"` imports red on a target with no `@external` coverage.
//!
//! The CLI codegen path (`codegen.generate` + `cli/check.zig`) threads its target
//! name through `comptimeMod.compile` → `analyzeSource`, which sets
//! `env.target` so `markStdImports` reads `env.stdModuleFns` and rejects any
//! imported std module whose `pub declare fn` lacks an `@external(<target>, …)`
//! match. The non-codegen paths (LSP, comptime tests) pass `null` and the
//! check stays off.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const diagnostics = @import("../diagnostics.zig");

fn typeErrorMessage(outcome: anytype) []const u8 {
    return switch (outcome.typeError.kind) {
        .custom => |c| c.message,
        else => "",
    };
}

/// `compile` prepends std modules to the analysis list (`expandStdImports`),
/// so `outputs[0]` is a std module and the project module is the last one.
fn projectOutcome(session: anytype) @TypeOf(session.outputs.items[0].outcome) {
    const items = session.outputs.items;
    return items[items.len - 1].outcome;
}

test "STD-001: import of std/process from wasm target reds" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {process} from \"std\";\n" }},
        io,
        ".botopinkbuild/comptime/std_target_gating_wasm",
        "wasm",
    );
    defer session.deinit(std.testing.allocator);
    const outcome = projectOutcome(session);
    try std.testing.expect(outcome == .typeError);
    const msg = typeErrorMessage(outcome);
    try std.testing.expect(std.mem.indexOf(u8, msg, diagnostics.std_unsupported_on_target) != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "wasm") != null);
}

test "STD-001: import of std/process from node target is accepted" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {process} from \"std\";\n" }},
        io,
        ".botopinkbuild/comptime/std_target_gating_node",
        "node",
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .ok);
}

test "STD-001: null target keeps the check off (tooling parity)" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {process} from \"std\";\n" }},
        io,
        ".botopinkbuild/comptime/std_target_gating_null",
        null,
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .ok);
}
