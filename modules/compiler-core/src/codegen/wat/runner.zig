//! The in-process runner of a wasm program (decisions 1032 (3), 1034; pieces
//! R0, R1): `botopink run --target wasm`, `botopink test` on wasm and the
//! codegen snapshot harness run a program here, on the process's engine
//! (`engine.zig`), never through the `wasmtime` CLI.
//!
//! Two shapes run: `run` a component whose core units are given to the
//! component linker by name (`wasmtime_component_linker_instance_add_module`),
//! WASI p2 added, `wasi:cli/run@0.2.0`'s `run` called; `runCore` a core
//! module over WASI preview 1 (the harness's binary), its `_start` called —
//! `runCoreWith` after defining the core units it imports by name, and
//! `invokeCore` calls any core export and answers its value.
//!
//! The outcome is the process's: `status` comes from the WASI exit status the
//! engine reports (`wasmtime_error_exit_status`), 0 for a `run` that returns
//! ok, 1 for one that returns err or traps — a trap keeps its `wasm trap: …`
//! line in `trap` (decision 1034 (3)), any other failure the last line of the
//! engine's error chain. stdout and stderr are each inherited, captured, or
//! both (`tee`); argv, the environment and stdin as the caller says.
//!
//! A program's needs (decision 518) choose only the host services it is
//! given (1034 (7)): `http` adds `wasi:http` and the host's network,
//! `filesystem` preopens `/` and the working directory, each under its own
//! path. The engine's features are the same for every program.
//!
//! **Time and Ctrl+C** (1034 (2), decision 878): every store has an epoch
//! deadline of one tick and a deadline callback. A run with a time limit has
//! a watchdog thread that moves the epoch when the limit passes; `interrupt`
//! (the CLI's SIGINT handler) moves it at once. Each store's callback decides
//! for itself: it ends its run when the run's own limit passed or an
//! interrupt came after the run began, and otherwise lets it go on, so a tick
//! meant for one run never ends another. `Outcome.end` says which.
//!
//! **Loaded code** (1034 (9)): `load` keeps the last 64 compiled modules and
//! components of the process in memory, over the `.cwasm` cache of
//! `engine.precompiled`.
const std = @import("std");
const engine_mod = @import("engine.zig");
const ast = @import("../../ast.zig");
const c = engine_mod.c;

pub const Error = std.mem.Allocator.Error;

/// A core module the component imports as `name`.
pub const Unit = struct {
    name: []const u8,
    module: *c.wasmtime_module_t,
};

pub const Stdio = enum {
    inherit,
    capture,
    /// Written to the host's stream as it comes, and captured too.
    tee,
};

pub const EnvVar = struct { name: []const u8, value: []const u8 };

pub const Env = union(enum) {
    /// No variable at all.
    none,
    /// The host process's environment.
    inherit,
    list: []const EnvVar,
};

pub const Options = struct {
    stdout: Stdio = .inherit,
    stderr: Stdio = .inherit,
    stdin_inherit: bool = false,
    argv: []const []const u8 = &.{},
    env: Env = .none,
    /// The host services the program is given (decision 1034 (7)).
    needs: ast.WasmNeeds = .initEmpty(),
    /// The absolute working directory a `filesystem` program is given as a
    /// second preopen, under its own path (decision 992).
    cwd: ?[]const u8 = null,
    /// The time limit; null runs to the end (or to an `interrupt`).
    timeout_ns: ?u64 = null,
};

pub const End = enum { exited, interrupted, timed_out };

pub const Outcome = struct {
    status: i32,
    /// The captured stdout / stderr, when asked for; owned by the caller.
    stdout: ?[]u8 = null,
    stderr: ?[]u8 = null,
    /// A trap's `wasm trap: …` line, or the last line of another failure; owned.
    trap: ?[]u8 = null,
    end: End = .exited,

    pub fn deinit(self: Outcome, alloc: std.mem.Allocator) void {
        if (self.stdout) |s| alloc.free(s);
        if (self.stderr) |s| alloc.free(s);
        if (self.trap) |t| alloc.free(t);
    }
};

// ── interrupt and time limit ─────────────────────────────────────────────────

/// Moved by `interrupt`; a run compares it with the value it began under.
var interrupt_gen: std.atomic.Value(u32) = .init(0);
/// The runs in progress, on any thread.
var active: std.atomic.Value(u32) = .init(0);

/// Whether a program is running now. Signal-safe.
pub fn running() bool {
    return active.load(.acquire) != 0;
}

/// End every run in progress (`Outcome.end == .interrupted`). Signal-safe.
pub fn interrupt() void {
    _ = interrupt_gen.fetchAdd(1, .acq_rel);
    engine_mod.incrementEpoch();
}

const Watch = struct {
    gen: u32,
    deadline: ?u64,
    timed_out: std.atomic.Value(bool) = .init(false),
    done: std.atomic.Value(bool) = .init(false),
    end: End = .exited,
};

fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) return 0;
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

/// The watchdog of a run with a time limit: it polls, and moves the epoch
/// once when the limit passed (the store's callback then ends that run).
fn watchdog(w: *Watch) void {
    const deadline = w.deadline.?;
    while (!w.done.load(.acquire)) {
        const now = nowNs();
        if (now >= deadline) {
            w.timed_out.store(true, .release);
            engine_mod.incrementEpoch();
            return;
        }
        const left = @min(deadline - now, 5 * std.time.ns_per_ms);
        var ts: std.c.timespec = .{ .sec = 0, .nsec = @intCast(left) };
        _ = std.c.nanosleep(&ts, &ts);
    }
}

fn onDeadline(
    _: ?*c.wasmtime_context_t,
    data: ?*anyopaque,
    delta: [*c]u64,
    kind: [*c]c.wasmtime_update_deadline_kind_t,
) callconv(.c) ?*c.wasmtime_error_t {
    const w: *Watch = @ptrCast(@alignCast(data.?));
    if (interrupt_gen.load(.acquire) != w.gen) {
        w.end = .interrupted;
        return c.wasmtime_error_new("interrupted");
    }
    if (w.timed_out.load(.acquire)) {
        w.end = .timed_out;
        return c.wasmtime_error_new("time limit reached");
    }
    // Another run's tick: go on.
    delta.* = 1;
    kind.* = c.WASMTIME_UPDATE_DEADLINE_CONTINUE;
    return null;
}

// ── the session: a store, its WASI context, its watch ───────────────────────

const Capture = struct {
    alloc: std.mem.Allocator,
    mode: Stdio = .inherit,
    fd: c_int,
    buf: std.ArrayList(u8) = .empty,

    fn write(data: ?*anyopaque, bytes: [*c]const u8, len: usize) callconv(.c) isize {
        const self: *Capture = @ptrCast(@alignCast(data.?));
        if (self.mode == .tee) {
            var off: usize = 0;
            while (off < len) {
                const n = std.c.write(self.fd, bytes + off, len - off);
                if (n <= 0) break;
                off += @intCast(n);
            }
        }
        self.buf.appendSlice(self.alloc, bytes[0..len]) catch return -12; // ENOMEM
        return @intCast(len);
    }
};

const Session = struct {
    alloc: std.mem.Allocator,
    store: *c.wasmtime_store_t,
    ctx: *c.wasmtime_context_t,
    out: Capture,
    err: Capture,
    watch: Watch,
    thread: ?std.Thread = null,

    /// A store with the WASI context `opts` describes. Null with `failure`
    /// set when the host refused a part of it. `self` must not move after.
    fn begin(self: *Session, alloc: std.mem.Allocator, opts: Options, http: bool, failure: *?Outcome) Error!void {
        const eng = try engine_mod.theEngine();
        self.* = .{
            .alloc = alloc,
            .store = c.wasmtime_store_new(eng, null, null) orelse return error.OutOfMemory,
            .ctx = undefined,
            .out = .{ .alloc = alloc, .mode = opts.stdout, .fd = 1 },
            .err = .{ .alloc = alloc, .mode = opts.stderr, .fd = 2 },
            .watch = .{ .gen = interrupt_gen.load(.acquire), .deadline = if (opts.timeout_ns) |t| nowNs() + t else null },
        };
        _ = active.fetchAdd(1, .acq_rel);
        self.ctx = c.wasmtime_store_context(self.store).?;
        c.wasmtime_context_set_epoch_deadline(self.ctx, 1);
        c.wasmtime_store_epoch_deadline_callback(self.store, onDeadline, &self.watch, null);

        const wasi = c.wasi_config_new() orelse return error.OutOfMemory;
        var wasi_owned = true;
        defer if (wasi_owned) c.wasi_config_delete(wasi);

        var scratch = std.heap.ArenaAllocator.init(alloc);
        defer scratch.deinit();
        const sa = scratch.allocator();
        const argv_z = try sa.alloc([*c]const u8, opts.argv.len);
        for (opts.argv, 0..) |a, i| argv_z[i] = (try sa.dupeZ(u8, a)).ptr;
        _ = c.wasi_config_set_argv(wasi, argv_z.len, argv_z.ptr);
        switch (opts.env) {
            .none => {},
            .inherit => c.wasi_config_inherit_env(wasi),
            .list => |l| {
                const names = try sa.alloc([*c]const u8, l.len);
                const values = try sa.alloc([*c]const u8, l.len);
                for (l, 0..) |v, i| {
                    names[i] = (try sa.dupeZ(u8, v.name)).ptr;
                    values[i] = (try sa.dupeZ(u8, v.value)).ptr;
                }
                _ = c.wasi_config_set_env(wasi, l.len, names.ptr, values.ptr);
            },
        }
        if (opts.stdin_inherit) c.wasi_config_inherit_stdin(wasi);
        if (opts.stdout == .inherit) c.wasi_config_inherit_stdout(wasi) else c.wasi_config_set_stdout_custom(wasi, Capture.write, &self.out, null);
        if (opts.stderr == .inherit) c.wasi_config_inherit_stderr(wasi) else c.wasi_config_set_stderr_custom(wasi, Capture.write, &self.err, null);
        if (opts.needs.contains(.filesystem)) {
            if (!c.wasi_config_preopen_dir(wasi, "/", "/", true)) {
                failure.* = try noRun(alloc, "the host could not preopen /");
                return;
            }
            if (opts.cwd) |cwd| {
                const z = try sa.dupeZ(u8, cwd);
                if (!c.wasi_config_preopen_dir(wasi, z.ptr, z.ptr, true)) {
                    failure.* = try noRun(alloc, "the host could not preopen the working directory");
                    return;
                }
            }
        }
        if (http) c.wasi_config_inherit_network(wasi);
        wasi_owned = false;
        // Takes `wasi`.
        if (c.wasmtime_context_set_wasi(self.ctx, wasi)) |err| {
            failure.* = try failed(alloc, "wasi: ", err);
            return;
        }
        if (http) c.wasmtime_context_set_wasi_http(self.ctx);

        if (self.watch.deadline != null)
            self.thread = std.Thread.spawn(.{}, watchdog, .{&self.watch}) catch null;
    }

    /// `o` with the captured streams and the run's end; the store is gone.
    fn finish(self: *Session, o: Outcome) Error!Outcome {
        self.watch.done.store(true, .release);
        if (self.thread) |t| t.join();
        c.wasmtime_store_delete(self.store);
        _ = active.fetchSub(1, .acq_rel);
        defer self.out.buf.deinit(self.alloc);
        defer self.err.buf.deinit(self.alloc);
        var out = o;
        out.end = self.watch.end;
        if (self.out.mode != .inherit) out.stdout = try self.alloc.dupe(u8, self.out.buf.items);
        if (self.err.mode != .inherit) out.stderr = try self.alloc.dupe(u8, self.err.buf.items);
        return out;
    }
};

// ── running ──────────────────────────────────────────────────────────────────

/// Instantiate `component` with `units` and run it. See the file comment.
pub fn run(alloc: std.mem.Allocator, component: *const c.wasmtime_component_t, units: []const Unit, opts: Options) Error!Outcome {
    const eng = try engine_mod.theEngine();
    const http = opts.needs.contains(.http);
    const linker = c.wasmtime_component_linker_new(eng) orelse return error.OutOfMemory;
    defer c.wasmtime_component_linker_delete(linker);

    {
        const root = c.wasmtime_component_linker_root(linker) orelse return error.OutOfMemory;
        defer c.wasmtime_component_linker_instance_delete(root);
        for (units) |u| {
            if (c.wasmtime_component_linker_instance_add_module(root, u.name.ptr, u.name.len, u.module)) |err|
                return failed(alloc, "linker: ", err);
        }
    }
    if (c.wasmtime_component_linker_add_wasip2(linker)) |err| return failed(alloc, "wasi p2: ", err);
    if (http) if (c.wasmtime_component_linker_add_wasi_http(linker)) |err| return failed(alloc, "wasi http: ", err);

    var s: Session = undefined;
    var refused: ?Outcome = null;
    try s.begin(alloc, opts, http, &refused);
    if (refused) |o| return s.finish(o);
    const ctx = s.ctx;

    var instance: c.wasmtime_component_instance_t = undefined;
    if (c.wasmtime_component_linker_instantiate(linker, ctx, component, &instance)) |err|
        return s.finish(try outcomeOf(alloc, err));

    const run_iface = c.wasmtime_component_get_export_index(component, null, "wasi:cli/run@0.2.0", "wasi:cli/run@0.2.0".len) orelse
        return s.finish(try noRun(alloc, "the component exports no wasi:cli/run@0.2.0"));
    defer c.wasmtime_component_export_index_delete(run_iface);
    const run_idx = c.wasmtime_component_get_export_index(component, run_iface, "run", 3) orelse
        return s.finish(try noRun(alloc, "wasi:cli/run@0.2.0 exports no run"));
    defer c.wasmtime_component_export_index_delete(run_idx);
    var func: c.wasmtime_component_func_t = undefined;
    if (!c.wasmtime_component_instance_get_func(&instance, ctx, run_idx, &func))
        return s.finish(try noRun(alloc, "the instance has no run function"));

    // The call overwrites (and drops) the old value: it must be a valid one,
    // so never `undefined`.
    var result: c.wasmtime_component_val_t = std.mem.zeroes(c.wasmtime_component_val_t);
    if (c.wasmtime_component_func_call(&func, ctx, null, 0, &result, 1)) |err|
        return s.finish(try outcomeOf(alloc, err));
    var status: i32 = 0;
    if (result.kind == c.WASMTIME_COMPONENT_RESULT and !result.of.result.is_ok) status = 1;
    c.wasmtime_component_val_delete(&result);
    return s.finish(.{ .status = status });
}

/// Run a core module over WASI preview 1: instantiate it and call its
/// `_start` (a module without one instantiates and ends, status 0).
pub fn runCore(alloc: std.mem.Allocator, module: *const c.wasmtime_module_t, opts: Options) Error!Outcome {
    return callCore(alloc, module, &.{}, "_start", opts, null);
}

/// `runCore` with `units` defined first, in order, each under its name
/// (`wasmtime_linker_module`, what `wasmtime run --preload <name>=<file>`
/// does): the runtime core and the std units a module imports (decisions
/// 1021 (2), 1026 (3)).
pub fn runCoreWith(alloc: std.mem.Allocator, module: *const c.wasmtime_module_t, units: []const Unit, opts: Options) Error!Outcome {
    return callCore(alloc, module, units, "_start", opts, null);
}

/// `invokeCore`'s answer: the outcome, and the export's first result as an
/// integer when it returned one.
pub const Invoked = struct { outcome: Outcome, value: ?i64 };

/// Instantiate `module` over WASI preview 1 (`units` defined first, as
/// `runCoreWith`) and call its export `name` with no argument; its first
/// `i32` / `i64` result is `value`.
pub fn invokeCore(alloc: std.mem.Allocator, module: *const c.wasmtime_module_t, units: []const Unit, name: []const u8, opts: Options) Error!Invoked {
    var value: ?i64 = null;
    const o = try callCore(alloc, module, units, name, opts, &value);
    return .{ .outcome = o, .value = value };
}

fn callCore(alloc: std.mem.Allocator, module: *const c.wasmtime_module_t, units: []const Unit, name: []const u8, opts: Options, value: ?*?i64) Error!Outcome {
    const eng = try engine_mod.theEngine();
    const linker = c.wasmtime_linker_new(eng) orelse return error.OutOfMemory;
    defer c.wasmtime_linker_delete(linker);
    if (c.wasmtime_linker_define_wasi(linker)) |err| return failed(alloc, "wasi p1: ", err);

    var s: Session = undefined;
    var refused: ?Outcome = null;
    try s.begin(alloc, opts, false, &refused);
    if (refused) |o| return s.finish(o);
    const ctx = s.ctx;

    for (units) |u| {
        if (c.wasmtime_linker_module(linker, ctx, u.name.ptr, u.name.len, u.module)) |err|
            return s.finish(try outcomeOf(alloc, err));
    }
    var instance: c.wasmtime_instance_t = undefined;
    var trap: ?*c.wasm_trap_t = null;
    if (c.wasmtime_linker_instantiate(linker, ctx, module, &instance, &trap)) |err|
        return s.finish(try outcomeOf(alloc, err));
    if (trap) |t| return s.finish(try outcomeOfTrap(alloc, t));

    var ext: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(ctx, &instance, name.ptr, name.len, &ext)) {
        // A command without `_start` has nothing to run; a named export must exist.
        if (value == null) return s.finish(.{ .status = 0 });
        return s.finish(try noRun(alloc, "the module has no such export"));
    }
    defer c.wasmtime_extern_delete(&ext);
    if (ext.kind != c.WASMTIME_EXTERN_FUNC) return s.finish(try noRun(alloc, "the export is not a function"));

    // The call takes exactly as many results as the function answers.
    const nresults: usize = blk: {
        const ty = c.wasmtime_func_type(ctx, &ext.of.func) orelse return error.OutOfMemory;
        defer c.wasm_functype_delete(ty);
        break :blk c.wasm_functype_results(ty).*.size;
    };
    var results = std.mem.zeroes([8]c.wasmtime_val_t);
    if (nresults > results.len) return s.finish(try noRun(alloc, "the export answers too many results"));
    if (c.wasmtime_func_call(ctx, &ext.of.func, null, 0, &results, nresults, &trap)) |err|
        return s.finish(try outcomeOf(alloc, err));
    if (trap) |t| return s.finish(try outcomeOfTrap(alloc, t));
    if (value) |v| v.* = if (nresults == 0) null else switch (results[0].kind) {
        c.WASMTIME_I32 => results[0].of.i32,
        c.WASMTIME_I64 => results[0].of.i64,
        else => null,
    };
    return s.finish(.{ .status = 0 });
}

fn noRun(alloc: std.mem.Allocator, text: []const u8) Error!Outcome {
    return .{ .status = 1, .trap = try alloc.dupe(u8, text) };
}

fn failed(alloc: std.mem.Allocator, prefix: []const u8, err: *c.wasmtime_error_t) Error!Outcome {
    return .{ .status = 1, .trap = try engine_mod.errorText(alloc, prefix, err) };
}

/// A call's error as an outcome: the WASI exit status when the error is an
/// `exit`, else status 1 with its `trapLine`. Takes `err`.
fn outcomeOf(alloc: std.mem.Allocator, err: *c.wasmtime_error_t) Error!Outcome {
    var status: c_int = 0;
    if (c.wasmtime_error_exit_status(err, &status)) {
        c.wasmtime_error_delete(err);
        return .{ .status = status };
    }
    const full = try engine_mod.errorText(alloc, "", err);
    defer alloc.free(full);
    return .{ .status = 1, .trap = try alloc.dupe(u8, trapLine(full)) };
}

/// A core call's trap as an outcome. Takes `trap`.
fn outcomeOfTrap(alloc: std.mem.Allocator, trap: *c.wasm_trap_t) Error!Outcome {
    defer c.wasm_trap_delete(trap);
    var msg: c.wasm_message_t = undefined;
    c.wasm_trap_message(trap, &msg);
    defer c.wasm_byte_vec_delete(&msg);
    var text: []const u8 = if (msg.size == 0) "" else msg.data[0..msg.size];
    text = std.mem.trimEnd(u8, text, "\x00");
    return .{ .status = 1, .trap = try alloc.dupe(u8, trapLine(text)) };
}

/// The line of an engine error chain a reader is shown (decision 1034 (3)):
/// the trap's own `wasm trap: <what>` line when there is one (the backtrace's
/// code offsets change with every lowering), else the chain's last line
/// without its `N: ` cause number — the shape the RUN LOG kept from the
/// `wasmtime` CLI's chain.
pub fn trapLine(chain: []const u8) []const u8 {
    var last: []const u8 = "";
    var trap: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, chain, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, &std.ascii.whitespace);
        if (line.len == 0) continue;
        if (std.mem.indexOf(u8, line, "wasm trap:")) |i| trap = line[i..];
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse 0;
        const numbered = colon > 0 and for (line[0..colon]) |ch| {
            if (!std.ascii.isDigit(ch)) break false;
        } else true;
        last = if (numbered) std.mem.trimStart(u8, line[colon + 1 ..], " ") else line;
    }
    return trap orelse last;
}

test "trapLine: the trap's line, else the chain's last cause" {
    try std.testing.expectEqualStrings("wasm trap: wasm `unreachable` instruction executed", trapLine(
        \\error while executing at wasm backtrace:
        \\    0:   0x2a - <unknown>!main
        \\
        \\Caused by:
        \\    wasm trap: wasm `unreachable` instruction executed
    ));
    try std.testing.expectEqualStrings("unknown import: `bp_fs::open` has not been defined", trapLine(
        \\failed to instantiate
        \\    1: unknown import: `bp_fs::open` has not been defined
    ));
}

// ── loaded code, per process ─────────────────────────────────────────────────

/// How many compiled modules and components `load` keeps (decision 1034 (9),
/// comptime's bound).
pub const max_loaded = 64;

const Loaded = struct { digest: [32]u8, code: engine_mod.Compiled, used: u64 };
var loaded: [max_loaded]?Loaded = @splat(null);
var loaded_tick: u64 = 0;
var loaded_lock: std.atomic.Value(u8) = .init(0);

fn lockLoaded() void {
    while (loaded_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn cloneOf(code: engine_mod.Compiled) engine_mod.Compiled {
    return switch (code) {
        .module => |m| .{ .module = c.wasmtime_module_clone(m).? },
        .component => |m| .{ .component = c.wasmtime_component_clone(m).? },
    };
}

/// Compiled code for `bytes` (`.wat` text or binary): from the process's
/// last `max_loaded` loads when it is there, else `engine.precompiled`
/// (`cache_dir`, `cold`) and kept, the least recently used one dropped.
/// The caller owns the answer (`deinit`). Null with `failure` set when the
/// engine refuses the bytes.
pub fn load(
    alloc: std.mem.Allocator,
    io: std.Io,
    cache_dir: ?[]const u8,
    bytes: []const u8,
    kind: engine_mod.Kind,
    cold: bool,
    failure: *?[]u8,
) Error!?engine_mod.Compiled {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update(&.{@intFromEnum(kind)});
    h.update(bytes);
    const digest = h.finalResult();
    {
        lockLoaded();
        defer loaded_lock.store(0, .release);
        for (&loaded) |*slot| if (slot.*) |*e| if (std.mem.eql(u8, &e.digest, &digest)) {
            loaded_tick += 1;
            e.used = loaded_tick;
            return cloneOf(e.code);
        };
    }
    const pc = (try engine_mod.precompiled(alloc, io, cache_dir, bytes, kind, cold, failure)) orelse return null;
    if (pc.path) |p| alloc.free(p);
    lockLoaded();
    defer loaded_lock.store(0, .release);
    var victim: usize = 0;
    for (&loaded, 0..) |*slot, i| {
        const e = slot.* orelse {
            victim = i;
            break;
        };
        if (std.mem.eql(u8, &e.digest, &digest)) return pc.code; // another thread kept it
        if (loaded[victim]) |v| if (e.used < v.used) {
            victim = i;
        };
    }
    if (loaded[victim]) |old| old.code.deinit();
    loaded_tick += 1;
    loaded[victim] = .{ .digest = digest, .code = cloneOf(pc.code), .used = loaded_tick };
    return pc.code;
}

/// How many entries `load` holds now (tests).
fn loadedCount() usize {
    lockLoaded();
    defer loaded_lock.store(0, .release);
    var n: usize = 0;
    for (loaded) |slot| if (slot != null) {
        n += 1;
    };
    return n;
}

// ── tests ────────────────────────────────────────────────────────────────────

/// The unit the run component imports: a message in memory and an exit code.
const unit_wat =
    \\(module
    \\  (memory (export "mem") 1)
    \\  (data (i32.const 16) "hi!\0a")
    \\  (func (export "ptr") (result i32) (i32.const 16))
    \\  (func (export "len") (result i32) (i32.const 4))
    \\  (func (export "code") (result i32) (i32.const 3)))
;

/// A component that imports the core module `unit`, writes its message to
/// stdout through `wasi:io/streams` and exits with its code through
/// `wasi:cli/exit`'s `exit-with-code`; `wasi:cli/run@0.2.0`'s `run` is the glue.
/// `%EXIT%` is the exit import's name and call, filled by `runComponent`.
const run_component_wat =
    \\(component
    \\  (import "unit" (core module $unit
    \\    (export "mem" (memory 1))
    \\    (export "ptr" (func (result i32)))
    \\    (export "len" (func (result i32)))
    \\    (export "code" (func (result i32)))))
    \\  (import "wasi:io/error@0.2.0" (instance $error_i
    \\    (export "error" (type (sub resource)))))
    \\  (alias export $error_i "error" (type $error))
    \\  (import "wasi:io/streams@0.2.0" (instance $streams_i
    \\    (alias outer 1 $error (type $error_outer))
    \\    (export "error" (type $e (eq $error_outer)))
    \\    (export "output-stream" (type $os (sub resource)))
    \\    (type $own_e (own $e))
    \\    (type $se0 (variant (case "last-operation-failed" $own_e) (case "closed")))
    \\    (export "stream-error" (type $se (eq $se0)))
    \\    (type $r (result (error $se)))
    \\    (type $bos (borrow $os))
    \\    (type $lu8 (list u8))
    \\    (export "[method]output-stream.blocking-write-and-flush"
    \\      (func (param "self" $bos) (param "contents" $lu8) (result $r)))))
    \\  (alias export $streams_i "output-stream" (type $os))
    \\  (import "wasi:cli/stdout@0.2.0" (instance $stdout_i
    \\    (alias outer 1 $os (type $os_outer))
    \\    (export "output-stream" (type $os2 (eq $os_outer)))
    \\    (type $own (own $os2))
    \\    (export "get-stdout" (func (result $own)))))
    \\  (import "wasi:cli/exit@0.2.0" (instance $exit_i
    \\    (export "exit-with-code" (func (param "status-code" u8)))))
    \\  (core instance $u (instantiate $unit))
    \\  (alias core export $u "mem" (core memory $mem))
    \\  (core func $get_stdout (canon lower (func $stdout_i "get-stdout")))
    \\  (core func $write (canon lower (func $streams_i "[method]output-stream.blocking-write-and-flush") (memory $mem)))
    \\  (core func $exit (canon lower (func $exit_i "exit-with-code")))
    \\  (core instance $io
    \\    (export "stdout" (func $get_stdout))
    \\    (export "write" (func $write))
    \\    (export "exit" (func $exit)))
    \\  (core module $glue
    \\    (import "u" "mem" (memory 1))
    \\    (import "u" "ptr" (func $ptr (result i32)))
    \\    (import "u" "len" (func $len (result i32)))
    \\    (import "u" "code" (func $code (result i32)))
    \\    (import "io" "stdout" (func $stdout (result i32)))
    \\    (import "io" "write" (func $write (param i32 i32 i32 i32)))
    \\    (import "io" "exit" (func $exit (param i32)))
    \\    (func (export "run") (result i32)
    \\      (call $write (call $stdout) (call $ptr) (call $len) (i32.const 512))
    \\      (call $exit (call $code))
    \\      (i32.const 0)))
    \\  (core instance $g (instantiate $glue (with "u" (instance $u)) (with "io" (instance $io))))
    \\  (func $run (result (result)) (canon lift (core func $g "run")))
    \\  (instance $run_i (export "run" (func $run)))
    \\  (export "wasi:cli/run@0.2.0" (instance $run_i)))
;

test "run: stdout is captured and the exit status is the program's" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var failure: ?[]u8 = null;
    const unit = (try engine_mod.precompiled(alloc, io, null, unit_wat, .module, false, &failure)).?;
    defer unit.code.deinit();
    const comp = (try engine_mod.precompiled(alloc, io, null, run_component_wat, .component, false, &failure)) orelse {
        std.debug.print("\ncomponent: {s}\n", .{failure.?});
        alloc.free(failure.?);
        return error.TestUnexpectedResult;
    };
    defer comp.code.deinit();

    const out = try run(alloc, comp.code.component, &.{.{ .name = "unit", .module = unit.code.module }}, .{ .stdout = .capture });
    defer out.deinit(alloc);
    if (out.trap) |t| std.debug.print("\ntrap: {s}\n", .{t});
    try std.testing.expectEqualStrings("hi!\n", out.stdout.?);
    try std.testing.expectEqual(@as(i32, 3), out.status);
}

// ── the import-name probe ────────────────────────────────────────────────────

/// A component that imports one core module under `name`, instantiates it and
/// lifts its `f` as the export `call`.
fn probeComponent(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    return std.fmt.allocPrint(alloc,
        \\(component
        \\  (import "{s}" (core module $m (export "f" (func (result i32)))))
        \\  (core instance $i (instantiate $m))
        \\  (func (export "call") (result u32) (canon lift (core func $i "f"))))
    , .{name});
}

const NamedUnit = struct { name: []const u8, text: []const u8 };

/// Compile `comp_wat`, define each of `units` under its name at the linker's
/// root, instantiate and call the exported `<export_name>: func() -> u32`,
/// everything through `cache_dir` when given. The answer is a line of text:
/// `ok <n>`, `trap <status> <text>` (the `Outcome` mapping of a failed call) or
/// `refused <message>`. `cached` is set when nothing had to be compiled.
fn probeText(
    alloc: std.mem.Allocator,
    cache_dir: ?[]const u8,
    comp_wat: []const u8,
    units: []const NamedUnit,
    export_name: []const u8,
    cached: ?*bool,
) ![]u8 {
    const io = std.testing.io;
    var failure: ?[]u8 = null;
    var all_cached = true;
    const comp = (try engine_mod.precompiled(alloc, io, cache_dir, comp_wat, .component, false, &failure)) orelse {
        defer alloc.free(failure.?);
        return std.fmt.allocPrint(alloc, "refused {s}", .{failure.?});
    };
    defer comp.code.deinit();
    defer if (comp.path) |p| alloc.free(p);
    if (!comp.from_cache) all_cached = false;

    const eng = try engine_mod.theEngine();
    const linker = c.wasmtime_component_linker_new(eng).?;
    defer c.wasmtime_component_linker_delete(linker);
    var held: std.ArrayList(engine_mod.Precompiled) = .empty;
    defer {
        for (held.items) |u| {
            u.code.deinit();
            if (u.path) |p| alloc.free(p);
        }
        held.deinit(alloc);
    }
    {
        const root = c.wasmtime_component_linker_root(linker).?;
        defer c.wasmtime_component_linker_instance_delete(root);
        for (units) |u| {
            const pc = (try engine_mod.precompiled(alloc, io, cache_dir, u.text, .module, false, &failure)) orelse {
                defer alloc.free(failure.?);
                return std.fmt.allocPrint(alloc, "refused (unit {s}) {s}", .{ u.name, failure.? });
            };
            try held.append(alloc, pc);
            if (!pc.from_cache) all_cached = false;
            if (c.wasmtime_component_linker_instance_add_module(root, u.name.ptr, u.name.len, pc.code.module)) |err|
                return engine_mod.errorText(alloc, "refused add_module: ", err);
        }
    }
    if (cached) |p| p.* = all_cached;

    const store = c.wasmtime_store_new(eng, null, null).?;
    defer c.wasmtime_store_delete(store);
    const ctx = c.wasmtime_store_context(store).?;
    c.wasmtime_context_set_epoch_deadline(ctx, 1);
    var instance: c.wasmtime_component_instance_t = undefined;
    if (c.wasmtime_component_linker_instantiate(linker, ctx, comp.code.component, &instance)) |err|
        return engine_mod.errorText(alloc, "refused instantiate: ", err);
    const idx = c.wasmtime_component_get_export_index(comp.code.component, null, export_name.ptr, export_name.len) orelse
        return alloc.dupe(u8, "refused no export index");
    defer c.wasmtime_component_export_index_delete(idx);
    var func: c.wasmtime_component_func_t = undefined;
    if (!c.wasmtime_component_instance_get_func(&instance, ctx, idx, &func)) return alloc.dupe(u8, "refused no func");
    var result: c.wasmtime_component_val_t = std.mem.zeroes(c.wasmtime_component_val_t);
    if (c.wasmtime_component_func_call(&func, ctx, null, 0, &result, 1)) |err| {
        const o = try outcomeOf(alloc, err);
        defer o.deinit(alloc);
        return std.fmt.allocPrint(alloc, "trap status={d} {s}", .{ o.status, o.trap orelse "" });
    }
    defer c.wasmtime_component_val_delete(&result);
    return std.fmt.allocPrint(alloc, "ok {d}", .{result.of.u32});
}

fn report(label: []const u8, answer: []const u8) void {
    std.debug.print("\nPROBE {s}: {s}\n", .{ label, answer });
}

test "probe: which core-module import names the component model accepts" {
    const alloc = std.testing.allocator;
    const names = [_][]const u8{ "unit", "std-string", "unit-0", "unit-1", "unlocked-dep=<std:string>", "std@string" };
    const unit = "(module (func (export \"f\") (result i32) (i32.const 42)))";
    for (names) |n| {
        const text = try probeComponent(alloc, n);
        defer alloc.free(text);
        const r = try probeText(alloc, null, text, &.{.{ .name = n, .text = unit }}, "call", null);
        defer alloc.free(r);
        report(n, r);
    }
}

// Decision 1037: units cross the boundary through abstract refs. The callee
// exports `f(anyref) -> anyref` (and `get`), casting to a `final` struct type
// and calling the typed internals; the caller knows no struct type.
const callee_wat =
    \\(module
    \\  (type $s (sub final (struct (field i32))))
    \\  (type $t (sub final (struct (field i64))))
    \\  (func $inc (param (ref null $s)) (result (ref null $s))
    \\    (struct.new $s (i32.add (struct.get $s 0 (local.get 0)) (i32.const 1))))
    \\  (func (export "f") (param anyref) (result anyref)
    \\    (call $inc (ref.cast (ref null $s) (local.get 0))))
    \\  (func (export "get") (param anyref) (result i32)
    \\    (struct.get $s 0 (ref.cast (ref null $s) (local.get 0))))
    \\  (func (export "mk") (param i32) (result anyref) (struct.new $s (local.get 0)))
    \\  (func (export "mkt") (result anyref) (struct.new $t (i64.const 9))))
;
const caller_wat =
    \\(module
    \\  (import "unit-0" "f" (func $f (param anyref) (result anyref)))
    \\  (import "unit-0" "get" (func $get (param anyref) (result i32)))
    \\  (import "unit-0" "mk" (func $mk (param i32) (result anyref)))
    \\  (import "unit-0" "mkt" (func $mkt (result anyref)))
    \\  (func (export "call") (result i32) (call $get (call $f (call $mk (i32.const 5)))))
    \\  (func (export "bad") (result i32) (call $get (call $f (call $mkt)))))
;
const boundary_comp =
    \\(component
    \\  (import "unit-0" (core module $a
    \\    (export "f" (func (param anyref) (result anyref)))
    \\    (export "get" (func (param anyref) (result i32)))
    \\    (export "mk" (func (param i32) (result anyref)))
    \\    (export "mkt" (func (result anyref)))))
    \\  (import "unit-1" (core module $b
    \\    (import "unit-0" "f" (func (param anyref) (result anyref)))
    \\    (import "unit-0" "get" (func (param anyref) (result i32)))
    \\    (import "unit-0" "mk" (func (param i32) (result anyref)))
    \\    (import "unit-0" "mkt" (func (result anyref)))
    \\    (export "call" (func (result i32)))
    \\    (export "bad" (func (result i32)))))
    \\  (core instance $ia (instantiate $a))
    \\  (core instance $ib (instantiate $b (with "unit-0" (instance $ia))))
    \\  (func (export "call") (result u32) (canon lift (core func $ib "call")))
    \\  (func (export "bad") (result u32) (canon lift (core func $ib "bad"))))
;

test "boundary: two core modules linked into a component cross through anyref, from the .cwasm cache" {
    const alloc = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);
    const units = [_]NamedUnit{ .{ .name = "unit-0", .text = callee_wat }, .{ .name = "unit-1", .text = caller_wat } };

    var cached = true;
    const first = try probeText(alloc, dir, boundary_comp, &units, "call", &cached);
    defer alloc.free(first);
    try std.testing.expectEqualStrings("ok 6", first);
    try std.testing.expect(!cached);

    cached = false;
    const second = try probeText(alloc, dir, boundary_comp, &units, "call", &cached);
    defer alloc.free(second);
    try std.testing.expectEqualStrings("ok 6", second);
    // The component and both units came out of the cache.
    try std.testing.expect(cached);
}

test "boundary: a failed cast is a trap with status 1" {
    const alloc = std.testing.allocator;
    const units = [_]NamedUnit{ .{ .name = "unit-0", .text = callee_wat }, .{ .name = "unit-1", .text = caller_wat } };
    const r = try probeText(alloc, null, boundary_comp, &units, "bad", null);
    defer alloc.free(r);
    report("failed ref.cast through the boundary", r);
    try std.testing.expectEqualStrings("trap status=1 wasm trap: cast failure", r);
}

/// Compile `comp_wat` as a component in a forked child (a wasmtime panic
/// aborts the process): `ok`, `refused <message>`, or `PROCESS DIED …` /
/// `EXITED <status>` when the child did not end normally.
fn compileIsolated(alloc: std.mem.Allocator, comp_wat: []const u8) ![]u8 {
    var fds: [2]c_int = undefined;
    if (std.c.pipe(&fds) != 0) return error.TestUnexpectedResult;
    const pid = std.c.fork();
    if (pid < 0) return error.TestUnexpectedResult;
    if (pid == 0) {
        _ = std.c.close(fds[0]);
        _ = std.c.dup2(fds[1], 1);
        _ = std.c.dup2(fds[1], 2);
        _ = std.c.alarm(60);
        engine_mod.resetEngineAfterFork();
        var failure: ?[]u8 = null;
        const line: []const u8 = if (engine_mod.precompiled(std.heap.page_allocator, std.testing.io, null, comp_wat, .component, false, &failure) catch null) |pc| blk: {
            pc.code.deinit();
            break :blk "ok";
        } else std.fmt.allocPrint(std.heap.page_allocator, "refused {s}", .{failure orelse "(error)"}) catch "refused";
        _ = std.c.write(1, line.ptr, line.len);
        std.c._exit(0);
    }
    _ = std.c.close(fds[1]);
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(alloc);
    var chunk: [4096]u8 = undefined;
    while (true) {
        const n = std.c.read(fds[0], &chunk, chunk.len);
        if (n <= 0) break;
        try buf.appendSlice(alloc, chunk[0..@intCast(n)]);
    }
    _ = std.c.close(fds[0]);
    var status: c_int = 0;
    _ = std.c.waitpid(pid, &status, 0);
    const sig: u32 = @intCast(status & 0x7f);
    if (sig != 0) return std.fmt.allocPrint(alloc, "PROCESS DIED (signal {d}); output: {s}", .{ sig, buf.items });
    const code: u32 = @intCast((status >> 8) & 0xff);
    if (code != 0) return std.fmt.allocPrint(alloc, "EXITED {d}; output: {s}", .{ code, buf.items });
    return alloc.dupe(u8, buf.items);
}

test "probe: a concrete GC type in an imported core module's type is refused (the recorded reproduction)" {
    const alloc = std.testing.allocator;
    // Decisions 1037 / 1045: a red here means a wasmtime bump compiles the import — revisit the abstract boundary.
    const concrete = try compileIsolated(alloc,
        \\(component (import "unit-0" (core module $u (type $s (struct)) (type $f (func (param (ref null $s)))) (export "a" (func (type $f))))))
    );
    defer alloc.free(concrete);
    report("concrete struct ref in the imported module type", concrete);
    try std.testing.expect(!std.mem.eql(u8, concrete, "ok"));
    // The control: the same import through an abstract ref compiles.
    const abstract = try compileIsolated(alloc,
        \\(component (import "unit-0" (core module $u (type $f (func (param anyref))) (export "a" (func (type $f))))))
    );
    defer alloc.free(abstract);
    try std.testing.expectEqualStrings("ok", abstract);
}

// ── R1: core modules, the time limit, interrupt, loaded code ────────────────

/// A WASI preview 1 command: writes `hi\n` to stdout, `oops\n` to stderr,
/// then exits with `proc_exit(4)`.
const p1_command_wat =
    \\(module
    \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
    \\  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))
    \\  (memory (export "memory") 1)
    \\  (data (i32.const 64) "hi\0a")
    \\  (data (i32.const 80) "oops\0a")
    \\  (func (export "_start")
    \\    (i32.store (i32.const 0) (i32.const 64))
    \\    (i32.store (i32.const 4) (i32.const 3))
    \\    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 32)))
    \\    (i32.store (i32.const 0) (i32.const 80))
    \\    (i32.store (i32.const 4) (i32.const 5))
    \\    (drop (call $fd_write (i32.const 2) (i32.const 0) (i32.const 1) (i32.const 32)))
    \\    (call $proc_exit (i32.const 4))))
;

const spin_wat =
    \\(module
    \\  (func (export "_start") (loop $l (br $l)))
    \\  (func (export "seven") (result i32) (i32.const 7))
    \\  (func (export "boom") (unreachable)))
;

fn compileModule(text: []const u8) !engine_mod.Compiled {
    var failure: ?[]u8 = null;
    const pc = (try engine_mod.precompiled(std.testing.allocator, std.testing.io, null, text, .module, false, &failure)) orelse {
        std.debug.print("\n{s}\n", .{failure.?});
        std.testing.allocator.free(failure.?);
        return error.TestUnexpectedResult;
    };
    return pc.code;
}

test "runCore: a WASI p1 command's stdout and stderr captured, its proc_exit the status" {
    const alloc = std.testing.allocator;
    const m = try compileModule(p1_command_wat);
    defer m.deinit();
    const out = try runCore(alloc, m.module, .{ .stdout = .capture, .stderr = .capture });
    defer out.deinit(alloc);
    try std.testing.expectEqualStrings("hi\n", out.stdout.?);
    try std.testing.expectEqualStrings("oops\n", out.stderr.?);
    try std.testing.expectEqual(@as(i32, 4), out.status);
    try std.testing.expect(out.trap == null);
    try std.testing.expectEqual(End.exited, out.end);
}

test "invokeCore: a core export's value; a trap is its wasm trap line, status 1" {
    const alloc = std.testing.allocator;
    const m = try compileModule(spin_wat);
    defer m.deinit();
    const seven = try invokeCore(alloc, m.module, &.{}, "seven", .{});
    defer seven.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(?i64, 7), seven.value);
    const boom = try invokeCore(alloc, m.module, &.{}, "boom", .{});
    defer boom.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(i32, 1), boom.outcome.status);
    try std.testing.expectEqualStrings("wasm trap: wasm `unreachable` instruction executed", boom.outcome.trap.?);
}

test "runCore: the time limit ends a loop through the epoch, and only its own run" {
    const alloc = std.testing.allocator;
    const m = try compileModule(spin_wat);
    defer m.deinit();
    const out = try runCore(alloc, m.module, .{ .timeout_ns = 50 * std.time.ns_per_ms });
    defer out.deinit(alloc);
    try std.testing.expectEqual(End.timed_out, out.end);
    try std.testing.expectEqual(@as(i32, 1), out.status);
    try std.testing.expect(!running());
}

fn interruptWhenRunning() void {
    var waited: usize = 0;
    while (!running() and waited < 20_000) : (waited += 1) {
        var ts: std.c.timespec = .{ .sec = 0, .nsec = std.time.ns_per_ms };
        _ = std.c.nanosleep(&ts, &ts);
    }
    var ts: std.c.timespec = .{ .sec = 0, .nsec = 20 * std.time.ns_per_ms };
    _ = std.c.nanosleep(&ts, &ts);
    interrupt();
}

test "runCore: interrupt ends a run in progress (the SIGINT path)" {
    const alloc = std.testing.allocator;
    const m = try compileModule(spin_wat);
    defer m.deinit();
    const killer = try std.Thread.spawn(.{}, interruptWhenRunning, .{});
    defer killer.join();
    // The limit only bounds the test if the interrupt never comes.
    const out = try runCore(alloc, m.module, .{ .timeout_ns = 20 * std.time.ns_per_s });
    defer out.deinit(alloc);
    try std.testing.expectEqual(End.interrupted, out.end);
    // A run begun after the interrupt is not ended by it.
    const later = try invokeCore(alloc, m.module, &.{}, "seven", .{});
    defer later.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(?i64, 7), later.value);
}

test "load: kept in the process, the same bytes compiled once" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var failure: ?[]u8 = null;
    const text = "(module (func (export \"f\") (result i32) (i32.const 11)))";
    const a = (try load(alloc, io, null, text, .module, false, &failure)).?;
    defer a.deinit();
    const n = loadedCount();
    const b = (try load(alloc, io, null, text, .module, false, &failure)).?;
    defer b.deinit();
    try std.testing.expectEqual(n, loadedCount());
    const got = try invokeCore(alloc, b.module, &.{}, "f", .{});
    defer got.outcome.deinit(alloc);
    try std.testing.expectEqual(@as(?i64, 11), got.value);
    try std.testing.expect(loadedCount() <= max_loaded);
}
