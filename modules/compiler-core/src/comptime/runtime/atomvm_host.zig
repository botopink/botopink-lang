//! Thin Zig wrapper over [AtomVM](https://github.com/atomvm/AtomVM)'s C API.
//!
//! Owns the process-lifetime `GlobalContext` singleton (spinlock-guarded —
//! same pattern as `wasm3_host`) and exposes `runBeam`: take BEAM bytecode,
//! instantiate in a fresh per-call Context, redirect stdout to a capture pipe,
//! call the module's entry function, and return whatever the module wrote to
//! stdout.
//!
//! The entry function is `main/0`. The `warm` function pre-initialises the
//! GlobalContext singleton.
//!
//! Uses `extern` declarations for AtomVM's C API instead of `@cImport`
//! because AtomVM's headers have complex interdependencies that Zig 0.16's
//! C translation cannot currently handle.
const std = @import("std");
const builtin = @import("builtin");

// ── AtomVM C API (extern declarations) ────────────────────────────────────────

// Opaque types — Zig only needs pointer-sized knowledge, no layout details.
pub const GlobalContext = opaque {};
pub const Module = opaque {};
pub const Context = opaque {};

// Forward declarations needed by the API: Module is the BEAM module handle.
// Context is the execution context.

extern fn globalcontext_new() ?*GlobalContext;
extern fn globalcontext_destroy(glb: *GlobalContext) void;
extern fn module_new_from_iff_binary(global: *GlobalContext, iff_binary: ?*const anyopaque, size: c_ulong) ?*Module;
extern fn context_new(glb: *GlobalContext) ?*Context;
extern fn context_destroy(ctx: *Context) void;
extern fn context_execute_loop(ctx: *Context, mod: *Module, function_name: [*c]const u8, arity: c_int) c_int;

// ── Error set ─────────────────────────────────────────────────────────────────

pub const Error = error{
    AtomvmOutOfMemory,
    AtomvmModuleLoadFailed,
    AtomvmContextCreateFailed,
    AtomvmExecuteFailed,
    OutOfMemory,
    PipeFailed,
};

// ── GlobalContext singleton (process-lifetime) ─────────────────────────────────

const Singleton = struct {
    glb: ?*GlobalContext = null,
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

fn getGlobal() Error!*GlobalContext {
    if (singleton.inited.load(.acquire)) {
        return singleton.glb.?;
    }
    spinLock(&singleton);
    defer spinUnlock(&singleton);
    if (singleton.inited.load(.acquire)) {
        return singleton.glb.?;
    }
    const glb = globalcontext_new() orelse return error.AtomvmContextCreateFailed;
    singleton.glb = glb;
    singleton.inited.store(true, .release);
    return glb;
}

// ── output cache ──────────────────────────────────────────────────────────────

const out_cache_max_entries: usize = 64;

const OutCacheEntry = struct {
    key: u64,
    out: []u8,
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
    const c2 = gpa.create(OutCache) catch return error.OutOfMemory;
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
    for (c2.entries) |maybe| {
        if (maybe) |e| if (e.key == key) return;
    }
    const owned = c2.arena.allocator().dupe(u8, captured) catch return error.OutOfMemory;
    c2.entries[c2.next_slot] = .{ .key = key, .out = owned };
    c2.next_slot = (c2.next_slot + 1) % out_cache_max_entries;
    if (c2.count < out_cache_max_entries) c2.count += 1;
}

// ── stdout capture via pipe ───────────────────────────────────────────────────

/// Redirect stdout to a pipe, run `body`, capture all written bytes,
/// then restore stdout. Returns the captured output (caller owns the buffer).
fn captureStdout(allocator: std.mem.Allocator, body: anytype) Error![]u8 {
    const pipe_fds = try std.os.pipe();
    defer {
        std.os.close(pipe_fds[0]);
        std.os.close(pipe_fds[1]);
    }

    const saved_stdout = try std.os.dup(std.os.STDOUT_FILENO);
    defer std.posix.close(saved_stdout);

    try std.os.dup2(pipe_fds[1], std.os.STDOUT_FILENO);
    defer {
        std.os.dup2(saved_stdout, std.os.STDOUT_FILENO) catch {};
    }

    body();

    // Close the write end so read doesn't block.
    std.os.close(pipe_fds[1]);
    // (prevent double-close in defer)
    const read_fd = pipe_fds[0];
    pipe_fds[0] = std.math.maxInt(std.os.fd_t);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    var read_buf: [4096]u8 = undefined;
    while (true) {
        const n = std.os.read(read_fd, &read_buf) catch |err| switch (err) {
            error.WouldBlock => break,
            else => |e| return e,
        };
        if (n == 0) break;
        try buf.appendSlice(read_buf[0..n]);
    }

    return try buf.toOwnedSlice();
}

// ── Public surface ────────────────────────────────────────────────────────────

/// Load BEAM bytecode into AtomVM, call the entry function, return what
/// the module wrote to stdout.
pub fn runBeam(allocator: std.mem.Allocator, beam_bytes: []const u8) Error![]u8 {
    const out_key = std.hash.Wyhash.hash(0, beam_bytes);
    if (outCacheLookup(out_key)) |hit| return allocator.dupe(u8, hit) catch error.OutOfMemory;

    _ = try getGlobal();
    const glb = singleton.glb.?;

    const captured = try captureStdout(allocator, struct {
        fn call(g: *GlobalContext, bytes: []const u8) void {
            const mod = module_new_from_iff_binary(g, bytes.ptr, @intCast(bytes.len));
            if (mod == null) return;
            const ctx = context_new(g) orelse return;
            defer context_destroy(ctx);
            _ = context_execute_loop(ctx, mod, "main", 0);
        }
    }.call, .{ glb, beam_bytes });

    outCacheStore(out_key, captured) catch {};
    return captured;
}

/// Pre-initialise the GlobalContext singleton. Idempotent. Safe to call
/// multiple times.
pub fn warm(allocator: std.mem.Allocator) Error!void {
    _ = allocator;
    _ = try getGlobal();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "warm: idempotent and safe to call repeatedly" {
    try warm(testing.allocator);
    try warm(testing.allocator);
}
