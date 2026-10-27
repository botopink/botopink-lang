//! The native comptime host (decision 1035 (2), piece C3a): one evaluation
//! over comptime units, run in the compiler's process on the program's engine
//! (`engine.zig`, decision 1033 (1)) with the compiler as host and no WASI.
//!
//! `evaluate` takes the core units of an evaluation in dependency order —
//! the runtime core and std units first, the module's own unit last, as
//! `out/wasm-comptime/<pkg>@<path>.wasm` holds them (1035 (1)) — each under
//! the name its importers use (`std@__rt`, `std@string`, `<pkg>@<path>`). It
//! loads each through the runner's process LRU and the `.cwasm` cache
//! (`runner.load`, 1034 (8), (9)), links them through a core linker (never
//! the component linker: 1037 (6)), defines the host imports they name,
//! instantiates them in order, calls every unit's `__bp_init` in order, then
//! crosses the input in, calls the evaluation export and crosses the reply out.
//!
//! **The crossing** (1035 (4)) is JSON through the core unit's linear memory:
//! `Crossing` names the exports it goes through. The host side is fixed here;
//! the botopink side (`std/compiler`'s codecs, 550) is C2's, which matches
//! `Crossing` or changes it.
//!
//! **The host** serves three import modules a program unit may name, and
//! nothing else (a unit importing any other module that is not an earlier
//! unit is a `compile_error` naming it):
//!
//! - `wasi_snapshot_preview1.fd_write` on fd 1 or 2 appends to the
//!   evaluation's `printed` text, which comes back with the reply (a raise
//!   keeps what was printed before it, decision 904); another fd is `EBADF`.
//! - **entropy** (`random_get`), **the clock** (`clock_time_get`,
//!   `clock_res_get`, `poll_oneoff`, `sched_yield`, every `bp_host` import —
//!   `delay`, `wait`, `drop`) and **files** (every `bp_fs` import and every
//!   other `wasi_snapshot_preview1` function: paths, descriptors, the
//!   environment, arguments, `proc_exit`) each trap at the call with one named
//!   text (`entropy_text`, `clock_text`, `files_text`) — a build has none of
//!   them (decision 451).
//!
//! **Time and interrupt** (decision 878, 1034 (2)): the store is watched by
//! the runner's `StoreWatch`, so `runner.interrupt()` ends an evaluation in
//! flight (`interrupted_text`, the reply comptime answers today) and an
//! optional time limit ends it at its deadline (`timed_out_text`); with none,
//! a body runs to its end (380 (2)). Each evaluation runs on a thread of its
//! own whose stack holds the engine's wasm stack (`engine.onWasmStack`), in a
//! store of its own, so nothing one evaluation leaves is seen by the next.
const std = @import("std");
const engine = @import("engine.zig");
const runner = @import("runner.zig");
const c = engine.c;

pub const Error = std.mem.Allocator.Error;

/// One core unit of an evaluation: the name its importers name it by and its
/// bytes (binary, or `.wat` text in a test).
pub const Unit = struct {
    name: []const u8,
    bytes: []const u8,
};

/// The exports the JSON crosses through (1035 (4)). The input: `alloc(len)`
/// of `memory_unit` answers an address in its `memory`, where the host writes
/// the input JSON. The evaluation: the LAST unit's `eval(ptr, len)` answers
/// `(ptr, len)` of the reply JSON in the same memory.
pub const Crossing = struct {
    memory_unit: []const u8 = "std@__rt",
    memory: []const u8 = "memory",
    alloc: []const u8 = "__alloc",
    eval: []const u8 = "__bp_comptime_eval",
};

pub const Options = struct {
    /// The `.cwasm` folder (`<cache root>/.botopinkbuild/cache/wasmtime/`),
    /// null to keep compiled code in the process only.
    cache_dir: ?[]const u8 = null,
    /// `--cold`: read no `.cwasm`, write what compiled.
    cold: bool = false,
    /// The time limit; null runs to the end or to `runner.interrupt()`.
    timeout_ns: ?u64 = null,
    crossing: Crossing = .{},
};

/// The texts of the named traps (decision 451; the entropy one is 451 /
/// 456's refusal, the same words the term runtime raises today).
pub const entropy_text = "an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)";
pub const clock_text = "a clock read: a build has no clock (decision 1035 (2))";
pub const files_text = "a file access: a build has no file system (decision 1035 (2))";
/// An evaluation `runner.interrupt()` ended: the reply comptime answers today
/// (`persistent_wat.interrupted_reply`, decision 878), which the evaluators
/// read as `comptime-interrupted`.
pub const interrupted_text = "wasmtime: interrupted";
/// An evaluation its time limit ended.
pub const timed_out_text = "wasmtime: time limit reached";

pub const Outcome = union(enum) {
    /// The reply JSON.
    reply: []u8,
    /// A unit the engine refused, or an import the host does not serve.
    compile_error: []u8,
    /// A trap: a named one's text, `wasmtime: <what>` for the engine's own,
    /// `interrupted_text` / `timed_out_text`.
    runtime_error: []u8,
};

pub const Answer = struct {
    outcome: Outcome,
    /// What the body printed (fd 1 and 2), in order; empty when nothing.
    printed: []u8,
    end: runner.End = .exited,

    pub fn deinit(self: Answer, alloc: std.mem.Allocator) void {
        switch (self.outcome) {
            inline else => |t| alloc.free(t),
        }
        alloc.free(self.printed);
    }
};

/// Run one evaluation. See the file comment. Every text of the answer is
/// owned by `alloc`.
pub fn evaluate(alloc: std.mem.Allocator, io: std.Io, units: []const Unit, input: []const u8, opts: Options) Error!Answer {
    if (units.len == 0) return .{ .outcome = .{ .compile_error = try alloc.dupe(u8, "an evaluation needs at least one unit") }, .printed = try alloc.dupe(u8, "") };
    const modules = try alloc.alloc(*c.wasmtime_module_t, units.len);
    defer alloc.free(modules);
    var loaded: usize = 0;
    defer for (modules[0..loaded]) |m| c.wasmtime_module_delete(m);
    for (units) |u| {
        var failure: ?[]u8 = null;
        const code = (try runner.load(alloc, io, opts.cache_dir, u.bytes, .module, opts.cold, &failure)) orelse {
            defer alloc.free(failure.?);
            return .{ .outcome = .{ .compile_error = try std.fmt.allocPrint(alloc, "unit {s}: {s}", .{ u.name, failure.? }) }, .printed = try alloc.dupe(u8, "") };
        };
        modules[loaded] = code.module;
        loaded += 1;
    }

    var job: Job = .{ .alloc = alloc, .units = units, .modules = modules, .input = input, .opts = opts };
    return engine.onWasmStack(Job.run, .{&job});
}

const Job = struct {
    alloc: std.mem.Allocator,
    units: []const Unit,
    modules: []const *c.wasmtime_module_t,
    input: []const u8,
    opts: Options,

    fn run(job: *Job) Error!Answer {
        const alloc = job.alloc;
        var host: Host = .{ .alloc = alloc };
        defer host.printed.deinit(alloc);
        const outcome = try job.evaluateIn(&host);
        return .{ .outcome = outcome.outcome, .printed = try alloc.dupe(u8, host.printed.items), .end = outcome.end };
    }

    fn evaluateIn(job: *Job, host: *Host) Error!struct { outcome: Outcome, end: runner.End } {
        const alloc = job.alloc;
        const eng = try engine.theEngine();
        const linker = c.wasmtime_linker_new(eng) orelse return error.OutOfMemory;
        defer c.wasmtime_linker_delete(linker);
        const store = c.wasmtime_store_new(eng, null, null) orelse return error.OutOfMemory;
        defer c.wasmtime_store_delete(store);
        const ctx = c.wasmtime_store_context(store).?;
        var watch: runner.StoreWatch = undefined;
        watch.begin(store, job.opts.timeout_ns);
        var ended = false;
        defer if (!ended) {
            _ = watch.end();
        };

        const instances = try alloc.alloc(c.wasmtime_instance_t, job.units.len);
        defer alloc.free(instances);
        var defined: std.StringHashMapUnmanaged(void) = .empty;
        defer {
            var it = defined.keyIterator();
            while (it.next()) |k| alloc.free(k.*);
            defined.deinit(alloc);
        }

        var outcome: Outcome = run: {
            for (job.units, job.modules, 0..) |u, m, i| {
                if (try defineImports(alloc, linker, host, u, m, job.units[0..i], &defined)) |refusal|
                    break :run .{ .compile_error = refusal };
                var trap: ?*c.wasm_trap_t = null;
                if (c.wasmtime_linker_instantiate(linker, ctx, m, &instances[i], &trap)) |err|
                    break :run .{ .compile_error = try engine.errorText(alloc, try std.fmt.allocPrint(alloc, "unit {s}: ", .{u.name}), err) };
                if (trap) |t| break :run .{ .runtime_error = try host.trapText(t) };
                if (c.wasmtime_linker_define_instance(linker, ctx, u.name.ptr, u.name.len, &instances[i])) |err|
                    break :run .{ .compile_error = try engine.errorText(alloc, "linker: ", err) };
            }
            for (instances) |*inst| {
                var f: c.wasmtime_func_t = undefined;
                if (!exportFunc(ctx, inst, "__bp_init", &f)) continue;
                var no: [1]c.wasmtime_val_t = undefined;
                if (try host.call(ctx, &f, &.{}, no[0..0])) |e| break :run .{ .runtime_error = e };
            }
            break :run try job.cross(host, ctx, instances);
        };
        ended = true;
        const end = watch.end();
        switch (end) {
            .exited => {},
            .interrupted, .timed_out => {
                switch (outcome) {
                    inline else => |t| alloc.free(t),
                }
                outcome = .{ .runtime_error = try alloc.dupe(u8, if (end == .interrupted) interrupted_text else timed_out_text) };
            },
        }
        return .{ .outcome = outcome, .end = end };
    }

    /// The input in, the evaluation, the reply out (`Crossing`).
    fn cross(job: *Job, host: *Host, ctx: *c.wasmtime_context_t, instances: []c.wasmtime_instance_t) Error!Outcome {
        const alloc = job.alloc;
        const cr = job.opts.crossing;
        const mem_inst = for (job.units, instances) |u, *inst| {
            if (std.mem.eql(u8, u.name, cr.memory_unit)) break inst;
        } else return .{ .compile_error = try std.fmt.allocPrint(alloc, "no unit is {s}, whose memory the JSON crosses through", .{cr.memory_unit}) };
        const entry = &instances[instances.len - 1];

        var alloc_f: c.wasmtime_func_t = undefined;
        if (!exportFunc(ctx, mem_inst, cr.alloc, &alloc_f))
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no function {s}", .{ cr.memory_unit, cr.alloc }) };
        var eval_f: c.wasmtime_func_t = undefined;
        if (!exportFunc(ctx, entry, cr.eval, &eval_f))
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no function {s}", .{ job.units[job.units.len - 1].name, cr.eval }) };

        var r: [2]c.wasmtime_val_t = undefined;
        if (try host.call(ctx, &alloc_f, &.{i32Val(@intCast(job.input.len))}, r[0..1])) |e| return .{ .runtime_error = e };
        const in_ptr: u32 = @bitCast(r[0].of.i32);
        {
            const mem = memoryOf(ctx, mem_inst, cr.memory) orelse
                return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no memory {s}", .{ cr.memory_unit, cr.memory }) };
            if (@as(usize, in_ptr) + job.input.len > mem.len)
                return .{ .runtime_error = try alloc.dupe(u8, "the input does not fit the core unit's memory") };
            @memcpy(mem[in_ptr..][0..job.input.len], job.input);
        }
        if (try host.call(ctx, &eval_f, &.{ i32Val(@bitCast(in_ptr)), i32Val(@intCast(job.input.len)) }, r[0..2])) |e| return .{ .runtime_error = e };
        const out_ptr: u32 = @bitCast(r[0].of.i32);
        const out_len: u32 = @bitCast(r[1].of.i32);
        // The memory may have grown during the evaluation: read it again.
        const mem = memoryOf(ctx, mem_inst, cr.memory).?;
        if (@as(usize, out_ptr) + out_len > mem.len)
            return .{ .runtime_error = try alloc.dupe(u8, "the reply lies outside the core unit's memory") };
        return .{ .reply = try alloc.dupe(u8, mem[out_ptr..][0..out_len]) };
    }
};

fn i32Val(v: i32) c.wasmtime_val_t {
    var val: c.wasmtime_val_t = undefined;
    val.kind = c.WASMTIME_I32;
    val.of.i32 = v;
    return val;
}

fn exportFunc(ctx: *c.wasmtime_context_t, inst: *const c.wasmtime_instance_t, name: []const u8, out: *c.wasmtime_func_t) bool {
    var item: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(ctx, inst, name.ptr, name.len, &item)) return false;
    if (item.kind != c.WASMTIME_EXTERN_FUNC) return false;
    out.* = item.of.func;
    return true;
}

fn memoryOf(ctx: *c.wasmtime_context_t, inst: *const c.wasmtime_instance_t, name: []const u8) ?[]u8 {
    var item: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(ctx, inst, name.ptr, name.len, &item) or item.kind != c.WASMTIME_EXTERN_MEMORY) return null;
    const p = c.wasmtime_memory_data(ctx, &item.of.memory);
    const n = c.wasmtime_memory_data_size(ctx, &item.of.memory);
    return p[0..n];
}

// ── the host ─────────────────────────────────────────────────────────────────

/// What a host import does.
pub const Service = enum {
    print,
    entropy,
    clock,
    files,

    fn text(s: Service) []const u8 {
        return switch (s) {
            .print => unreachable,
            .entropy => entropy_text,
            .clock => clock_text,
            .files => files_text,
        };
    }
};

/// The service of the import `module.name`, null when the host serves no
/// such module (a unit's import of another unit, or one refused).
pub fn serviceOf(module: []const u8, name: []const u8) ?Service {
    if (std.mem.eql(u8, module, "bp_host")) return .clock;
    if (std.mem.eql(u8, module, "bp_fs")) return .files;
    if (!std.mem.eql(u8, module, "wasi_snapshot_preview1")) return null;
    if (std.mem.eql(u8, name, "fd_write")) return .print;
    if (std.mem.eql(u8, name, "random_get")) return .entropy;
    const clock = [_][]const u8{ "clock_time_get", "clock_res_get", "poll_oneoff", "sched_yield" };
    for (clock) |n| if (std.mem.eql(u8, name, n)) return .clock;
    return .files;
}

const Host = struct {
    alloc: std.mem.Allocator,
    printed: std.ArrayList(u8) = .empty,
    /// The text of the named trap a host import raised, for the call that
    /// raised it.
    named: ?[]const u8 = null,
    /// An allocation in a callback failed.
    oom: bool = false,

    /// Call `f`; null when it returned (its results in `results`), else the
    /// runtime error's text (owned).
    fn call(host: *Host, ctx: *c.wasmtime_context_t, f: *const c.wasmtime_func_t, args: []const c.wasmtime_val_t, results: []c.wasmtime_val_t) Error!?[]u8 {
        var trap: ?*c.wasm_trap_t = null;
        host.named = null;
        const err = c.wasmtime_func_call(ctx, f, args.ptr, args.len, results.ptr, results.len, &trap);
        if (host.oom) return error.OutOfMemory;
        if (err) |e| {
            // The epoch callback's error (interrupt, time limit): the caller
            // replaces the text by the watch's end.
            const full = try engine.errorText(host.alloc, "", e);
            defer host.alloc.free(full);
            return try host.alloc.dupe(u8, runner.trapLine(full));
        }
        if (trap) |t| return try host.trapText(t);
        return null;
    }

    /// A trap as one line: a named trap's text as the host raised it, else
    /// `wasmtime: <what>` — the trap code's name, or the message's first line
    /// (persistent_wat's shape, never the engine's backtrace). Takes `trap`.
    fn trapText(host: *Host, trap: *c.wasm_trap_t) Error![]u8 {
        defer c.wasm_trap_delete(trap);
        if (host.named) |n| return host.alloc.dupe(u8, n);
        var code: c.wasmtime_trap_code_t = undefined;
        if (c.wasmtime_trap_code(trap, &code)) if (trapName(code)) |name|
            return std.fmt.allocPrint(host.alloc, "wasmtime: {s}", .{name});
        var msg: c.wasm_message_t = undefined;
        c.wasm_trap_message(trap, &msg);
        defer c.wasm_byte_vec_delete(&msg);
        var text: []const u8 = if (msg.size == 0) "" else msg.data[0..msg.size];
        if (std.mem.indexOfScalar(u8, text, 0)) |z| text = text[0..z];
        if (std.mem.indexOfScalar(u8, text, '\n')) |nl| text = text[0..nl];
        return std.fmt.allocPrint(host.alloc, "wasmtime: {s}", .{text});
    }
};

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

/// Define, in `linker`, every host import of `module` not defined yet. Null
/// when every import is served (by the host or by one of `earlier`), else
/// the refusal (owned).
fn defineImports(
    alloc: std.mem.Allocator,
    linker: *c.wasmtime_linker_t,
    host: *Host,
    unit: Unit,
    module: *c.wasmtime_module_t,
    earlier: []const Unit,
    defined: *std.StringHashMapUnmanaged(void),
) Error!?[]u8 {
    var imports: c.wasm_importtype_vec_t = undefined;
    c.wasmtime_module_imports(module, &imports);
    defer c.wasm_importtype_vec_delete(&imports);
    for (imports.data[0..imports.size]) |imp| {
        const mn = c.wasm_importtype_module(imp);
        const nn = c.wasm_importtype_name(imp);
        const m: []const u8 = if (mn.*.size == 0) "" else mn.*.data[0..mn.*.size];
        const n: []const u8 = if (nn.*.size == 0) "" else nn.*.data[0..nn.*.size];
        const service = serviceOf(m, n) orelse {
            for (earlier) |e| {
                if (std.mem.eql(u8, e.name, m)) break;
            } else return try std.fmt.allocPrint(alloc, "unit {s} imports {s}.{s}: no earlier unit is {s}, and the comptime host serves no such import", .{ unit.name, m, n, m });
            continue;
        };
        const key = try std.fmt.allocPrint(alloc, "{s}\x00{s}", .{ m, n });
        const gop = defined.getOrPut(alloc, key) catch |e| {
            alloc.free(key);
            return e;
        };
        if (gop.found_existing) {
            alloc.free(key);
            continue;
        }
        const ty = c.wasm_externtype_as_functype_const(c.wasm_importtype_type(imp)) orelse
            return try std.fmt.allocPrint(alloc, "unit {s} imports {s}.{s} as no function: the comptime host serves functions only", .{ unit.name, m, n });
        const cb: c.wasmtime_func_callback_t = switch (service) {
            .print => fdWrite,
            .entropy => trapEntropy,
            .clock => trapClock,
            .files => trapFiles,
        };
        if (c.wasmtime_linker_define_func(linker, m.ptr, m.len, n.ptr, n.len, ty, cb, host, null)) |err|
            return try engine.errorText(alloc, "linker: ", err);
    }
    return null;
}

fn raise(env: ?*anyopaque, s: Service) ?*c.wasm_trap_t {
    const host: *Host = @ptrCast(@alignCast(env.?));
    const text = s.text();
    host.named = text;
    return c.wasmtime_trap_new(text.ptr, text.len);
}

fn trapEntropy(env: ?*anyopaque, _: ?*c.wasmtime_caller_t, _: [*c]const c.wasmtime_val_t, _: usize, _: [*c]c.wasmtime_val_t, _: usize) callconv(.c) ?*c.wasm_trap_t {
    return raise(env, .entropy);
}

fn trapClock(env: ?*anyopaque, _: ?*c.wasmtime_caller_t, _: [*c]const c.wasmtime_val_t, _: usize, _: [*c]c.wasmtime_val_t, _: usize) callconv(.c) ?*c.wasm_trap_t {
    return raise(env, .clock);
}

fn trapFiles(env: ?*anyopaque, _: ?*c.wasmtime_caller_t, _: [*c]const c.wasmtime_val_t, _: usize, _: [*c]c.wasmtime_val_t, _: usize) callconv(.c) ?*c.wasm_trap_t {
    return raise(env, .files);
}

/// WASI's errnos `fd_write` answers here.
const errno_badf = 8;
const errno_fault = 21;

/// `fd_write(fd, iovs, iovs_len, nwritten) -> errno` over the caller's
/// `memory`: fd 1 and 2 append to the evaluation's printed text.
fn fdWrite(env: ?*anyopaque, caller: ?*c.wasmtime_caller_t, args: [*c]const c.wasmtime_val_t, nargs: usize, results: [*c]c.wasmtime_val_t, nresults: usize) callconv(.c) ?*c.wasm_trap_t {
    const host: *Host = @ptrCast(@alignCast(env.?));
    if (nargs != 4 or nresults != 1) {
        host.named = files_text;
        return c.wasmtime_trap_new(files_text.ptr, files_text.len);
    }
    results[0].kind = c.WASMTIME_I32;
    const fd = args[0].of.i32;
    if (fd != 1 and fd != 2) {
        results[0].of.i32 = errno_badf;
        return null;
    }
    var item: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_caller_export_get(caller, "memory", "memory".len, &item) or item.kind != c.WASMTIME_EXTERN_MEMORY) {
        results[0].of.i32 = errno_fault;
        return null;
    }
    const ctx = c.wasmtime_caller_context(caller);
    const mem = c.wasmtime_memory_data(ctx, &item.of.memory)[0..c.wasmtime_memory_data_size(ctx, &item.of.memory)];
    const iovs: usize = @as(u32, @bitCast(args[1].of.i32));
    const count: usize = @as(u32, @bitCast(args[2].of.i32));
    const nwritten: usize = @as(u32, @bitCast(args[3].of.i32));
    var total: u32 = 0;
    for (0..count) |k| {
        const at = iovs + 8 * k;
        if (at + 8 > mem.len) {
            results[0].of.i32 = errno_fault;
            return null;
        }
        const p = std.mem.readInt(u32, mem[at..][0..4], .little);
        const n = std.mem.readInt(u32, mem[at + 4 ..][0..4], .little);
        if (@as(usize, p) + n > mem.len) {
            results[0].of.i32 = errno_fault;
            return null;
        }
        host.printed.appendSlice(host.alloc, mem[p..][0..n]) catch {
            host.oom = true;
            return c.wasmtime_trap_new("out of memory", "out of memory".len);
        };
        total += n;
    }
    if (nwritten + 4 > mem.len) {
        results[0].of.i32 = errno_fault;
        return null;
    }
    std.mem.writeInt(u32, mem[nwritten..][0..4], total, .little);
    results[0].of.i32 = 0;
    return null;
}

// ── tests: hand-written core units ───────────────────────────────────────────

/// A runtime core in the shape `runtime_unit.zig` writes: the memory, a bump
/// `__alloc`, `fd_write` imported from the host; its `__bp_init` sets the
/// heap start (and counts, in the `inits` global, the inits that ran before).
fn coreWat(comptime tag: []const u8) []const u8 {
    return
    \\(module $core_
    ++ tag ++
        \\
        \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (global $heap (export "__heap_ptr") (mut i32) (i32.const 0))
        \\  (global $order (export "order") (mut i32) (i32.const 0))
        \\  (func (export "__bp_init") (global.set $heap (i32.const 1024)) (global.set $order (i32.const 1)))
        \\  (func (export "__alloc") (param $n i32) (result i32)
        \\    (global.get $heap)
        \\    (global.set $heap (i32.add (global.get $heap) (local.get $n))))
        \\  (func (export "print") (param $p i32) (param $n i32)
        \\    (i32.store (i32.const 16) (local.get $p))
        \\    (i32.store (i32.const 20) (local.get $n))
        \\    (drop (call $fd_write (i32.const 1) (i32.const 16) (i32.const 1) (i32.const 24)))))
    ;
}

/// The module's own unit: its `__bp_init` records that the core's ran first
/// (`order` 1 → 2, else 99); `__bp_comptime_eval` prints the input and
/// answers `{"in":<input>,"order":<n>}`, built in the core's memory.
fn entryWat(comptime tag: []const u8) []const u8 {
    return
    \\(module $entry_
    ++ tag ++
        \\
        \\  (import "std@__rt" "memory" (memory 1))
        \\  (import "std@__rt" "__alloc" (func $alloc (param i32) (result i32)))
        \\  (import "std@__rt" "print" (func $print (param i32 i32)))
        \\  (import "std@__rt" "order" (global $order (mut i32)))
        \\  (data (i32.const 512) "{\22in\22:,\22order\22:}")
        \\  (func (export "__bp_init")
        \\    (global.set $order (select (i32.const 2) (i32.const 99) (i32.eq (global.get $order) (i32.const 1)))))
        \\  (func (export "__bp_comptime_eval") (param $p i32) (param $n i32) (result i32 i32)
        \\    (local $out i32)
        \\    (call $print (local.get $p) (local.get $n))
        \\    (local.set $out (call $alloc (i32.add (local.get $n) (i32.const 32))))
        \\    (memory.copy (local.get $out) (i32.const 512) (i32.const 6))
        \\    (memory.copy (i32.add (local.get $out) (i32.const 6)) (local.get $p) (local.get $n))
        \\    (memory.copy (i32.add (local.get $out) (i32.add (local.get $n) (i32.const 6))) (i32.const 518) (i32.const 9))
        \\    (i32.store8 (i32.add (local.get $out) (i32.add (local.get $n) (i32.const 15)))
        \\      (i32.add (i32.const 48) (global.get $order)))
        \\    (i32.store8 (i32.add (local.get $out) (i32.add (local.get $n) (i32.const 16))) (i32.const 125))
        \\    (local.get $out) (i32.add (local.get $n) (i32.const 17))))
    ;
}

fn units2(comptime tag: []const u8) [2]Unit {
    return .{ .{ .name = "std@__rt", .bytes = coreWat(tag) }, .{ .name = "app@main", .bytes = entryWat(tag) } };
}

test "comptime host: two units linked, __bp_init in order, the JSON crosses in and out, print captured" {
    const alloc = std.testing.allocator;
    const units = units2("roundtrip");
    const a = try evaluate(alloc, std.testing.io, &units, "[1,\"x\"]", .{});
    defer a.deinit(alloc);
    if (a.outcome != .reply) std.debug.print("\n{s}: {s}\n", .{ @tagName(a.outcome), switch (a.outcome) {
        inline else => |t| t,
    } });
    try std.testing.expectEqualStrings("{\"in\":[1,\"x\"],\"order\":2}", a.outcome.reply);
    try std.testing.expectEqualStrings("[1,\"x\"]", a.printed);
    try std.testing.expectEqual(runner.End.exited, a.end);
}

test "comptime host: every evaluation starts from fresh instances" {
    const alloc = std.testing.allocator;
    const units = units2("fresh");
    for (0..2) |_| {
        const a = try evaluate(alloc, std.testing.io, &units, "7", .{});
        defer a.deinit(alloc);
        try std.testing.expectEqualStrings("{\"in\":7,\"order\":2}", a.outcome.reply);
    }
}

/// One unit importing a host service and calling it from the evaluation.
fn serviceWat(comptime import: []const u8, comptime sig: []const u8, comptime call: []const u8) []const u8 {
    return "(module\n  (import " ++ import ++ " (func $h " ++ sig ++ "))\n" ++
        \\  (memory (export "memory") 1)
        \\  (func (export "__alloc") (param i32) (result i32) (i32.const 64))
        \\  (func (export "__bp_comptime_eval") (param i32 i32) (result i32 i32)
        \\
    ++ "    " ++ call ++ "\n" ++
        \\    (i32.const 0) (i32.const 0)))
    ;
}

test "comptime host: clock, entropy and files each trap with their named text" {
    const alloc = std.testing.allocator;
    const cases = [_]struct { []const u8, []const u8 }{
        .{ serviceWat("\"wasi_snapshot_preview1\" \"random_get\"", "(param i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 8)))"), entropy_text },
        .{ serviceWat("\"wasi_snapshot_preview1\" \"clock_time_get\"", "(param i32 i64 i32) (result i32)", "(drop (call $h (i32.const 0) (i64.const 1) (i32.const 0)))"), clock_text },
        .{ serviceWat("\"bp_host\" \"delay\"", "(param i32) (result i32)", "(drop (call $h (i32.const 10)))"), clock_text },
        .{ serviceWat("\"bp_fs\" \"open\"", "(param i32 i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0) (i32.const 0)))"), files_text },
        .{ serviceWat("\"wasi_snapshot_preview1\" \"path_open\"", "(param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)", "(drop (call $h (i32.const 3) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0) (i64.const 0) (i64.const 0) (i32.const 0) (i32.const 0)))"), files_text },
    };
    for (cases) |case_| {
        const units = [_]Unit{.{ .name = "std@__rt", .bytes = case_[0] }};
        const a = try evaluate(alloc, std.testing.io, &units, "", .{});
        defer a.deinit(alloc);
        try std.testing.expectEqualStrings(case_[1], a.outcome.runtime_error);
    }
}

test "comptime host: an import of no earlier unit and no host service is refused, naming it" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = serviceWat("\"env\" \"elsewhere\"", "", "(call $h)") }};
    const a = try evaluate(alloc, std.testing.io, &units, "", .{});
    defer a.deinit(alloc);
    try std.testing.expect(std.mem.indexOf(u8, a.outcome.compile_error, "env.elsewhere") != null);
}

const spin_eval = serviceWat("\"bp_host\" \"drop\"", "(param i32)", "(loop $l (br $l))");

test "comptime host: the epoch deadline stops a loop, and the next evaluation runs" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = spin_eval }};
    const a = try evaluate(alloc, std.testing.io, &units, "", .{ .timeout_ns = 50 * std.time.ns_per_ms });
    defer a.deinit(alloc);
    try std.testing.expectEqual(runner.End.timed_out, a.end);
    try std.testing.expectEqualStrings(timed_out_text, a.outcome.runtime_error);
    try std.testing.expect(!runner.running());

    const ok = units2("after-deadline");
    const b = try evaluate(alloc, std.testing.io, &ok, "1", .{});
    defer b.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":1,\"order\":2}", b.outcome.reply);
}

fn interruptWhenRunning() void {
    var waited: usize = 0;
    while (!runner.running() and waited < 20_000) : (waited += 1) {
        var ts: std.c.timespec = .{ .sec = 0, .nsec = std.time.ns_per_ms };
        _ = std.c.nanosleep(&ts, &ts);
    }
    var ts: std.c.timespec = .{ .sec = 0, .nsec = 20 * std.time.ns_per_ms };
    _ = std.c.nanosleep(&ts, &ts);
    runner.interrupt();
}

test "comptime host: runner.interrupt ends an evaluation with today's interrupted reply (decision 878)" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = spin_eval }};
    const killer = try std.Thread.spawn(.{}, interruptWhenRunning, .{});
    defer killer.join();
    // The limit only bounds the test if the interrupt never comes.
    const a = try evaluate(alloc, std.testing.io, &units, "", .{ .timeout_ns = 20 * std.time.ns_per_s });
    defer a.deinit(alloc);
    try std.testing.expectEqual(runner.End.interrupted, a.end);
    try std.testing.expectEqualStrings(interrupted_text, a.outcome.runtime_error);
}

/// `depth(n)` recurses `n` times with no tail call, as an Erlang-shaped loop
/// does: `deep` within the 64 MiB wasm stack (past wasmtime's 512 KiB
/// default), `too_deep` past it.
pub const depth_wat =
    \\(module $depth
    \\  (memory (export "memory") 1)
    \\  (func (export "__alloc") (param i32) (result i32) (i32.const 64))
    \\  (func $depth (param i32) (result i32)
    \\    (if (result i32) (i32.eqz (local.get 0)) (then (i32.const 0))
    \\      (else (i32.add (i32.const 1) (call $depth (i32.sub (local.get 0) (i32.const 1)))))))
    \\  (func (export "deep") (param i32 i32) (result i32 i32)
    \\    (drop (call $depth (i32.const 200000))) (i32.const 0) (i32.const 0))
    \\  (func (export "too_deep") (param i32 i32) (result i32 i32)
    \\    (drop (call $depth (i32.const 100000000))) (i32.const 0) (i32.const 0)))
;

test "comptime host: deep recursion runs on the 64 MiB wasm stack; past it, call stack exhausted" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = depth_wat }};
    const deep = try evaluate(alloc, std.testing.io, &units, "", .{ .crossing = .{ .eval = "deep" } });
    defer deep.deinit(alloc);
    try std.testing.expectEqualStrings("", deep.outcome.reply);
    const too = try evaluate(alloc, std.testing.io, &units, "", .{ .crossing = .{ .eval = "too_deep" } });
    defer too.deinit(alloc);
    try std.testing.expectEqualStrings("wasmtime: call stack exhausted", too.outcome.runtime_error);
}

test "comptime host: the .cwasm of each unit is written once and reused by a second call" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);
    const units = units2("cwasm");

    const first = try evaluate(alloc, io, &units, "1", .{ .cache_dir = dir });
    defer first.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":1,\"order\":2}", first.outcome.reply);
    var stats: [2]std.Io.File.Stat = undefined;
    for (units, 0..) |u, i| {
        const path = try engine.cachePath(alloc, dir, .module, u.bytes);
        defer alloc.free(path);
        stats[i] = try std.Io.Dir.cwd().statFile(io, path, .{});
    }

    const second = try evaluate(alloc, io, &units, "2", .{ .cache_dir = dir });
    defer second.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":2,\"order\":2}", second.outcome.reply);
    for (units, 0..) |u, i| {
        const path = try engine.cachePath(alloc, dir, .module, u.bytes);
        defer alloc.free(path);
        const s = try std.Io.Dir.cwd().statFile(io, path, .{});
        // Not rewritten: the same file.
        try std.testing.expectEqual(stats[i].inode, s.inode);
        try std.testing.expectEqual(stats[i].mtime.nanoseconds, s.mtime.nanoseconds);
        // And the engine takes it as it is, compiling nothing.
        var failure: ?[]u8 = null;
        const pc = (try engine.precompiled(alloc, io, dir, u.bytes, .module, false, &failure)).?;
        defer pc.code.deinit();
        defer alloc.free(pc.path.?);
        try std.testing.expect(pc.from_cache);
    }
}

test "the program path: deep recursion traps call stack exhausted, never faults (the shared 64 MiB wasm stack)" {
    const alloc = std.testing.allocator;
    var failure: ?[]u8 = null;
    const m = (try engine.precompiled(alloc, std.testing.io, null,
        \\(module
        \\  (func $depth (param i32) (result i32)
        \\    (if (result i32) (i32.eqz (local.get 0)) (then (i32.const 0))
        \\      (else (i32.add (i32.const 1) (call $depth (i32.sub (local.get 0) (i32.const 1)))))))
        \\  (func (export "mid") (result i32) (call $depth (i32.const 200000)))
        \\  (func (export "huge") (result i32) (call $depth (i32.const 100000000))))
    , .module, false, &failure)).?;
    defer m.code.deinit();
    const mid = try runner.invokeCore(alloc, m.code.module, &.{}, "mid", .{});
    defer mid.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(?i64, 200000), mid.value);
    const huge = try runner.invokeCore(alloc, m.code.module, &.{}, "huge", .{});
    defer huge.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(i32, 1), huge.outcome.status);
    try std.testing.expectEqualStrings("wasm trap: call stack exhausted", huge.outcome.trap.?);
}
