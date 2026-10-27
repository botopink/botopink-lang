//! The embedded wasmtime engine, one per process, and the compiled-code cache
//! beside it (decision 1032 (2), piece R0).
//!
//! The engine is configured here once (decision 67: no flag): exception
//! handling, GC, the component model and parallel compilation on, epoch
//! interruption on (`incrementEpoch` is what a SIGINT handler or a timeout
//! calls; a store whose deadline is one tick traps at the next increment),
//! and a 64 MiB wasm stack (`wasm_stack`, comptime's bound: one configuration
//! serves the program and comptime, decision 1033 (1)), a call reaching that
//! depth running on a thread that holds it (`onWasmStack`).
//! `wasm_component_model_async` stays off: `add_wasip2` (sync) needs the sync
//! `func_call` path. The engine is not the CLI's: decision 1033 puts comptime on
//! this same GC engine, so nothing here knows a command.
//!
//! `precompiled` turns bytes (`.wat` text or a binary module / component) into
//! compiled code, through a content-addressed cache directory: one flat folder
//! of `<sha256>.cwasm`, the digest over the kind's tag, the wasmtime version, the
//! engine's settings and the input bytes — so a change of any of them is a new
//! file, never a stale hit. A file the engine refuses is compiled again and
//! overwritten.
//!
//! The cache folder is the caller's (the CLI's `<cache root>/.botopinkbuild/cache/wasmtime/`, decision 1034 (8)).
//!
//! This file does not touch `comptime/runtime/persistent_wat.zig`, which keeps
//! its own engine until comptime moves (1033).
const std = @import("std");
const manifest = @import("manifest");

pub const c = @cImport({
    @cInclude("wasmtime.h");
});

pub const Error = std.mem.Allocator.Error;

/// The wasmtime release of the cache key (`manifest.WASMTIME_VERSION`).
pub const version_tag = "wasmtime " ++ manifest.WASMTIME_VERSION;

/// The literal of the engine's settings, part of the cache key: whatever
/// `theEngine` configures is named here, in the same order.
pub const settings_key = "exceptions=1;gc=1;component-model=1;parallel-compilation=1;epoch-interruption=1;max-wasm-stack=67108864;async-stack-size=68157440";

/// The wasm stack a call may use (decision 1033 (1): one configuration for
/// the program and comptime). Comptime's Erlang-shaped loops are recursion
/// with no tail calls, so a body's depth is its iteration count: the bound
/// persistent_wat ran with. A call deeper than the native stack it runs on
/// would fault before this bound, so a deep caller runs on a thread of
/// `thread_stack` bytes (the comptime host does).
pub const wasm_stack: usize = 64 * 1024 * 1024;
/// The engine refuses a wasm stack past its fibers' stacks, which no call
/// here uses (every call is synchronous).
pub const async_stack: usize = wasm_stack + 1024 * 1024;
/// The native stack of a thread that runs a call to `wasm_stack`'s depth: the
/// wasm stack and the host's own frames under it.
pub const thread_stack: usize = wasm_stack + 16 * 1024 * 1024;

var engine: ?*c.wasm_engine_t = null;
var engine_lock: std.atomic.Value(u8) = .init(0);

/// The process's engine, built on first use. Null only on out of memory.
pub fn theEngine() Error!*c.wasm_engine_t {
    while (engine_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
    defer engine_lock.store(0, .release);
    if (engine) |e| return e;
    const config = c.wasm_config_new() orelse return error.OutOfMemory;
    c.wasmtime_config_wasm_exceptions_set(config, true);
    c.wasmtime_config_wasm_function_references_set(config, true);
    c.wasmtime_config_wasm_gc_set(config, true);
    c.wasmtime_config_wasm_component_model_set(config, true);
    c.wasmtime_config_parallel_compilation_set(config, true);
    c.wasmtime_config_epoch_interruption_set(config, true);
    c.wasmtime_config_max_wasm_stack_set(config, wasm_stack);
    c.wasmtime_config_async_stack_size_set(config, async_stack);
    // Takes `config`.
    engine = c.wasm_engine_new_with_config(config) orelse return error.OutOfMemory;
    return engine.?;
}

/// `f(args)` run on a thread of `thread_stack` bytes, joined before the
/// answer: a wasm call may use the whole `wasm_stack`, which no caller's own
/// stack is sure to hold (a deeper call than the native stack faults instead
/// of trapping `call stack exhausted`). Inline when no thread can be made.
pub fn onWasmStack(comptime f: anytype, args: anytype) @typeInfo(@TypeOf(f)).@"fn".return_type.? {
    const R = @typeInfo(@TypeOf(f)).@"fn".return_type.?;
    const Call = struct {
        args: @TypeOf(args),
        out: R = undefined,
        fn work(call: *@This()) void {
            call.out = @call(.auto, f, call.args);
        }
    };
    var call: Call = .{ .args = args };
    const thread = std.Thread.spawn(.{ .stack_size = thread_stack }, Call.work, .{&call}) catch return @call(.auto, f, args);
    thread.join();
    return call.out;
}

/// Move the engine's epoch one tick: every store whose deadline is the next
/// tick traps (`interrupted`). Signal-safe; a no-op before the engine exists.
pub fn incrementEpoch() void {
    if (@atomicLoad(?*c.wasm_engine_t, &engine, .acquire)) |e| c.wasmtime_engine_increment_epoch(e);
}

pub const Kind = enum {
    module,
    component,

    fn tag(k: Kind) []const u8 {
        return switch (k) {
            .module => "module",
            .component => "component",
        };
    }
};

/// What `bytes` holds: a component when the binary's layer is 1 (version
/// `0d 00 01 00`) or the text opens with `(component`, else a core module.
pub fn kindOf(bytes: []const u8) Kind {
    if (std.mem.startsWith(u8, bytes, "\x00asm"))
        return if (bytes.len >= 8 and bytes[6] == 1) .component else .module;
    const text = std.mem.trimStart(u8, bytes, &std.ascii.whitespace);
    return if (std.mem.startsWith(u8, text, "(component")) .component else .module;
}

test "kindOf: binary layer and text head" {
    try std.testing.expectEqual(Kind.module, kindOf("\x00asm\x01\x00\x00\x00"));
    try std.testing.expectEqual(Kind.component, kindOf("\x00asm\x0d\x00\x01\x00"));
    try std.testing.expectEqual(Kind.component, kindOf("\n(component\n)"));
    try std.testing.expectEqual(Kind.module, kindOf("(module)"));
}

/// Compiled code of either kind. Owns it: `deinit`.
pub const Compiled = union(Kind) {
    module: *c.wasmtime_module_t,
    component: *c.wasmtime_component_t,

    pub fn deinit(self: Compiled) void {
        switch (self) {
            .module => |m| c.wasmtime_module_delete(m),
            .component => |m| c.wasmtime_component_delete(m),
        }
    }
};

pub const Precompiled = struct {
    code: Compiled,
    /// The code was read from the cache file (not compiled by this call).
    from_cache: bool,
    /// The file's path, null with no cache directory.
    path: ?[:0]u8,
};

/// The engine's message of `err`, prefixed. Takes `err`.
pub fn errorText(alloc: std.mem.Allocator, prefix: []const u8, err: *c.wasmtime_error_t) Error![]u8 {
    defer c.wasmtime_error_delete(err);
    var msg: c.wasm_name_t = undefined;
    c.wasmtime_error_message(err, &msg);
    defer c.wasm_byte_vec_delete(&msg);
    return std.fmt.allocPrint(alloc, "{s}{s}", .{ prefix, msg.data[0..msg.size] });
}

/// `<dir>/<hex sha256(tag ‖ version ‖ settings ‖ bytes)>.cwasm`.
pub fn cachePath(alloc: std.mem.Allocator, dir: []const u8, kind: Kind, bytes: []const u8) Error![:0]u8 {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update(kind.tag());
    h.update(version_tag);
    h.update(settings_key);
    h.update(bytes);
    const hex = std.fmt.bytesToHex(h.finalResult(), .lower);
    return std.fmt.allocPrintSentinel(alloc, "{s}/{s}.cwasm", .{ dir, hex }, 0);
}

/// `bytes` as wasm binary: itself when it starts with the `\0asm` magic, else
/// the `.wat` text read by the engine's reader. Null with `failure` set when
/// the text does not read. Free with `alloc` (a copy in both cases).
fn binaryOf(alloc: std.mem.Allocator, bytes: []const u8, failure: *?[]u8) Error!?[]u8 {
    if (std.mem.startsWith(u8, bytes, "\x00asm")) return try alloc.dupe(u8, bytes);
    var out: c.wasm_byte_vec_t = undefined;
    if (c.wasmtime_wat2wasm(bytes.ptr, bytes.len, &out)) |err| {
        failure.* = try errorText(alloc, "wasmtime could not read the wat text: ", err);
        return null;
    }
    defer c.wasm_byte_vec_delete(&out);
    return try alloc.dupe(u8, out.data[0..out.size]);
}

/// Compiled code for `bytes` (`.wat` text or binary). With a `cache_dir` the
/// file `cachePath` names is deserialized when it exists and the engine takes
/// it; otherwise (absent, refused, or `cold`, which reads nothing) the bytes are
/// compiled and the code serialized atomically into it. A write that fails costs
/// a compile next time, nothing else. Null with `failure` set (caller frees)
/// when the engine refuses the bytes.
pub fn precompiled(
    alloc: std.mem.Allocator,
    io: std.Io,
    cache_dir: ?[]const u8,
    bytes: []const u8,
    kind: Kind,
    cold: bool,
    failure: *?[]u8,
) Error!?Precompiled {
    const eng = try theEngine();
    const path: ?[:0]u8 = if (cache_dir) |d| try cachePath(alloc, d, kind, bytes) else null;
    errdefer if (path) |p| alloc.free(p);

    if (path) |p| if (!cold) {
        // A file the engine refuses (another wasmtime, a torn write) is
        // compiled again and written over.
        switch (kind) {
            .module => {
                var m: ?*c.wasmtime_module_t = null;
                if (c.wasmtime_module_deserialize_file(eng, p.ptr, &m)) |err| c.wasmtime_error_delete(err) else if (m) |mm|
                    return .{ .code = .{ .module = mm }, .from_cache = true, .path = path };
            },
            .component => {
                var m: ?*c.wasmtime_component_t = null;
                if (c.wasmtime_component_deserialize_file(eng, p.ptr, &m)) |err| c.wasmtime_error_delete(err) else if (m) |mm|
                    return .{ .code = .{ .component = mm }, .from_cache = true, .path = path };
            },
        }
    };

    const binary = (try binaryOf(alloc, bytes, failure)) orelse {
        if (path) |p| alloc.free(p);
        return null;
    };
    defer alloc.free(binary);

    var serialized: c.wasm_byte_vec_t = undefined;
    const code: Compiled = switch (kind) {
        .module => blk: {
            var m: ?*c.wasmtime_module_t = null;
            if (c.wasmtime_module_new(eng, binary.ptr, binary.len, &m)) |err| {
                failure.* = try errorText(alloc, "wasmtime could not compile the module: ", err);
                if (path) |p| alloc.free(p);
                return null;
            }
            if (path != null) {
                if (c.wasmtime_module_serialize(m.?, &serialized)) |err| c.wasmtime_error_delete(err) else {
                    defer c.wasm_byte_vec_delete(&serialized);
                    writeAtomic(alloc, io, path.?, serialized.data[0..serialized.size]);
                }
            }
            break :blk .{ .module = m.? };
        },
        .component => blk: {
            var m: ?*c.wasmtime_component_t = null;
            if (c.wasmtime_component_new(eng, binary.ptr, binary.len, &m)) |err| {
                failure.* = try errorText(alloc, "wasmtime could not compile the component: ", err);
                if (path) |p| alloc.free(p);
                return null;
            }
            if (path != null) {
                if (c.wasmtime_component_serialize(m.?, &serialized)) |err| c.wasmtime_error_delete(err) else {
                    defer c.wasm_byte_vec_delete(&serialized);
                    writeAtomic(alloc, io, path.?, serialized.data[0..serialized.size]);
                }
            }
            break :blk .{ .component = m.? };
        },
    };
    return .{ .code = code, .from_cache = false, .path = path };
}

/// Write `data` to `path`: staged as `<path>.<rand>.tmp`, then renamed over it
/// (no lock: a reader sees a whole file or none). Creates the directory. A
/// failure leaves nothing staged and costs the next reader a compile.
pub fn writeAtomic(alloc: std.mem.Allocator, io: std.Io, path: []const u8, data: []const u8) void {
    const cwd = std.Io.Dir.cwd();
    if (std.fs.path.dirname(path)) |d| cwd.createDirPath(io, d) catch return;
    var rand: [8]u8 = undefined;
    io.random(&rand);
    const tmp = std.fmt.allocPrint(alloc, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &rand, .little) }) catch return;
    defer alloc.free(tmp);
    cwd.writeFile(io, .{ .sub_path = tmp, .data = data }) catch {
        cwd.deleteFile(io, tmp) catch {};
        return;
    };
    std.Io.Dir.rename(cwd, tmp, cwd, path, io) catch cwd.deleteFile(io, tmp) catch {};
}

// ── tests ────────────────────────────────────────────────────────────────────

const test_module =
    \\(module (func (export "f") (result i32) (i32.const 7)))
;

fn countFiles(io: std.Io, dir: []const u8, suffix: []const u8) !usize {
    var d = try std.Io.Dir.cwd().openDir(io, dir, .{ .iterate = true });
    defer d.close(io);
    var n: usize = 0;
    var it = d.iterate();
    while (try it.next(io)) |e| if (std.mem.endsWith(u8, e.name, suffix)) {
        n += 1;
    };
    return n;
}

test "precompiled: a .cwasm is written once and deserialized on the second call" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);

    var failure: ?[]u8 = null;
    const first = (try precompiled(alloc, io, dir, test_module, .module, false, &failure)).?;
    defer alloc.free(first.path.?);
    defer first.code.deinit();
    try std.testing.expect(!first.from_cache);
    const s1 = try std.Io.Dir.cwd().statFile(io, first.path.?, .{});

    const second = (try precompiled(alloc, io, dir, test_module, .module, false, &failure)).?;
    defer alloc.free(second.path.?);
    defer second.code.deinit();
    try std.testing.expect(second.from_cache);
    const s2 = try std.Io.Dir.cwd().statFile(io, second.path.?, .{});
    // The file is not rewritten: same inode, same modification time.
    try std.testing.expectEqual(s1.inode, s2.inode);
    try std.testing.expectEqual(s1.mtime.nanoseconds, s2.mtime.nanoseconds);
    try std.testing.expectEqual(@as(usize, 1), try countFiles(io, dir, ".cwasm"));
}

test "precompiled: cold reads nothing and compiles again; nothing staged is left behind" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);

    var failure: ?[]u8 = null;
    const a = (try precompiled(alloc, io, dir, test_module, .module, false, &failure)).?;
    defer alloc.free(a.path.?);
    defer a.code.deinit();
    const cold = (try precompiled(alloc, io, dir, test_module, .module, true, &failure)).?;
    defer alloc.free(cold.path.?);
    defer cold.code.deinit();
    try std.testing.expect(!cold.from_cache);
    try std.testing.expectEqual(@as(usize, 1), try countFiles(io, dir, ".cwasm"));
    try std.testing.expectEqual(@as(usize, 0), try countFiles(io, dir, ".tmp"));
}

test "precompiled: a file the engine refuses is compiled again and overwritten" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir = try std.fmt.allocPrint(alloc, ".zig-cache/tmp/{s}/wasmtime", .{tmp.sub_path});
    defer alloc.free(dir);

    const path = try cachePath(alloc, dir, .module, test_module);
    defer alloc.free(path);
    writeAtomic(alloc, io, path, "not a cwasm");
    var failure: ?[]u8 = null;
    const r = (try precompiled(alloc, io, dir, test_module, .module, false, &failure)).?;
    defer alloc.free(r.path.?);
    defer r.code.deinit();
    try std.testing.expect(!r.from_cache);
    const again = (try precompiled(alloc, io, dir, test_module, .module, false, &failure)).?;
    defer alloc.free(again.path.?);
    defer again.code.deinit();
    try std.testing.expect(again.from_cache);
}

test "precompiled: binary input is accepted, the key differs by kind, and bad text is a failure" {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var failure: ?[]u8 = null;
    var out: c.wasm_byte_vec_t = undefined;
    try std.testing.expect(c.wasmtime_wat2wasm(test_module.ptr, test_module.len, &out) == null);
    defer c.wasm_byte_vec_delete(&out);
    const r = (try precompiled(alloc, io, null, out.data[0..out.size], .module, false, &failure)).?;
    r.code.deinit();
    try std.testing.expect(r.path == null);

    const a = try cachePath(alloc, "d", .module, "x");
    defer alloc.free(a);
    const b = try cachePath(alloc, "d", .component, "x");
    defer alloc.free(b);
    try std.testing.expect(!std.mem.eql(u8, a, b));

    try std.testing.expect((try precompiled(alloc, io, null, "(module", .module, false, &failure)) == null);
    defer alloc.free(failure.?);
}
