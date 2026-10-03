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

/// Run the linked module `wasm` with the ETF argument `arg`.
pub fn evalWithArg(alloc: std.mem.Allocator, wasm: []const u8, arg: []const u8) Error!Response {
    if (comptime builtin.cpu.arch.isWasm()) return evalHost(alloc, wasm, arg) else return evalNative(alloc, wasm, arg);
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

fn evalNative(alloc: std.mem.Allocator, wasm: []const u8, arg: []const u8) Error!Response {
    const env = c.m3_NewEnvironment() orelse return error.OutOfMemory;
    defer c.m3_FreeEnvironment(env);
    const runtime = c.m3_NewRuntime(env, stack_bytes, null) orelse return error.OutOfMemory;
    defer c.m3_FreeRuntime(runtime);

    var module: c.IM3Module = null;
    if (c.m3_ParseModule(env, &module, wasm.ptr, @intCast(wasm.len))) |err| {
        return .{ .compile_error = try std.fmt.allocPrint(alloc, "wasm3 could not parse the module: {s}", .{std.mem.span(err)}) };
    }
    if (c.m3_LoadModule(runtime, module)) |err| {
        c.m3_FreeModule(module);
        return .{ .compile_error = try std.fmt.allocPrint(alloc, "wasm3 could not load the module: {s}", .{std.mem.span(err)}) };
    }

    var vm: Vm = .{ .alloc = alloc, .runtime = runtime };
    _ = vm.call("bp_init", &.{}) catch |e| return vm.trapped(e);
    const ptr = vm.call("rt_alloc", &.{@intCast(arg.len)}) catch |e| return vm.trapped(e);
    const mem = vm.memory() orelse return .{ .runtime_error = try alloc.dupe(u8, "wasm3: the module has no memory") };
    if (@as(usize, ptr) + arg.len > mem.len) return .{ .runtime_error = try alloc.dupe(u8, "wasm3: the argument does not fit the module's memory") };
    @memcpy(mem[ptr..][0..arg.len], arg);

    const reply = vm.call("bp_main", &.{ ptr, @intCast(arg.len) }) catch |e| return vm.trapped(e);
    const pending = vm.call("rt_pending", &.{}) catch |e| return vm.trapped(e);
    if (reply == 0 or pending != 0) {
        const class = vm.call("rt_class", &.{}) catch |e| return vm.trapped(e);
        const reason = vm.call("rt_reason", &.{}) catch |e| return vm.trapped(e);
        const text = vm.call("rt_describe", &.{ class, reason }) catch |e| return vm.trapped(e);
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
    return evalWithArg(alloc, ok.wasm, try etf.encode(arena_state.allocator(), arg));
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

test "a construct outside the subset is refused before anything runs" {
    const built = try program.build("bp@wat_test_refuse", "-module(bp@wat_test_refuse).\n-export([main/1]).\nmain(_) -> self().\n");
    try std.testing.expect(built == .refused);
    try std.testing.expect(std.mem.indexOf(u8, built.refused, "self/0") != null);
}
