//! Decision 1036 — `botopink pack`'s component: one WASI p2 component
//! holding every unit a `wasi` entry reaches, runnable by a standalone
//! `wasmtime run`.
//!
//! It is the shape the runner composes at run time (`runner.runEntry`,
//! decision 1032 (3)) made self-contained: the frame `wat_emitter.frameOfAs`
//! renders in `.slot` mode defines each unit as a core module of its own
//! whose body is a placeholder (exporting only `pack_slot_prefix ++ "<k>"`)
//! instead of importing it as `unit-<k>`; the frame's text is read into a
//! component binary by the engine's reader (`engine.binaryOf`), and each
//! placeholder's core module section is then replaced by the unit's own
//! bytes, as they are — the unit is never re-encoded, so the packed file
//! carries the bytes `out/wasm/` holds (and the compiler's own core and std
//! units). The component imports only the WASI interfaces the frame names.
const std = @import("std");
const runner = @import("runner.zig");
const watEmitter = @import("wat_emitter.zig");
const engine_mod = @import("engine.zig");

pub const Error = std.mem.Allocator.Error;

/// The component section holding one core module.
const core_module_section: u8 = 1;
/// A component binary's preamble: the magic, then its version and layer.
const component_preamble = "\x00asm\x0d\x00\x01\x00";

/// The packed component of the units entry `entry` (binary or `.wat`), its
/// units read from `units` as `runner.runEntry` reads them. Null with
/// `failure` set (allocated with `alloc`) when a unit is missing, the frame
/// cannot be built, or the frame's text does not read. The caller owns the
/// answer.
pub fn pack(alloc: std.mem.Allocator, io: std.Io, entry: []const u8, units: runner.UnitSource, failure: *?[]u8) Error!?[]u8 {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    var why: ?[]u8 = null;
    const g = (try runner.gather(ar, io, entry, units, &why)) orelse {
        failure.* = try alloc.dupe(u8, why.?);
        return null;
    };
    var frame: std.Io.Writer.Allocating = .init(ar);
    watEmitter.frameOfAs(ar, &frame.writer, g.bytes[g.bytes.len - 1], g.program, .slot) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            failure.* = try std.fmt.allocPrint(alloc, "the entry's component frame cannot be built: {s}", .{@errorName(err)});
            return null;
        },
    };
    const shell = (try engine_mod.binaryOf(ar, frame.written(), &why)) orelse {
        failure.* = try alloc.dupe(u8, why.?);
        return null;
    };
    return fill(alloc, shell, g.bytes) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            failure.* = try std.fmt.allocPrint(alloc, "the packed component cannot be assembled: {s}", .{@errorName(err)});
            return null;
        },
    };
}

pub const FillError = Error || error{
    /// `shell` is not a component binary, or a section overruns it.
    NotAComponent,
    /// A slot's index is not one of `units`, or a unit has no slot / two.
    SlotMismatch,
};

/// `shell` (a component binary) with each placeholder core module `k` of a
/// `.slot` frame replaced by `units[k]`, every other byte kept.
pub fn fill(alloc: std.mem.Allocator, shell: []const u8, units: []const []const u8) FillError![]u8 {
    if (!std.mem.startsWith(u8, shell, component_preamble)) return error.NotAComponent;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, component_preamble);
    const seen = try alloc.alloc(bool, units.len);
    defer alloc.free(seen);
    @memset(seen, false);
    var i: usize = component_preamble.len;
    while (i < shell.len) {
        const start = i;
        const id = shell[i];
        i += 1;
        const size = uleb(shell, &i) orelse return error.NotAComponent;
        if (i + size > shell.len) return error.NotAComponent;
        const body = shell[i .. i + size];
        i += size;
        const k = if (id == core_module_section) slotOf(body) else null;
        if (k) |slot| {
            if (slot >= units.len or seen[slot]) return error.SlotMismatch;
            seen[slot] = true;
            try out.append(alloc, core_module_section);
            try writeUleb(alloc, &out, units[slot].len);
            try out.appendSlice(alloc, units[slot]);
        } else try out.appendSlice(alloc, shell[start..i]);
    }
    for (seen) |s| if (!s) return error.SlotMismatch;
    return out.toOwnedSlice(alloc);
}

/// The slot index a placeholder module exports, `<pack_slot_prefix><k>`.
fn slotOf(module: []const u8) ?usize {
    const p = watEmitter.pack_slot_prefix;
    const at = std.mem.indexOf(u8, module, p) orelse return null;
    var j = at + p.len;
    const from = j;
    while (j < module.len and std.ascii.isDigit(module[j])) j += 1;
    if (j == from) return null;
    return std.fmt.parseInt(usize, module[from..j], 10) catch null;
}

fn uleb(bytes: []const u8, i: *usize) ?usize {
    var result: usize = 0;
    var shift: u6 = 0;
    while (i.* < bytes.len) {
        const b = bytes[i.*];
        i.* += 1;
        result |= @as(usize, b & 0x7f) << shift;
        if (b & 0x80 == 0) return result;
        if (shift >= 56) return null;
        shift += 7;
    }
    return null;
}

fn writeUleb(alloc: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), value: usize) Error!void {
    var v = value;
    while (true) {
        const b: u8 = @intCast(v & 0x7f);
        v >>= 7;
        if (v == 0) return out.append(alloc, b);
        try out.append(alloc, b | 0x80);
    }
}

// ── tests ────────────────────────────────────────────────────────────────────

test "fill replaces each slot's core module with its unit and keeps every other section" {
    const a = std.testing.allocator;
    const slot0 = "\x00asm\x01\x00\x00\x00" ++ watEmitter.pack_slot_prefix ++ "0";
    const slot1 = "\x00asm\x01\x00\x00\x00" ++ watEmitter.pack_slot_prefix ++ "1";
    const other = "\x00asm\x01\x00\x00\x00shim";
    const shell = component_preamble ++
        "\x01" ++ [_]u8{slot1.len} ++ slot1 ++
        "\x0a\x02\xaa\xbb" ++
        "\x01" ++ [_]u8{other.len} ++ other ++
        "\x01" ++ [_]u8{slot0.len} ++ slot0;
    const big = "\x00asm\x01\x00\x00\x00" ++ "x" ** 200;
    const got = try fill(a, shell, &.{ "\x00asm\x01\x00\x00\x00u0", big });
    defer a.free(got);
    const want = component_preamble ++
        "\x01\xd0\x01" ++ big ++
        "\x0a\x02\xaa\xbb" ++
        "\x01" ++ [_]u8{other.len} ++ other ++
        "\x01\x0a\x00asm\x01\x00\x00\x00u0";
    try std.testing.expectEqualSlices(u8, want, got);
}

test "fill refuses a unit with no slot and a slot with no unit" {
    const a = std.testing.allocator;
    const slot0 = "\x00asm\x01\x00\x00\x00" ++ watEmitter.pack_slot_prefix ++ "0";
    const shell = component_preamble ++ "\x01" ++ [_]u8{slot0.len} ++ slot0;
    try std.testing.expectError(error.SlotMismatch, fill(a, shell, &.{ "u0", "u1" }));
    try std.testing.expectError(error.SlotMismatch, fill(a, shell, &.{}));
    try std.testing.expectError(error.NotAComponent, fill(a, "\x00asm\x01\x00\x00\x00", &.{}));
}
