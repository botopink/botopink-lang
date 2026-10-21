//! `binary:` over binaries (decision 450); `replace` and `split` answer through
//! `text.zig` (`replacedLength` / `replaceInto`, `Split`).
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── binary: and unicode: ─────────────────────────────────────────────────────

fn binArg(t: T) ?[]const u8 {
    if (term.tagOf(t) != .binary) {
        _ = term.badarg();
        return null;
    }
    return term.binBytes(t);
}

pub fn rt_binary_part(b: T, p: T, l: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pos = erlang.intArg(p) orelse return &term.nil_cell;
    const len = erlang.intArg(l) orelse return &term.nil_cell;
    const a = if (len < 0) pos + len else pos;
    const z = if (len < 0) pos else pos + len;
    if (a < 0 or z > s.len or a > z) return term.badarg();
    return term.binOf(s[@intCast(a)..@intCast(z)]);
}

pub fn rt_binary_first(b: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    if (s.len == 0) return term.badarg();
    return term.mkInt(s[0]);
}

pub fn rt_binary_last(b: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    if (s.len == 0) return term.badarg();
    return term.mkInt(s[s.len - 1]);
}

pub fn rt_binary_at(b: T, p: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const i = erlang.intArg(p) orelse return &term.nil_cell;
    if (i < 0 or i >= s.len) return term.badarg();
    return term.mkInt(s[@intCast(i)]);
}

pub fn rt_binary_copy(b: T, n: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const k = erlang.intArg(n) orelse return &term.nil_cell;
    if (k < 0) return term.badarg();
    const count: usize = @intCast(k);
    const out = term.alloc(s.len * count);
    for (0..count) |i| @memcpy(out[i * s.len ..][0..s.len], s);
    return term.mkBin(out, s.len * count);
}

pub fn rt_binary_match(b: T, p: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pat = binArg(p) orelse return &term.nil_cell;
    if (pat.len == 0) return term.badarg();
    const i = std.mem.indexOf(u8, s, pat) orelse return term.a_nomatch;
    return term.tuple(&.{ term.mkInt(@intCast(i)), term.mkInt(@intCast(pat.len)) });
}

fn replaceBytes(s: []const u8, pat: []const u8, rep: []const u8, all: bool) term.T {
    const n = stdWasm.text.replacedLength(s, pat, rep, all);
    const out = term.alloc(n);
    stdWasm.text.replaceInto(out[0..n], s, pat, rep, all);
    return term.mkBin(out, n);
}

pub fn rt_binary_replace3(b: T, p: T, r: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pat = binArg(p) orelse return &term.nil_cell;
    const rep = binArg(r) orelse return &term.nil_cell;
    if (pat.len == 0) return term.badarg();
    return replaceBytes(s, pat, rep, false);
}

pub fn rt_binary_replace4(b: T, p: T, r: T, opts: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pat = binArg(p) orelse return &term.nil_cell;
    const rep = binArg(r) orelse return &term.nil_cell;
    if (pat.len == 0) return term.badarg();
    const items = term.listArg(opts) orelse return &term.nil_cell;
    var all = false;
    for (items) |o| {
        if (o == term.a_global) all = true else {
            term.raiseWat("binary:replace/4 with options other than [global]");
            return &term.nil_cell;
        }
    }
    return replaceBytes(s, pat, rep, all);
}

pub fn rt_binary_split2(b: T, p: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pat = binArg(p) orelse return &term.nil_cell;
    if (pat.len == 0) return term.badarg();
    const i = std.mem.indexOf(u8, s, pat) orelse return term.listFrom(&.{b});
    return term.listFrom(&.{ term.binOf(s[0..i]), term.binOf(s[i + pat.len ..]) });
}

pub fn rt_binary_split3(b: T, p: T, opts: T) callconv(.c) term.T {
    const s = binArg(b) orelse return &term.nil_cell;
    const pat = binArg(p) orelse return &term.nil_cell;
    if (pat.len == 0) return term.badarg();
    const items = term.listArg(opts) orelse return &term.nil_cell;
    var all = false;
    for (items) |o| {
        if (o == term.a_global) all = true else {
            term.raiseWat("binary:split/3 with options other than [global]");
            return &term.nil_cell;
        }
    }
    var parts: term.Terms = .{};
    var it = if (all) stdWasm.text.Split.init(s, pat) else stdWasm.text.Split.once(s, pat);
    while (it.next()) |piece| parts.append(term.binOf(piece));
    return term.listFrom(parts.items);
}
