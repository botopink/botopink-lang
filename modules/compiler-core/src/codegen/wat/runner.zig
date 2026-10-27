//! Run a component whose core units are given to the component linker
//! (decision 1032 (3), piece R0): the program is a component that imports its
//! core modules by name, the precompiled units (`engine.precompiled`) are
//! defined under those names at the linker's root
//! (`wasmtime_component_linker_instance_add_module`), WASI p2 is added, and the
//! `wasi:cli/run@0.2.0` export's `run` is called.
//!
//! The outcome is the process's: `status` comes from the WASI exit status the
//! engine reports (`wasmtime_error_exit_status`), 0 for a `run` that returns
//! ok, 1 for one that returns err or traps — a trap keeps the engine's message
//! in `trap`. `stdout` is either the host's own or captured into a buffer.
const std = @import("std");
const engine_mod = @import("engine.zig");
const c = engine_mod.c;

pub const Error = std.mem.Allocator.Error;

/// A core module the component imports as `name`.
pub const Unit = struct {
    name: []const u8,
    module: *c.wasmtime_module_t,
};

pub const Options = struct {
    /// Capture the program's stdout into `Outcome.stdout` (else it is inherited).
    capture_stdout: bool = false,
    argv: []const []const u8 = &.{},
};

pub const Outcome = struct {
    status: i32,
    /// The captured stdout, when asked for; owned by the caller.
    stdout: ?[]u8 = null,
    /// The engine's message of a trap (or of a failure to instantiate); owned.
    trap: ?[]u8 = null,

    pub fn deinit(self: Outcome, alloc: std.mem.Allocator) void {
        if (self.stdout) |s| alloc.free(s);
        if (self.trap) |t| alloc.free(t);
    }
};

const Capture = struct {
    alloc: std.mem.Allocator,
    buf: std.ArrayList(u8) = .empty,
    failed: bool = false,

    fn write(data: ?*anyopaque, bytes: [*c]const u8, len: usize) callconv(.c) isize {
        const self: *Capture = @ptrCast(@alignCast(data.?));
        self.buf.appendSlice(self.alloc, bytes[0..len]) catch {
            self.failed = true;
            return -12; // ENOMEM
        };
        return @intCast(len);
    }
};

/// Instantiate `component` with `units` and run it. See the file comment.
pub fn run(alloc: std.mem.Allocator, component: *const c.wasmtime_component_t, units: []const Unit, opts: Options) Error!Outcome {
    const eng = try engine_mod.theEngine();
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

    const store = c.wasmtime_store_new(eng, null, null) orelse return error.OutOfMemory;
    defer c.wasmtime_store_delete(store);
    const ctx = c.wasmtime_store_context(store).?;
    // Only `engine.incrementEpoch` moves the epoch: a program runs to its end.
    c.wasmtime_context_set_epoch_deadline(ctx, 1);

    var capture: Capture = .{ .alloc = alloc };
    defer capture.buf.deinit(alloc);

    const wasi = c.wasi_config_new() orelse return error.OutOfMemory;
    var argv_z = try alloc.alloc([*c]const u8, opts.argv.len);
    defer alloc.free(argv_z);
    var made: usize = 0;
    defer for (argv_z[0..made]) |p| alloc.free(std.mem.span(p));
    for (opts.argv, 0..) |a, i| {
        argv_z[i] = (try alloc.dupeZ(u8, a)).ptr;
        made += 1;
    }
    _ = c.wasi_config_set_argv(wasi, argv_z.len, argv_z.ptr);
    if (opts.capture_stdout) {
        c.wasi_config_set_stdout_custom(wasi, Capture.write, &capture, null);
    } else {
        c.wasi_config_inherit_stdout(wasi);
    }
    c.wasi_config_inherit_stderr(wasi);
    // Takes `wasi`.
    if (c.wasmtime_context_set_wasi(ctx, wasi)) |err| return failed(alloc, "wasi: ", err);

    var instance: c.wasmtime_component_instance_t = undefined;
    if (c.wasmtime_component_linker_instantiate(linker, ctx, component, &instance)) |err| {
        const o = try outcomeOf(alloc, err);
        return withStdout(alloc, o, opts, &capture);
    }

    const run_iface = c.wasmtime_component_get_export_index(component, null, "wasi:cli/run@0.2.0", "wasi:cli/run@0.2.0".len) orelse
        return noRun(alloc, "the component exports no wasi:cli/run@0.2.0");
    defer c.wasmtime_component_export_index_delete(run_iface);
    const run_idx = c.wasmtime_component_get_export_index(component, run_iface, "run", 3) orelse
        return noRun(alloc, "wasi:cli/run@0.2.0 exports no run");
    defer c.wasmtime_component_export_index_delete(run_idx);
    var func: c.wasmtime_component_func_t = undefined;
    if (!c.wasmtime_component_instance_get_func(&instance, ctx, run_idx, &func))
        return noRun(alloc, "the instance has no run function");

    // The call overwrites (and drops) the old value: it must be a valid one,
    // so never `undefined`.
    var result: c.wasmtime_component_val_t = std.mem.zeroes(c.wasmtime_component_val_t);
    if (c.wasmtime_component_func_call(&func, ctx, null, 0, &result, 1)) |err| {
        const o = try outcomeOf(alloc, err);
        return withStdout(alloc, o, opts, &capture);
    }
    defer c.wasmtime_component_val_delete(&result);
    var status: i32 = 0;
    if (result.kind == c.WASMTIME_COMPONENT_RESULT and !result.of.result.is_ok) status = 1;
    return withStdout(alloc, .{ .status = status }, opts, &capture);
}

fn noRun(alloc: std.mem.Allocator, text: []const u8) Error!Outcome {
    return .{ .status = 1, .trap = try alloc.dupe(u8, text) };
}

fn failed(alloc: std.mem.Allocator, prefix: []const u8, err: *c.wasmtime_error_t) Error!Outcome {
    return .{ .status = 1, .trap = try engine_mod.errorText(alloc, prefix, err) };
}

/// A call's error as an outcome: the WASI exit status when the error is an
/// `exit`, else status 1 with `wasm trap: <first line of the message>`
/// (decision 1034 (3): the text the harness extracts today). Takes `err`.
fn outcomeOf(alloc: std.mem.Allocator, err: *c.wasmtime_error_t) Error!Outcome {
    var status: c_int = 0;
    if (c.wasmtime_error_exit_status(err, &status)) {
        c.wasmtime_error_delete(err);
        return .{ .status = status };
    }
    const full = try engine_mod.errorText(alloc, "", err);
    defer alloc.free(full);
    // The engine's chain ends in the trap's own line, `wasm trap: <what>`; an
    // error that is no trap keeps its first line under the same prefix.
    if (std.mem.indexOf(u8, full, "wasm trap: ")) |i| {
        const rest = full[i..];
        const end = std.mem.indexOfScalar(u8, rest, '\n') orelse rest.len;
        return .{ .status = 1, .trap = try alloc.dupe(u8, rest[0..end]) };
    }
    const line = if (std.mem.indexOfScalar(u8, full, '\n')) |i| full[0..i] else full;
    return .{ .status = 1, .trap = try std.fmt.allocPrint(alloc, "wasm trap: {s}", .{line}) };
}

fn withStdout(alloc: std.mem.Allocator, o: Outcome, opts: Options, capture: *Capture) Error!Outcome {
    var out = o;
    if (opts.capture_stdout) out.stdout = try alloc.dupe(u8, capture.buf.items);
    return out;
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

    const out = try run(alloc, comp.code.component, &.{.{ .name = "unit", .module = unit.code.module }}, .{ .capture_stdout = true });
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

/// `probeText` in a forked child: wasmtime's panics abort the process, and
/// that is an answer, not a test failure. The child writes its line (and the
/// panic's stderr) into a pipe; a signal is reported by number. The child
/// builds a private engine without the parallel compiler, since the parent's
/// worker threads do not exist after a fork.
fn probeIsolated(alloc: std.mem.Allocator, comp_wat: []const u8, units: []const NamedUnit, export_name: []const u8) ![]u8 {
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
        const line = probeText(std.heap.page_allocator, null, comp_wat, units, export_name, null) catch "refused (probe error)";
        var off: usize = 0;
        while (off < line.len) {
            const n = std.c.write(1, line.ptr + off, line.len - off);
            if (n <= 0) break;
            off += @intCast(n);
        }
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
    return alloc.dupe(u8, buf.items);
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

test "probe: a concrete GC type in an imported core module's type (the recorded reproduction)" {
    const alloc = std.testing.allocator;
    const concrete_comp =
        \\(component
        \\  (import "unit" (core module $m
        \\    (type $s (struct (field i32)))
        \\    (export "f" (func (param (ref null $s)) (result i32)))
        \\    (export "call" (func (result i32)))))
        \\  (core instance $i (instantiate $m))
        \\  (func (export "call") (result u32) (canon lift (core func $i "call"))))
    ;
    const concrete_unit =
        \\(module
        \\  (type $s (struct (field i32)))
        \\  (func (export "f") (param (ref null $s)) (result i32) (struct.get $s 0 (local.get 0)))
        \\  (func (export "call") (result i32) (call 0 (struct.new $s (i32.const 5)))))
    ;
    const a = try probeIsolated(alloc, concrete_comp, &.{.{ .name = "unit", .text = concrete_unit }}, "call");
    defer alloc.free(a);
    // Recorded, not asserted: on wasmtime 49.0.3 the engine aborts the process.
    report("concrete struct ref in the imported module type", a);
}
