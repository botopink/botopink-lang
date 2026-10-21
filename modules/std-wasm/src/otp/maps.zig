//! `maps:` over terms (decision 450): `{badkey, K}` and `{badmap, M}` as the
//! BEAM raises them.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── maps: BIFs ───────────────────────────────────────────────────────────────

pub fn rt_maps_get(k: T, m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const i = term.mapFind(mm, k) orelse {
        term.raiseError(term.tuple(&.{ term.a_badkey, k }));
        return &term.nil_cell;
    };
    return mm.vals[i];
}

pub fn rt_maps_get3(k: T, m: T, default: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const i = term.mapFind(mm, k) orelse return default;
    return mm.vals[i];
}

pub fn rt_maps_find(k: T, m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const i = term.mapFind(mm, k) orelse return term.atomOf("error");
    return term.tuple(&.{ term.a_ok, mm.vals[i] });
}

pub fn rt_maps_is_key(k: T, m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    return term.boolAtom(term.mapFind(term.as(term.Map, m), k) != null);
}

pub fn rt_maps_put(k: T, v: T, m: T) callconv(.c) term.T {
    return term.rt_map_put(m, k, v);
}

pub fn rt_maps_remove(k: T, m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const i = term.mapFind(mm, k) orelse return m;
    const out = term.mkMap(mm.count - 1);
    var j: usize = 0;
    for (0..mm.count) |x| {
        if (x == i) continue;
        out.keys[j] = mm.keys[x];
        out.vals[j] = mm.vals[x];
        j += 1;
    }
    return @ptrCast(out);
}

pub fn rt_maps_keys(m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    return term.listFrom(mm.keys[0..mm.count]);
}

pub fn rt_maps_values(m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    return term.listFrom(mm.vals[0..mm.count]);
}

pub fn rt_maps_size(m: T) callconv(.c) term.T {
    return erlang.rt_erlang_map_size(m);
}

pub fn rt_maps_to_list(m: T) callconv(.c) term.T {
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const out = term.allocTerms(mm.count);
    for (0..mm.count) |i| out[i] = term.tuple(&.{ mm.keys[i], mm.vals[i] });
    return term.listFrom(out[0..mm.count]);
}

pub fn rt_maps_from_list(l: T) callconv(.c) term.T {
    const items = term.listArg(l) orelse return &term.nil_cell;
    var m: T = @ptrCast(term.mkMap(0));
    for (items) |it| {
        if (term.tagOf(it) != .tuple or term.as(term.Tuple, it).arity != 2) return term.badarg();
        m = term.mapPut(m, term.as(term.Tuple, it).items[0], term.as(term.Tuple, it).items[1]);
    }
    return m;
}

pub fn rt_maps_merge(a: T, b: T) callconv(.c) term.T {
    if (term.tagOf(a) != .map) return term.badmap(a);
    if (term.tagOf(b) != .map) return term.badmap(b);
    var m = a;
    const mb = term.as(term.Map, b);
    for (0..mb.count) |i| m = term.mapPut(m, mb.keys[i], mb.vals[i]);
    return m;
}

pub fn rt_maps_map(f: T, m: T) callconv(.c) term.T {
    if (!lists.funArg(f, 2)) return &term.nil_cell;
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    const out = term.mkMap(mm.count);
    for (0..mm.count) |i| {
        out.keys[i] = mm.keys[i];
        out.vals[i] = term.applyFun(f, &.{ mm.keys[i], mm.vals[i] });
        if (term.pending) return &term.nil_cell;
    }
    return @ptrCast(out);
}

pub fn rt_maps_fold(f: T, acc0: T, m: T) callconv(.c) term.T {
    if (!lists.funArg(f, 3)) return &term.nil_cell;
    if (term.tagOf(m) != .map) return term.badmap(m);
    const mm = term.as(term.Map, m);
    var acc = acc0;
    for (0..mm.count) |i| {
        acc = term.applyFun(f, &.{ mm.keys[i], mm.vals[i], acc });
        if (term.pending) return &term.nil_cell;
    }
    return acc;
}
