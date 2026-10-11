//! `lists:` over terms (decision 450). A function taking a fun calls it back
//! through the caller's table (`term.applyFun`).
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── lists ────────────────────────────────────────────────────────────────────

pub fn funArg(f: T, arity: u32) bool {
    if (term.tagOf(f) != .fun or term.as(term.Fun, f).arity != arity) {
        _ = term.badarg();
        return false;
    }
    return true;
}

pub fn rt_lists_map(f: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 1)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    const out = term.allocTerms(items.len);
    for (items, 0..) |it, i| {
        out[i] = term.applyFun(f, &.{it});
        if (term.pending) return &term.nil_cell;
    }
    return term.listFrom(out[0..items.len]);
}

pub fn rt_lists_foreach(f: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 1)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    for (items) |it| {
        _ = term.applyFun(f, &.{it});
        if (term.pending) return &term.nil_cell;
    }
    return term.a_ok;
}

pub fn rt_lists_filter(f: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 1)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    const out = term.allocTerms(items.len);
    var n: usize = 0;
    for (items) |it| {
        const keep = term.applyFun(f, &.{it});
        if (term.pending) return &term.nil_cell;
        switch (term.rt_truth(keep)) {
            1 => {
                out[n] = it;
                n += 1;
            },
            0 => {},
            else => return term.badarg(),
        }
    }
    return term.listFrom(out[0..n]);
}

pub fn rt_lists_foldl(f: T, acc0: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 2)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    var acc = acc0;
    for (items) |it| {
        acc = term.applyFun(f, &.{ it, acc });
        if (term.pending) return &term.nil_cell;
    }
    return acc;
}

pub fn rt_lists_foldr(f: T, acc0: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 2)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    var acc = acc0;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        acc = term.applyFun(f, &.{ items[i], acc });
        if (term.pending) return &term.nil_cell;
    }
    return acc;
}

pub fn rt_lists_any(f: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 1)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    for (items) |it| {
        const r = term.applyFun(f, &.{it});
        if (term.pending) return &term.nil_cell;
        switch (term.rt_truth(r)) {
            1 => return term.a_true,
            0 => {},
            else => return term.badarg(),
        }
    }
    return term.a_false;
}

pub fn rt_lists_all(f: T, l: T) callconv(.c) term.T {
    if (!funArg(f, 1)) return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    for (items) |it| {
        const r = term.applyFun(f, &.{it});
        if (term.pending) return &term.nil_cell;
        switch (term.rt_truth(r)) {
            0 => return term.a_false,
            1 => {},
            else => return term.badarg(),
        }
    }
    return term.a_true;
}

pub fn rt_lists_reverse(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    var out: T = &term.nil_cell;
    for (items) |it| out = term.cons(it, out);
    return out;
}

pub fn rt_lists_reverse2(l: T, tail: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    var out: T = tail;
    for (items) |it| out = term.cons(it, out);
    return out;
}

pub fn rt_lists_append2(a: T, b: T) callconv(.c) term.T {
    return term.rt_append(a, b);
}

pub fn rt_lists_append1(ls: T) callconv(.c) term.T {
    const items = term.listArg(ls) orelse return &term.nil_cell;
    var out: T = &term.nil_cell;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        out = term.rt_append(items[i], out);
        if (term.pending) return &term.nil_cell;
    }
    return out;
}

pub fn rt_lists_join(sep: T, l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    if (items.len == 0) return &term.nil_cell;
    const out = term.allocTerms(items.len * 2 - 1);
    for (items, 0..) |it, i| {
        if (i > 0) out[i * 2 - 1] = sep;
        out[i * 2] = it;
    }
    return term.listFrom(out[0 .. items.len * 2 - 1]);
}

pub fn rt_lists_member(x: T, l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    for (items) |it| if (term.compare(it, x, true) == 0) return term.a_true;
    return term.a_false;
}

pub fn rt_lists_nth(n: T, l: T) callconv(.c) term.T {
    const i = erlang.intArg(n) orelse return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    if (i < 1 or i > items.len) return term.rt_function_clause();
    return items[@intCast(i - 1)];
}

pub fn rt_lists_nthtail(n: T, l: T) callconv(.c) term.T {
    var i = erlang.intArg(n) orelse return &term.nil_cell;
    var it = l;
    while (i > 0) : (i -= 1) {
        if (term.tagOf(it) != .cons) return term.rt_function_clause();
        it = term.as(term.Cons, it).tail;
    }
    return it;
}

pub fn rt_lists_sublist2(l: T, n: T) callconv(.c) term.T {
    const len = erlang.intArg(n) orelse return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    if (len < 0) return term.rt_function_clause();
    const k: usize = @min(items.len, @as(usize, @intCast(len)));
    return term.listFrom(items[0..k]);
}

pub fn rt_lists_sublist3(l: T, s: T, n: T) callconv(.c) term.T {
    const start = erlang.intArg(s) orelse return &term.nil_cell;
    const len = erlang.intArg(n) orelse return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    if (start < 1 or len < 0) return term.rt_function_clause();
    const from: usize = @intCast(start - 1);
    if (from >= items.len) return &term.nil_cell;
    const k: usize = @min(items.len - from, @as(usize, @intCast(len)));
    return term.listFrom(items[from..][0..k]);
}

/// `lists:enumerate(Index, List)`: `[{Index, E1}, {Index + 1, E2}, …]`.
pub fn rt_lists_enumerate2(first: T, l: T) callconv(.c) term.T {
    const start = erlang.intArg(first) orelse return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    const out = term.allocTerms(items.len);
    for (items, 0..) |it, i| out[i] = term.tuple(&.{ term.mkInt(start + @as(i64, @intCast(i))), it });
    return term.listFrom(out[0..items.len]);
}

pub fn rt_lists_enumerate1(l: T) callconv(.c) term.T {
    return rt_lists_enumerate2(term.mkInt(1), l);
}

pub fn rt_lists_duplicate(n: T, x: T) callconv(.c) term.T {
    const k = erlang.intArg(n) orelse return &term.nil_cell;
    if (k < 0) return term.rt_function_clause();
    var out: T = &term.nil_cell;
    var i: i64 = 0;
    while (i < k) : (i += 1) out = term.cons(x, out);
    return out;
}

pub fn rt_lists_seq(a: T, b: T) callconv(.c) term.T {
    const from = erlang.intArg(a) orelse return &term.nil_cell;
    const to = erlang.intArg(b) orelse return &term.nil_cell;
    if (to < from - 1) return term.rt_function_clause();
    var out: T = &term.nil_cell;
    var i = to;
    while (i >= from) : (i -= 1) out = term.cons(term.mkInt(i), out);
    return out;
}

pub fn rt_lists_zipwith(f: T, a: T, b: T) callconv(.c) term.T {
    if (!funArg(f, 2)) return &term.nil_cell;
    const xs = term.listArg(a) orelse return &term.nil_cell;
    const ys = term.listArg(b) orelse return &term.nil_cell;
    if (xs.len != ys.len) return term.rt_function_clause();
    const out = term.allocTerms(xs.len);
    for (xs, ys, 0..) |x, y, i| {
        out[i] = term.applyFun(f, &.{ x, y });
        if (term.pending) return &term.nil_cell;
    }
    return term.listFrom(out[0..xs.len]);
}

pub fn rt_lists_last(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    if (items.len == 0) return term.rt_function_clause();
    return items[items.len - 1];
}

fn flattenInto(out: *term.Terms, l: T) bool {
    var it = l;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const h = term.as(term.Cons, it).head;
        if (term.tagOf(h) == .cons or term.tagOf(h) == .nil) {
            if (!flattenInto(out, h)) return false;
        } else out.append(h);
    }
    return term.tagOf(it) == .nil;
}

pub fn rt_lists_flatten(l: T) callconv(.c) term.T {
    var out: term.Terms = .{};
    if (!flattenInto(&out, l)) return term.badarg();
    return term.listFrom(out.items);
}

fn sortTerms(items: []term.T) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and term.compare(items[j - 1], items[j], false) > 0) : (j -= 1) {
            const tmp = items[j];
            items[j] = items[j - 1];
            items[j - 1] = tmp;
        }
    }
}

pub fn rt_lists_sort(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    const copy = term.allocTerms(items.len);
    @memcpy(copy[0..items.len], items);
    sortTerms(copy[0..items.len]);
    return term.listFrom(copy[0..items.len]);
}

pub fn rt_lists_usort(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    const copy = term.allocTerms(items.len);
    @memcpy(copy[0..items.len], items);
    sortTerms(copy[0..items.len]);
    var n: usize = 0;
    for (copy[0..items.len]) |it| {
        if (n > 0 and term.compare(copy[n - 1], it, true) == 0) continue;
        copy[n] = it;
        n += 1;
    }
    return term.listFrom(copy[0..n]);
}

pub fn rt_lists_keyfind(k: T, n: T, l: T) callconv(.c) term.T {
    const pos = erlang.intArg(n) orelse return &term.nil_cell;
    const items = term.listArg(l) orelse return &term.nil_cell;
    for (items) |it| {
        if (term.tagOf(it) != .tuple) continue;
        const tp = term.as(term.Tuple, it);
        if (pos >= 1 and pos <= tp.arity and term.compare(tp.items[@intCast(pos - 1)], k, false) == 0) return it;
    }
    return term.a_false;
}

pub fn rt_lists_concat(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    const bb = term.rt_bb_new();
    for (items) |it| {
        switch (term.tagOf(it)) {
            .atom => term.bbPush(bb, term.atomBytes(it)),
            .int => {
                var buf: [24]u8 = undefined;
                term.bbPush(bb, erlang.intText(term.as(term.Int, it).value, &buf));
            },
            .float => {
                var buf: [64]u8 = undefined;
                term.bbPush(bb, term.shortFloat(term.as(term.Float, it).value, &buf));
            },
            else => if (!erlang.ioFlatten(bb, it)) return term.badarg(),
        }
    }
    return erlang.utf8Chars(term.binBytes(term.rt_bb_end(bb)));
}
