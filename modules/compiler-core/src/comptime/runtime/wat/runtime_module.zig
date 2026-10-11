//! The comptime runtime's term library, linked from `std_wasm.wasm` once per
//! process (decision 450 (3)): there is one wasm runtime, std-wasm. Every
//! runtime export of std-wasm (`rt_*` — the Erlang terms, the OTP functions,
//! each `std:` export's comptime face) is decoded by
//! `codegen/wat/std_wasm_link.zig`, as a `--target wasm` program's calls are,
//! and emitted into one standalone module with what std-wasm leaves to its
//! caller:
//!
//! | std-wasm imports | the comptime binds |
//! |---|---|
//! | `env.bp_alloc` | `$__bp_arena_alloc` — the comptime's arena: a bump pointer from `rt_init(start)` on, grown by `memory.grow`, never freed (decision 450 (5), 449 (4)) |
//! | `env.bp_call0` … `bp_call4` | `$__bp_call<N>` — a `call_indirect` through the module's table, where the lowered program's closures are |
//! | `env.bp_random_f64` | nothing: the build has no entropy (decision 451), and no comptime face reaches it |
//! | `env.memory`, `__memory_base`, `__stack_pointer` | the module's memory; std-wasm's data at `data_base`; a stack of `stack_bytes` after it |
//!
//! It adds the two entries the executor and the lowering call beside the term
//! library's: `rt_init(start)` (the arena starts at `start`, then the terms'
//! state is reset, `rt_reset`) and `rt_alloc(len)` (room for the argument the
//! host writes). The module exports its memory and `__heap_base` (where
//! static memory ends); `link.zig` splices each lowered comptime program into
//! these bytes.
const std = @import("std");
const wat = @import("../../../codegen/wat/wat_ast.zig");
const bin = @import("../../../codegen/wat/wasm_binary_emitter.zig");
const swl = @import("../../../codegen/wat/std_wasm_link.zig");

pub const Error = swl.Error || bin.Error;

/// The shadow stack the term library's frames take: 1 MiB, as the term
/// library had when it was compiled on its own; each frame is checked
/// against the stack's floor (decision 447 (3)).
pub const stack_bytes: u32 = 1 << 20;

/// Where std-wasm's data starts: address 0 stays a null pointer.
pub const data_base: u32 = 1024;

const arena_alloc = "__bp_arena_alloc";
const arena = "__bp_arena";
const arena_end = "__bp_arena_end";
/// Table slot 0: a fun index that names no fun traps.
const no_fun = "__bp_no_fun";

/// What std-wasm's imports are bound to at comptime.
const bindings = [_]swl.Binding{
    .{ .import = "bp_alloc", .to = arena_alloc },
    .{ .import = "bp_random_f64", .to = "" },
    .{ .import = "bp_call0", .to = "__bp_call0" },
    .{ .import = "bp_call1", .to = "__bp_call1" },
    .{ .import = "bp_call2", .to = "__bp_call2" },
    .{ .import = "bp_call3", .to = "__bp_call3" },
    .{ .import = "bp_call4", .to = "__bp_call4" },
};

/// Why the last `build` failed, for the refusal's text.
pub var failure: []const u8 = "";

/// The runtime's bytes: std-wasm's runtime exports linked into one module.
pub fn build(ar: std.mem.Allocator) Error![]u8 {
    var diag: swl.Diag = .{};
    errdefer failure = diag.message;
    const wanted = try swl.runtimeExports(ar, swl.module_bytes, &diag);
    const linked = try swl.linkWith(ar, swl.module_bytes, wanted, data_base, .{
        .bindings = &bindings,
        .fixed_stack = stack_bytes,
        .export_wanted = true,
    }, &diag);

    var items: std.ArrayListUnmanaged(wat.Item) = .empty;
    try items.append(ar, .{ .memory = .{ .@"export" = "memory", .min_pages = @intCast((@as(u64, linked.end) + 65535) / 65536) } });
    // Slot 0 traps (no fun has index 0); the lowered program's closures
    // follow it (`link.zig` sizes the table). An empty table or element
    // segment is one wasm3 refuses to allocate ("memory allocation failed").
    try items.append(ar, .{ .table = try ar.dupe([]const u8, &.{no_fun}) });
    // The stack pointer is the first global (`link.zig` reads the stack top
    // from global 0).
    try items.appendSlice(ar, linked.items);
    try items.append(ar, .{ .global = .{ .name = arena, .ty = .i32, .mutable = true, .init = "0" } });
    try items.append(ar, .{ .global = .{ .name = arena_end, .ty = .i32, .mutable = true, .init = "0" } });
    try items.append(ar, .{ .global = .{ .name = "__heap_base", .exports = &.{"__heap_base"}, .ty = .i32, .init = try std.fmt.allocPrint(ar, "{d}", .{linked.end}) } });
    try items.append(ar, .{ .func = try arenaAlloc(ar) });
    try items.append(ar, .{ .func = try rtInit(ar) });
    try items.append(ar, .{ .func = try rtAlloc(ar) });
    for (0..5) |n| try items.append(ar, .{ .func = try callN(ar, n) });
    try items.append(ar, .{ .func = .{ .name = no_fun, .body = .{ .lines = try ar.dupe(wat.Line, &.{line(.@"unreachable")}), .stack = .terminated } } });
    return bin.encodeModule(ar, .{ .items = items.items });
}

fn line(instr: wat.Instr) wat.Line {
    return .{ .instr = instr };
}

fn c32(text: []const u8) wat.Instr {
    return .{ .@"const" = .{ .ty = .i32, .text = text } };
}

fn op(name: []const u8) wat.Instr {
    return .{ .op = .{ .ty = .i32, .name = name } };
}

fn params(ar: std.mem.Allocator, names: []const []const u8) ![]const wat.Param {
    const out = try ar.alloc(wat.Param, names.len);
    for (out, names) |*p, n| p.* = .{ .name = n, .ty = .i32 };
    return out;
}

/// `$__bp_arena_alloc(n)`: `n` bytes rounded up to 8, 8-aligned, from the
/// arena; the memory grows by whole pages when the arena reaches its end,
/// and a refused growth traps.
fn arenaAlloc(ar: std.mem.Allocator) !wat.Func {
    const grow = try ar.dupe(wat.Line, &.{
        line(.{ .local_get = "end" }),
        line(.{ .global_get = arena_end }),
        line(op("sub")),
        line(c32("65535")),
        line(op("add")),
        line(c32("16")),
        line(op("shr_u")),
        line(.{ .local_tee = "pages" }),
        line(.memory_grow),
        line(c32("0")),
        line(op("lt_s")),
        line(.{ .@"if" = .{ .then = .{ .seq = .{ .lines = try ar.dupe(wat.Line, &.{line(.@"unreachable")}), .stack = .terminated } } } }),
        line(.{ .global_get = arena_end }),
        line(.{ .local_get = "pages" }),
        line(c32("16")),
        line(op("shl")),
        line(op("add")),
        line(.{ .global_set = arena_end }),
    });
    const body = try ar.dupe(wat.Line, &.{
        line(.{ .global_get = arena }),
        line(.{ .local_tee = "p" }),
        line(.{ .local_get = "n" }),
        line(c32("7")),
        line(op("add")),
        line(c32("-8")),
        line(op("and")),
        line(op("add")),
        line(.{ .local_tee = "end" }),
        line(.{ .global_get = arena_end }),
        line(op("gt_u")),
        line(.{ .@"if" = .{ .then = .{ .seq = .{ .lines = grow, .stack = .none } } } }),
        line(.{ .local_get = "end" }),
        line(.{ .global_set = arena }),
        line(.{ .local_get = "p" }),
    });
    const locals = try ar.dupe([]const wat.Local, &.{try ar.dupe(wat.Local, &.{
        .{ .name = "p", .ty = .i32 },
        .{ .name = "end", .ty = .i32 },
        .{ .name = "pages", .ty = .i32 },
    })});
    return .{ .name = arena_alloc, .params = try params(ar, &.{"n"}), .result = .i32, .locals = locals, .body = .{ .lines = body, .stack = .{ .value = .i32 } } };
}

/// `rt_init(start)`: the arena from `start` (rounded up to 8) to the end of
/// the memory, then the terms' state reset.
fn rtInit(ar: std.mem.Allocator) !wat.Func {
    const body = try ar.dupe(wat.Line, &.{
        line(.{ .local_get = "start" }),
        line(c32("7")),
        line(op("add")),
        line(c32("-8")),
        line(op("and")),
        line(.{ .global_set = arena }),
        line(.memory_size),
        line(c32("16")),
        line(op("shl")),
        line(.{ .global_set = arena_end }),
        line(.{ .call = "rt_reset" }),
    });
    return .{ .name = "rt_init", .exports = try ar.dupe([]const u8, &.{"rt_init"}), .params = try params(ar, &.{"start"}), .body = .{ .lines = body } };
}

/// `rt_alloc(len)`: room on the arena for `len` bytes the host writes.
fn rtAlloc(ar: std.mem.Allocator) !wat.Func {
    const body = try ar.dupe(wat.Line, &.{
        line(.{ .local_get = "len" }),
        line(.{ .call = arena_alloc }),
    });
    return .{ .name = "rt_alloc", .exports = try ar.dupe([]const u8, &.{"rt_alloc"}), .params = try params(ar, &.{"len"}), .result = .i32, .body = .{ .lines = body, .stack = .{ .value = .i32 } } };
}

/// `$__bp_call<n>(index, f, a1 … an)`: the fun `f` called through the table
/// at `index` — the lifted function takes the fun itself first.
fn callN(ar: std.mem.Allocator, n: usize) !wat.Func {
    const names = [_][]const u8{ "index", "f", "a1", "a2", "a3", "a4" };
    var body: std.ArrayListUnmanaged(wat.Line) = .empty;
    for (names[1 .. n + 2]) |p| try body.append(ar, line(.{ .local_get = p }));
    try body.append(ar, line(.{ .local_get = "index" }));
    const sig = try ar.alloc(wat.ValType, n + 1);
    @memset(sig, .i32);
    try body.append(ar, line(.{ .call_indirect = .{ .params = sig, .result = .i32 } }));
    return .{
        .name = try std.fmt.allocPrint(ar, "__bp_call{d}", .{n}),
        .params = try params(ar, names[0 .. n + 2]),
        .result = .i32,
        .body = .{ .lines = body.items, .stack = .{ .value = .i32 } },
    };
}

test "the runtime links from std_wasm.wasm: every runtime export, standalone" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const bytes = build(ar) catch |err| {
        std.debug.print("runtime_module: {s} ({s})\n", .{ @errorName(err), failure });
        return err;
    };
    const link = @import("link.zig");
    const rt = try link.Runtime.parse(ar, bytes);
    try std.testing.expectEqual(@as(u32, 0), rt.n_imported_funcs);
    for ([_][]const u8{ "rt_init", "rt_alloc", "rt_reset", "rt_cons", "rt_pending", "rt_describe", "rt_bin_ptr", "rt_bin_len", "rt_lists_reverse", "rt_string_titlecase", "rt_std_hash__contentHash" }) |name|
        if (!rt.exports.contains(name)) {
            std.debug.print("runtime_module: no export `{s}`\n", .{name});
            return error.TestExpectedExport;
        };
    try std.testing.expect(rt.data_end >= data_base + stack_bytes);
}
