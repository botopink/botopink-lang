//! Thin Zig wrapper over [wasm3](https://github.com/wasm3/wasm3)'s C API.
//!
//! Owns the process-lifetime `IM3Environment` singleton (spinlock-guarded —
//! same pattern as `persistent_node`'s child-process singleton) and exposes
//! `runWat`: take WAT source bytes, parse via `wat_to_wasm.compile`, instantiate
//! in a fresh per-call `IM3Runtime`, register a one-function `fd_write` WASI
//! shim (plus no-op stubs for `proc_exit`, `environ_get`, `args_get`, …), call
//! the module's entry function, and return whatever the module wrote to fd 1.
//!
//! The entry function is auto-detected: `_botopink_main` wins (used by the
//! user-codegen WAT shape — `codegen/runtime.executeWat`); `_start` is the
//! fallback (used by `comptime/runtime/wasm.zig:buildScript`). Modules with
//! neither return an empty buffer — matching the legacy behaviour of
//! `executeWat` (snapshot RUN LOG stays empty).
const std = @import("std");
const builtin = @import("builtin");
const wat_to_wasm = @import("./wat_to_wasm.zig");

const c = @cImport({
    @cInclude("wasm3.h");
});

pub const Error = error{
    Wasm3OutOfMemory,
    Wasm3ParseFailed,
    Wasm3LoadFailed,
    Wasm3CallFailed,
    Wasm3LinkFailed,
    Wasm3RuntimeInit,
    WatCompileFailed,
    OutOfMemory,
} || wat_to_wasm.Error;

// ── Environment singleton (process-lifetime) ──────────────────────────────────

const Singleton = struct {
    env: ?*c.M3Environment = null,
    inited: std.atomic.Value(bool) = .{ .raw = false },
    lock: std.atomic.Value(bool) = .{ .raw = false },
};

fn spinLock(s: *Singleton) void {
    while (s.lock.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
        std.atomic.spinLoopHint();
    }
}

fn spinUnlock(s: *Singleton) void {
    s.lock.store(false, .release);
}

var singleton: Singleton = .{};

fn getEnv() Error!*c.M3Environment {
    if (singleton.inited.load(.acquire)) {
        return singleton.env.?;
    }
    spinLock(&singleton);
    defer spinUnlock(&singleton);
    if (singleton.inited.load(.acquire)) {
        return singleton.env.?;
    }
    const env = c.m3_NewEnvironment() orelse return error.Wasm3RuntimeInit;
    singleton.env = env;
    singleton.inited.store(true, .release);
    return env;
}

// ── runWat output cache ───────────────────────────────────────────────────────

/// Cap on the captured-stdout cache. A repeat `runWat` call with byte-identical
/// WAT input returns the same captured bytes — this is sound because the only
/// host call we wire (`wasi_snapshot_preview1.fd_write`) is pure-out, and the
/// other stubs (`proc_exit`, `environ_get`, …) deterministically return 0.
/// Same sizing rationale as `wat_cache_max_entries`.
const out_cache_max_entries: usize = 64;

const OutCacheEntry = struct {
    key: u64,
    out: []u8, // owned by `out_cache.arena`
};

const OutCache = struct {
    arena: std.heap.ArenaAllocator,
    entries: [out_cache_max_entries]?OutCacheEntry = .{null} ** out_cache_max_entries,
    next_slot: usize = 0,
    count: usize = 0,
};

var out_cache: ?*OutCache = null;
var out_cache_lock: std.atomic.Value(bool) = .{ .raw = false };

fn outCacheLock() void {
    while (out_cache_lock.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
        std.atomic.spinLoopHint();
    }
}

fn outCacheUnlock() void {
    out_cache_lock.store(false, .release);
}

fn outCacheGet() Error!*OutCache {
    if (out_cache) |c2| return c2;
    const gpa = std.heap.page_allocator;
    const c2 = gpa.create(OutCache) catch return error.Wasm3OutOfMemory;
    c2.* = .{ .arena = std.heap.ArenaAllocator.init(gpa) };
    out_cache = c2;
    return c2;
}

fn outCacheLookup(key: u64) ?[]const u8 {
    outCacheLock();
    defer outCacheUnlock();
    const c2 = out_cache orelse return null;
    for (c2.entries) |maybe| {
        if (maybe) |e| if (e.key == key) return e.out;
    }
    return null;
}

fn outCacheStore(key: u64, captured: []const u8) Error!void {
    outCacheLock();
    defer outCacheUnlock();
    const c2 = try outCacheGet();
    // Skip the insert if a concurrent caller already cached the same key.
    for (c2.entries) |maybe| {
        if (maybe) |e| if (e.key == key) return;
    }
    const owned = c2.arena.allocator().dupe(u8, captured) catch return error.Wasm3OutOfMemory;
    c2.entries[c2.next_slot] = .{ .key = key, .out = owned };
    c2.next_slot = (c2.next_slot + 1) % out_cache_max_entries;
    if (c2.count < out_cache_max_entries) c2.count += 1;
}

// ── WAT → WASM bytes cache ────────────────────────────────────────────────────

/// Cap on the number of cached (WAT-hash → binary-WASM-bytes) entries. Each
/// entry costs `key` (8 B) + `value len + ptr` (~24 B) + the WASM bytes
/// themselves (a few hundred B to a few KB for our subset). 64 entries × ~2 KB
/// avg ≈ 128 KB worst-case — trivial vs the ~50 KB wasm3 + ~80 KB stdlib
/// template footprint.
const wat_cache_max_entries: usize = 64;

const CacheEntry = struct {
    key: u64, // Wyhash of wat_bytes
    wasm: []u8, // owned by `cache_arena`
};

const WatCache = struct {
    /// Backing storage for every cached `.wasm` payload. The arena is a giant
    /// `page_allocator`-backed slab; entries are never freed individually —
    /// when the ring fills we wrap and overwrite the oldest slot, which
    /// orphans those bytes inside the arena until process exit.
    arena: std.heap.ArenaAllocator,
    entries: [wat_cache_max_entries]?CacheEntry = .{null} ** wat_cache_max_entries,
    /// Next slot to overwrite when the ring fills. Modulo
    /// `wat_cache_max_entries`.
    next_slot: usize = 0,
    /// Number of entries currently populated. Caps at the array length.
    count: usize = 0,
};

var wat_cache: ?*WatCache = null;
/// Atomic flag guarding the cache lookup/insert path.
var wat_cache_lock: std.atomic.Value(bool) = .{ .raw = false };

fn watCacheLock() void {
    while (wat_cache_lock.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
        std.atomic.spinLoopHint();
    }
}

fn watCacheUnlock() void {
    wat_cache_lock.store(false, .release);
}

fn watCacheGet() Error!*WatCache {
    if (wat_cache) |c2| return c2;
    const gpa = std.heap.page_allocator;
    const c2 = gpa.create(WatCache) catch return error.Wasm3OutOfMemory;
    c2.* = .{ .arena = std.heap.ArenaAllocator.init(gpa) };
    wat_cache = c2;
    return c2;
}

/// Look up `wat_bytes` in the cache; on miss compile via `wat_to_wasm.compile`
/// and store the result. The returned slice is owned by the cache (lives for
/// the process lifetime under the ring-buffer cap).
fn cachedCompile(allocator: std.mem.Allocator, wat_bytes: []const u8) Error![]const u8 {
    const key = std.hash.Wyhash.hash(0, wat_bytes);

    watCacheLock();
    const c2 = try watCacheGet();
    for (c2.entries) |maybe| {
        if (maybe) |e| if (e.key == key) {
            watCacheUnlock();
            return e.wasm;
        };
    }
    watCacheUnlock();

    // Cache miss — compile outside the lock so concurrent callers don't
    // serialise on the compile step.
    const compiled = wat_to_wasm.compile(allocator, wat_bytes) catch |err| return @errorCast(@as(anyerror, err));
    defer allocator.free(compiled);

    watCacheLock();
    defer watCacheUnlock();
    // Re-check after taking the lock — a concurrent miss might have populated
    // the same key in the meantime, in which case we drop ours rather than
    // double-insert.
    for (c2.entries) |maybe| {
        if (maybe) |e| if (e.key == key) return e.wasm;
    }
    const owned = c2.arena.allocator().dupe(u8, compiled) catch return error.Wasm3OutOfMemory;
    c2.entries[c2.next_slot] = .{ .key = key, .wasm = owned };
    c2.next_slot = (c2.next_slot + 1) % wat_cache_max_entries;
    if (c2.count < wat_cache_max_entries) c2.count += 1;
    return owned;
}

// ── Per-call capture buffer ───────────────────────────────────────────────────

/// One capture buffer per active `runWat` call. The fd_write shim looks up the
/// active buffer via the `IM3Runtime`'s `userdata` pointer, which we set right
/// after `m3_NewRuntime`.
const Capture = struct {
    allocator: std.mem.Allocator,
    buf: std.ArrayListUnmanaged(u8) = .empty,

    fn deinit(self: *Capture) void {
        self.buf.deinit(self.allocator);
    }
};

// ── WASI shim ─────────────────────────────────────────────────────────────────

/// wasi_snapshot_preview1.fd_write — reads `iovs_len` iovecs from memory at
/// `iovs_ptr`, appends each iovec's payload to the active capture buffer,
/// stores total bytes written into `nwritten_ptr`, returns 0 (success).
/// Signature in wasm3's mini-DSL: "i(iiii)" → returns i32, takes 4 × i32.
fn fdWrite(
    runtime: c.IM3Runtime,
    ctx: c.IM3ImportContext,
    sp: [*c]u64,
    mem: ?*anyopaque,
) callconv(.c) ?*const anyopaque {
    _ = ctx;
    var sp_iter = sp;
    // Pop return slot pointer (one i32 result), then the four i32 args.
    const raw_return: *u32 = @ptrCast(@alignCast(sp_iter));
    sp_iter += 1;
    const fd: u32 = @truncate(sp_iter[0]);
    sp_iter += 1;
    const iovs_ptr: u32 = @truncate(sp_iter[0]);
    sp_iter += 1;
    const iovs_len: u32 = @truncate(sp_iter[0]);
    sp_iter += 1;
    const nwritten_ptr: u32 = @truncate(sp_iter[0]);
    sp_iter += 1;

    // Only fd 1 (stdout) is captured. Other fds get a successful no-op.
    var total_written: u32 = 0;
    if (mem) |mem_ptr| {
        const mem_bytes: [*]u8 = @ptrCast(mem_ptr);
        if (fd == 1 or fd == 2) {
            const capture = capturePtr(runtime);
            var i: u32 = 0;
            while (i < iovs_len) : (i += 1) {
                const iov_off = iovs_ptr + i * 8;
                const buf_off = std.mem.readInt(u32, mem_bytes[iov_off..][0..4], .little);
                const buf_len = std.mem.readInt(u32, mem_bytes[iov_off + 4 ..][0..4], .little);
                if (capture) |cap| {
                    cap.buf.appendSlice(cap.allocator, mem_bytes[buf_off..][0..buf_len]) catch {
                        raw_return.* = 28; // ENOSPC
                        return c.m3Err_none;
                    };
                }
                total_written += buf_len;
            }
        } else {
            // Other fds: silently count the bytes.
            var i: u32 = 0;
            while (i < iovs_len) : (i += 1) {
                const iov_off = iovs_ptr + i * 8;
                const buf_len = std.mem.readInt(u32, mem_bytes[iov_off + 4 ..][0..4], .little);
                total_written += buf_len;
            }
        }
        std.mem.writeInt(u32, mem_bytes[nwritten_ptr..][0..4], total_written, .little);
    }
    raw_return.* = 0;
    return c.m3Err_none;
}

/// proc_exit (i32) — wasm3 traps via the special `m3Err_trapExit` sentinel.
/// We treat trapExit with code 0 as success.
fn procExit(
    runtime: c.IM3Runtime,
    ctx: c.IM3ImportContext,
    sp: [*c]u64,
    mem: ?*anyopaque,
) callconv(.c) ?*const anyopaque {
    _ = runtime;
    _ = ctx;
    _ = mem;
    _ = sp;
    return c.m3Err_trapExit;
}

/// Generic no-op returning 0 — covers `environ_get`, `environ_sizes_get`,
/// `args_get`, `args_sizes_get`, `clock_time_get`, etc. wasm3 dispatches by
/// signature, so this single body works for any "returns i32" WASI shim we
/// don't truly need.
fn wasiNoopRetI32(
    runtime: c.IM3Runtime,
    ctx: c.IM3ImportContext,
    sp: [*c]u64,
    mem: ?*anyopaque,
) callconv(.c) ?*const anyopaque {
    _ = runtime;
    _ = ctx;
    _ = mem;
    const raw_return: *u32 = @ptrCast(@alignCast(sp));
    raw_return.* = 0;
    return c.m3Err_none;
}

fn capturePtr(runtime: c.IM3Runtime) ?*Capture {
    // wasm3 stores per-runtime userdata via `m3_NewRuntime`'s third arg, which
    // we set immediately after creation. The getter is `m3_GetUserData`.
    const p = c.m3_GetUserData(runtime) orelse return null;
    return @ptrCast(@alignCast(p));
}

// ── Public surface ────────────────────────────────────────────────────────────

/// Compile WAT, instantiate via wasm3, call the entry function, return what
/// the module wrote to fd 1.
pub fn runWat(allocator: std.mem.Allocator, wat_bytes: []const u8) Error![]u8 {
    var mem_buf: std.ArrayListUnmanaged(u8) = .empty;
    const stdout = try runWatInternal(allocator, wat_bytes, &mem_buf, null, 0);
    if (mem_buf.items.len > 0) allocator.free(mem_buf.items);
    return stdout;
}

/// Like runWat but also returns a copy of linear memory starting at `mem_off`
/// for `mem_len` bytes (0 = entire memory). Caller owns both returned slices.
pub fn runWatGetMem(allocator: std.mem.Allocator, wat_bytes: []const u8, mem_off: u32, mem_len: u32) Error!struct { stdout: []u8, memory: []u8 } {
    var mem_buf: std.ArrayListUnmanaged(u8) = .empty;
    const stdout = try runWatInternal(allocator, wat_bytes, &mem_buf, @intCast(mem_off), mem_len);
    return .{ .stdout = stdout, .memory = try mem_buf.toOwnedSlice(allocator) };
}

fn runWatInternal(allocator: std.mem.Allocator, wat_bytes: []const u8, out_mem: *std.ArrayListUnmanaged(u8), mem_off: ?u32, mem_len: u32) Error![]u8 {
    // Output-cache short-circuit: same WAT → same captured stdout, since the
    // host functions we wire are pure-out (`fd_write`) or deterministic no-ops
    // (`environ_get`, `clock_time_get`, …). Skips the entire wasm3 cycle for a
    // hit — `m3_NewRuntime` + `Parse` + `Load` + `linkWasiShims` + `Call` +
    // cleanup. Typical hit rate in test cycles is high: every comptime val
    // with the same lowered expression produces byte-identical WAT.
    const out_key = std.hash.Wyhash.hash(0, wat_bytes);
    if (outCacheLookup(out_key)) |hit| return allocator.dupe(u8, hit) catch error.Wasm3OutOfMemory;

    const env = try getEnv();

    // WAT → binary-WASM cache covers the cold-output-miss path.
    const wasm_bytes = try cachedCompile(allocator, wat_bytes);

    var capture = Capture{ .allocator = allocator };
    defer capture.deinit();

    // 64KB stack is more than enough for our comptime WAT subset.
    const runtime = c.m3_NewRuntime(env, 64 * 1024, &capture) orelse return error.Wasm3RuntimeInit;
    defer c.m3_FreeRuntime(runtime);

    var module: c.IM3Module = null;
    if (c.m3_ParseModule(env, &module, wasm_bytes.ptr, @intCast(wasm_bytes.len))) |_| {
        return error.Wasm3ParseFailed;
    }
    // ParseModule transfers ownership to the runtime once LoadModule succeeds.
    if (c.m3_LoadModule(runtime, module)) |_| {
        c.m3_FreeModule(module);
        return error.Wasm3LoadFailed;
    }

    try linkWasiShims(module);

    // Auto-detect the entry function. Most user-codegen WAT exports
    // `_botopink_main`; comptime val WAT (`wasm.zig:buildScript`) exports
    // `_start`. Try `_botopink_main` first; fall back to `_start`. Modules with
    // neither: return empty (mirrors legacy executeWat).
    var fn_ptr: c.IM3Function = null;
    var find_err = c.m3_FindFunction(&fn_ptr, runtime, "_botopink_main");
    if (find_err != null) {
        find_err = c.m3_FindFunction(&fn_ptr, runtime, "_start");
    }
    if (find_err != null) {
        const out_empty = try capture.buf.toOwnedSlice(allocator);
        outCacheStore(out_key, out_empty) catch {};
        return out_empty;
    }

    const call_err = c.m3_CallV(fn_ptr);
    if (call_err != null and call_err != c.m3Err_trapExit) {
        return error.Wasm3CallFailed;
    }

    // Read linear memory before freeing the runtime.
    if (mem_off) |off| {
        var msize: u32 = 0;
        const mem = c.m3_GetMemory(runtime, &msize, 0);
        if (mem != null and msize > off) {
            const len: u32 = if (mem_len == 0) msize - off else @min(mem_len, msize - off);
            try out_mem.appendSlice(allocator, mem[off..][0..len]);
        }
    }

    const captured = try capture.buf.toOwnedSlice(allocator);
    outCacheStore(out_key, captured) catch {};
    return captured;
}

/// Pre-spawn / pre-init for the warmup test. Idempotent. Lazy-inits the env
/// and runs a trivial WAT once so the first real call only pays for the
/// per-call runtime / per-call module load.
pub fn warm(allocator: std.mem.Allocator) Error!void {
    const trivial = "(module (func (export \"_botopink_main\")))";
    const bytes = runWat(allocator, trivial) catch return;
    allocator.free(bytes);
}

fn linkWasiShims(module: c.IM3Module) Error!void {
    const ns = "wasi_snapshot_preview1";

    // fd_write is the critical one — everything else is best-effort no-op.
    if (c.m3_LinkRawFunction(module, ns, "fd_write", "i(iiii)", &fdWrite) != null) {
        // Not fatal: a module that doesn't import fd_write is fine.
    }
    _ = c.m3_LinkRawFunction(module, ns, "proc_exit", "v(i)", &procExit);
    _ = c.m3_LinkRawFunction(module, ns, "environ_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "environ_sizes_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "args_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "args_sizes_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "clock_time_get", "i(iIi)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "fd_close", "i(i)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "fd_seek", "i(iIii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "fd_read", "i(iiii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "fd_fdstat_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "random_get", "i(ii)", &wasiNoopRetI32);
    _ = c.m3_LinkRawFunction(module, ns, "poll_oneoff", "i(iiii)", &wasiNoopRetI32);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "runWat: empty module returns empty buffer" {
    const wat = "(module (func (export \"_botopink_main\")))";
    const out = try runWat(testing.allocator, wat);
    defer testing.allocator.free(out);
    try testing.expectEqual(@as(usize, 0), out.len);
}

test "runWat: fd_write captures bytes printed via WASI" {
    const wat =
        \\(module
        \\  (import "wasi_snapshot_preview1" "fd_write"
        \\    (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 8) "hi")
        \\  (func (export "_start")
        \\    (i32.store (i32.const 0) (i32.const 8))
        \\    (i32.store (i32.const 4) (i32.const 2))
        \\    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200)))))
    ;
    const out = try runWat(testing.allocator, wat);
    defer testing.allocator.free(out);
    try testing.expectEqualStrings("hi", out);
}

test "runWat: two iovecs concatenate correctly" {
    const wat =
        \\(module
        \\  (import "wasi_snapshot_preview1" "fd_write"
        \\    (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 32) "ab")
        \\  (data (i32.const 64) "cd")
        \\  (func (export "_start")
        \\    (i32.store (i32.const 0) (i32.const 32))
        \\    (i32.store (i32.const 4) (i32.const 2))
        \\    (i32.store (i32.const 8) (i32.const 64))
        \\    (i32.store (i32.const 12) (i32.const 2))
        \\    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 2) (i32.const 200)))))
    ;
    const out = try runWat(testing.allocator, wat);
    defer testing.allocator.free(out);
    try testing.expectEqualStrings("abcd", out);
}

test "runWat: env singleton reused across calls" {
    const wat = "(module (func (export \"_botopink_main\")))";
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        const out = try runWat(testing.allocator, wat);
        testing.allocator.free(out);
    }
}

test "runWat: missing entry function returns empty (matches legacy executeWat)" {
    const wat = "(module (func $other (export \"other\")))";
    const out = try runWat(testing.allocator, wat);
    defer testing.allocator.free(out);
    try testing.expectEqual(@as(usize, 0), out.len);
}

test "warm: idempotent and safe to call repeatedly" {
    try warm(testing.allocator);
    try warm(testing.allocator);
}
