//! STD-001 — a call of a std function reaching a host declaration no
//! binding covers on the target reds AT THE CALL; the import never does
//! (decision 518 (4)).
//!
//! The CLI codegen path (`codegen.generate` + `cli/check.zig`) threads its target
//! name through `comptimeMod.compile` → `analyzeSource`, which sets
//! `env.target`; `infer.zig` `checkStdCall` reads `env.stdModuleAllFns` and
//! refuses a call whose function reaches a declaration with no
//! `#[@External.<Target>(…)]` for that target. The non-codegen paths (LSP,
//! comptime tests) pass `null` and the check stays off.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const diagnostics = @import("../diagnostics.zig");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");

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

test "STD-001: a call of std/io/process.pid from wasm target reds at the call" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\nfn main() {\n    @print(process.pid());\n}\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_wasm"),
        "wasm",
    );
    defer session.deinit(std.testing.allocator);
    const outcome = projectOutcome(session);
    try std.testing.expect(outcome == .typeError);
    const msg = typeErrorMessage(outcome);
    try std.testing.expect(std.mem.indexOf(u8, msg, diagnostics.std_unsupported_on_target) != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "wasm") != null);
    // The binding's spelling is the annotation's (`#[@External.Wasm]`), not
    // the retired `@external`.
    try std.testing.expect(std.mem.indexOf(u8, msg, "std/io/process.pid has no `#[@External.Wasm]` for target 'wasm'") != null);
    try std.testing.expectEqual(@as(usize, 3), outcome.typeError.loc.?.line);
}

test "STD-001: the import alone of std/io/process on wasm is accepted" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_import"),
        "wasm",
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .ok);
}

test "STD-001: import of std/io/process from node target is accepted" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_node"),
        "node",
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .ok);
}

test "STD-001: null target keeps the check off (tooling parity)" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_null"),
        null,
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .ok);
}
