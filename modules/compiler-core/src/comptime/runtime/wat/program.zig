//! A generated comptime module, made runnable on the wat runtime: its `.erl`
//! text and the resident prelude it imports are parsed (`erl_parse.zig`),
//! lowered to one wat module (`lower.zig`) and linked into the runtime's
//! bytes (`link.zig`) — std-wasm's term library, linked from `std_wasm.wasm`
//! once per process (`runtime_module.zig`, decision 450 (3)). The result is cached by module atom —
//! the atom is the content hash of the text, so a hit is the same program.
//! The cache keeps the text too, not its `COMPTIME WAT` listing: the listing is
//! lowered again from it when a trace is rendered (`listing`, 144 B-127).
//!
//! A construct the lowering cannot take is a **refusal** naming it
//! (`Built.refused`), which the evaluator reports as the module not compiling.
const std = @import("std");
const ep = @import("../../../codegen/beam/erl_parse.zig");
const lower = @import("lower.zig");
const link = @import("link.zig");
const preludeMod = @import("../prelude.zig");
const watEmitter = @import("../../../codegen/wat/wat_emitter.zig");
const runtimeModule = @import("runtime_module.zig");

pub const Built = union(enum) {
    ok: struct {
        /// The linked module: the runtime plus the lowered program.
        wasm: []const u8,
    },
    /// What could not be lowered, and where.
    refused: []const u8,
};

pub const Error = std.mem.Allocator.Error;

// ── the process-wide cache ───────────────────────────────────────────────────

const cache_alloc = std.heap.page_allocator;
var cache_lock: std.atomic.Value(u8) = .init(0);
/// A built module and the text it was built from (`listing` lowers it again).
const Cached = struct { built: Built, code: []const u8 };
var cache: std.StringHashMapUnmanaged(Cached) = .empty;
var preludes: ?[]const ep.Module = null;
var runtime: ?[]const u8 = null;

/// The runtime's bytes (`runtime_module.zig`), linked once per process.
/// Called with the lock held; null when std-wasm does not link (a defect
/// of this tree, reported for every evaluation).
fn runtimeBytes() Error!?[]const u8 {
    if (runtime) |r| return r;
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const bytes = runtimeModule.build(arena_state.allocator()) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    runtime = bytes;
    return bytes;
}

fn lock() void {
    while (cache_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlock() void {
    cache_lock.store(0, .release);
}

/// The two resident preludes, parsed once per process. Called with the lock
/// held.
fn parsedPreludes() Error!?[]const ep.Module {
    if (preludes) |p| return p;
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const ar = arena_state.allocator();
    const mods = preludeMod.modules(ar) catch return error.OutOfMemory;
    const out = try ar.alloc(ep.Module, mods.len);
    for (mods, 0..) |m, i| {
        var failure: ep.Failure = .{};
        out[i] = ep.parseModule(ar, m.source, &failure) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            // The prelude is ours: a construct outside the subset is a defect
            // of this front, reported for every evaluation.
            else => return null,
        };
    }
    preludes = out;
    return out;
}

/// Build (or fetch) the runnable form of the module `module` whose text is
/// `code`. Everything answered is owned by the cache and lives for the
/// process.
pub fn build(module: []const u8, code: []const u8) Error!Built {
    lock();
    defer unlock();
    if (cache.get(module)) |hit| return hit.built;

    // The parse, the lowering and the rendered wat text of the build are
    // scratch: only the linked bytes outlive it, with the text they were
    // built from. Keeping the whole arena held the intermediate forms of
    // every module the process had built (144 B-117); keeping the listing
    // held a copy of the lowered functions per module, ~1.7 MB a decorator
    // call, for a listing only a snapshot or the code cache reads (144 B-127).
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    defer arena_state.deinit();
    const built = try ownedBuilt(try buildUncached(arena_state.allocator(), code));
    const kept_code: []const u8 = if (built == .ok) try cache_alloc.dupe(u8, code) else "";
    try cache.put(cache_alloc, try cache_alloc.dupe(u8, module), .{ .built = built, .code = kept_code });
    return built;
}

/// The `COMPTIME WAT` listing of the module `module` built — its lowered
/// functions as `.wat` text (not `main/1`, not the prelude's, not the
/// runtime's) — lowered again from the text the cache keeps; owned by
/// `allocator`. Null when `module` was not built or was refused.
pub fn listing(allocator: std.mem.Allocator, module: []const u8) Error!?[]u8 {
    lock();
    defer unlock();
    const hit = cache.get(module) orelse return null;
    if (hit.built != .ok) return null;
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    defer arena_state.deinit();
    return switch (try lowerUncached(arena_state.allocator(), hit.code)) {
        .ok => |o| try allocator.dupe(u8, try listingOf(arena_state.allocator(), o.text, o.lowered.listed)),
        .refused => null,
    };
}

/// `built` with its bytes copied out of the build's scratch arena into the
/// process-wide cache's allocator.
fn ownedBuilt(built: Built) Error!Built {
    return switch (built) {
        .ok => |o| .{ .ok = .{ .wasm = try cache_alloc.dupe(u8, o.wasm) } },
        .refused => |why| .{ .refused = try cache_alloc.dupe(u8, why) },
    };
}

/// The generated module lowered to one wat module with the preludes it
/// imports, and that module's rendered text — or what could not be lowered.
const Lowered = union(enum) {
    ok: struct { lowered: lower.Output, text: []const u8 },
    refused: []const u8,
};

/// Called with the lock held (the preludes are parsed once, under it).
fn lowerUncached(ar: std.mem.Allocator, code: []const u8) Error!Lowered {
    const pre = (try parsedPreludes()) orelse return .{ .refused = "the wat runtime could not read its own resident prelude" };

    var pf: ep.Failure = .{};
    const gen = ep.parseModule(ar, code, &pf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime does not take {s} (line {d} of the generated module)", .{ pf.message, pf.line }) },
        error.Syntax => return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime could not read the generated module: {s} at line {d}", .{ pf.message, pf.line }) },
    };

    // The generated module first, then the preludes it imports.
    var mods: std.ArrayListUnmanaged(ep.Module) = .empty;
    try mods.append(ar, gen);
    for (pre) |p| {
        for (gen.imports) |im| {
            if (std.mem.eql(u8, im.module, p.name)) {
                try mods.append(ar, p);
                break;
            }
        }
    }

    var lf: lower.Failure = .{};
    const lowered = lower.lowerProgram(ar, .{ .modules = mods.items }, &lf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime does not take {s}", .{lf.message}) },
    };

    var aw: std.Io.Writer.Allocating = .init(ar);
    watEmitter.renderModule(&aw.writer, lowered.module) catch |err| return .{
        .refused = try std.fmt.allocPrint(ar, "the lowered wat module is invalid ({s})", .{@errorName(err)}),
    };
    return .{ .ok = .{ .lowered = lowered, .text = aw.written() } };
}

fn buildUncached(ar: std.mem.Allocator, code: []const u8) Error!Built {
    const ok = switch (try lowerUncached(ar, code)) {
        .ok => |o| o,
        .refused => |why| return .{ .refused = why },
    };
    const runtime_bytes = (try runtimeBytes()) orelse return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime could not link std-wasm's term library ({s})", .{runtimeModule.failure}) };
    const wasm = link.link(ar, runtime_bytes, ok.lowered.module, ok.lowered.data) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime could not link the module ({s})", .{@errorName(err)}) },
    };
    return .{ .ok = .{ .wasm = wasm } };
}

/// The `(func $<name> …)` forms of `listed`, cut out of the rendered module
/// text in order, re-indented to the left margin.
fn listingOf(ar: std.mem.Allocator, text: []const u8, listed: []const []const u8) Error![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (listed) |name| {
        const head = try std.fmt.allocPrint(ar, "\n  (func ${s}", .{name});
        var at: usize = 0;
        const start = while (std.mem.indexOfPos(u8, text, at, head)) |i| {
            const after = i + head.len;
            if (after < text.len and (text[after] == ' ' or text[after] == '\n')) break i + 1;
            at = after;
        } else continue;
        const end = std.mem.indexOfPos(u8, text, start + 1, "\n  (") orelse text.len;
        var lines = std.mem.splitScalar(u8, text[start..end], '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            try out.appendSlice(ar, if (std.mem.startsWith(u8, line, "  ")) line[2..] else line);
            try out.append(ar, '\n');
        }
        try out.append(ar, '\n');
    }
    return out.items;
}

test "the resident preludes parse" {
    lock();
    defer unlock();
    const pre = (try parsedPreludes()).?;
    try std.testing.expectEqual(@as(usize, 2), pre.len);
    try std.testing.expectEqualStrings(preludeMod.template_module, pre[0].name);
}
