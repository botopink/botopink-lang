//! The external term format the comptime argument arrives in (`rt_etf_decode`,
//! `binary_to_term/1`): exactly the tags `compiler-core`'s `comptime/runtime/etf.zig`
//! writes.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const T = term.T;

// ── ETF (the argument) ───────────────────────────────────────────────────────

const Reader = struct {
    s: []const u8,
    i: usize = 0,
    fn u8_(r: *Reader) ?u8 {
        if (r.i >= r.s.len) return null;
        r.i += 1;
        return r.s[r.i - 1];
    }
    fn be(r: *Reader, comptime I: type) ?I {
        const n = @sizeOf(I);
        if (r.i + n > r.s.len) return null;
        const v = std.mem.readInt(I, r.s[r.i..][0..n], .big);
        r.i += n;
        return v;
    }
    fn bytes(r: *Reader, n: usize) ?[]const u8 {
        if (r.i + n > r.s.len) return null;
        r.i += n;
        return r.s[r.i - n .. r.i];
    }
};

fn etfTerm(r: *Reader) ?term.T {
    const tag = r.u8_() orelse return null;
    switch (tag) {
        97 => return term.mkInt(r.u8_() orelse return null), // SMALL_INTEGER
        98 => return term.mkInt(r.be(i32) orelse return null), // INTEGER
        110 => { // SMALL_BIG
            const n = r.u8_() orelse return null;
            const sign = r.u8_() orelse return null;
            const ds = r.bytes(n) orelse return null;
            if (n > 8) return null;
            var v: u64 = 0;
            var k: usize = n;
            while (k > 0) {
                k -= 1;
                v = (v << 8) | ds[k];
            }
            if (v > std.math.maxInt(i64)) return null;
            const iv: i64 = @intCast(v);
            return term.mkInt(if (sign == 1) -iv else iv);
        },
        70 => return term.mkFloat(@bitCast(r.be(u64) orelse return null)), // NEW_FLOAT
        106 => return &term.nil_cell, // NIL
        108 => { // LIST
            const n = r.be(u32) orelse return null;
            const items = term.allocTerms(n);
            for (0..n) |i| items[i] = etfTerm(r) orelse return null;
            var l = etfTerm(r) orelse return null;
            var i: usize = n;
            while (i > 0) {
                i -= 1;
                l = term.cons(items[i], l);
            }
            return l;
        },
        107 => { // STRING_EXT: a list of bytes
            const n = r.be(u16) orelse return null;
            return erlang.charsOf(r.bytes(n) orelse return null);
        },
        104 => { // SMALL_TUPLE
            const n = r.u8_() orelse return null;
            const t = term.mkTuple(n);
            for (0..n) |i| t.items[i] = etfTerm(r) orelse return null;
            return @ptrCast(t);
        },
        105 => { // LARGE_TUPLE
            const n = r.be(u32) orelse return null;
            const t = term.mkTuple(n);
            for (0..n) |i| t.items[i] = etfTerm(r) orelse return null;
            return @ptrCast(t);
        },
        116 => { // MAP
            const n = r.be(u32) orelse return null;
            var m: T = @ptrCast(term.mkMap(0));
            for (0..n) |_| {
                const k = etfTerm(r) orelse return null;
                const v = etfTerm(r) orelse return null;
                m = term.mapPut(m, k, v);
            }
            return m;
        },
        109 => { // BINARY
            const n = r.be(u32) orelse return null;
            return term.binOf(r.bytes(n) orelse return null);
        },
        118 => { // ATOM_UTF8
            const n = r.be(u16) orelse return null;
            const b = r.bytes(n) orelse return null;
            return term.internAtom(b.ptr, b.len);
        },
        119 => { // SMALL_ATOM_UTF8
            const n = r.u8_() orelse return null;
            const b = r.bytes(n) orelse return null;
            return term.internAtom(b.ptr, b.len);
        },
        else => return null,
    }
}

/// Decode `binary_to_term` bytes (the version byte 131 first). A tag
/// `etf.zig` does not write traps — the encoder and this decoder are a pair.
pub fn rt_etf_decode(ptr: [*]const u8, len: usize) callconv(.c) term.T {
    var r: Reader = .{ .s = ptr[0..len] };
    if ((r.u8_() orelse 0) != 131) @trap();
    return etfTerm(&r) orelse @trap();
}
