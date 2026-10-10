//! The wat comptime runtime's executor: a linked module (`wat/program.zig`)
//! run **in-process** on wasm3 — no child process, no pipe, no file.
//!
//! One evaluation is one fresh wasm3 runtime (its own linear memory, so the
//! body's arena never outlives it): `bp_init` starts the arena past the
//! module's literals, `rt_alloc` makes room for the ETF argument the evaluator
//! encoded with `etf.zig` (the same bytes the BEAM runtime receives), and
//! `bp_main(ptr, len)` answers the reply binary — the JSON `main/1` encoded —
//! or 0 with an exception pending, whose `~p` text (`rt_describe`) is the
//! runtime error. A trap of the engine (a stack overflow, an out-of-bounds
//! access) is a runtime error carrying wasm3's message.
//!
//! On a wasm host (the browser build, front 18 step 5) there is no wasm3: the
//! executor is the page's engine, reached through three host imports the JS
//! glue serves (`modules/compiler-web/glue.js`): `bp_host.run_module(wasm,
//! arg) → status` instantiates the linked bytes and runs the same export
//! sequence as here, keeping the answer on the JS side;
//! `bp_host.result_len()` and `bp_host.result_copy(dst)` bring it back into
//! the compiler's memory. Status 0 is the reply, 1 a runtime error (the
//! exception's `Class:Reason`, or the engine's trap message), 2 the engine
//! refusing the module.
const std = @import("std");
const builtin = @import("builtin");
const stages = @import("stages.zig");

const c = if (builtin.cpu.arch.isWasm()) struct {} else @cImport({
    @cInclude("wasm3.h");
});

/// The browser build's engine (see the file comment).
const host = if (builtin.cpu.arch.isWasm()) struct {
    extern "bp_host" fn run_module(wasm_ptr: [*]const u8, wasm_len: usize, arg_ptr: [*]const u8, arg_len: usize) u32;
    extern "bp_host" fn result_len() usize;
    extern "bp_host" fn result_copy(dst: [*]u8) void;
} else struct {};

pub const Response = union(enum) {
    /// The reply bytes (`main`'s JSON).
    ok: []u8,
    /// The module did not load (the engine rejected it).
    compile_error: []u8,
    /// `main` raised, or the engine trapped.
    runtime_error: []u8,

    pub fn payload(self: Response) []u8 {
        return switch (self) {
            inline else => |p| p,
        };
    }
};

/// Interpreter stack per evaluation. Erlang loops are recursion and the
/// lowering has no tail calls, so a body's depth is its iteration count.
const stack_bytes: u32 = 8 * 1024 * 1024;

pub const Error = std.mem.Allocator.Error;

/// Run the linked module `wasm` with the ETF argument `arg`. `key` is the
/// module's content key — its atom, the hash of the Erlang text `wasm` was
/// lowered from (`wat/program.zig` caches the bytes under the same key): an
/// evaluation of a module this process has already instantiated reuses that
/// instance (`Kept`), reset to the state its load left.
pub fn evalWithArg(alloc: std.mem.Allocator, key: []const u8, wasm: []const u8, arg: []const u8) Error!Response {
    if (comptime builtin.cpu.arch.isWasm()) return evalHost(alloc, wasm, arg) else return evalNative(alloc, key, wasm, arg);
}

fn evalHost(alloc: std.mem.Allocator, wasm: []const u8, arg: []const u8) Error!Response {
    const status = host.run_module(wasm.ptr, wasm.len, arg.ptr, arg.len);
    const text = try alloc.alloc(u8, host.result_len());
    host.result_copy(text.ptr);
    return switch (status) {
        0 => .{ .ok = text },
        2 => .{ .compile_error = text },
        else => .{ .runtime_error = text },
    };
}

// ── the kept instances ───────────────────────────────────────────────────────
//
// A fresh wasm3 environment, runtime, parse and load per evaluation, and the
// lazy compile of every function the body reaches on its first call, were the
// largest per-evaluation cost left (front 14 step 2: 0.34 ms instance + 0.37 ms
// run of an N=200 build's 1.1 ms/eval). Every call site of one declaration
// runs the same module, so the instance is kept, keyed by the module's content
// key, and reset before each evaluation to the exact state `m3_LoadModule`
// left: linear memory resized to its load-time page count and overwritten with
// the bytes it held then (data segments, the runtime's statics, zeros), every
// global set back to its load-time value. What survives is what is a function
// of the bytes alone: the parsed module and its compiled code. An evaluation
// therefore starts where a fresh instance would — a body cannot see what a
// previous call site left — and an instance an engine trap interrupted is
// dropped, never reused. The cache lives in this process only (decision 229:
// no runtime survives a build), bounded by `max_kept`, the oldest dropped first.

const wasm3_env = if (builtin.cpu.arch.isWasm()) struct {} else @cImport({
    @cInclude("m3_env.h");
});

/// Instances kept at once. One per declaration a build evaluates; a build with
/// more evaluates the extra ones on instances it re-creates.
const max_kept = 16;

const Kept = struct {
    key: []u8,
    /// wasm3 reads a function's body from the module bytes when it first
    /// compiles it, so the instance owns its copy.
    wasm: []u8,
    env: c.IM3Environment,
    runtime: c.IM3Runtime,
    /// Linear memory as `m3_LoadModule` left it.
    memory: []u8,
    /// Every global's value as `m3_LoadModule` left it.
    globals: []i64,

    fn create(key: []const u8, wasm: []const u8, alloc: std.mem.Allocator, failure: *?[]u8) Error!?*Kept {
        const k = try kept_alloc.create(Kept);
        k.* = .{ .key = &.{}, .wasm = &.{}, .env = null, .runtime = null, .memory = &.{}, .globals = &.{} };
        errdefer k.destroy();
        k.key = try kept_alloc.dupe(u8, key);
        k.wasm = try kept_alloc.dupe(u8, wasm);
        k.env = c.m3_NewEnvironment() orelse return error.OutOfMemory;
        k.runtime = c.m3_NewRuntime(k.env, stack_bytes, null) orelse return error.OutOfMemory;

        var module: c.IM3Module = null;
        if (c.m3_ParseModule(k.env, &module, k.wasm.ptr, @intCast(k.wasm.len))) |err| {
            failure.* = try std.fmt.allocPrint(alloc, "wasm3 could not parse the module: {s}", .{std.mem.span(err)});
            k.destroy();
            return null;
        }
        if (c.m3_LoadModule(k.runtime, module)) |err| {
            c.m3_FreeModule(module);
            failure.* = try std.fmt.allocPrint(alloc, "wasm3 could not load the module: {s}", .{std.mem.span(err)});
            k.destroy();
            return null;
        }
        var size: u32 = 0;
        if (c.m3_GetMemory(k.runtime, &size, 0)) |p| k.memory = try kept_alloc.dupe(u8, p[0..size]);
        const m: *wasm3_env.M3Module = @ptrCast(@alignCast(module));
        k.globals = try kept_alloc.alloc(i64, m.numGlobals);
        for (k.globals, 0..) |*g, i| g.* = m.globals[i].unnamed_0.intValue;
        return k;
    }

    /// Back to the state `m3_LoadModule` left (see the section comment).
    fn reset(k: *Kept) bool {
        const rt: *wasm3_env.M3Runtime = @ptrCast(@alignCast(k.runtime));
        const pages: u32 = @intCast(k.memory.len / 65536);
        if (rt.memory.numPages != pages and wasm3_env.ResizeMemory(rt, pages) != null) return false;
        var size: u32 = 0;
        const p = c.m3_GetMemory(k.runtime, &size, 0);
        if (size != k.memory.len) return false;
        if (p) |mem| @memcpy(mem[0..size], k.memory);
        const m: *wasm3_env.M3Module = @ptrCast(@alignCast(rt.modules));
        if (m.numGlobals != k.globals.len) return false;
        for (k.globals, 0..) |g, i| m.globals[i].unnamed_0.intValue = g;
        c.m3_ResetErrorInfo(k.runtime);
        return true;
    }

    fn destroy(k: *Kept) void {
        // The runtime frees the modules loaded into it.
        if (k.runtime != null) c.m3_FreeRuntime(k.runtime);
        if (k.env != null) c.m3_FreeEnvironment(k.env);
        kept_alloc.free(k.globals);
        kept_alloc.free(k.memory);
        kept_alloc.free(k.wasm);
        kept_alloc.free(k.key);
        kept_alloc.destroy(k);
    }
};

const kept_alloc = std.heap.page_allocator;
var kept_lock: std.atomic.Value(u8) = .init(0);
/// Oldest first. An instance in use is out of the list, so two threads never
/// share one: the second evaluation of a module in flight builds its own.
var kept: std.ArrayListUnmanaged(*Kept) = .empty;

fn lockKept() void {
    while (kept_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlockKept() void {
    kept_lock.store(0, .release);
}

/// The kept instance of `key` taken out of the list, or null.
fn take(key: []const u8, wasm: []const u8) ?*Kept {
    lockKept();
    defer unlockKept();
    for (kept.items, 0..) |k, i| {
        if (!std.mem.eql(u8, k.key, key)) continue;
        _ = kept.orderedRemove(i);
        // The same key is the same bytes; a length that differs is a key
        // reused for other bytes (a test), and the instance is not this one.
        if (k.wasm.len == wasm.len) return k;
        k.destroy();
        return null;
    }
    return null;
}

/// Put `k` back as the newest instance, dropping the oldest past `max_kept`
/// (or `k` itself, when the list cannot grow).
fn keep(k: *Kept) void {
    lockKept();
    defer unlockKept();
    for (kept.items) |other| if (std.mem.eql(u8, other.key, k.key)) {
        // Another thread kept the same module while this one ran.
        k.destroy();
        return;
    };
    if (kept.items.len >= max_kept) kept.orderedRemove(0).destroy();
    kept.append(kept_alloc, k) catch k.destroy();
}

fn evalNative(alloc: std.mem.Allocator, key: []const u8, wasm: []const u8, arg: []const u8) Error!Response {
    const t_instance = stages.start();
    const k: *Kept = blk: {
        if (take(key, wasm)) |k| {
            if (k.reset()) break :blk k;
            k.destroy();
        }
        var failure: ?[]u8 = null;
        break :blk try Kept.create(key, wasm, alloc, &failure) orelse return .{ .compile_error = failure.? };
    };
    stages.stop(.instance, t_instance);
    const t_run = stages.start();
    defer stages.stop(.run, t_run);

    var vm: Vm = .{ .alloc = alloc, .runtime = k.runtime };
    const response = run(&vm, arg) catch |e| {
        k.destroy();
        return switch (e) {
            error.Trap => vm.trapped(error.Trap),
            error.OutOfMemory => error.OutOfMemory,
        };
    };
    // An engine trap leaves the interpreter mid-call (`binary` answers one as
    // text): such an instance is never reused.
    if (vm.last.len == 0) keep(k) else k.destroy();
    return response;
}

fn run(vm: *Vm, arg: []const u8) (Error || error{Trap})!Response {
    const alloc = vm.alloc;
    _ = try vm.call("bp_init", &.{});
    const ptr = try vm.call("rt_alloc", &.{@intCast(arg.len)});
    const mem = vm.memory() orelse return .{ .runtime_error = try alloc.dupe(u8, "wasm3: the module has no memory") };
    if (@as(usize, ptr) + arg.len > mem.len) return .{ .runtime_error = try alloc.dupe(u8, "wasm3: the argument does not fit the module's memory") };
    @memcpy(mem[ptr..][0..arg.len], arg);

    const reply = try vm.call("bp_main", &.{ ptr, @intCast(arg.len) });
    const pending = try vm.call("rt_pending", &.{});
    if (reply == 0 or pending != 0) {
        const class = try vm.call("rt_class", &.{});
        const reason = try vm.call("rt_reason", &.{});
        const text = try vm.call("rt_describe", &.{ class, reason });
        return .{ .runtime_error = try vm.binary(text) };
    }
    return .{ .ok = try vm.binary(reply) };
}

const Vm = struct {
    alloc: std.mem.Allocator,
    runtime: if (builtin.cpu.arch.isWasm()) void else c.IM3Runtime,
    /// wasm3's message for the last failed call.
    last: []const u8 = "",

    fn call(vm: *Vm, name: [*:0]const u8, args: []const u32) error{Trap}!u32 {
        var f: c.IM3Function = null;
        if (c.m3_FindFunction(&f, vm.runtime, name)) |err| {
            vm.last = std.mem.span(err);
            return error.Trap;
        }
        var ptrs: [4]?*const anyopaque = .{null} ** 4;
        var vals: [4]u32 = undefined;
        for (args, 0..) |a, i| {
            vals[i] = a;
            ptrs[i] = &vals[i];
        }
        if (c.m3_Call(f, @intCast(args.len), @ptrCast(&ptrs))) |err| {
            vm.last = std.mem.span(err);
            return error.Trap;
        }
        if (c.m3_GetRetCount(f) == 0) return 0;
        var out: u32 = 0;
        var outs: [1]?*const anyopaque = .{&out};
        if (c.m3_GetResults(f, 1, @ptrCast(&outs))) |err| {
            vm.last = std.mem.span(err);
            return error.Trap;
        }
        return out;
    }

    fn memory(vm: *Vm) ?[]u8 {
        var size: u32 = 0;
        const p = c.m3_GetMemory(vm.runtime, &size, 0) orelse return null;
        return p[0..size];
    }

    /// The bytes of binary term `t`.
    fn binary(vm: *Vm, t: u32) Error![]u8 {
        const p = vm.call("rt_bin_ptr", &.{t}) catch return vm.alloc.dupe(u8, "wasm3: could not read the reply");
        const n = vm.call("rt_bin_len", &.{t}) catch return vm.alloc.dupe(u8, "wasm3: could not read the reply");
        const mem = vm.memory() orelse return vm.alloc.dupe(u8, "wasm3: the module has no memory");
        if (@as(usize, p) + n > mem.len) return vm.alloc.dupe(u8, "wasm3: the reply lies outside the module's memory");
        return vm.alloc.dupe(u8, mem[p..][0..n]);
    }

    fn trapped(vm: *Vm, _: error{Trap}) Error!Response {
        return .{ .runtime_error = try std.fmt.allocPrint(vm.alloc, "wasm3: {s}", .{vm.last}) };
    }
};

// ── tests ────────────────────────────────────────────────────────────────────

const program = @import("wat/program.zig");
const etf = @import("etf.zig");
const Term = @import("../../codegen/beam/term.zig").Term;

fn runSource(alloc: std.mem.Allocator, module: []const u8, code: []const u8, arg: Term) !Response {
    const built = try program.build(module, code);
    const ok = switch (built) {
        .ok => |o| o,
        .refused => |why| {
            std.debug.print("\nrefused: {s}\n", .{why});
            return error.TestUnexpectedResult;
        },
    };
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    return evalWithArg(alloc, module, ok.wasm, try etf.encode(arena_state.allocator(), arg));
}

test "a module importing the template prelude runs in-process and answers its JSON" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_add).
        \\-export([main/1]).
        \\-import(bp_comptime_template, [expr/1, '__bp_reply'/1, '__bp_add'/2, '__bp_text'/1]).
        \\
        \\main({Arg0}) ->
        \\    try
        \\        json:encode('__bp_reply'(expr('__bp_add'(Arg0, 2))))
        \\    catch
        \\        Class:Reason ->
        \\            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
        \\    end.
    ;
    const r = try runSource(alloc, "bp@wat_test_add", code, Term.tupleOf(&.{.{ .integer = 40 }}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("{\"value\":42,\"kind\":\"value\"}", r.ok);
}

test "an exception out of main is a runtime error carrying the reason" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_raise).
        \\-export([main/1]).
        \\
        \\main({Arg0}) -> maps:get(missing, Arg0).
    ;
    const r = try runSource(alloc, "bp@wat_test_raise", code, Term.tupleOf(&.{.{ .map = &.{} }}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("error:{badkey,missing}", r.runtime_error);
}

test "a body's prints are captured in the module, never written to the compiler's stdout" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_print).
        \\-export([main/1]).
        \\
        \\main({Arg0}) ->
        \\    io:format("printed ~p~n", [Arg0]),
        \\    json:encode(#{value => Arg0}).
    ;
    const r = try runSource(alloc, "bp@wat_test_print", code, Term.tupleOf(&.{.{ .integer = 7 }}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("{\"value\":7}", r.ok);
}

// ── the kept instances ───────────────────────────────────────────────────────

/// How many kept instances `key` has (0 or 1).
fn keptCount(key: []const u8) usize {
    lockKept();
    defer unlockKept();
    var n: usize = 0;
    for (kept.items) |k| {
        if (std.mem.eql(u8, k.key, key)) n += 1;
    }
    return n;
}

test "a kept instance starts every evaluation from the state its load left" {
    const alloc = std.testing.allocator;
    const module = "bp@wat_test_kept";
    // The process dictionary and a large list: the first evaluation writes the
    // one and grows linear memory for the other; the next must see neither.
    const code =
        \\-module(bp@wat_test_kept).
        \\-export([main/1]).
        \\
        \\main({Arg0}) ->
        \\    Before = get(seen),
        \\    put(seen, Arg0),
        \\    json:encode(#{before => Before, n => length(lists:seq(1, Arg0))}).
    ;
    const first = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 200000 }}));
    defer alloc.free(first.payload());
    try std.testing.expectEqualStrings("{\"before\":\"undefined\",\"n\":200000}", first.ok);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));

    // The first evaluation grew memory past its load-time size; the reset puts
    // back the load-time size and bytes.
    const k = take(module, (try program.build(module, code)).ok.wasm).?;
    try std.testing.expect(c.m3_GetMemorySize(k.runtime) > k.memory.len);
    try std.testing.expect(k.reset());
    var size: u32 = 0;
    const mem = c.m3_GetMemory(k.runtime, &size, 0).?;
    try std.testing.expectEqualSlices(u8, k.memory, mem[0..size]);
    keep(k);

    const second = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 3 }}));
    defer alloc.free(second.payload());
    try std.testing.expectEqualStrings("{\"before\":\"undefined\",\"n\":3}", second.ok);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));
}

test "an exception keeps the instance; an engine trap drops it, and the next evaluation answers" {
    const alloc = std.testing.allocator;
    const module = "bp@wat_test_kept_trap";
    const code =
        \\-module(bp@wat_test_kept_trap).
        \\-export([main/1]).
        \\
        \\main({Arg0}) -> json:encode(#{depth => depth(Arg0)}).
        \\
        \\depth(0) -> 0;
        \\depth(N) when N > 0 -> 1 + depth(N - 1).
    ;
    const raised = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = -1 }}));
    defer alloc.free(raised.payload());
    try std.testing.expect(raised == .runtime_error);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));

    // The interpreter's stack runs out mid-call: a trap, not an exception.
    const trapped = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 100_000_000 }}));
    defer alloc.free(trapped.payload());
    try std.testing.expect(trapped == .runtime_error);
    try std.testing.expect(std.mem.startsWith(u8, trapped.runtime_error, "wasm3: "));
    try std.testing.expectEqual(@as(usize, 0), keptCount(module));

    const after = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 5 }}));
    defer alloc.free(after.payload());
    try std.testing.expectEqualStrings("{\"depth\":5}", after.ok);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));
}

// ── the limits (`AGENTS.md` § Limits): each pinned where it raises ──────────

test "limit 1: no process, mailbox or ETS table — what `safe_call` isolates is refused by name" {
    const cases = [_]struct { []const u8, []const u8, []const u8 }{
        .{
            \\-module(bp@wat_test_limit1a).
            \\-export([main/1]).
            \\main(_) -> spawn(fun() -> ok end).
            ,
            "spawn/1",
            "bp@wat_test_limit1a",
        },
        .{
            \\-module(bp@wat_test_limit1b).
            \\-export([main/1]).
            \\main(_) -> receive X -> X end.
            ,
            "`receive`",
            "bp@wat_test_limit1b",
        },
        .{
            \\-module(bp@wat_test_limit1c).
            \\-export([main/1]).
            \\main(_) -> ets:new(t, []).
            ,
            "ets:new/2",
            "bp@wat_test_limit1c",
        },
    };
    for (cases) |case_| {
        const built = try program.build(case_[2], case_[0]);
        try std.testing.expect(built == .refused);
        if (std.mem.indexOf(u8, built.refused, case_[1]) == null) {
            std.debug.print("\nrefusal without {s}: {s}\n", .{ case_[1], built.refused });
            return error.TestUnexpectedResult;
        }
    }
}

test "limit 3: Unicode case mapping of a non-ASCII letter raises bp_wat_runtime" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_limit3).
        \\-export([main/1]).
        \\
        \\main({Arg0}) -> string:uppercase(Arg0).
    ;
    const r = try runSource(alloc, "bp@wat_test_limit3", code, Term.tupleOf(&.{Term.str("\xc3\xa9t\xc3\xa9")}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("error:{bp_wat_runtime,<<\"string case mapping of a non-ASCII character\">>}", r.runtime_error);
}

test "limit 4: an integer beyond 64 bits raises bp_wat_runtime" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_limit4).
        \\-export([main/1]).
        \\
        \\main({Arg0}) -> Arg0 * Arg0.
    ;
    const r = try runSource(alloc, "bp@wat_test_limit4", code, Term.tupleOf(&.{.{ .integer = 4294967296 }}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("error:{bp_wat_runtime,<<\"integer beyond 64 bits (a bignum)\">>}", r.runtime_error);
}

test "a construct outside the subset is refused before anything runs" {
    const built = try program.build("bp@wat_test_refuse", "-module(bp@wat_test_refuse).\n-export([main/1]).\nmain(_) -> self().\n");
    try std.testing.expect(built == .refused);
    try std.testing.expect(std.mem.indexOf(u8, built.refused, "self/0") != null);
}
