//! A host function's Erlang cell, run at comptime through beam-to-wasm
//! (decision 434 (3), 144 B-00b).
//!
//! An `@External.Erlang("…")` template — or an `@External.Erlang("m", "f")` /
//! `@External.Beam("m", "f")` pair, read as the template `m:f($0, …)` — is
//! compiled to a `.beam` the way the beam target compiles every Erlang
//! template (`codegen/beam/erl_template.zig` `templateBody` → `templateModuleText` →
//! `lowerTemplateText`, then `beam/beam_file.zig` `assemble`: the compiler's
//! own BEAM assembler, no `erlc`), and that `.beam` is translated by
//! `modules/beam-to-wasm` into wasm functions over this runtime's terms, its
//! BIF calls bound to `rt.zig`'s exports (`lower.zig` `bifs`).
//!
//! The one-function module is `bp_cell_<hash>` (the hash of the arity and the
//! template text): a comptime module calls it `bp_cell_<hash>:t(…)`, and
//! `program.zig` hands the translated module to the lowering for every cell
//! module its text names (`modulesIn`). Cached process-wide by module name.
const std = @import("std");
const bw = @import("beam_to_wasm");
const erlTemplate = @import("../../../codegen/beam/erl_template.zig");
const beamFile = @import("../../../codegen/beam/beam_file.zig");
const lower = @import("lower.zig");

pub const Error = std.mem.Allocator.Error;

/// The prefix of every cell module's name.
pub const module_prefix = "bp_cell_";

pub const Cell = union(enum) {
    /// The cell module's name: call `<name>:t/<arity>`.
    ok: []const u8,
    /// What beam-to-wasm (or the template's reading) did not convert.
    refused: []const u8,
};

const Entry = union(enum) {
    ok: bw.ir.Module,
    refused: []const u8,
};

const cache_alloc = std.heap.page_allocator;
var cache_lock: std.atomic.Value(u8) = .init(0);
var cache: std.StringArrayHashMapUnmanaged(Entry) = .empty;

fn lock() void {
    while (cache_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlock() void {
    cache_lock.store(0, .release);
}

/// The cell module serving template `template_raw` (as written in the
/// annotation) called with `arity` arguments, translated once per process.
pub fn ofTemplate(template_raw: []const u8, arity: usize) Error!Cell {
    var h = std.hash.Wyhash.init(0x434);
    h.update(std.mem.asBytes(&arity));
    h.update(template_raw);
    var name_buf: [module_prefix.len + 16]u8 = undefined;
    const name = std.fmt.bufPrint(&name_buf, module_prefix ++ "{x:0>16}", .{h.final()}) catch unreachable;

    lock();
    defer unlock();
    if (cache.get(name)) |hit| return switch (hit) {
        .ok => |m| .{ .ok = m.name },
        .refused => |why| .{ .refused = why },
    };
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const ar = arena_state.allocator();
    const owned = try ar.dupe(u8, name);
    const entry = try translate(ar, template_raw, arity, owned);
    try cache.put(cache_alloc, owned, entry);
    return switch (entry) {
        .ok => .{ .ok = owned },
        .refused => |why| .{ .refused = why },
    };
}

/// The cell module serving `module:function` called with `arity` arguments
/// (an `@External.Erlang("m", "f")` / `@External.Beam("m", "f")` pair).
pub fn ofCall(arena: std.mem.Allocator, module: []const u8, function: []const u8, arity: usize) Error!Cell {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.print(arena, "{s}:{s}(", .{ module, function });
    for (0..arity) |i| try text.print(arena, "{s}${d}", .{ if (i == 0) "" else ", ", i });
    try text.append(arena, ')');
    return ofTemplate(text.items, arity);
}

fn translate(ar: std.mem.Allocator, template_raw: []const u8, arity: usize, name: []const u8) Error!Entry {
    const body = erlTemplate.templateBody(ar, template_raw, arity) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the template does not read ({s})", .{@errorName(err)}) },
    };
    const text = try erlTemplate.templateModuleText(ar, body, false, arity);
    const lowered = switch (try erlTemplate.lowerTemplateText(ar, text, name)) {
        .ok => |o| o,
        .refused => |why| return .{ .refused = why },
    };
    const beam = beamFile.assemble(ar, lowered.module) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the template does not assemble ({s})", .{@errorName(err)}) },
    };
    return switch (try bw.translate(ar, beam, lower.beam_to_wasm_bifs)) {
        .ok => |m| .{ .ok = m },
        .refused => |why| .{ .refused = why },
    };
}

/// The translated cell modules the generated module text `code` calls.
pub fn modulesIn(arena: std.mem.Allocator, code: []const u8) Error![]const bw.ir.Module {
    if (std.mem.indexOf(u8, code, module_prefix) == null) return &.{};
    lock();
    defer unlock();
    var out: std.ArrayListUnmanaged(bw.ir.Module) = .empty;
    for (cache.keys(), cache.values()) |name, entry| switch (entry) {
        .ok => |m| if (std.mem.indexOf(u8, code, name) != null) try out.append(arena, m),
        .refused => {},
    };
    return out.toOwnedSlice(arena);
}

test "a template cell translates; the same text is one module" {
    const a = try ofTemplate("<<($0)/binary, \"!\">>", 1);
    const b = try ofTemplate("<<($0)/binary, \"!\">>", 1);
    try std.testing.expect(a == .ok);
    try std.testing.expectEqualStrings(a.ok, b.ok);
    try std.testing.expect(std.mem.startsWith(u8, a.ok, module_prefix));
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const in = try modulesIn(arena_state.allocator(), a.ok);
    try std.testing.expectEqual(@as(usize, 1), in.len);
    try std.testing.expectEqualStrings("t/1", in[0].functions[0].name);
}

test "a call outside the runtime's BIFs is refused, named" {
    const c = try ofTemplate("[re:run($0, <<\"a\">>)]", 1);
    try std.testing.expectEqualStrings("`re:run/2`", c.refused);
}

test "an opcode outside the measured subset is refused, named: a tail call" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const c = try ofCall(arena_state.allocator(), "string", "uppercase", 1);
    try std.testing.expectEqualStrings("opcode 8 (call_ext_last)", c.refused);
}
