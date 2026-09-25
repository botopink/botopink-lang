//! Which comptime runtime runs an evaluation, and the one entry both
//! evaluators call to run it (front 18 steps 3 and 5).
//!
//! **Decision 84: the comptime runtime follows the target's VM, beam by
//! default.** A build whose target is `erlang` or `beam` evaluates on the BEAM
//! runtime (`persistent_erl.zig`); `commonJS` and `wasm` evaluate on the wat
//! runtime (`persistent_wat.zig`, wasm3 in-process); a compilation that names
//! no target (the language server's type pass) uses beam. No flag and no build
//! option: `codegen.generateWith` selects `Config.comptime_runtime orelse
//! of(Config.targetSource)` for the duration of its comptime pass (`select`),
//! and the evaluators ask `current` — the evaluators are reached through the
//! type checker, which carries no configuration, so the selection travels on
//! this thread rather than through every call between them.
//!
//! What a host can run is decided at compile time: the BEAM runtime needs a
//! process the compiler can spawn (`can_spawn`, false on `wasm32`, where
//! `persistent_erl.zig` is never analysed); the wat runtime needs an engine —
//! wasm3 on a native host, the page's `WebAssembly.instantiate` in the browser
//! build (not wired yet, step 5's comptime half). An evaluation whose runtime
//! the host lacks is REFUSED with a located diagnostic naming it (decision 67),
//! never answered with an empty reply.
//!
//! `evalWithArg` dispatches; `parity` (a test hook) makes it run an evaluation
//! on the other runtime too and record where the two answers differ — the
//! invariant `parity.zig` and the codegen harness assert.
const std = @import("std");
const builtin = @import("builtin");
const configMod = @import("../../codegen/config.zig");
const replyOrder = @import("reply_order.zig");

const is_wasm = builtin.cpu.arch.isWasm();
const persistent_erl = if (is_wasm) struct {} else @import("persistent_erl.zig");
const persistent_wat = @import("persistent_wat.zig");
const watProgram = @import("wat/program.zig");

pub const ComptimeRuntime = configMod.ComptimeRuntime;

/// Whether this build can spawn a child process: the BEAM runtime's
/// precondition, and the RUN LOG executors' (`codegen/runtime.zig`).
pub const can_spawn: bool = !is_wasm;

/// Whether this build can run `r` at all.
pub fn available(r: ComptimeRuntime) bool {
    return switch (r) {
        .beam => can_spawn,
        // wasm3 is linked into every native build; the browser's engine is
        // reached through a host import that is not wired yet.
        .wat => !is_wasm,
    };
}

/// Decision 84: the runtime of a build for `target`.
pub fn of(target: configMod.TargetSource) ComptimeRuntime {
    return switch (target) {
        .erlang, .beam => .beam,
        .commonJS, .wasm => .wat,
    };
}

/// The runtime of the comptime pass running on this thread. Beam when no
/// target decided (decision 84's default).
threadlocal var selected: ComptimeRuntime = .beam;

pub fn current() ComptimeRuntime {
    return selected;
}

/// Run this thread's comptime evaluations on `r` until the returned value is
/// passed back to `select` (the previous selection).
pub fn select(r: ComptimeRuntime) ComptimeRuntime {
    const prev = selected;
    selected = r;
    return prev;
}

/// What an evaluator answers for a runtime the host lacks — the sentence after
/// "the <template|decorator> evaluator has ".
pub fn missingRuntimeMessage(r: ComptimeRuntime) []const u8 {
    return switch (r) {
        .beam => "no BEAM runtime in this build of the compiler: it needs a process it can spawn, " ++
            "and an erlang or beam target evaluates comptime on it (decision 84)",
        .wat => "no wat runtime engine in this build of the compiler: the browser build does not reach " ++
            "the page's WebAssembly engine yet (front 18 step 5, the comptime half)",
    };
}

/// A runtime's answer. The same three cases on both runtimes, so the
/// evaluators' `switch` does not know which one ran.
pub const Response = union(enum) {
    /// The reply bytes: `main/1`'s JSON.
    ok: []u8,
    /// The module did not compile (`erlc` rejected it) or could not be lowered
    /// to wat (a refusal naming the construct).
    compile_error: []u8,
    /// `main` raised, trapped or timed out.
    runtime_error: []u8,
};

pub const Result = union(enum) {
    response: Response,
    /// The runtime could not be reached: the reason, for the evaluator's
    /// diagnostic (no runtime on this host, a broken `erl` transport).
    unavailable: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed };

/// Evaluate generated module `module` (Erlang text `code`, staged under
/// `dir` for the BEAM runtime) with the ETF argument `arg`, on this thread's
/// runtime. `host` names the evaluator in diagnostics.
pub fn evalWithArg(arena: std.mem.Allocator, io: std.Io, host: []const u8, dir: []const u8, module: []const u8, code: []const u8, arg: []const u8) EvalError!Result {
    const r = current();
    const result = try evalOn(arena, io, r, host, dir, module, code, arg);
    if (parity) |p| {
        const other: ComptimeRuntime = if (r == .beam) .wat else .beam;
        if (available(other)) {
            const second = try evalOn(arena, io, other, host, dir, module, code, arg);
            const beam_result = if (r == .beam) result else second;
            const wat_result = if (r == .beam) second else result;
            try p.record(host, module, beam_result, wat_result);
        }
    }
    return result;
}

pub fn evalOn(arena: std.mem.Allocator, io: std.Io, r: ComptimeRuntime, host: []const u8, dir: []const u8, module: []const u8, code: []const u8, arg: []const u8) EvalError!Result {
    if (!available(r)) return .{ .unavailable = try std.fmt.allocPrint(arena, "the {s} evaluator has {s}", .{ host, missingRuntimeMessage(r) }) };
    return switch (r) {
        .beam => if (comptime can_spawn) evalBeam(arena, io, host, dir, module, code, arg) else unreachable,
        .wat => evalWat(arena, module, code, arg),
    };
}

fn evalBeam(arena: std.mem.Allocator, io: std.Io, host: []const u8, dir: []const u8, module: []const u8, code: []const u8, arg: []const u8) EvalError!Result {
    const path = try ensureModule(arena, io, dir, module, code);
    const response = persistent_erl.evalWithArg(arena, io, path, module, arg) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            // No message means `erl` is missing rather than a broken stream:
            // the caller's hint for that case names PATH.
            const detail = persistent_erl.lastTransportError() orelse return error.EvalFailed;
            return .{ .unavailable = try std.fmt.allocPrint(arena, "the {s} evaluator's erl runtime failed ({s}): {s}", .{ host, @errorName(err), detail }) };
        },
    };
    return .{ .response = switch (response) {
        .ok => |b| .{ .ok = b },
        .compile_error => |b| .{ .compile_error = b },
        .runtime_error => |b| .{ .runtime_error = b },
    } };
}

fn evalWat(arena: std.mem.Allocator, module: []const u8, code: []const u8, arg: []const u8) EvalError!Result {
    const built = try watProgram.build(module, code);
    const ok = switch (built) {
        .ok => |o| o,
        .refused => |why| return .{ .response = .{ .compile_error = try arena.dupe(u8, why) } },
    };
    const response = persistent_wat.evalWithArg(arena, ok.wasm, arg) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.NoEngineOnThisHost => unreachable, // `available(.wat)` said so
    };
    return .{ .response = switch (response) {
        .ok => |b| .{ .ok = b },
        .compile_error => |b| .{ .compile_error = b },
        .runtime_error => |b| .{ .runtime_error = b },
    } };
}

// ── the BEAM runtime's staging ───────────────────────────────────────────────

/// Stage `<dir>/<module>.erl` unless it is already there, and return its path
/// either way. The atom **is** the content's hash, and `writeModule` stages and
/// renames, so a file at that path is that content, complete — a second call
/// site of one declaration would rewrite the same bytes. The check is a single
/// `access`, and asking the filesystem rather than remembering means a cleared
/// `.botopinkbuild/` or a changed working directory mid-process writes the file
/// again instead of pointing the node at one that is gone.
fn ensureModule(arena: std.mem.Allocator, io: std.Io, dir: []const u8, module: []const u8, code: []const u8) EvalError![]const u8 {
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, module });
    if (std.Io.Dir.cwd().access(io, path, .{})) |_| return path else |_| {}
    return writeModule(arena, io, dir, module, code);
}

/// Write `<dir>/<module>.erl` and return its path. The module is written to a
/// uniquely named sibling first and renamed into place, so a reader never sees
/// a partial file: two evaluations of the same body — concurrent tests, or two
/// compiler processes sharing a working directory — derive the same
/// content-hashed name, and a plain truncate-and-write let one `compile:file`
/// read the file mid-rewrite and fail with no usable diagnostic.
fn writeModule(arena: std.mem.Allocator, io: std.Io, dir: []const u8, module: []const u8, code: []const u8) EvalError![]const u8 {
    const cwd = std.Io.Dir.cwd();
    cwd.createDirPath(io, dir) catch return error.EvalFailed;
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, module });
    var nonce: [8]u8 = undefined;
    io.random(&nonce);
    const staging = try std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &nonce, .little) });
    cwd.writeFile(io, .{ .sub_path = staging, .data = code }) catch return error.EvalFailed;
    cwd.rename(staging, cwd, path, io) catch {
        cwd.deleteFile(io, staging) catch {};
        return error.EvalFailed;
    };
    return path;
}

// ── parity ───────────────────────────────────────────────────────────────────

/// Set on a thread to run every evaluation on both runtimes and collect the
/// ones whose answers differ (`Parity.record`). A test hook: nothing in a
/// compilation sets it.
pub threadlocal var parity: ?*Parity = null;

pub const Parity = struct {
    alloc: std.mem.Allocator,
    evaluations: usize = 0,
    mismatches: std.ArrayListUnmanaged(Mismatch) = .empty,

    pub const Mismatch = struct {
        host: []const u8,
        module: []const u8,
        beam: []const u8,
        wat: []const u8,
    };

    pub fn deinit(p: *Parity) void {
        for (p.mismatches.items) |m| {
            p.alloc.free(m.host);
            p.alloc.free(m.module);
            p.alloc.free(m.beam);
            p.alloc.free(m.wat);
        }
        p.mismatches.deinit(p.alloc);
    }

    /// Compare the two answers of one evaluation; keep them when they differ.
    pub fn record(p: *Parity, host: []const u8, module: []const u8, beam: Result, wat: Result) EvalError!void {
        p.evaluations += 1;
        if (try equivalent(p.alloc, beam, wat)) return;
        try p.mismatches.append(p.alloc, .{
            .host = try p.alloc.dupe(u8, host),
            .module = try p.alloc.dupe(u8, module),
            .beam = try describe(p.alloc, beam),
            .wat = try describe(p.alloc, wat),
        });
    }

    /// Every mismatch, both answers printed, for a failing test.
    pub fn report(p: *Parity, w: *std.Io.Writer) std.Io.Writer.Error!void {
        for (p.mismatches.items) |m| {
            try w.print("\n{s} {s}\n  beam: {s}\n  wat:  {s}\n", .{ m.host, m.module, m.beam, m.wat });
        }
    }
};

/// Two answers are the same answer: replies equal in their canonical key order
/// (`reply_order.zig` — a map's iteration order is the BEAM's atom-table
/// accident, not part of the reply); a compile error on both sides; runtime
/// errors with the same `Class:Reason` (the BEAM appends a stack trace the wat
/// runtime has no equivalent of).
pub fn equivalent(alloc: std.mem.Allocator, beam: Result, wat: Result) std.mem.Allocator.Error!bool {
    const b = switch (beam) {
        .response => |r| r,
        .unavailable => return false,
    };
    const w = switch (wat) {
        .response => |r| r,
        .unavailable => return false,
    };
    return switch (b) {
        .ok => |x| blk: {
            if (w != .ok) break :blk false;
            const cx = (try replyOrder.canonical(alloc, x)) orelse break :blk std.mem.eql(u8, x, w.ok);
            defer alloc.free(cx);
            const cy = (try replyOrder.canonical(alloc, w.ok)) orelse break :blk false;
            defer alloc.free(cy);
            break :blk std.mem.eql(u8, cx, cy);
        },
        .compile_error => w == .compile_error,
        .runtime_error => |x| w == .runtime_error and std.mem.eql(u8, firstLine(x), firstLine(w.runtime_error)),
    };
}

fn firstLine(s: []const u8) []const u8 {
    return s[0 .. std.mem.indexOfScalar(u8, s, '\n') orelse s.len];
}

fn describe(alloc: std.mem.Allocator, r: Result) std.mem.Allocator.Error![]const u8 {
    return switch (r) {
        .unavailable => |why| std.fmt.allocPrint(alloc, "unavailable: {s}", .{why}),
        .response => |resp| switch (resp) {
            .ok => |b| std.fmt.allocPrint(alloc, "ok: {s}", .{b}),
            .compile_error => |b| std.fmt.allocPrint(alloc, "compile error: {s}", .{b}),
            .runtime_error => |b| std.fmt.allocPrint(alloc, "runtime error: {s}", .{b}),
        },
    };
}

test "decision 84: the runtime follows the target, beam by default" {
    try std.testing.expectEqual(ComptimeRuntime.beam, of(.erlang));
    try std.testing.expectEqual(ComptimeRuntime.beam, of(.beam));
    try std.testing.expectEqual(ComptimeRuntime.wat, of(.commonJS));
    try std.testing.expectEqual(ComptimeRuntime.wat, of(.wasm));
    try std.testing.expectEqual(ComptimeRuntime.beam, current());
    const prev = select(.wat);
    defer _ = select(prev);
    try std.testing.expectEqual(ComptimeRuntime.wat, current());
}

test "a native build carries both runtimes" {
    try std.testing.expect(can_spawn);
    try std.testing.expect(available(.beam));
    try std.testing.expect(available(.wat));
}

test "equivalent: replies byte for byte, runtime errors by class and reason" {
    const alloc = std.testing.allocator;
    var a = "{\"kind\":\"code\",\"source\":\"x\"}".*;
    var b = "{\"source\":\"x\",\"kind\":\"code\"}".*;
    var c = "{\"kind\":\"value\",\"source\":\"x\"}".*;
    try std.testing.expect(try equivalent(alloc, .{ .response = .{ .ok = &a } }, .{ .response = .{ .ok = &b } }));
    try std.testing.expect(!try equivalent(alloc, .{ .response = .{ .ok = &a } }, .{ .response = .{ .ok = &c } }));
    var e1 = "error:{badkey,x}\n[{m,f,1}]".*;
    var e2 = "error:{badkey,x}".*;
    try std.testing.expect(try equivalent(alloc, .{ .response = .{ .runtime_error = &e1 } }, .{ .response = .{ .runtime_error = &e2 } }));
}
