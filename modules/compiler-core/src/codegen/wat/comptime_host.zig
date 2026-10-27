//! The native comptime host (decisions 1035 (2), 1059; piece C3a): one
//! evaluation over comptime units, run in the compiler's process on the
//! program's engine (`engine.zig`, decision 1033 (1)) with the compiler as
//! host and no WASI.
//!
//! `evaluate` takes the core units of an evaluation in dependency order —
//! the runtime core and std units first, as `out/wasm-comptime/<pkg>@<path>.wasm`
//! holds them (1035 (1)) — each under the name its importers use (`std@__rt`,
//! `std@string`, `<pkg>@<path>`), and the name of the module whose body is
//! evaluated. It loads each through the runner's process LRU and the `.cwasm`
//! cache (`runner.load`, 1034 (8), (9)), links them through a core linker
//! (never the component linker: 1037 (6)), defines the host imports they
//! name, instantiates them in order, calls every unit's `__bp_init` in order,
//! then crosses the input in, calls the evaluation export and crosses the
//! reply out.
//!
//! **The crossing** (1059 (1)) is the contract `runtime_unit.zig` names once:
//! the input JSON written at the core's `alloc_export` in its
//! `memory_export`, the evaluated module's unit's `comptime_eval_export(ptr,
//! len) -> (ptr, len)` the reply JSON. **Reset**: a fresh store and fresh
//! instances per evaluation (`reset`), so nothing one evaluation leaves —
//! the heap past `__heap_ptr` included — is seen by the next.
//!
//! **The reply** (1059 (2)): when the evaluation export returns, its reply
//! is the answer as it is — C2's codec wrote `printed` into it. When no codec
//! ran — a trap, the deadline, an interrupt — the host builds the reply,
//! `{"kind":"error","message":…}` with `"printed"` holding the text fd 1 and
//! 2 received so far when there is any (904).
//!
//! **The host services** (1059 (4)), and nothing else (any other import that
//! is not an earlier unit is a `compile_error` naming it):
//!
//! - print: `wasi_snapshot_preview1.fd_write` on fd 1 or 2 is captured;
//! - clock: `clock_time_get`, `clock_res_get`, `poll_oneoff`, every
//!   `bp_host` timer — trap `a build has no clock: …`;
//! - entropy: `random_get`, `bp_random_f64` — trap with 451's refusal;
//! - files: every `bp_fs` import, every `fd_*` and `path_*` but `fd_write`
//!   on 1 / 2 — trap `a build has no file system: …`;
//! - process: `environ_*`, `args_*` — trap `a build has no process: …`;
//!   `proc_exit` — trap `a build does not exit the process`;
//! - `sched_yield` answers 0.
//!
//! A trap's message is the plain fact; the evaluator locates it at the
//! expression being evaluated (451 (3), 878's shape), as it does today.
//!
//! **Time and interrupt** (878, 1059 (5)): no default limit — a body runs to
//! its end (380 (2)). The store is watched by the runner's `StoreWatch`, so
//! `runner.interrupt()` ends an evaluation in flight (`interrupted_text`, the
//! reply comptime answers today) and a deadline a caller arms
//! (`Options.deadline_ns`: `run`, `test` or the LSP's cancel, never a flag or
//! a variable) ends it with `timed_out_text`. Each evaluation runs on a thread
//! whose stack holds the engine's wasm stack (`engine.onWasmStack`).
const std = @import("std");
const engine = @import("engine.zig");
const runner = @import("runner.zig");
const ru = @import("runtime_unit.zig");
const wat_ast = @import("wat_ast.zig");
const c = engine.c;

pub const Error = std.mem.Allocator.Error;

/// One core unit of an evaluation: the name its importers name it by and its
/// bytes (binary, or `.wat` text in a test).
pub const Unit = struct {
    name: []const u8,
    bytes: []const u8,
};

/// Which reset an evaluation gets (1059 (1)): a store and instances of its
/// own, never a saved `__heap_ptr` restored over a kept instance.
pub const reset: enum { fresh_instance, heap_ptr_restored } = .fresh_instance;

pub const Options = struct {
    /// The `.cwasm` folder (`<cache root>/.botopinkbuild/cache/wasmtime/`),
    /// null to keep compiled code in the process only.
    cache_dir: ?[]const u8 = null,
    /// `--cold`: read no `.cwasm`, write what compiled.
    cold: bool = false,
    /// The deadline, armed only by `run`, `test` or the LSP's cancel (1059
    /// (5)); null runs to the end or to `runner.interrupt()`.
    deadline_ns: ?u64 = null,
};

/// Decision 451's refusal of an unseeded draw, the words the term runtime
/// raises today.
pub const entropy_text = "an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)";
pub const exit_text = "a build does not exit the process";
/// An evaluation `runner.interrupt()` ended: the reply comptime answers today
/// (`persistent_wat.interrupted_reply`, decision 878), which the evaluators
/// read as `comptime-interrupted`.
pub const interrupted_text = "wasmtime: interrupted";
/// An evaluation its deadline ended (1059 (5), 1034 (3)).
pub const timed_out_text = "wasm trap: time limit reached";

/// The named fact of a host service a build does not have, for the function
/// `name` (1059 (3)). Owned.
pub fn namedText(alloc: std.mem.Allocator, service: Service, name: []const u8) Error![]u8 {
    return switch (service) {
        .clock => std.fmt.allocPrint(alloc, "a build has no clock: {s} reads the time when the program runs", .{name}),
        .files => std.fmt.allocPrint(alloc, "a build has no file system: {s} reads a file when the program runs", .{name}),
        .environment => std.fmt.allocPrint(alloc, "a build has no process: {s} reads the environment when the program runs", .{name}),
        .exit => alloc.dupe(u8, exit_text),
        .entropy => alloc.dupe(u8, entropy_text),
        .print, .yield => unreachable,
    };
}

pub const Outcome = union(enum) {
    /// The evaluation export's reply JSON, as the codec wrote it.
    reply: []u8,
    /// No codec ran: the reply the host built, and its message.
    raised: struct { reply: []u8, message: []u8 },
    /// A unit the engine refused, an import the host does not serve, or a
    /// crossing export missing.
    compile_error: []u8,
};

pub const Answer = struct {
    outcome: Outcome,
    /// What fd 1 and 2 received, in order.
    printed: []u8,
    end: runner.End = .exited,

    pub fn deinit(self: Answer, alloc: std.mem.Allocator) void {
        switch (self.outcome) {
            .reply, .compile_error => |t| alloc.free(t),
            .raised => |r| {
                alloc.free(r.reply);
                alloc.free(r.message);
            },
        }
        alloc.free(self.printed);
    }
};

/// Run one evaluation of the module `module`'s body. See the file comment.
/// Every text of the answer is owned by `alloc`.
pub fn evaluate(alloc: std.mem.Allocator, io: std.Io, units: []const Unit, module: []const u8, input: []const u8, opts: Options) Error!Answer {
    const modules = try alloc.alloc(*c.wasmtime_module_t, units.len);
    defer alloc.free(modules);
    var loaded: usize = 0;
    defer for (modules[0..loaded]) |m| c.wasmtime_module_delete(m);
    for (units) |u| {
        var failure: ?[]u8 = null;
        const code = (try runner.load(alloc, io, opts.cache_dir, u.bytes, .module, opts.cold, &failure)) orelse {
            defer alloc.free(failure.?);
            return refused(alloc, try std.fmt.allocPrint(alloc, "unit {s}: {s}", .{ u.name, failure.? }));
        };
        modules[loaded] = code.module;
        loaded += 1;
    }
    var job: Job = .{ .alloc = alloc, .units = units, .module = module, .modules = modules, .input = input, .opts = opts };
    return engine.onWasmStack(Job.run, .{&job});
}

fn refused(alloc: std.mem.Allocator, text: []u8) Error!Answer {
    return .{ .outcome = .{ .compile_error = text }, .printed = try alloc.dupe(u8, "") };
}

/// `{"kind":"error","message":<message>}`, with `"printed"` when `printed`
/// is not empty: the reply the host builds when no codec ran (1059 (2)).
pub fn hostReply(alloc: std.mem.Allocator, message: []const u8, printed: []const u8) Error![]u8 {
    var out: std.Io.Writer.Allocating = .init(alloc);
    defer out.deinit();
    var s: std.json.Stringify = .{ .writer = &out.writer };
    s.beginObject() catch return error.OutOfMemory;
    s.objectField("kind") catch return error.OutOfMemory;
    s.write("error") catch return error.OutOfMemory;
    s.objectField("message") catch return error.OutOfMemory;
    s.write(message) catch return error.OutOfMemory;
    if (printed.len > 0) {
        s.objectField("printed") catch return error.OutOfMemory;
        s.write(printed) catch return error.OutOfMemory;
    }
    s.endObject() catch return error.OutOfMemory;
    return out.toOwnedSlice();
}

/// What a run of the units came to, before the reply is settled.
const Ran = union(enum) {
    reply: []u8,
    raised: []u8,
    compile_error: []u8,

    fn free(r: Ran, alloc: std.mem.Allocator) void {
        switch (r) {
            inline else => |t| alloc.free(t),
        }
    }
};

const Job = struct {
    alloc: std.mem.Allocator,
    units: []const Unit,
    module: []const u8,
    modules: []const *c.wasmtime_module_t,
    input: []const u8,
    opts: Options,

    fn run(job: *Job) Error!Answer {
        const alloc = job.alloc;
        var host: Host = .{ .alloc = alloc };
        defer host.deinit();
        var end: runner.End = .exited;
        var ran = try job.evaluateIn(&host, &end);
        switch (end) {
            .exited => {},
            .interrupted, .timed_out => {
                ran.free(alloc);
                ran = .{ .raised = try alloc.dupe(u8, if (end == .interrupted) interrupted_text else timed_out_text) };
            },
        }
        const printed = try alloc.dupe(u8, host.printed.items);
        errdefer alloc.free(printed);
        const outcome: Outcome = switch (ran) {
            .reply => |r| .{ .reply = r },
            .compile_error => |t| .{ .compile_error = t },
            .raised => |m| .{ .raised = .{ .reply = try hostReply(alloc, m, printed), .message = m } },
        };
        return .{ .outcome = outcome, .printed = printed, .end = end };
    }

    fn evaluateIn(job: *Job, host: *Host, end: *runner.End) Error!Ran {
        const alloc = job.alloc;
        const eng = try engine.theEngine();
        const linker = c.wasmtime_linker_new(eng) orelse return error.OutOfMemory;
        defer c.wasmtime_linker_delete(linker);
        const store = c.wasmtime_store_new(eng, null, null) orelse return error.OutOfMemory;
        defer c.wasmtime_store_delete(store);
        const ctx = c.wasmtime_store_context(store).?;
        var watch: runner.StoreWatch = undefined;
        watch.begin(store, job.opts.deadline_ns);
        defer end.* = watch.end();

        const instances = try alloc.alloc(c.wasmtime_instance_t, job.units.len);
        defer alloc.free(instances);

        for (job.units, job.modules, 0..) |u, m, i| {
            if (try defineImports(alloc, linker, host, u, m, job.units[0..i])) |refusal|
                return .{ .compile_error = refusal };
            var trap: ?*c.wasm_trap_t = null;
            if (c.wasmtime_linker_instantiate(linker, ctx, m, &instances[i], &trap)) |err| {
                const prefix = try std.fmt.allocPrint(alloc, "unit {s}: ", .{u.name});
                defer alloc.free(prefix);
                return .{ .compile_error = try engine.errorText(alloc, prefix, err) };
            }
            if (trap) |t| return .{ .raised = try host.trapText(t) };
            if (c.wasmtime_linker_define_instance(linker, ctx, u.name.ptr, u.name.len, &instances[i])) |err|
                return .{ .compile_error = try engine.errorText(alloc, "linker: ", err) };
        }
        for (instances) |*inst| {
            var f: c.wasmtime_func_t = undefined;
            if (!exportFunc(ctx, inst, wat_ast.host_init_export, &f)) continue;
            if (try host.call(ctx, &f, &.{}, &.{})) |e| return .{ .raised = e };
        }
        return job.cross(host, ctx, instances);
    }

    /// The input in, the evaluation, the reply out (`runtime_unit.zig`'s
    /// crossing constants).
    fn cross(job: *Job, host: *Host, ctx: *c.wasmtime_context_t, instances: []c.wasmtime_instance_t) Error!Ran {
        const alloc = job.alloc;
        const core = unitNamed(job.units, instances, ru.name) orelse
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "no unit is {s}, whose memory the JSON crosses through", .{ru.name}) };
        const entry = unitNamed(job.units, instances, job.module) orelse
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "no unit is {s}, the module evaluated", .{job.module}) };

        var alloc_f: c.wasmtime_func_t = undefined;
        if (!exportFunc(ctx, core, ru.alloc_export, &alloc_f))
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no function {s}", .{ ru.name, ru.alloc_export }) };
        var eval_f: c.wasmtime_func_t = undefined;
        if (!exportFunc(ctx, entry, ru.comptime_eval_export, &eval_f))
            return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no function {s}", .{ job.module, ru.comptime_eval_export }) };

        var r: [2]c.wasmtime_val_t = undefined;
        if (try host.call(ctx, &alloc_f, &.{i32Val(@intCast(job.input.len))}, r[0..1])) |e| return .{ .raised = e };
        const in_ptr: u32 = @bitCast(r[0].of.i32);
        {
            const mem = memoryOf(ctx, core, ru.memory_export) orelse
                return .{ .compile_error = try std.fmt.allocPrint(alloc, "{s} exports no memory {s}", .{ ru.name, ru.memory_export }) };
            if (@as(usize, in_ptr) + job.input.len > mem.len)
                return .{ .raised = try alloc.dupe(u8, "the input does not fit the core unit's memory") };
            @memcpy(mem[in_ptr..][0..job.input.len], job.input);
        }
        if (try host.call(ctx, &eval_f, &.{ i32Val(@bitCast(in_ptr)), i32Val(@intCast(job.input.len)) }, r[0..2])) |e| return .{ .raised = e };
        const out_ptr: u32 = @bitCast(r[0].of.i32);
        const out_len: u32 = @bitCast(r[1].of.i32);
        // The memory may have grown during the evaluation: read it again.
        const mem = memoryOf(ctx, core, ru.memory_export).?;
        if (@as(usize, out_ptr) + out_len > mem.len)
            return .{ .raised = try alloc.dupe(u8, "the reply lies outside the core unit's memory") };
        return .{ .reply = try alloc.dupe(u8, mem[out_ptr..][0..out_len]) };
    }
};

fn unitNamed(units: []const Unit, instances: []c.wasmtime_instance_t, name: []const u8) ?*c.wasmtime_instance_t {
    for (units, instances) |u, *inst| if (std.mem.eql(u8, u.name, name)) return inst;
    return null;
}

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

/// What a host import does (1059 (4)).
pub const Service = enum { print, clock, entropy, files, environment, exit, yield };

/// The service of the import `module.name`, null when the host serves no
/// such import (a unit's import of another unit, or one refused).
pub fn serviceOf(module: []const u8, name: []const u8) ?Service {
    if (std.mem.eql(u8, name, "bp_random_f64")) return .entropy;
    if (std.mem.eql(u8, module, "bp_host")) return .clock;
    if (std.mem.eql(u8, module, "bp_fs")) return .files;
    if (!std.mem.eql(u8, module, "wasi_snapshot_preview1")) return null;
    const eq = std.mem.eql;
    if (eq(u8, name, "fd_write")) return .print;
    if (eq(u8, name, "random_get")) return .entropy;
    if (eq(u8, name, "clock_time_get") or eq(u8, name, "clock_res_get") or eq(u8, name, "poll_oneoff")) return .clock;
    if (eq(u8, name, "sched_yield")) return .yield;
    if (eq(u8, name, "proc_exit")) return .exit;
    if (std.mem.startsWith(u8, name, "environ_") or std.mem.startsWith(u8, name, "args_")) return .environment;
    if (std.mem.startsWith(u8, name, "fd_") or std.mem.startsWith(u8, name, "path_")) return .files;
    return null;
}

/// The function a named fact names: the import's own name for WASI's, the
/// host module's and its name for botopink's (`bp_fs.open`). The std
/// function behind it is the evaluator's to name (the frames).
fn shownName(alloc: std.mem.Allocator, module: []const u8, name: []const u8) Error![]u8 {
    if (std.mem.eql(u8, module, "wasi_snapshot_preview1")) return alloc.dupe(u8, name);
    return std.fmt.allocPrint(alloc, "{s}.{s}", .{ module, name });
}

/// One host import as defined: the callback's `env`.
const Import = struct {
    host: *Host,
    service: Service,
    /// The named fact it traps with (null for print and yield).
    text: ?[]u8,
};

const Host = struct {
    alloc: std.mem.Allocator,
    printed: std.ArrayList(u8) = .empty,
    imports: std.ArrayList(*Import) = .empty,
    defined: std.StringHashMapUnmanaged(void) = .empty,
    /// The text of the named trap a host import raised, for the call that
    /// raised it.
    named: ?[]const u8 = null,
    /// An allocation in a callback failed.
    oom: bool = false,

    fn deinit(host: *Host) void {
        const alloc = host.alloc;
        host.printed.deinit(alloc);
        for (host.imports.items) |imp| {
            if (imp.text) |t| alloc.free(t);
            alloc.destroy(imp);
        }
        host.imports.deinit(alloc);
        var it = host.defined.keyIterator();
        while (it.next()) |k| alloc.free(k.*);
        host.defined.deinit(alloc);
    }

    /// Call `f`; null when it returned (its results in `results`), else the
    /// runtime error's text (owned).
    fn call(host: *Host, ctx: *c.wasmtime_context_t, f: *const c.wasmtime_func_t, args: []const c.wasmtime_val_t, results: []c.wasmtime_val_t) Error!?[]u8 {
        var trap: ?*c.wasm_trap_t = null;
        host.named = null;
        const err = c.wasmtime_func_call(ctx, f, args.ptr, args.len, results.ptr, results.len, &trap);
        if (host.oom) return error.OutOfMemory;
        if (err) |e| {
            // The epoch callback's error (interrupt, deadline): `Job.run`
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
        const gop = host.defined.getOrPut(alloc, key) catch |e| {
            alloc.free(key);
            return e;
        };
        if (gop.found_existing) {
            alloc.free(key);
            continue;
        }
        const ty = c.wasm_externtype_as_functype_const(c.wasm_importtype_type(imp)) orelse
            return try std.fmt.allocPrint(alloc, "unit {s} imports {s}.{s} as no function: the comptime host serves functions only", .{ unit.name, m, n });
        const entry = try alloc.create(Import);
        entry.* = .{ .host = host, .service = service, .text = null };
        host.imports.append(alloc, entry) catch |e| {
            alloc.destroy(entry);
            return e;
        };
        if (service != .yield) {
            // `fd_write` beyond fd 1 / 2 is a file.
            const shown = try shownName(alloc, m, n);
            defer alloc.free(shown);
            entry.text = try namedText(alloc, if (service == .print) .files else service, shown);
        }
        const cb: c.wasmtime_func_callback_t = switch (service) {
            .print => fdWrite,
            .yield => yieldZero,
            else => raise,
        };
        if (c.wasmtime_linker_define_func(linker, m.ptr, m.len, n.ptr, n.len, ty, cb, entry, null)) |err|
            return try engine.errorText(alloc, "linker: ", err);
    }
    return null;
}

fn trapWith(imp: *Import) ?*c.wasm_trap_t {
    const text = imp.text.?;
    imp.host.named = text;
    return c.wasmtime_trap_new(text.ptr, text.len);
}

fn raise(env: ?*anyopaque, _: ?*c.wasmtime_caller_t, _: [*c]const c.wasmtime_val_t, _: usize, _: [*c]c.wasmtime_val_t, _: usize) callconv(.c) ?*c.wasm_trap_t {
    return trapWith(@ptrCast(@alignCast(env.?)));
}

fn yieldZero(_: ?*anyopaque, _: ?*c.wasmtime_caller_t, _: [*c]const c.wasmtime_val_t, _: usize, results: [*c]c.wasmtime_val_t, nresults: usize) callconv(.c) ?*c.wasm_trap_t {
    if (nresults > 0) {
        results[0].kind = c.WASMTIME_I32;
        results[0].of.i32 = 0;
    }
    return null;
}

/// WASI's errno `fd_write` answers for an iovec outside the memory.
const errno_fault = 21;

/// `fd_write(fd, iovs, iovs_len, nwritten) -> errno` over the caller's
/// `memory`: fd 1 and 2 append to the evaluation's printed text; any other
/// fd is a file, and traps as one.
fn fdWrite(env: ?*anyopaque, caller: ?*c.wasmtime_caller_t, args: [*c]const c.wasmtime_val_t, nargs: usize, results: [*c]c.wasmtime_val_t, nresults: usize) callconv(.c) ?*c.wasm_trap_t {
    const imp: *Import = @ptrCast(@alignCast(env.?));
    const host = imp.host;
    if (nargs != 4 or nresults != 1) return trapWith(imp);
    const fd = args[0].of.i32;
    if (fd != 1 and fd != 2) return trapWith(imp);
    results[0].kind = c.WASMTIME_I32;
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

const snap = @import("../../utils/snap.zig");

/// A runtime core in the shape `runtime_unit.zig` writes: the memory, a bump
/// `__alloc`, `fd_write` imported from the host; its `__bp_init` sets the
/// heap start and `order` to 1.
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

/// Another module's unit after the evaluated one, with an evaluation export
/// of its own answering `"other"`: the host must not pick it by position.
const other_wat =
    \\(module $other
    \\  (import "std@__rt" "memory" (memory 1))
    \\  (data (i32.const 600) "\22other\22")
    \\  (func (export "__bp_comptime_eval") (param i32 i32) (result i32 i32) (i32.const 600) (i32.const 7)))
;

fn units2(comptime tag: []const u8) [2]Unit {
    return .{ .{ .name = "std@__rt", .bytes = coreWat(tag) }, .{ .name = "app@main", .bytes = entryWat(tag) } };
}

fn replyOf(a: Answer) ![]const u8 {
    if (a.outcome != .reply) {
        std.debug.print("\n{s}: {s}\n", .{ @tagName(a.outcome), switch (a.outcome) {
            .reply, .compile_error => |t| t,
            .raised => |r| r.message,
        } });
        return error.TestUnexpectedResult;
    }
    return a.outcome.reply;
}

test "comptime host: units linked, __bp_init in order, the JSON crosses in and out, print captured" {
    const alloc = std.testing.allocator;
    const units = units2("roundtrip");
    const a = try evaluate(alloc, std.testing.io, &units, "app@main", "[1,\"x\"]", .{});
    defer a.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":[1,\"x\"],\"order\":2}", try replyOf(a));
    try std.testing.expectEqualStrings("[1,\"x\"]", a.printed);
    try std.testing.expectEqual(runner.End.exited, a.end);
}

test "comptime host: the evaluated unit is chosen by module name, never by position" {
    const alloc = std.testing.allocator;
    const two = units2("by-name");
    const units = [_]Unit{ two[0], two[1], .{ .name = "app@other", .bytes = other_wat } };
    const main = try evaluate(alloc, std.testing.io, &units, "app@main", "1", .{});
    defer main.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":1,\"order\":2}", try replyOf(main));
    const other = try evaluate(alloc, std.testing.io, &units, "app@other", "1", .{});
    defer other.deinit(alloc);
    try std.testing.expectEqualStrings("\"other\"", try replyOf(other));
    const none = try evaluate(alloc, std.testing.io, &units, "app@absent", "1", .{});
    defer none.deinit(alloc);
    try std.testing.expectEqualStrings("no unit is app@absent, the module evaluated", none.outcome.compile_error);
}

test "comptime host: every evaluation starts from fresh instances (reset)" {
    const alloc = std.testing.allocator;
    try std.testing.expectEqual(.fresh_instance, reset);
    const units = units2("fresh");
    for (0..2) |_| {
        const a = try evaluate(alloc, std.testing.io, &units, "app@main", "7", .{});
        defer a.deinit(alloc);
        try std.testing.expectEqualStrings("{\"in\":7,\"order\":2}", try replyOf(a));
    }
}

/// One unit, the core and the evaluated module at once, importing a host
/// service and calling it from the evaluation after printing `hi`.
fn serviceWat(comptime import: []const u8, comptime sig: []const u8, comptime call: []const u8) []const u8 {
    return "(module\n  (import " ++ import ++ " (func $h " ++ sig ++ "))\n" ++
        \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 32) "hi\0a")
        \\  (data (i32.const 48) "{\22ok\22:0}")
        \\  (func (export "__alloc") (param i32) (result i32) (i32.const 64))
        \\  (func (export "__bp_comptime_eval") (param i32 i32) (result i32 i32)
        \\    (i32.store (i32.const 0) (i32.const 32))
        \\    (i32.store (i32.const 4) (i32.const 3))
        \\    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 8)))
        \\
    ++ "    " ++ call ++ "\n" ++
        \\    (i32.const 48) (i32.const 8)))
    ;
}

const Case = struct { label: []const u8, wat: []const u8 };

/// Every host service a build does not have, one call each (1059 (4)).
const service_cases = [_]Case{
    .{ .label = "clock_time_get", .wat = serviceWat("\"wasi_snapshot_preview1\" \"clock_time_get\"", "(param i32 i64 i32) (result i32)", "(drop (call $h (i32.const 0) (i64.const 1) (i32.const 0)))") },
    .{ .label = "clock_res_get", .wat = serviceWat("\"wasi_snapshot_preview1\" \"clock_res_get\"", "(param i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0)))") },
    .{ .label = "poll_oneoff", .wat = serviceWat("\"wasi_snapshot_preview1\" \"poll_oneoff\"", "(param i32 i32 i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0)))") },
    .{ .label = "bp_host.delay", .wat = serviceWat("\"bp_host\" \"delay\"", "(param i32) (result i32)", "(drop (call $h (i32.const 10)))") },
    .{ .label = "random_get", .wat = serviceWat("\"wasi_snapshot_preview1\" \"random_get\"", "(param i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 8)))") },
    .{ .label = "env.bp_random_f64", .wat = serviceWat("\"env\" \"bp_random_f64\"", "(result f64)", "(drop (call $h))") },
    .{ .label = "bp_fs.open", .wat = serviceWat("\"bp_fs\" \"open\"", "(param i32 i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0) (i32.const 0)))") },
    .{ .label = "path_open", .wat = serviceWat("\"wasi_snapshot_preview1\" \"path_open\"", "(param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)", "(drop (call $h (i32.const 3) (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0) (i64.const 0) (i64.const 0) (i32.const 0) (i32.const 0)))") },
    .{ .label = "fd_read", .wat = serviceWat("\"wasi_snapshot_preview1\" \"fd_read\"", "(param i32 i32 i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0)))") },
    .{ .label = "fd_write on fd 3", .wat = serviceWat("\"wasi_snapshot_preview1\" \"fd_close\"", "(param i32) (result i32)", "(drop (call $fd_write (i32.const 3) (i32.const 0) (i32.const 1) (i32.const 8)))") },
    .{ .label = "environ_get", .wat = serviceWat("\"wasi_snapshot_preview1\" \"environ_get\"", "(param i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0)))") },
    .{ .label = "args_sizes_get", .wat = serviceWat("\"wasi_snapshot_preview1\" \"args_sizes_get\"", "(param i32 i32) (result i32)", "(drop (call $h (i32.const 0) (i32.const 0)))") },
    .{ .label = "proc_exit", .wat = serviceWat("\"wasi_snapshot_preview1\" \"proc_exit\"", "(param i32)", "(call $h (i32.const 0))") },
    .{ .label = "sched_yield", .wat = serviceWat("\"wasi_snapshot_preview1\" \"sched_yield\"", "(result i32)", "(drop (call $h))") },
};

test "comptime host: comptime_host_named_traps — each service a build lacks traps with its fact, and the host builds the reply" {
    const alloc = std.testing.allocator;
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(alloc);
    for (service_cases) |case_| {
        const units = [_]Unit{.{ .name = "std@__rt", .bytes = case_.wat }};
        const a = try evaluate(alloc, std.testing.io, &units, "std@__rt", "", .{});
        defer a.deinit(alloc);
        const reply = switch (a.outcome) {
            .reply => |r| r,
            .raised => |r| r.reply,
            .compile_error => |t| t,
        };
        try text.print(alloc, "{s} ({s})\n{s}\n\n", .{ case_.label, @tagName(a.outcome), reply });
    }
    // The deadline, armed by a caller: no codec ran, the host replies.
    const spin = [_]Unit{.{ .name = "std@__rt", .bytes = spin_eval }};
    const d = try evaluate(alloc, std.testing.io, &spin, "std@__rt", "", .{ .deadline_ns = 50 * std.time.ns_per_ms });
    defer d.deinit(alloc);
    try text.print(alloc, "deadline ({s})\n{s}\n", .{ @tagName(d.outcome), d.outcome.raised.reply });
    try snap.checkText(alloc, "comptime/runtime/comptime_host_named_traps", text.items);
}

test "comptime host: an import of no earlier unit and no host service is refused, naming it" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = serviceWat("\"env\" \"elsewhere\"", "", "(call $h)") }};
    const a = try evaluate(alloc, std.testing.io, &units, "std@__rt", "", .{});
    defer a.deinit(alloc);
    try std.testing.expect(std.mem.indexOf(u8, a.outcome.compile_error, "env.elsewhere") != null);
}

const spin_eval = serviceWat("\"wasi_snapshot_preview1\" \"sched_yield\"", "(result i32)", "(loop $l (br $l))");

test "comptime host: no default limit; an armed deadline stops a loop, and the next evaluation runs" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{.{ .name = "std@__rt", .bytes = spin_eval }};
    const a = try evaluate(alloc, std.testing.io, &units, "std@__rt", "", .{ .deadline_ns = 50 * std.time.ns_per_ms });
    defer a.deinit(alloc);
    try std.testing.expectEqual(runner.End.timed_out, a.end);
    try std.testing.expectEqualStrings(timed_out_text, a.outcome.raised.message);
    try std.testing.expectEqualStrings("hi\n", a.printed);
    try std.testing.expect(!runner.running());
    try std.testing.expectEqual(@as(?u64, null), (Options{}).deadline_ns);

    const ok = units2("after-deadline");
    const b = try evaluate(alloc, std.testing.io, &ok, "app@main", "1", .{});
    defer b.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":1,\"order\":2}", try replyOf(b));
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
    // The deadline only bounds the test if the interrupt never comes.
    const a = try evaluate(alloc, std.testing.io, &units, "std@__rt", "", .{ .deadline_ns = 20 * std.time.ns_per_s });
    defer a.deinit(alloc);
    try std.testing.expectEqual(runner.End.interrupted, a.end);
    try std.testing.expectEqualStrings(interrupted_text, a.outcome.raised.message);
}

/// `depth(n)` recurses `n` times with no tail call, as an Erlang-shaped loop
/// does; `app@deep` within the 64 MiB wasm stack (past wasmtime's 512 KiB
/// default), `app@too_deep` past it.
const depth_core =
    \\(module $depth
    \\  (memory (export "memory") 1)
    \\  (func (export "__alloc") (param i32) (result i32) (i32.const 64))
    \\  (func $depth (export "depth") (param i32) (result i32)
    \\    (if (result i32) (i32.eqz (local.get 0)) (then (i32.const 0))
    \\      (else (i32.add (i32.const 1) (call $depth (i32.sub (local.get 0) (i32.const 1))))))))
;

fn depthEntry(comptime n: []const u8) []const u8 {
    return
    \\(module
    \\  (import "std@__rt" "depth" (func $depth (param i32) (result i32)))
    \\  (func (export "__bp_comptime_eval") (param i32 i32) (result i32 i32)
    \\    (drop (call $depth (i32.const
    ++ " " ++ n ++
        \\))) (i32.const 0) (i32.const 0)))
    ;
}

test "comptime host: deep recursion runs on the 64 MiB wasm stack; past it, call stack exhausted" {
    const alloc = std.testing.allocator;
    const units = [_]Unit{
        .{ .name = "std@__rt", .bytes = depth_core },
        .{ .name = "app@deep", .bytes = depthEntry("200000") },
        .{ .name = "app@too_deep", .bytes = depthEntry("100000000") },
    };
    const deep = try evaluate(alloc, std.testing.io, &units, "app@deep", "", .{});
    defer deep.deinit(alloc);
    try std.testing.expectEqualStrings("", try replyOf(deep));
    const too = try evaluate(alloc, std.testing.io, &units, "app@too_deep", "", .{});
    defer too.deinit(alloc);
    try std.testing.expectEqualStrings("wasmtime: call stack exhausted", too.outcome.raised.message);
}

test "comptime host: the .cwasm of each unit is written once and reused by a second call" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);
    const units = units2("cwasm");

    const first = try evaluate(alloc, io, &units, "app@main", "1", .{ .cache_dir = dir });
    defer first.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":1,\"order\":2}", try replyOf(first));
    var stats: [2]std.Io.File.Stat = undefined;
    for (units, 0..) |u, i| {
        const path = try engine.cachePath(alloc, dir, .module, u.bytes);
        defer alloc.free(path);
        stats[i] = try std.Io.Dir.cwd().statFile(io, path, .{});
    }

    const second = try evaluate(alloc, io, &units, "app@main", "2", .{ .cache_dir = dir });
    defer second.deinit(alloc);
    try std.testing.expectEqualStrings("{\"in\":2,\"order\":2}", try replyOf(second));
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
