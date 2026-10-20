//! STD-001 — a call of a std function reaching a host declaration no
//! binding covers on the target reds AT THE CALL; the import never does
//! (decision 518 (4)).
//!
//! Comptime never reads the target (decision 798 (4)): `comptimeMod.compile`
//! takes none, and inference records each std call that reaches a host
//! declaration (`OkData.std_host_calls`). The refusal is the emit's
//! (`codegen/target_check.zig`), which `codegen.emit` and `botopink check`
//! apply over the analysed outputs; the language server applies none.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const targetCheck = @import("../../codegen/target_check.zig");
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

const pid_src = "import {io.process, io.terminal.print} from \"std\";\nfn main() -> void {\n    print(process.pid());\n}\n";

test "STD-001: a call of std/io/process.pid reds at the call on wasm, at emit" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = pid_src }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_wasm"),
    );
    defer session.deinit(std.testing.allocator);
    // The analysis is the target's none: it records the call, refuses nothing.
    try std.testing.expect(projectOutcome(session) == .ok);
    try std.testing.expect(projectOutcome(session).ok.std_host_calls.len > 0);
    _ = try targetCheck.apply(session.arena.allocator(), session.outputs.items, "wasm");
    const outcome = projectOutcome(session);
    try std.testing.expect(outcome == .typeError);
    const msg = typeErrorMessage(outcome);
    try std.testing.expect(std.mem.indexOf(u8, msg, diagnostics.std_unsupported_on_target) != null);
    // The binding's spelling is the annotation's (`#[@External.Wasm]`), not
    // the retired `@external`.
    try std.testing.expect(std.mem.indexOf(u8, msg, "std/io/process.pid has no `.Wasm(…)` implementation for target 'wasm'") != null);
    try std.testing.expectEqual(@as(usize, 3), outcome.typeError.loc.?.line);
}

test "STD-001: the same analysis is taken on erlang, and handed back after the emit's refusal" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = pid_src }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_restore"),
    );
    defer session.deinit(std.testing.allocator);
    const refused = try targetCheck.apply(session.arena.allocator(), session.outputs.items, "wasm");
    try std.testing.expectEqual(@as(usize, 1), refused.len);
    targetCheck.restore(session.outputs.items, refused);
    try std.testing.expect(projectOutcome(session) == .ok);
    try std.testing.expectEqual(@as(usize, 0), (try targetCheck.apply(session.arena.allocator(), session.outputs.items, "erlang")).len);
}

test "STD-001: the import alone of std/io/process on wasm is accepted" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_import"),
    );
    defer session.deinit(std.testing.allocator);
    _ = try targetCheck.apply(session.arena.allocator(), session.outputs.items, "wasm");
    try std.testing.expect(projectOutcome(session) == .ok);
}

test "STD-001: import of std/io/process from node target is accepted" {
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process} from \"std\";\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_node"),
    );
    defer session.deinit(std.testing.allocator);
    _ = try targetCheck.apply(session.arena.allocator(), session.outputs.items, "node");
    try std.testing.expect(projectOutcome(session) == .ok);
}

test "STD-001: a call refused on the target before a type error answers the target's refusal" {
    // Decision 798 (4): the analysis goes on past the call and refuses the
    // argument; on wasm the call came first, so the emit answers it there.
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "main.bp", .source = "import {io.process, io.terminal.print} from \"std\";\nfn main() -> void {\n    print(process.pid());\n    val n: i32 = \"x\";\n}\n" }},
        io,
        test_scratch.path(io, "comptime/std_target_gating_before_error"),
    );
    defer session.deinit(std.testing.allocator);
    try std.testing.expect(projectOutcome(session) == .typeError);
    try std.testing.expectEqual(@as(usize, 0), (try targetCheck.apply(session.arena.allocator(), session.outputs.items, "erlang")).len);
    try std.testing.expectEqual(@as(usize, 4), projectOutcome(session).typeError.loc.?.line);
    const refused = try targetCheck.apply(session.arena.allocator(), session.outputs.items, "wasm");
    try std.testing.expectEqual(@as(usize, 1), refused.len);
    const msg = typeErrorMessage(projectOutcome(session));
    try std.testing.expect(std.mem.indexOf(u8, msg, diagnostics.std_unsupported_on_target) != null);
    try std.testing.expectEqual(@as(usize, 3), projectOutcome(session).typeError.loc.?.line);
}
