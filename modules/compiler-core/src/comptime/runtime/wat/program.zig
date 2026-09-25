//! A generated comptime module, made runnable on the wat runtime: its `.erl`
//! text and the resident prelude it imports are parsed (`erl_parse.zig`),
//! lowered to one wat module (`lower.zig`) and linked into the embedded
//! runtime bytes (`link.zig`, `rt.zig`). The result is cached by module atom —
//! the atom is the content hash of the text, so a hit is the same program.
//!
//! A construct the lowering cannot take is a **refusal** naming it
//! (`Built.refused`), which the evaluator reports as the module not compiling —
//! the same channel the BEAM runtime uses for an `erlc` rejection.
const std = @import("std");
const ep = @import("erl_parse.zig");
const lower = @import("lower.zig");
const link = @import("link.zig");
const preludeMod = @import("../prelude.zig");
const watEmitter = @import("../../../codegen/wat/wat_emitter.zig");

/// The runtime's bytes, compiled from `rt.zig` for `wasm32-freestanding` by
/// the root `build.zig` (`bp_wat_rt.wasm`).
pub const runtime_bytes = @embedFile("bp_wat_rt.wasm");

pub const Built = union(enum) {
    ok: struct {
        /// The linked module: the runtime plus the lowered program.
        wasm: []const u8,
        /// The lowered program as `.wat` text (`COMPTIME WAT`).
        listing: []const u8,
    },
    /// What could not be lowered, and where.
    refused: []const u8,
};

pub const Error = std.mem.Allocator.Error;

// ── the process-wide cache ───────────────────────────────────────────────────

const cache_alloc = std.heap.page_allocator;
var cache_lock: std.atomic.Value(u8) = .init(0);
var cache: std.StringHashMapUnmanaged(Built) = .empty;
var preludes: ?[]const ep.Module = null;

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
    if (cache.get(module)) |hit| return hit;

    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const ar = arena_state.allocator();
    const built = try buildUncached(ar, code);
    try cache.put(cache_alloc, try cache_alloc.dupe(u8, module), built);
    return built;
}

fn buildUncached(ar: std.mem.Allocator, code: []const u8) Error!Built {
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
    const wasm = link.link(ar, runtime_bytes, lowered.module, lowered.data) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the wat runtime could not link the module ({s})", .{@errorName(err)}) },
    };
    return .{ .ok = .{ .wasm = wasm, .listing = aw.written() } };
}

test "the resident preludes parse" {
    lock();
    defer unlock();
    const pre = (try parsedPreludes()).?;
    try std.testing.expectEqual(@as(usize, 2), pre.len);
    try std.testing.expectEqualStrings(preludeMod.template_module, pre[0].name);
}
