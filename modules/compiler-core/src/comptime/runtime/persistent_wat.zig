//! The wat comptime runtime's executor: a linked module (`wat/program.zig`)
//! run **in-process** on the host's engine — no child process, no pipe, no
//! file (decision 543).
//!
//! **One interface, two engines.** The contract is `bp_host.run_module`'s
//! (`modules/compiler-web/glue.js`): compile and instantiate the linked
//! module — it imports nothing: its host functions (`env.bp_term_alloc`,
//! `env.bp_term_static`, `env.bp_call<N>`) are bound when it is linked
//! (`wat/runtime_module.zig`), so an import is the engine's refusal —, run
//! the export sequence (`bp_init` starts the arena past the literals,
//! `rt_alloc` makes room for the ETF argument the evaluator encoded with
//! `etf.zig`, the argument written into the module's memory, `bp_main(ptr,
//! len)` → the reply binary, or 0 with an exception pending whose `~p` text,
//! `rt_describe(rt_class(), rt_reason())`, is the runtime error), read the
//! answer out of the module's memory (`rt_bin_ptr` / `rt_bin_len`); a trap is
//! a runtime error carrying the engine's message, a module the engine refuses
//! a compile error. Every answer is std-wasm's, never the engine's (434 (5)).
//!
//! - **Natively** (`botopink`, `botopink-lsp`) the engine is wasmtime,
//!   embedded through its C API (`Wasmtime` below; the library `build.zig`
//!   links, pinned by `build.zig.zon`).
//! - **On a wasm host** (the browser build, `modules/compiler-web`) it is the
//!   page's `WebAssembly`, reached through three host imports the JS glue
//!   serves: `bp_host.run_module(wasm, arg) → status` runs the sequence above
//!   and keeps the answer on the JS side; `bp_host.result_len()` and
//!   `bp_host.result_copy(dst)` bring it back into the compiler's memory.
//!   Status 0 is the reply, 1 a runtime error, 2 the engine refusing the
//!   module (`Page` below).
const std = @import("std");
const builtin = @import("builtin");
const stages = @import("stages.zig");

const is_wasm = builtin.cpu.arch.isWasm();

/// glibc's `malloc_trim`: returns the free memory of every arena to the system.
extern "c" fn malloc_trim(pad: usize) c_int;

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

pub const Error = std.mem.Allocator.Error;

/// The engine this build runs a comptime module on.
const Engine = if (is_wasm) Page else Wasmtime;

/// Run the linked module `wasm` with the ETF argument `arg`. `key` is the
/// module's content key — its atom, the hash of the Erlang text `wasm` was
/// lowered from (`wat/program.zig` caches the bytes under the same key): the
/// native engine compiles a module once per process and keeps the compiled
/// code under it.
pub fn evalWithArg(alloc: std.mem.Allocator, io: std.Io, key: []const u8, wasm: []const u8, arg: []const u8) Error!Response {
    return Engine.run(alloc, io, key, wasm, arg);
}

/// The directory of the compiled-module cache (`Wasmtime.compiled`): set once
/// by a command that knows its cache root (`runtime.useCompiledCache`), null
/// for any other compilation (the language server's, a test's) — those keep
/// their compiled modules in the process only.
pub var compiled_dir: ?[]const u8 = null;
/// `--cold`: read no compiled module from `compiled_dir`, write what compiled.
pub var compiled_cold: bool = false;

/// Stop every body running now (a trap, `interrupt`), whatever thread runs
/// it. Signal-safe. A no-op on the page's engine.
pub fn interrupt() void {
    if (comptime !is_wasm) Wasmtime.interrupt();
}

/// The runtime error an interrupted body answers (decision 878): the trap
/// code's name behind the engine's prefix. The evaluators read it as the
/// `comptime-interrupted` refusal.
pub const interrupted_reply = "wasmtime: interrupted";

/// Whether a comptime body is running now, on any thread. Signal-safe: the
/// CLI's SIGINT handler interrupts only then, and otherwise ends the process
/// as any process ends (decision 878).
pub fn running() bool {
    if (comptime is_wasm) return false;
    return Wasmtime.bodies.load(.acquire) != 0;
}

// ── the page's engine (`modules/compiler-web`) ───────────────────────────────

const Page = struct {
    const host = if (is_wasm) struct {
        extern "bp_host" fn run_module(wasm_ptr: [*]const u8, wasm_len: usize, arg_ptr: [*]const u8, arg_len: usize) u32;
        extern "bp_host" fn result_len() usize;
        extern "bp_host" fn result_copy(dst: [*]u8) void;
    } else struct {};

    fn run(alloc: std.mem.Allocator, io: std.Io, key: []const u8, wasm: []const u8, arg: []const u8) Error!Response {
        _ = io;
        _ = key;
        const status = host.run_module(wasm.ptr, wasm.len, arg.ptr, arg.len);
        const text = try alloc.alloc(u8, host.result_len());
        host.result_copy(text.ptr);
        return switch (status) {
            0 => .{ .ok = text },
            2 => .{ .compile_error = text },
            else => .{ .runtime_error = text },
        };
    }
};

// ── the export sequence, over any instance ───────────────────────────────────

/// `bp_host.run_module`'s sequence (the file comment) over an instance that
/// can `call(name, args) error{Trap}!u32`, answer its `memory() ?[]u8` and
/// say why it `trapped`. The page's engine runs the same sequence in
/// `glue.js` `runComptime`.
fn runSequence(inst: anytype, alloc: std.mem.Allocator, arg: []const u8) (Error || error{Trap})!Response {
    _ = try inst.call("bp_init", &.{});
    const ptr = try inst.call("rt_alloc", &.{@intCast(arg.len)});
    const mem = inst.memory() orelse return .{ .runtime_error = try alloc.dupe(u8, "the module has no memory") };
    if (@as(usize, ptr) + arg.len > mem.len) return .{ .runtime_error = try alloc.dupe(u8, "the argument does not fit the module's memory") };
    @memcpy(mem[ptr..][0..arg.len], arg);

    const reply = try inst.call("bp_main", &.{ ptr, @intCast(arg.len) });
    const pending = try inst.call("rt_pending", &.{});
    if (reply == 0 or pending != 0) {
        const class = try inst.call("rt_class", &.{});
        const reason = try inst.call("rt_reason", &.{});
        const text = try inst.call("rt_describe", &.{ class, reason });
        return .{ .runtime_error = try binary(inst, alloc, text) };
    }
    return .{ .ok = try binary(inst, alloc, reply) };
}

/// The bytes of binary term `t`, copied out of the module's memory.
fn binary(inst: anytype, alloc: std.mem.Allocator, t: u32) (Error || error{Trap})![]u8 {
    const p = try inst.call("rt_bin_ptr", &.{t});
    const n = try inst.call("rt_bin_len", &.{t});
    const mem = inst.memory() orelse return alloc.dupe(u8, "the module has no memory");
    if (@as(usize, p) + n > mem.len) return alloc.dupe(u8, "the reply lies outside the module's memory");
    return alloc.dupe(u8, mem[p..][0..n]);
}

// ── wasmtime (the native compiler) ───────────────────────────────────────────
//
// One engine per process, its configuration fixed here (decision 67: no
// flag): exception handling on (decision 518 — the engine runs what a wasm
// program runs), epoch interruption on (`interrupt`; there is no budget,
// 380 (2): a store's deadline is the next tick, which only `interrupt`
// gives), a wasm stack of `wasm_stack` bytes. A module is compiled once per
// process and kept under its key (`Compiled`, at most `max_compiled`, the
// oldest dropped first; a compiled module is immutable and shared by every
// thread). Every evaluation instantiates it in a store of its own, so a body
// never sees what a previous call site left and an instance a trap
// interrupted is simply dropped. Nothing outlives the process (decision 229).

const c = if (is_wasm) struct {} else @cImport({
    @cInclude("wasmtime.h");
});

/// The wasm stack a body runs on. Erlang loops are recursion and the lowering
/// has no tail calls, so a body's depth is its iteration count: the bound is
/// an 8 MiB value stack measured in wasmtime's frames, with room.
const wasm_stack: usize = 64 * 1024 * 1024;
/// The native stack of the thread a body runs on: the wasm stack and the
/// host's own frames under it.
const thread_stack: usize = wasm_stack + 16 * 1024 * 1024;

/// Compiled modules kept at once. A build with more distinct comptime
/// modules than this compiles the extra ones again when they recur.
const max_compiled = 64;

const Wasmtime = struct {
    var engine: ?*c.wasm_engine_t = null;
    var engine_lock: std.atomic.Value(u8) = .init(0);

    const Compiled = struct {
        key: []u8,
        len: usize,
        module: *c.wasmtime_module_t,

        fn destroy(m: *Compiled) void {
            c.wasmtime_module_delete(m.module);
            kept_alloc.free(m.key);
            kept_alloc.destroy(m);
        }
    };

    const kept_alloc = std.heap.page_allocator;
    var kept_lock: std.atomic.Value(u8) = .init(0);
    /// Oldest first.
    var kept: std.ArrayListUnmanaged(*Compiled) = .empty;

    fn lock(l: *std.atomic.Value(u8)) void {
        while (l.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
    }

    fn unlock(l: *std.atomic.Value(u8)) void {
        l.store(0, .release);
    }

    fn theEngine() Error!*c.wasm_engine_t {
        lock(&engine_lock);
        defer unlock(&engine_lock);
        if (engine) |e| return e;
        const config = c.wasm_config_new() orelse return error.OutOfMemory;
        c.wasmtime_config_wasm_exceptions_set(config, true);
        c.wasmtime_config_epoch_interruption_set(config, true);
        c.wasmtime_config_max_wasm_stack_set(config, wasm_stack);
        // The engine refuses a wasm stack past its fibers' stacks, which no
        // call here uses (every call is synchronous).
        c.wasmtime_config_async_stack_size_set(config, wasm_stack + 1024 * 1024);
        // Takes `config`.
        engine = c.wasm_engine_new_with_config(config) orelse return error.OutOfMemory;
        return engine.?;
    }

    /// The bodies running now (`instantiateAndRun`), for `running`.
    var bodies: std.atomic.Value(u32) = .init(0);

    fn interrupt() void {
        if (@atomicLoad(?*c.wasm_engine_t, &engine, .acquire)) |e| c.wasmtime_engine_increment_epoch(e);
    }

    /// The compiled module of `key`, compiled now when no thread kept it;
    /// null with `failure` set when the engine refuses the bytes.
    fn compiled(alloc: std.mem.Allocator, io: std.Io, key: []const u8, wasm: []const u8, failure: *?[]u8) Error!?*c.wasmtime_module_t {
        {
            lock(&kept_lock);
            defer unlock(&kept_lock);
            for (kept.items, 0..) |m, i| {
                if (!std.mem.eql(u8, m.key, key)) continue;
                // The same key is the same bytes; a length that differs is a
                // key reused for other bytes (a test), and the module is not
                // this one.
                if (m.len == wasm.len) {
                    // Newest last.
                    _ = kept.orderedRemove(i);
                    kept.appendAssumeCapacity(m);
                    return c.wasmtime_module_clone(m.module);
                }
                kept.orderedRemove(i).destroy();
                break;
            }
        }
        const eng = try theEngine();
        var module: ?*c.wasmtime_module_t = null;
        const file = if (compiled_dir) |dir| try cachedPath(alloc, dir, wasm) else null;
        if (file) |path| if (!compiled_cold) {
            // A file the engine refuses (another wasmtime, a torn write) is
            // compiled again and written over.
            if (c.wasmtime_module_deserialize_file(eng, path.ptr, &module)) |err| c.wasmtime_error_delete(err);
        };
        if (module == null) {
            if (c.wasmtime_module_new(eng, wasm.ptr, wasm.len, &module)) |err| {
                failure.* = try errorText(alloc, "wasmtime could not compile the module: ", err);
                return null;
            }
            if (file) |path| writeCompiled(alloc, io, path, module.?);
            // Compiling leaves the allocator holding the compiler's working
            // memory (tens of MB a module, in per-thread arenas that never give
            // it back): a project of many distinct comptime modules held it for
            // each one (144 B-117).
            if (comptime builtin.os.tag == .linux and builtin.abi.isGnu()) _ = malloc_trim(0);
        }
        // The linked module imports nothing (the file comment).
        var imports: c.wasm_importtype_vec_t = undefined;
        c.wasmtime_module_imports(module, &imports);
        defer c.wasm_importtype_vec_delete(&imports);
        if (imports.size > 0) {
            const imp = imports.data[0];
            const m = c.wasm_importtype_module(imp);
            const n = c.wasm_importtype_name(imp);
            c.wasmtime_module_delete(module);
            failure.* = try std.fmt.allocPrint(alloc, "the module imports {s}.{s}: a comptime module's host functions are bound when it is linked, the engine serves no import", .{ m.*.data[0..m.*.size], n.*.data[0..n.*.size] });
            return null;
        }
        keep(key, wasm.len, module.?);
        return module.?;
    }

    /// `<compiled_dir>/<sha256 of the bytes>.cwasm`: the compiled form of
    /// exactly these bytes, whichever module key names them.
    fn cachedPath(alloc: std.mem.Allocator, dir: []const u8, wasm: []const u8) Error![:0]u8 {
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(wasm, &digest, .{});
        const hex = std.fmt.bytesToHex(digest, .lower);
        return std.fmt.allocPrintSentinel(alloc, "{s}/{s}.cwasm", .{ dir, hex }, 0);
    }

    /// Write `module`'s compiled form to `path`: staged under a name no
    /// other writer uses, then renamed over it (no lock: a reader sees a
    /// whole file or none). A write that fails costs a compile next time.
    fn writeCompiled(alloc: std.mem.Allocator, io: std.Io, path: []const u8, module: *c.wasmtime_module_t) void {
        var bytes: c.wasm_byte_vec_t = undefined;
        if (c.wasmtime_module_serialize(module, &bytes)) |err| {
            c.wasmtime_error_delete(err);
            return;
        }
        defer c.wasm_byte_vec_delete(&bytes);
        const cwd = std.Io.Dir.cwd();
        if (std.fs.path.dirname(path)) |d| cwd.createDirPath(io, d) catch return;
        var rand: [8]u8 = undefined;
        io.random(&rand);
        const tmp = std.fmt.allocPrint(alloc, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &rand, .little) }) catch return;
        cwd.writeFile(io, .{ .sub_path = tmp, .data = bytes.data[0..bytes.size] }) catch {
            cwd.deleteFile(io, tmp) catch {};
            return;
        };
        std.Io.Dir.rename(cwd, tmp, cwd, path, io) catch cwd.deleteFile(io, tmp) catch {};
    }

    /// Keep a clone of `module` under `key`, dropping the oldest past
    /// `max_compiled`. A failure to keep it costs a recompile, nothing else.
    fn keep(key: []const u8, len: usize, module: *c.wasmtime_module_t) void {
        const m = kept_alloc.create(Compiled) catch return;
        m.* = .{
            .key = kept_alloc.dupe(u8, key) catch {
                kept_alloc.destroy(m);
                return;
            },
            .len = len,
            .module = c.wasmtime_module_clone(module) orelse {
                kept_alloc.free(m.key);
                kept_alloc.destroy(m);
                return;
            },
        };
        lock(&kept_lock);
        defer unlock(&kept_lock);
        for (kept.items) |other| if (std.mem.eql(u8, other.key, key)) {
            // Another thread kept the same module meanwhile.
            m.destroy();
            return;
        };
        if (kept.items.len >= max_compiled) kept.orderedRemove(0).destroy();
        kept.ensureTotalCapacity(kept_alloc, max_compiled) catch {
            m.destroy();
            return;
        };
        kept.appendAssumeCapacity(m);
    }

    fn run(alloc: std.mem.Allocator, io: std.Io, key: []const u8, wasm: []const u8, arg: []const u8) Error!Response {
        const t_instance = stages.start();
        var failure: ?[]u8 = null;
        const module = try compiled(alloc, io, key, wasm, &failure) orelse return .{ .compile_error = failure.? };
        defer c.wasmtime_module_delete(module);
        stages.stop(.instance, t_instance);
        const t_run = stages.start();
        defer stages.stop(.run, t_run);

        // The body runs on a thread of its own, whose stack holds the wasm
        // stack (`wasm_stack`) whatever the calling thread's is.
        var job: Job = .{ .alloc = alloc, .module = module, .arg = arg };
        const thread = std.Thread.spawn(.{ .stack_size = thread_stack }, Job.work, .{&job}) catch {
            job.work();
            return job.out;
        };
        thread.join();
        return job.out;
    }

    const Job = struct {
        alloc: std.mem.Allocator,
        module: *c.wasmtime_module_t,
        arg: []const u8,
        out: Error!Response = error.OutOfMemory,

        fn work(job: *Job) void {
            job.out = job.instantiateAndRun();
        }

        fn instantiateAndRun(job: *Job) Error!Response {
            const alloc = job.alloc;
            _ = bodies.fetchAdd(1, .acq_rel);
            defer _ = bodies.fetchSub(1, .acq_rel);
            const store = c.wasmtime_store_new(try theEngine(), null, null) orelse return error.OutOfMemory;
            defer c.wasmtime_store_delete(store);
            const ctx = c.wasmtime_store_context(store).?;
            // Only `interrupt` moves the epoch: a body runs to its end (380 (2)).
            c.wasmtime_context_set_epoch_deadline(ctx, 1);
            var inst: Instance = .{ .alloc = alloc, .ctx = ctx, .instance = undefined };
            var trap: ?*c.wasm_trap_t = null;
            if (c.wasmtime_instance_new(ctx, job.module, null, 0, &inst.instance, &trap)) |err|
                return .{ .compile_error = try errorText(alloc, "wasmtime could not instantiate the module: ", err) };
            if (trap) |t| return .{ .runtime_error = try trapText(alloc, t) };
            return runSequence(&inst, alloc, job.arg) catch |e| switch (e) {
                error.Trap => .{ .runtime_error = inst.last orelse try alloc.dupe(u8, "wasmtime: the call failed") },
                error.OutOfMemory => error.OutOfMemory,
            };
        }
    };

    const Instance = struct {
        alloc: std.mem.Allocator,
        ctx: *c.wasmtime_context_t,
        instance: c.wasmtime_instance_t,
        /// The engine's message for the call that failed.
        last: ?[]u8 = null,

        fn call(inst: *Instance, name: []const u8, args: []const u32) error{Trap}!u32 {
            var item: c.wasmtime_extern_t = undefined;
            if (!c.wasmtime_instance_export_get(inst.ctx, &inst.instance, name.ptr, name.len, &item) or item.kind != c.WASMTIME_EXTERN_FUNC)
                return inst.fail(std.fmt.allocPrint(inst.alloc, "wasmtime: the module exports no function {s}", .{name}));
            var vals: [4]c.wasmtime_val_t = undefined;
            for (args, 0..) |a, i| {
                vals[i].kind = c.WASMTIME_I32;
                vals[i].of.i32 = @bitCast(a);
            }
            var results: [1]c.wasmtime_val_t = undefined;
            var trap: ?*c.wasm_trap_t = null;
            const nresults = funcResults(inst.ctx, &item.of.func);
            if (c.wasmtime_func_call(inst.ctx, &item.of.func, &vals, args.len, &results, nresults, &trap)) |err|
                return inst.fail(errorText(inst.alloc, "wasmtime: ", err));
            if (trap) |t| return inst.fail(trapText(inst.alloc, t));
            if (nresults == 0) return 0;
            return @bitCast(results[0].of.i32);
        }

        fn fail(inst: *Instance, text: Error![]u8) error{Trap} {
            inst.last = text catch null;
            return error.Trap;
        }

        fn memory(inst: *Instance) ?[]u8 {
            var item: c.wasmtime_extern_t = undefined;
            if (!c.wasmtime_instance_export_get(inst.ctx, &inst.instance, "memory", "memory".len, &item) or item.kind != c.WASMTIME_EXTERN_MEMORY) return null;
            const p = c.wasmtime_memory_data(inst.ctx, &item.of.memory);
            const n = c.wasmtime_memory_data_size(inst.ctx, &item.of.memory);
            return p[0..n];
        }
    };

    /// How many results `f` answers (0 or 1: every export the sequence calls
    /// answers at most one `i32`).
    fn funcResults(ctx: *c.wasmtime_context_t, f: *const c.wasmtime_func_t) usize {
        const ty = c.wasmtime_func_type(ctx, f);
        defer c.wasm_functype_delete(ty);
        return c.wasm_functype_results(ty).*.size;
    }

    /// `prefix` and the engine's message; takes `err`.
    fn errorText(alloc: std.mem.Allocator, prefix: []const u8, err: *c.wasmtime_error_t) Error![]u8 {
        defer c.wasmtime_error_delete(err);
        var msg: c.wasm_name_t = undefined;
        c.wasmtime_error_message(err, &msg);
        defer c.wasm_byte_vec_delete(&msg);
        return std.fmt.allocPrint(alloc, "{s}{s}", .{ prefix, msg.data[0..msg.size] });
    }

    /// A trap as one line, `wasmtime: <what>`: its code's name when it has
    /// one, else the first line of its message (the engine's backtrace is
    /// never part of an answer). Takes `trap`.
    fn trapText(alloc: std.mem.Allocator, trap: *c.wasm_trap_t) Error![]u8 {
        defer c.wasm_trap_delete(trap);
        var code: c.wasmtime_trap_code_t = undefined;
        if (c.wasmtime_trap_code(trap, &code)) if (trapName(code)) |name|
            return std.fmt.allocPrint(alloc, "wasmtime: {s}", .{name});
        var msg: c.wasm_message_t = undefined;
        c.wasm_trap_message(trap, &msg);
        defer c.wasm_byte_vec_delete(&msg);
        var text: []const u8 = msg.data[0..msg.size];
        if (std.mem.indexOfScalar(u8, text, 0)) |z| text = text[0..z];
        if (std.mem.indexOfScalar(u8, text, '\n')) |nl| text = text[0..nl];
        return std.fmt.allocPrint(alloc, "wasmtime: {s}", .{text});
    }

    fn trapName(code: c.wasmtime_trap_code_t) ?[]const u8 {
        return switch (code) {
            c.WASMTIME_TRAP_CODE_STACK_OVERFLOW => "call stack exhausted",
            c.WASMTIME_TRAP_CODE_MEMORY_OUT_OF_BOUNDS => "out of bounds memory access",
            c.WASMTIME_TRAP_CODE_HEAP_MISALIGNED => "misaligned memory access",
            c.WASMTIME_TRAP_CODE_TABLE_OUT_OF_BOUNDS => "undefined element: out of bounds table access",
            c.WASMTIME_TRAP_CODE_INDIRECT_CALL_TO_NULL => "uninitialized element",
            c.WASMTIME_TRAP_CODE_BAD_SIGNATURE => "indirect call type mismatch",
            c.WASMTIME_TRAP_CODE_INTEGER_OVERFLOW => "integer overflow",
            c.WASMTIME_TRAP_CODE_INTEGER_DIVISION_BY_ZERO => "integer divide by zero",
            c.WASMTIME_TRAP_CODE_BAD_CONVERSION_TO_INTEGER => "invalid conversion to integer",
            c.WASMTIME_TRAP_CODE_UNREACHABLE_CODE_REACHED => "unreachable",
            c.WASMTIME_TRAP_CODE_INTERRUPT => "interrupted",
            c.WASMTIME_TRAP_CODE_UNHANDLED_TAG => "uncaught exception",
            else => null,
        };
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
    return evalWithArg(alloc, std.testing.io, module, ok.wasm, try etf.encode(arena_state.allocator(), arg));
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

// ── the compiled modules ─────────────────────────────────────────────────────

/// How many compiled modules `key` has kept (0 or 1).
fn keptCount(key: []const u8) usize {
    Wasmtime.lock(&Wasmtime.kept_lock);
    defer Wasmtime.unlock(&Wasmtime.kept_lock);
    var n: usize = 0;
    for (Wasmtime.kept.items) |m| {
        if (std.mem.eql(u8, m.key, key)) n += 1;
    }
    return n;
}

test "the compiled module is kept; every evaluation starts from a fresh instance" {
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

    const second = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 3 }}));
    defer alloc.free(second.payload());
    try std.testing.expectEqualStrings("{\"before\":\"undefined\",\"n\":3}", second.ok);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));
}

test "an exception and an engine trap are runtime errors, and the next evaluation answers" {
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

    // The wasm stack runs out mid-call: a trap, not an exception.
    const trapped = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 100_000_000 }}));
    defer alloc.free(trapped.payload());
    try std.testing.expectEqualStrings("wasmtime: call stack exhausted", trapped.runtime_error);

    // Deep, but within the wasm stack's 8 MiB bound.
    const deep = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 100_000 }}));
    defer alloc.free(deep.payload());
    try std.testing.expectEqualStrings("{\"depth\":100000}", deep.ok);
    try std.testing.expectEqual(@as(usize, 1), keptCount(module));
}

/// Waits (bounded) until a body runs, lets it settle into its loop, then
/// interrupts it from this other thread.
fn interruptWhenRunning(io: std.Io) void {
    var waited: u32 = 0;
    while (!running() and waited < 20_000) : (waited += 1) io.sleep(std.Io.Duration.fromMilliseconds(1), .awake) catch {};
    io.sleep(std.Io.Duration.fromMilliseconds(200), .awake) catch {};
    interrupt();
}

test "decision 878: an unbounded body interrupted from another thread answers the interrupted reply, and the next one runs" {
    const alloc = std.testing.allocator;
    const module = "bp@wat_test_interrupt";
    // About 10^12 steps over one shared list: no bound a test could wait out,
    // and no growing stack or heap to trap first.
    const code =
        \\-module(bp@wat_test_interrupt).
        \\-export([main/1]).
        \\
        \\main({Arg0}) ->
        \\    L = lists:seq(1, 1000000),
        \\    lists:foreach(fun(_) -> lists:foreach(fun(_) -> ok end, L) end, lists:seq(1, Arg0)),
        \\    json:encode(#{done => Arg0}).
    ;
    const killer = try std.Thread.spawn(.{}, interruptWhenRunning, .{std.testing.io});
    const stopped = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 1_000_000 }}));
    killer.join();
    defer alloc.free(stopped.payload());
    try std.testing.expectEqualStrings(interrupted_reply, stopped.runtime_error);
    try std.testing.expect(!running());

    // A store of its own and a deadline from the current epoch: the next body runs.
    const after = try runSource(alloc, module, code, Term.tupleOf(&.{.{ .integer = 1 }}));
    defer alloc.free(after.payload());
    try std.testing.expectEqualStrings("{\"done\":1}", after.ok);
}

/// `text` (the wat text format) compiled by the engine's own reader.
fn watBytes(text: []const u8) !c.wasm_byte_vec_t {
    var out: c.wasm_byte_vec_t = undefined;
    if (c.wasmtime_wat2wasm(text.ptr, text.len, &out)) |err| {
        const msg = try Wasmtime.errorText(std.testing.allocator, "", err);
        defer std.testing.allocator.free(msg);
        std.debug.print("\nwat: {s}\n", .{msg});
        return error.TestUnexpectedResult;
    }
    return out;
}

test "the engine runs wasm exception handling (decision 518): a throw caught by a try_table" {
    const alloc = std.testing.allocator;
    // The export sequence's functions, with `bp_main` answering the binary
    // its `try_table` caught: `$t`'s payload is the reply term.
    var bytes = try watBytes(
        \\(module
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 64) "caught")
        \\  (tag $t (param i32))
        \\  (func (export "bp_init"))
        \\  (func (export "rt_alloc") (param i32) (result i32) (i32.const 128))
        \\  (func (export "rt_pending") (result i32) (i32.const 0))
        \\  (func (export "rt_class") (result i32) (i32.const 0))
        \\  (func (export "rt_reason") (result i32) (i32.const 0))
        \\  (func (export "rt_describe") (param i32 i32) (result i32) (i32.const 0))
        \\  (func (export "rt_bin_ptr") (param i32) (result i32) (local.get 0))
        \\  (func (export "rt_bin_len") (param i32) (result i32) (i32.const 6))
        \\  (func $raise (throw $t (i32.const 64)))
        \\  (func (export "bp_main") (param i32 i32) (result i32)
        \\    (block $h (result i32)
        \\      (try_table (catch $t $h) (call $raise))
        \\      (i32.const 0))))
    );
    defer c.wasm_byte_vec_delete(&bytes);
    const r = try evalWithArg(alloc, std.testing.io, "bp@wat_test_exceptions", bytes.data[0..bytes.size], "x");
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("caught", r.ok);
}

test "a module that imports anything is refused by the engine, naming the import" {
    const alloc = std.testing.allocator;
    var bytes = try watBytes(
        \\(module (import "env" "bp_elsewhere" (func)) (memory (export "memory") 1))
    );
    defer c.wasm_byte_vec_delete(&bytes);
    const r = try evalWithArg(alloc, std.testing.io, "bp@wat_test_imports", bytes.data[0..bytes.size], "");
    defer alloc.free(r.payload());
    try std.testing.expect(r == .compile_error);
    try std.testing.expect(std.mem.indexOf(u8, r.compile_error, "env.bp_elsewhere") != null);
}

// ── the limits (`AGENTS.md` § Limits): each pinned where it raises ──────────

test "limit 1: no process, mailbox or ETS table — refused by name before anything runs" {
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

// Decision 443 — the limit that refused a non-ASCII letter is gone: the
// runtime maps case over all of Unicode, std-wasm's (OTP's) answer.
test "Unicode case mapping answers OTP's: string:uppercase, lowercase and titlecase" {
    const alloc = std.testing.allocator;
    const code =
        \\-module(bp@wat_test_case).
        \\-export([main/1]).
        \\
        \\main({Arg0}) -> [string:uppercase(Arg0), string:lowercase(<<"ΟΔΟΣ"/utf8>>), string:titlecase(<<"ǆa"/utf8>>)].
    ;
    const r = try runSource(alloc, "bp@wat_test_case", code, Term.tupleOf(&.{Term.str("\xc3\xa9t\xc3\xa9 stra\xc3\x9fe")}));
    defer alloc.free(r.payload());
    try std.testing.expectEqualStrings("ÉTÉ STRASSEοδοσǅa", r.ok);
}

test "limit 3: an integer beyond 64 bits raises bp_wat_runtime" {
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
