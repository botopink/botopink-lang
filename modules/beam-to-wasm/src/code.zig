//! The `Code` chunk's instruction stream: opcodes (OTP's `genop.tab`
//! numbering) and their operands in the compact term encoding.
//!
//! Only the measured subset is decoded (decision 435; `../AGENTS.md`
//! § Measured): an opcode outside `ops` stops the decoding with the opcode's
//! number — its arity is not known, so nothing after it can be read — and the
//! translation refuses the module naming it.
const std = @import("std");

pub const Error = error{ OutOfMemory, BadBeam };

/// The opcodes decoded, by `genop.tab` number.
pub const Op = enum(u8) {
    label = 1,
    func_info = 2,
    int_code_end = 3,
    call_ext = 7,
    allocate = 12,
    test_heap = 16,
    deallocate = 18,
    @"return" = 19,
    is_binary = 53,
    jump = 61,
    move = 64,
    put_list = 69,
    init_yregs = 172,

    pub fn arity(op: Op) u8 {
        return switch (op) {
            .label, .deallocate, .jump, .init_yregs => 1,
            .func_info, .put_list => 3,
            .int_code_end, .@"return" => 0,
            .call_ext, .allocate, .test_heap, .is_binary, .move => 2,
        };
    }
};

/// One operand. `a` with index 0 is `nil` (`[]`); the others are 1-based
/// into the atom table.
pub const Arg = union(enum) {
    u: u64,
    i: i64,
    a: u32,
    nil,
    x: u32,
    y: u32,
    f: u32,
    /// `{literal, N}` — index into `LitT`.
    literal: u32,
    /// `{list, [...]}` (`init_yregs`' register list).
    list: []const Arg,
};

pub const Instr = struct { op: Op, args: []const Arg };

pub const Decoded = struct {
    instrs: []const Instr,
    /// The first opcode outside `Op`, when the stream holds one: decoding
    /// stopped there.
    unknown: ?u8 = null,
};

const Reader = struct {
    bytes: []const u8,
    at: usize = 0,

    fn byte(r: *Reader) Error!u8 {
        if (r.at >= r.bytes.len) return error.BadBeam;
        defer r.at += 1;
        return r.bytes[r.at];
    }
};

/// The value of a compact term whose first byte is `b` (tag in the low 3
/// bits): 4 bits inline, 11 bits over two bytes, or 2–8 (or more, with a
/// nested length) big-endian bytes — sign-extended for an `i`.
fn value(r: *Reader, b: u8, signed: bool) Error!i128 {
    if (b & 0x08 == 0) return b >> 4;
    if (b & 0x10 == 0) return (@as(i128, b & 0xE0) << 3) | try r.byte();
    var n: usize = (b >> 5) + 2;
    if (n == 9) {
        const lb = try r.byte();
        const extra = try value(r, lb, false);
        if (extra < 0 or extra > 7) return error.BadBeam;
        n = @as(usize, @intCast(extra)) + 9;
    }
    if (n > 16) return error.BadBeam;
    var v: i128 = 0;
    for (0..n) |_| v = (v << 8) | try r.byte();
    if (signed and n < 16 and (v >> @intCast(n * 8 - 1)) & 1 == 1) v -= @as(i128, 1) << @intCast(n * 8);
    return v;
}

fn arg(arena: std.mem.Allocator, r: *Reader) Error!Arg {
    const b = try r.byte();
    const tag = b & 7;
    if (tag == 7) {
        // Extended: the sub-tag in the high nibble.
        switch (b >> 4) {
            1 => { // {list, …}: a `u` count, then that many terms
                const nb = try r.byte();
                const n = try value(r, nb, false);
                if (n < 0 or n > r.bytes.len) return error.BadBeam;
                const items = try arena.alloc(Arg, @intCast(n));
                for (items) |*it| it.* = try arg(arena, r);
                return .{ .list = items };
            },
            4 => { // {literal, N}: a `u` index
                const nb = try r.byte();
                return .{ .literal = std.math.cast(u32, try value(r, nb, false)) orelse return error.BadBeam };
            },
            else => return error.BadBeam,
        }
    }
    const v = try value(r, b, tag == 1);
    const small = std.math.cast(u32, v);
    return switch (tag) {
        0 => .{ .u = std.math.cast(u64, v) orelse return error.BadBeam },
        1 => .{ .i = std.math.cast(i64, v) orelse return error.BadBeam },
        2 => if (v == 0) .nil else .{ .a = small orelse return error.BadBeam },
        3 => .{ .x = small orelse return error.BadBeam },
        4 => .{ .y = small orelse return error.BadBeam },
        5 => .{ .f = small orelse return error.BadBeam },
        else => error.BadBeam,
    };
}

/// Decode `code` up to `int_code_end`, or up to the first opcode outside
/// the subset.
pub fn decode(arena: std.mem.Allocator, code: []const u8) Error!Decoded {
    var r: Reader = .{ .bytes = code };
    var out: std.ArrayListUnmanaged(Instr) = .empty;
    while (r.at < code.len) {
        const n = try r.byte();
        const op = std.enums.fromInt(Op, n) orelse return .{ .instrs = out.items, .unknown = n };
        const args = try arena.alloc(Arg, op.arity());
        for (args) |*a| a.* = try arg(arena, &r);
        try out.append(arena, .{ .op = op, .args = args });
        if (op == .int_code_end) break;
    }
    return .{ .instrs = out.items };
}

test "compact terms: each tag and the three value widths" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    var r: Reader = .{
        .bytes = &.{
            0x30, // u 3
            0x13, // x 1
            0x24, // y 2
            0x02, // a 0 = nil
            0x12, // a 1
            0x55, // f 5
            0x08 | 0x00 | 0x20, 0x10, // u, 11-bit: (0x20 << 3) | 0x10 = 0x110
            0x09, 0xff, // i, 11-bit: 0x0ff
            0x09, 0x7f, // i, 11-bit: 0x07f
        },
    };
    try std.testing.expectEqual(Arg{ .u = 3 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .x = 1 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .y = 2 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg.nil, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .a = 1 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .f = 5 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .u = 0x110 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .i = 0xff }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .i = 0x7f }, try arg(ar, &r));
}

test "compact terms: multi-byte values, signed and unsigned" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // 0x19: tag i, bits 3 and 4 set, n = (0x19 >> 5) + 2 = 2 bytes; 0x18 the same for u.
    var r: Reader = .{ .bytes = &.{ 0x19, 0xff, 0xfe, 0x18, 0x01, 0x00 } };
    try std.testing.expectEqual(Arg{ .i = -2 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .u = 256 }, try arg(ar, &r));
}

test "extended terms: a literal and a register list" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    var r: Reader = .{ .bytes = &.{ 0x47, 0x00, 0x17, 0x20, 0x04, 0x14 } };
    try std.testing.expectEqual(Arg{ .literal = 0 }, try arg(ar, &r));
    const l = try arg(ar, &r);
    try std.testing.expectEqual(@as(usize, 2), l.list.len);
    try std.testing.expectEqual(Arg{ .y = 0 }, l.list[0]);
    try std.testing.expectEqual(Arg{ .y = 1 }, l.list[1]);
}

test "decode: an opcode outside the subset stops the stream, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    // label 1, then `call` (4).
    const d = try decode(arena_state.allocator(), &.{ 1, 0x10, 4, 0x10, 0x15 });
    try std.testing.expectEqual(@as(usize, 1), d.instrs.len);
    try std.testing.expectEqual(@as(?u8, 4), d.unknown);
}
