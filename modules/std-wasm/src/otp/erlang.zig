//! `erlang:` BIFs over terms (decision 450): tuples, lists, numbers and their
//! text, atoms, the type tests, `apply/2`, and the process dictionary
//! (`put/2`, `get/1`, `erase/1`). Raises with the BEAM's reasons.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── the process dictionary ───────────────────────────────────────────────────

/// The process dictionary, a list of `{K, V}` (set by `term.rt_reset`).
pub var pdict: T = undefined;

pub fn rt_erlang_put(k: T, v: T) callconv(.c) term.T {
    var old: T = term.a_undefined;
    var l: T = &term.nil_cell;
    var it = pdict;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const kv = term.as(term.Tuple, term.as(term.Cons, it).head);
        if (term.compare(kv.items[0], k, true) == 0) {
            old = kv.items[1];
        } else l = term.cons(term.as(term.Cons, it).head, l);
    }
    pdict = term.cons(term.tuple(&.{ k, v }), l);
    return old;
}

pub fn rt_erlang_get(k: T) callconv(.c) term.T {
    var it = pdict;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const kv = term.as(term.Tuple, term.as(term.Cons, it).head);
        if (term.compare(kv.items[0], k, true) == 0) return kv.items[1];
    }
    return term.a_undefined;
}

pub fn rt_erlang_erase(k: T) callconv(.c) term.T {
    var old: T = term.a_undefined;
    var l: T = &term.nil_cell;
    var it = pdict;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const kv = term.as(term.Tuple, term.as(term.Cons, it).head);
        if (term.compare(kv.items[0], k, true) == 0) {
            old = kv.items[1];
        } else l = term.cons(term.as(term.Cons, it).head, l);
    }
    pdict = l;
    return old;
}

// ── erlang: BIFs ─────────────────────────────────────────────────────────────

pub fn intArg(t: T) ?i64 {
    if (term.tagOf(t) != .int) {
        _ = term.badarg();
        return null;
    }
    return term.as(term.Int, t).value;
}

pub fn rt_erlang_element(n: T, t: T) callconv(.c) term.T {
    const i = intArg(n) orelse return &term.nil_cell;
    if (term.tagOf(t) != .tuple) return term.badarg();
    const tp = term.as(term.Tuple, t);
    if (i < 1 or i > tp.arity) return term.badarg();
    return tp.items[@intCast(i - 1)];
}

pub fn rt_erlang_setelement(n: T, t: T, v: T) callconv(.c) term.T {
    const i = intArg(n) orelse return &term.nil_cell;
    if (term.tagOf(t) != .tuple) return term.badarg();
    const tp = term.as(term.Tuple, t);
    if (i < 1 or i > tp.arity) return term.badarg();
    const out = term.mkTuple(tp.arity);
    for (0..tp.arity) |j| out.items[j] = tp.items[j];
    out.items[@intCast(i - 1)] = v;
    return @ptrCast(out);
}

pub fn rt_erlang_tuple_size(t: T) callconv(.c) term.T {
    if (term.tagOf(t) != .tuple) return term.badarg();
    return term.mkInt(term.as(term.Tuple, t).arity);
}

pub fn rt_erlang_tuple_to_list(t: T) callconv(.c) term.T {
    if (term.tagOf(t) != .tuple) return term.badarg();
    const tp = term.as(term.Tuple, t);
    return term.listFrom(tp.items[0..tp.arity]);
}

pub fn rt_erlang_list_to_tuple(l: T) callconv(.c) term.T {
    const items = term.listItems(l) orelse return term.badarg();
    return term.tuple(items);
}

pub fn rt_erlang_length(l: T) callconv(.c) term.T {
    const items = term.listItems(l) orelse return term.badarg();
    return term.mkInt(@intCast(items.len));
}

pub fn rt_erlang_hd(l: T) callconv(.c) term.T {
    if (term.tagOf(l) != .cons) return term.badarg();
    return term.as(term.Cons, l).head;
}

pub fn rt_erlang_tl(l: T) callconv(.c) term.T {
    if (term.tagOf(l) != .cons) return term.badarg();
    return term.as(term.Cons, l).tail;
}

pub fn rt_erlang_byte_size(b: T) callconv(.c) term.T {
    if (term.tagOf(b) != .binary) return term.badarg();
    return term.mkInt(term.as(term.Bin, b).len);
}

pub fn rt_erlang_map_size(m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    return term.mkInt(term.as(term.Map, m).count);
}

pub fn rt_erlang_abs(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => term.mkInt(if (term.as(term.Int, a).value < 0) -term.as(term.Int, a).value else term.as(term.Int, a).value),
        .float => term.mkFloat(@abs(term.as(term.Float, a).value)),
        else => term.badarg(),
    };
}

pub fn rt_erlang_max(a: T, b: T) callconv(.c) term.T {
    return if (term.compare(a, b, false) < 0) b else a;
}

pub fn rt_erlang_min(a: T, b: T) callconv(.c) term.T {
    return if (term.compare(a, b, false) > 0) b else a;
}

fn floatToInt(f: f64) term.T {
    if (!(f > -9.2e18 and f < 9.2e18)) {
        term.raiseWat("integer beyond 64 bits (a bignum)");
        return &term.nil_cell;
    }
    return term.mkInt(@intFromFloat(f));
}

pub fn rt_erlang_round(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => a,
        .float => floatToInt(@round(term.as(term.Float, a).value)),
        else => term.badarg(),
    };
}

pub fn rt_erlang_trunc(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => a,
        .float => floatToInt(@trunc(term.as(term.Float, a).value)),
        else => term.badarg(),
    };
}

pub fn rt_erlang_floor(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => a,
        .float => floatToInt(@floor(term.as(term.Float, a).value)),
        else => term.badarg(),
    };
}

pub fn rt_erlang_ceil(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => a,
        .float => floatToInt(@ceil(term.as(term.Float, a).value)),
        else => term.badarg(),
    };
}

pub fn rt_erlang_float(a: T) callconv(.c) term.T {
    return switch (term.tagOf(a)) {
        .int => term.mkFloat(@floatFromInt(term.as(term.Int, a).value)),
        .float => a,
        else => term.badarg(),
    };
}

pub fn intText(v: i64, buf: []u8) []const u8 {
    return buf[0..stdWasm.number.signedText(buf, v)];
}

pub fn rt_erlang_integer_to_binary(a: T) callconv(.c) term.T {
    const v = intArg(a) orelse return &term.nil_cell;
    var buf: [24]u8 = undefined;
    return term.binCopy(intText(v, &buf));
}

pub fn rt_erlang_integer_to_list(a: T) callconv(.c) term.T {
    const v = intArg(a) orelse return &term.nil_cell;
    var buf: [24]u8 = undefined;
    return charsOf(intText(v, &buf));
}

fn parseInteger(bytes: []const u8) ?i64 {
    if (bytes.len == 0) return null;
    return std.fmt.parseInt(i64, bytes, 10) catch null;
}

pub fn rt_erlang_binary_to_integer(b: T) callconv(.c) term.T {
    if (term.tagOf(b) != .binary) return term.badarg();
    const v = parseInteger(term.binBytes(b)) orelse return term.badarg();
    return term.mkInt(v);
}

pub fn rt_erlang_list_to_integer(l: T) callconv(.c) term.T {
    const bytes = charsToBytes(l) orelse return term.badarg();
    const v = parseInteger(bytes) orelse return term.badarg();
    return term.mkInt(v);
}

pub fn rt_erlang_atom_to_binary(a: T) callconv(.c) term.T {
    if (term.tagOf(a) != .atom) return term.badarg();
    return term.binOf(term.atomBytes(a));
}

pub fn rt_erlang_atom_to_binary2(a: T, _: T) callconv(.c) term.T {
    return rt_erlang_atom_to_binary(a);
}

pub fn rt_erlang_atom_to_list(a: T) callconv(.c) term.T {
    if (term.tagOf(a) != .atom) return term.badarg();
    return utf8Chars(term.atomBytes(a));
}

pub fn rt_erlang_binary_to_atom(b: T) callconv(.c) term.T {
    if (term.tagOf(b) != .binary) return term.badarg();
    const bytes = term.binBytes(b);
    return term.internAtom(bytes.ptr, bytes.len);
}

pub fn rt_erlang_binary_to_atom2(b: T, _: T) callconv(.c) term.T {
    return rt_erlang_binary_to_atom(b);
}

pub fn rt_erlang_list_to_atom(l: T) callconv(.c) term.T {
    const bytes = charsToUtf8(l) orelse return term.badarg();
    return term.internAtom(bytes.ptr, bytes.len);
}

/// A list of the bytes of `bytes` (a Latin-1 char list).
pub fn charsOf(bytes: []const u8) term.T {
    var l: T = &term.nil_cell;
    var i = bytes.len;
    while (i > 0) {
        i -= 1;
        l = term.cons(term.mkInt(bytes[i]), l);
    }
    return l;
}

/// The code points of UTF-8 `bytes` as a list (invalid bytes as themselves).
pub fn utf8Chars(bytes: []const u8) term.T {
    const tmp = term.allocTerms(bytes.len);
    var n: usize = 0;
    var i: usize = 0;
    while (i < bytes.len) {
        const len = std.unicode.utf8ByteSequenceLength(bytes[i]) catch 1;
        const cp: u21 = if (i + len <= bytes.len)
            std.unicode.utf8Decode(bytes[i..][0..len]) catch bytes[i]
        else
            bytes[i];
        tmp[n] = term.mkInt(cp);
        n += 1;
        i += if (i + len <= bytes.len) len else 1;
    }
    return term.listFrom(tmp[0..n]);
}

/// A flat list of integers 0..255 as bytes, or null.
fn charsToBytes(l: T) ?[]const u8 {
    const items = term.listItems(l) orelse return null;
    const out = term.alloc(items.len);
    for (items, 0..) |it, i| {
        if (term.tagOf(it) != .int) return null;
        const v = term.as(term.Int, it).value;
        if (v < 0 or v > 255) return null;
        out[i] = @intCast(v);
    }
    return out[0..items.len];
}

/// A flat list of code points as UTF-8, or null.
fn charsToUtf8(l: T) ?[]const u8 {
    var bb = term.rt_bb_new();
    var it = l;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const h = term.as(term.Cons, it).head;
        if (term.tagOf(h) != .int) return null;
        bb = term.rt_bb_utf8(bb, h);
        if (term.pending) return null;
    }
    if (term.tagOf(it) != .nil) return null;
    return term.binBytes(term.rt_bb_end(bb));
}

pub fn rt_erlang_binary_to_list(b: T) callconv(.c) term.T {
    if (term.tagOf(b) != .binary) return term.badarg();
    return charsOf(term.binBytes(b));
}

/// Flatten an iolist (bytes 0..255, binaries, nested lists) into `bb`.
pub fn ioFlatten(bb: T, t: T) bool {
    switch (term.tagOf(t)) {
        .binary => term.bbPush(bb, term.binBytes(t)),
        .nil => {},
        .cons => {
            var it = t;
            while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
                const h = term.as(term.Cons, it).head;
                if (term.tagOf(h) == .int) {
                    const v = term.as(term.Int, h).value;
                    if (v < 0 or v > 255) return false;
                    term.bbPush(bb, &.{@intCast(v)});
                } else if (!ioFlatten(bb, h)) return false;
            }
            if (term.tagOf(it) == .binary) {
                term.bbPush(bb, term.binBytes(it));
            } else if (term.tagOf(it) != .nil) return false;
        },
        else => return false,
    }
    return true;
}

pub fn rt_erlang_iolist_to_binary(t: T) callconv(.c) term.T {
    if (term.tagOf(t) == .binary) return t;
    const bb = term.rt_bb_new();
    if (!ioFlatten(bb, t)) return term.badarg();
    return term.rt_bb_end(bb);
}

pub fn rt_erlang_list_to_binary(t: T) callconv(.c) term.T {
    if (term.tagOf(t) != .cons and term.tagOf(t) != .nil) return term.badarg();
    return rt_erlang_iolist_to_binary(t);
}

pub fn rt_erlang_iolist_size(t: T) callconv(.c) term.T {
    const b = rt_erlang_iolist_to_binary(t);
    if (term.pending) return b;
    return term.mkInt(term.as(term.Bin, b).len);
}

pub fn rt_erlang_float_to_binary(f: T) callconv(.c) term.T {
    // `float_to_binary/1` is the 20-digit scientific form; the comptime
    // bodies only reach the `[short]` form (primitives' `toString`).
    _ = f;
    term.raiseWat("float_to_binary/1 (scientific form)");
    return &term.nil_cell;
}

pub fn rt_erlang_float_to_binary2(f: T, opts: T) callconv(.c) term.T {
    if (term.tagOf(f) != .float) return term.badarg();
    if (!(term.tagOf(opts) == .cons and term.as(term.Cons, opts).head == term.a_short and term.tagOf(term.as(term.Cons, opts).tail) == .nil)) {
        term.raiseWat("float_to_binary/2 with options other than [short]");
        return &term.nil_cell;
    }
    var buf: [64]u8 = undefined;
    return term.binCopy(term.shortFloat(term.as(term.Float, f).value, &buf));
}

pub fn rt_erlang_float_to_list2(f: T, opts: T) callconv(.c) term.T {
    const b = rt_erlang_float_to_binary2(f, opts);
    if (term.pending) return b;
    return charsOf(term.binBytes(b));
}

pub fn rt_erlang_is_atom(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .atom);
}
pub fn rt_erlang_is_binary(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .binary);
}
pub fn rt_erlang_is_integer(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .int);
}
pub fn rt_erlang_is_float(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .float);
}
pub fn rt_erlang_is_number(t: T) callconv(.c) term.T {
    return term.boolAtom(term.isNum(t));
}
pub fn rt_erlang_is_list(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .cons or term.tagOf(t) == .nil);
}
pub fn rt_erlang_is_tuple(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .tuple);
}
pub fn rt_erlang_is_map(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .map);
}
pub fn rt_erlang_is_function(t: T) callconv(.c) term.T {
    return term.boolAtom(term.tagOf(t) == .fun);
}
/// `fun_info(F, arity)` — `{arity, N}`: what `'__bp_show'/2` reads to print a
/// function value `fn/<N>` (decision 1051). Any other item is `badarg`.
pub fn rt_erlang_fun_info2(f: T, item: T) callconv(.c) term.T {
    if (term.tagOf(f) != .fun or item != term.atomOf("arity")) return term.badarg();
    return term.tuple(&.{ item, term.mkInt(term.as(term.Fun, f).arity) });
}
pub fn rt_erlang_is_boolean(t: T) callconv(.c) term.T {
    return term.boolAtom(t == term.a_true or t == term.a_false);
}

/// `apply(F, Args)`.
pub fn rt_erlang_apply(f: T, args: T) callconv(.c) term.T {
    const items = term.listItems(args) orelse return term.badarg();
    return term.applyFun(f, items);
}
