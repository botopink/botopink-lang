//! The one entry the evaluators call to run a comptime module (front 18 steps
//! 3 and 5; decision 434).
//!
//! **Comptime runs on wasm only** (decision 434): every target's decorator,
//! template and `comptime` evaluation — `erlang`, `beam`, `commonJS`, `wasm`,
//! and a compilation that names no target (the language server's type pass) —
//! runs on the wat runtime: the generated module lowered to wasm and linked
//! into the term library (`wat/program.zig`), run in-process on wasm3
//! (`persistent_wat.zig`) — or on the page's engine in the browser build. A
//! compile spawns no `erl`; there is no other runtime to select, so nothing
//! here is configured per target or per thread.
const std = @import("std");
const builtin = @import("builtin");

const persistent_wat = @import("persistent_wat.zig");
const watProgram = @import("wat/program.zig");
const stages = @import("stages.zig");

/// Whether this build can spawn a child process: the RUN LOG executors'
/// precondition (`codegen/runtime.zig`). The comptime runtime needs none.
pub const can_spawn: bool = !builtin.cpu.arch.isWasm();

/// The runtime's answer.
pub const Response = union(enum) {
    /// The reply bytes: `main/1`'s JSON.
    ok: []u8,
    /// The module could not be lowered to wasm (a refusal naming the
    /// construct) or did not load.
    compile_error: []u8,
    /// `main` raised or trapped.
    runtime_error: []u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed };

/// Evaluate generated module `module` (Erlang text `code`) with the ETF
/// argument `arg`. `host` names the evaluator (`template`, `decorator`,
/// `comptime`) in a listing.
pub fn evalWithArg(arena: std.mem.Allocator, io: std.Io, host: []const u8, module: []const u8, code: []const u8, arg: []const u8) EvalError!Response {
    _ = io;
    _ = host;
    const t_lower = stages.start();
    const built = try watProgram.build(module, code);
    stages.stop(.lower, t_lower);
    const ok = switch (built) {
        .ok => |o| o,
        .refused => |why| return .{ .compile_error = try arena.dupe(u8, why) },
    };
    return switch (try persistent_wat.evalWithArg(arena, module, ok.wasm, arg)) {
        .ok => |b| .{ .ok = b },
        .compile_error => |b| .{ .compile_error = b },
        .runtime_error => |b| .{ .runtime_error = b },
    };
}

// ── what a snapshot shows of an evaluation ───────────────────────────────────

/// The listing of the module that ran (a `COMPTIME WAT` section): the
/// generated module's functions as lowered to wasm (`wat/program.zig`), then
/// `main/1`'s argument as `;;` lines (`erl_listing` from its `%% main/1
/// argument` line on: the template and decorator evaluators pass only that
/// part, `template_eval.argumentListing`; `block_eval` its whole Erlang
/// listing) — or the refusal.
pub fn listingOf(arena: std.mem.Allocator, host: []const u8, module: []const u8, code: []const u8, erl_listing: []const u8) EvalError![]const u8 {
    _ = host;
    const marker = "\n%% main/1 argument";
    const argument: ?[]const u8 = if (std.mem.indexOf(u8, erl_listing, marker)) |i| erl_listing[i + 1 ..] else null;
    const built = try watProgram.build(module, code);
    const body = switch (built) {
        .ok => |o| o.listing,
        .refused => |why| return std.fmt.allocPrint(arena, ";; not lowered: {s}\n", .{why}),
    };
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.appendSlice(arena, std.mem.trimEnd(u8, body, "\n"));
    try out.append(arena, '\n');
    if (argument) |a| {
        try out.append(arena, '\n');
        var lines = std.mem.splitScalar(u8, a, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            try out.appendSlice(arena, ";;");
            try out.appendSlice(arena, if (std.mem.startsWith(u8, line, "%%")) line[2..] else line);
            try out.append(arena, '\n');
        }
    }
    return out.items;
}

test "a module the lowering does not take is a compile error naming the construct" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const code =
        \\-module(bp_runtime_refused).
        \\-export([main/1]).
        \\main(_) -> maybe X end.
    ;
    const r = try evalWithArg(arena_state.allocator(), std.testing.io, "template", "bp_runtime_refused", code, "\x83\x6a");
    try std.testing.expect(r == .compile_error);
    try std.testing.expect(std.mem.indexOf(u8, r.compile_error, "`maybe`") != null);
}

test "a module answers its reply" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const code =
        \\-module(bp_runtime_answers).
        \\-export([main/1]).
        \\main(_) -> <<"ok">>.
    ;
    const r = try evalWithArg(arena_state.allocator(), std.testing.io, "template", "bp_runtime_answers", code, "\x83\x6a");
    try std.testing.expectEqualStrings("ok", r.ok);
}
