//! The `Code` chunk's instruction stream: opcodes (OTP's `genop.tab`
//! numbering) and their operands in the compact term encoding.
//!
//! Every opcode of `genop.tab` is decoded — its operand count is the table's
//! (`genop`) — so a module reads whole whatever it holds; which of them the
//! lowering converts is `lower.zig`'s business, and an opcode it does not is
//! refused in the function that holds it, named (decision 438). A number
//! outside the table stops the decoding: nothing after it can be read.
const std = @import("std");

pub const Error = error{ OutOfMemory, BadBeam };

/// Every opcode of OTP's `genop.tab` (OTP 28: 1–184), by number: its name
/// and operand count. The decoder reads every one — an opcode the lowering
/// does not convert is refused in the function that holds it, by name.
pub const genop = [_]struct { []const u8, u8 }{
    .{ "label", 1 },
    .{ "func_info", 3 },
    .{ "int_code_end", 0 },
    .{ "call", 2 },
    .{ "call_last", 3 },
    .{ "call_only", 2 },
    .{ "call_ext", 2 },
    .{ "call_ext_last", 3 },
    .{ "bif0", 2 },
    .{ "bif1", 4 },
    .{ "bif2", 5 },
    .{ "allocate", 2 },
    .{ "allocate_heap", 3 },
    .{ "allocate_zero", 2 },
    .{ "allocate_heap_zero", 3 },
    .{ "test_heap", 2 },
    .{ "init", 1 },
    .{ "deallocate", 1 },
    .{ "return", 0 },
    .{ "send", 0 },
    .{ "remove_message", 0 },
    .{ "timeout", 0 },
    .{ "loop_rec", 2 },
    .{ "loop_rec_end", 1 },
    .{ "wait", 1 },
    .{ "wait_timeout", 2 },
    .{ "m_plus", 4 },
    .{ "m_minus", 4 },
    .{ "m_times", 4 },
    .{ "m_div", 4 },
    .{ "int_div", 4 },
    .{ "int_rem", 4 },
    .{ "int_band", 4 },
    .{ "int_bor", 4 },
    .{ "int_bxor", 4 },
    .{ "int_bsl", 4 },
    .{ "int_bsr", 4 },
    .{ "int_bnot", 3 },
    .{ "is_lt", 3 },
    .{ "is_ge", 3 },
    .{ "is_eq", 3 },
    .{ "is_ne", 3 },
    .{ "is_eq_exact", 3 },
    .{ "is_ne_exact", 3 },
    .{ "is_integer", 2 },
    .{ "is_float", 2 },
    .{ "is_number", 2 },
    .{ "is_atom", 2 },
    .{ "is_pid", 2 },
    .{ "is_reference", 2 },
    .{ "is_port", 2 },
    .{ "is_nil", 2 },
    .{ "is_binary", 2 },
    .{ "is_constant", 2 },
    .{ "is_list", 2 },
    .{ "is_nonempty_list", 2 },
    .{ "is_tuple", 2 },
    .{ "test_arity", 3 },
    .{ "select_val", 3 },
    .{ "select_tuple_arity", 3 },
    .{ "jump", 1 },
    .{ "catch", 2 },
    .{ "catch_end", 1 },
    .{ "move", 2 },
    .{ "get_list", 3 },
    .{ "get_tuple_element", 3 },
    .{ "set_tuple_element", 3 },
    .{ "put_string", 3 },
    .{ "put_list", 3 },
    .{ "put_tuple", 2 },
    .{ "put", 1 },
    .{ "badmatch", 1 },
    .{ "if_end", 0 },
    .{ "case_end", 1 },
    .{ "call_fun", 1 },
    .{ "make_fun", 3 },
    .{ "is_function", 2 },
    .{ "call_ext_only", 2 },
    .{ "bs_start_match", 2 },
    .{ "bs_get_integer", 5 },
    .{ "bs_get_float", 5 },
    .{ "bs_get_binary", 5 },
    .{ "bs_skip_bits", 4 },
    .{ "bs_test_tail", 2 },
    .{ "bs_save", 1 },
    .{ "bs_restore", 1 },
    .{ "bs_init", 2 },
    .{ "bs_final", 2 },
    .{ "bs_put_integer", 5 },
    .{ "bs_put_binary", 5 },
    .{ "bs_put_float", 5 },
    .{ "bs_put_string", 2 },
    .{ "bs_need_buf", 1 },
    .{ "fclearerror", 0 },
    .{ "fcheckerror", 1 },
    .{ "fmove", 2 },
    .{ "fconv", 2 },
    .{ "fadd", 4 },
    .{ "fsub", 4 },
    .{ "fmul", 4 },
    .{ "fdiv", 4 },
    .{ "fnegate", 3 },
    .{ "make_fun2", 1 },
    .{ "try", 2 },
    .{ "try_end", 1 },
    .{ "try_case", 1 },
    .{ "try_case_end", 1 },
    .{ "raise", 2 },
    .{ "bs_init2", 6 },
    .{ "bs_bits_to_bytes", 3 },
    .{ "bs_add", 5 },
    .{ "apply", 1 },
    .{ "apply_last", 2 },
    .{ "is_boolean", 2 },
    .{ "is_function2", 3 },
    .{ "bs_start_match2", 5 },
    .{ "bs_get_integer2", 7 },
    .{ "bs_get_float2", 7 },
    .{ "bs_get_binary2", 7 },
    .{ "bs_skip_bits2", 5 },
    .{ "bs_test_tail2", 3 },
    .{ "bs_save2", 2 },
    .{ "bs_restore2", 2 },
    .{ "gc_bif1", 5 },
    .{ "gc_bif2", 6 },
    .{ "bs_final2", 2 },
    .{ "bs_bits_to_bytes2", 2 },
    .{ "put_literal", 2 },
    .{ "is_bitstr", 2 },
    .{ "bs_context_to_binary", 1 },
    .{ "bs_test_unit", 3 },
    .{ "bs_match_string", 4 },
    .{ "bs_init_writable", 0 },
    .{ "bs_append", 8 },
    .{ "bs_private_append", 6 },
    .{ "trim", 2 },
    .{ "bs_init_bits", 6 },
    .{ "bs_get_utf8", 5 },
    .{ "bs_skip_utf8", 4 },
    .{ "bs_get_utf16", 5 },
    .{ "bs_skip_utf16", 4 },
    .{ "bs_get_utf32", 5 },
    .{ "bs_skip_utf32", 4 },
    .{ "bs_utf8_size", 3 },
    .{ "bs_put_utf8", 3 },
    .{ "bs_utf16_size", 3 },
    .{ "bs_put_utf16", 3 },
    .{ "bs_put_utf32", 3 },
    .{ "on_load", 0 },
    .{ "recv_mark", 1 },
    .{ "recv_set", 1 },
    .{ "gc_bif3", 7 },
    .{ "line", 1 },
    .{ "put_map_assoc", 5 },
    .{ "put_map_exact", 5 },
    .{ "is_map", 2 },
    .{ "has_map_fields", 3 },
    .{ "get_map_elements", 3 },
    .{ "is_tagged_tuple", 4 },
    .{ "build_stacktrace", 0 },
    .{ "raw_raise", 0 },
    .{ "get_hd", 2 },
    .{ "get_tl", 2 },
    .{ "put_tuple2", 2 },
    .{ "bs_get_tail", 3 },
    .{ "bs_start_match3", 4 },
    .{ "bs_get_position", 3 },
    .{ "bs_set_position", 2 },
    .{ "swap", 2 },
    .{ "bs_start_match4", 4 },
    .{ "make_fun3", 3 },
    .{ "init_yregs", 1 },
    .{ "recv_marker_bind", 2 },
    .{ "recv_marker_clear", 1 },
    .{ "recv_marker_reserve", 1 },
    .{ "recv_marker_use", 1 },
    .{ "bs_create_bin", 6 },
    .{ "call_fun2", 3 },
    .{ "nif_start", 0 },
    .{ "badrecord", 1 },
    .{ "update_record", 5 },
    .{ "bs_match", 3 },
    .{ "executable_line", 2 },
    .{ "debug_line", 4 },
};

/// The opcodes the lowering names; any other number of `genop` is decoded
/// and refused by name where it is met.
pub const Op = enum(u8) {
    label = 1,
    func_info = 2,
    int_code_end = 3,
    call = 4,
    call_last = 5,
    call_only = 6,
    call_ext = 7,
    call_ext_last = 8,
    bif0 = 9,
    bif1 = 10,
    bif2 = 11,
    allocate = 12,
    allocate_heap = 13,
    allocate_zero = 14,
    allocate_heap_zero = 15,
    test_heap = 16,
    init = 17,
    deallocate = 18,
    @"return" = 19,
    is_lt = 39,
    is_ge = 40,
    is_eq = 41,
    is_ne = 42,
    is_eq_exact = 43,
    is_ne_exact = 44,
    is_integer = 45,
    is_float = 46,
    is_number = 47,
    is_atom = 48,
    is_nil = 52,
    is_binary = 53,
    is_list = 55,
    is_nonempty_list = 56,
    is_tuple = 57,
    test_arity = 58,
    select_val = 59,
    select_tuple_arity = 60,
    jump = 61,
    move = 64,
    get_list = 65,
    get_tuple_element = 66,
    put_list = 69,
    badmatch = 72,
    if_end = 73,
    case_end = 74,
    is_function = 77,
    call_ext_only = 78,
    is_boolean = 114,
    gc_bif1 = 124,
    gc_bif2 = 125,
    gc_bif3 = 152,
    line = 153,
    is_map = 156,
    is_tagged_tuple = 159,
    get_hd = 162,
    get_tl = 163,
    put_tuple2 = 164,
    swap = 169,
    init_yregs = 172,
    bs_create_bin = 177,
    executable_line = 183,
    _,
};

/// The name of opcode `op` (`genop`), or `?` outside the table.
pub fn opName(op: u8) []const u8 {
    if (op == 0 or op > genop.len) return "?";
    return genop[op - 1][0];
}

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
    /// `{list, [...]}` (`init_yregs`' register list, `select_val`'s pairs,
    /// `bs_create_bin`'s segments).
    list: []const Arg,
    /// `{fr, N}` — a float register.
    fr: u32,
    /// `{alloc, [{words, W}, {floats, F}, {funs, N}]}` — `test_heap`'s and
    /// `allocate_heap`'s need, by kind (a plain `u` need is words alone).
    alloc: Alloc,
};

/// A heap need by kind, as `{alloc, …}` lists it.
pub const Alloc = struct { words: u32 = 0, floats: u32 = 0, funs: u32 = 0 };

pub const Instr = struct { op: Op, args: []const Arg };

pub const Decoded = struct {
    instrs: []const Instr,
    /// A number outside `genop`, when the stream holds one: decoding stopped
    /// there.
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

/// A `u` term read as a count or an index.
fn count(r: *Reader) Error!usize {
    const nb = try r.byte();
    if (nb & 7 != 0) return error.BadBeam;
    const n = try value(r, nb, false);
    if (n < 0 or n > r.bytes.len) return error.BadBeam;
    return @intCast(n);
}

fn arg(arena: std.mem.Allocator, r: *Reader) Error!Arg {
    const b = try r.byte();
    const tag = b & 7;
    if (tag == 7) {
        // Extended: the sub-tag in the high nibble.
        switch (b >> 4) {
            1 => { // {list, …}: a `u` count, then that many terms
                const n = try count(r);
                const items = try arena.alloc(Arg, n);
                for (items) |*it| it.* = try arg(arena, r);
                return .{ .list = items };
            },
            2 => return .{ .fr = std.math.cast(u32, try count(r)) orelse return error.BadBeam }, // {fr, N}
            3 => { // {alloc, [{Kind, N}…]}: a `u` count of `u` pairs (kind 0 words, 1 floats, 2 funs)
                const n = try count(r);
                var need: Alloc = .{};
                for (0..n) |_| {
                    const kind = try count(r);
                    const k = std.math.cast(u32, try count(r)) orelse return error.BadBeam;
                    switch (kind) {
                        0 => need.words += k,
                        1 => need.floats += k,
                        2 => need.funs += k,
                        else => return error.BadBeam,
                    }
                }
                return .{ .alloc = need };
            },
            4 => return .{ .literal = std.math.cast(u32, try count(r)) orelse return error.BadBeam }, // {literal, N}
            5 => { // {tr, Reg, Type}: a register and its type's index in `Type`
                const reg = try arg(arena, r);
                if (reg != .x and reg != .y) return error.BadBeam;
                _ = try count(r);
                return reg;
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

/// Decode `code` up to `int_code_end`, or up to a number outside `genop`.
pub fn decode(arena: std.mem.Allocator, code: []const u8) Error!Decoded {
    var r: Reader = .{ .bytes = code };
    var out: std.ArrayListUnmanaged(Instr) = .empty;
    while (r.at < code.len) {
        const n = try r.byte();
        if (n == 0 or n > genop.len) return .{ .instrs = out.items, .unknown = n };
        const args = try arena.alloc(Arg, genop[n - 1][1]);
        for (args) |*a| a.* = try arg(arena, &r);
        const op: Op = @enumFromInt(n);
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

test "decode: every genop opcode reads; a number outside the table stops the stream" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // label 1, `call` 1 {f,2} (decoded, though not one the stream above held before), then 200.
    const d = try decode(ar, &.{ 1, 0x10, 4, 0x10, 0x25, 200 });
    try std.testing.expectEqual(@as(usize, 2), d.instrs.len);
    try std.testing.expectEqual(Op.call, d.instrs[1].op);
    try std.testing.expectEqual(Arg{ .f = 2 }, d.instrs[1].args[1]);
    try std.testing.expectEqual(@as(?u8, 200), d.unknown);
    // `send` (20) is no opcode the lowering names; it decodes all the same.
    const s = try decode(ar, &.{ 20, 3 });
    try std.testing.expectEqual(@as(u8, 20), @intFromEnum(s.instrs[0].op));
    try std.testing.expectEqualStrings("send", opName(20));
    try std.testing.expectEqualStrings("bs_create_bin", opName(177));
}

test "extended terms: a typed register, a float register, an allocation list" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // {tr, {x,1}, type 0}; {fr, 2}; {alloc, [{words, 3}]}.
    var r: Reader = .{ .bytes = &.{ 0x57, 0x13, 0x00, 0x27, 0x20, 0x37, 0x10, 0x00, 0x30 } };
    try std.testing.expectEqual(Arg{ .x = 1 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .fr = 2 }, try arg(ar, &r));
    try std.testing.expectEqual(Arg{ .alloc = .{ .words = 3 } }, try arg(ar, &r));
    // {alloc, [{words, 3}, {floats, 2}, {funs, 1}]}.
    r = .{ .bytes = &.{ 0x37, 0x30, 0x00, 0x30, 0x10, 0x20, 0x20, 0x10 } };
    try std.testing.expectEqual(Arg{ .alloc = .{ .words = 3, .floats = 2, .funs = 1 } }, try arg(ar, &r));
}

test "genop: the table is OTP's numbering" {
    try std.testing.expectEqual(@as(usize, 184), genop.len);
    try std.testing.expectEqualStrings("label", genop[0][0]);
    try std.testing.expectEqual(@as(u8, 6), genop[@intFromEnum(Op.bs_create_bin) - 1][1]);
    try std.testing.expectEqualStrings("init_yregs", genop[@intFromEnum(Op.init_yregs) - 1][0]);
    inline for (@typeInfo(Op).@"enum".fields) |f| {
        try std.testing.expectEqualStrings(f.name, genop[f.value - 1][0]);
    }
}
