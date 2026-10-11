//! `string:` over chardata (decision 450): a binary answers a binary, a list a
//! code-point list. The algorithms are `text.zig`'s, a program's faces' too.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── strings (unicode:chardata as binaries or code-point lists) ───────────────

/// The UTF-8 bytes of chardata `t` (a binary, or a list of code points and
/// binaries), or null.
pub fn chardata(t: T) ?[]const u8 {
    if (term.tagOf(t) == .binary) return term.binBytes(t);
    if (term.tagOf(t) != .cons and term.tagOf(t) != .nil) return null;
    const bb = term.rt_bb_new();
    if (!chardataInto(bb, t)) return null;
    return term.binBytes(term.rt_bb_end(bb));
}

fn chardataInto(bb: T, t: T) bool {
    var it = t;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const h = term.as(term.Cons, it).head;
        switch (term.tagOf(h)) {
            .int => {
                _ = term.rt_bb_utf8(bb, h);
                if (term.pending) return false;
            },
            .binary => term.bbPush(bb, term.binBytes(h)),
            .cons, .nil => if (!chardataInto(bb, h)) return false,
            else => return false,
        }
    }
    if (term.tagOf(it) == .binary) {
        term.bbPush(bb, term.binBytes(it));
        return true;
    }
    return term.tagOf(it) == .nil;
}

/// The result of a `string:` function whose input was `like`: a binary input
/// answers a binary, a list input a code-point list.
fn strResult(like: T, bytes: []const u8) term.T {
    if (term.tagOf(like) == .binary) return term.binOf(bytes);
    return erlang.utf8Chars(bytes);
}

pub fn strArg(t: T) ?[]const u8 {
    return chardata(t) orelse {
        term.raiseError(term.tuple(&.{ term.a_badarg, t }));
        return null;
    };
}

/// Grapheme boundaries of UTF-8 `s` (`stdWasm.text.graphemes`): `g[i]` is
/// the byte offset of the i-th, `g[n] = s.len`.
fn graphemes(s: []const u8) []usize {
    const out: [*]usize = @ptrCast(@alignCast(term.alloc((s.len + 1) * @sizeOf(usize))));
    return stdWasm.text.graphemes(out[0 .. s.len + 1], s);
}

pub fn rt_string_length(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    return term.mkInt(@intCast(graphemes(s).len - 1));
}

pub fn rt_string_is_empty(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    return term.boolAtom(s.len == 0);
}

/// `s` with its case mapped over all of Unicode — std-wasm's, OTP's answer
/// (decision 443: the full mappings, no final sigma).
pub fn caseBytes(s: []const u8, case: stdWasm.text.Case, first_only: bool) []const u8 {
    const n = stdWasm.text.caseLength(s, case, first_only);
    const out = term.alloc(n);
    stdWasm.text.caseInto(out[0..n], s, case, first_only);
    return out[0..n];
}

fn caseMap(t: T, case: stdWasm.text.Case) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    return strResult(t, caseBytes(s, case, false));
}

pub fn rt_string_uppercase(t: T) callconv(.c) term.T {
    return caseMap(t, .upper);
}

pub fn rt_string_lowercase(t: T) callconv(.c) term.T {
    return caseMap(t, .lower);
}

/// `string:titlecase/1` — the first character's title mapping, the rest as
/// it is (std-wasm's `text.caseInto`).
pub fn rt_string_titlecase(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    return strResult(t, caseBytes(s, .title, true));
}

fn trimBytes(s: []const u8, dir: T) []const u8 {
    return stdWasm.text.trim(s, if (dir == term.a_leading) .leading else if (dir == term.a_trailing) .trailing else .both);
}

pub fn rt_string_trim(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    return strResult(t, trimBytes(s, term.a_both));
}

pub fn rt_string_trim2(t: T, dir: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    if (dir != term.a_leading and dir != term.a_trailing and dir != term.a_both) return term.badarg();
    return strResult(t, trimBytes(s, dir));
}

pub fn rt_string_find(t: T, p: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const pat = strArg(p) orelse return &term.nil_cell;
    if (pat.len == 0) return t;
    const i = stdWasm.text.find(s, pat) orelse return term.a_nomatch;
    return strResult(t, s[i..]);
}

pub fn rt_string_prefix(t: T, p: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const pat = strArg(p) orelse return &term.nil_cell;
    if (!stdWasm.text.startsWith(s, pat)) return term.a_nomatch;
    return strResult(t, s[pat.len..]);
}

pub fn rt_string_equal(a: T, b: T) callconv(.c) term.T {
    const x = strArg(a) orelse return &term.nil_cell;
    const y = strArg(b) orelse return &term.nil_cell;
    return term.boolAtom(std.mem.eql(u8, x, y));
}

fn sliceBytes(s: []const u8, start: i64, len: ?i64) []const u8 {
    const from: usize = @intCast(@max(start, 0));
    const count: ?usize = if (len) |l| @intCast(@max(l, 0)) else null;
    return stdWasm.text.slice(s, graphemes(s), from, count);
}

pub fn rt_string_slice2(t: T, st: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const start = erlang.intArg(st) orelse return &term.nil_cell;
    if (start < 0) return term.badarg();
    return strResult(t, sliceBytes(s, start, null));
}

pub fn rt_string_slice3(t: T, st: T, ln: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const start = erlang.intArg(st) orelse return &term.nil_cell;
    const len = erlang.intArg(ln) orelse return &term.nil_cell;
    if (start < 0 or len < 0) return term.badarg();
    return strResult(t, sliceBytes(s, start, len));
}

/// `string:split(S, Sep)` / `string:split(S, Sep, all)`.
fn split(t: T, p: T, all: bool) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const sep = strArg(p) orelse return &term.nil_cell;
    if (sep.len == 0) return term.listFrom(&.{t});
    var parts: term.Terms = .{};
    var it = if (all) stdWasm.text.Split.init(s, sep) else stdWasm.text.Split.once(s, sep);
    while (it.next()) |piece| parts.append(strResult(t, piece));
    return term.listFrom(parts.items);
}

pub fn rt_string_split(t: T, p: T) callconv(.c) term.T {
    return split(t, p, false);
}

pub fn rt_string_split3(t: T, p: T, where: T) callconv(.c) term.T {
    if (where == term.a_all) return split(t, p, true);
    if (where == term.atomOf("leading")) return split(t, p, false);
    term.raiseWat("string:split/3 other than leading/all");
    return &term.nil_cell;
}

pub fn rt_string_replace(t: T, p: T, r: T) callconv(.c) term.T {
    // `string:replace/3` replaces the leading match and answers chardata
    // `[Before, Replacement, After]`.
    const s = strArg(t) orelse return &term.nil_cell;
    const pat = strArg(p) orelse return &term.nil_cell;
    const rep = strArg(r) orelse return &term.nil_cell;
    if (pat.len == 0) return term.listFrom(&.{t});
    const i = std.mem.indexOf(u8, s, pat) orelse return term.listFrom(&.{t});
    return term.listFrom(&.{ term.binOf(s[0..i]), term.binOf(rep), term.binOf(s[i + pat.len ..]) });
}

pub fn rt_string_reverse(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    const out = term.alloc(s.len);
    return strResult(t, stdWasm.text.reverse(out[0..s.len], s, graphemes(s)));
}

pub fn rt_string_to_integer(t: T) callconv(.c) term.T {
    const s = strArg(t) orelse return &term.nil_cell;
    var i: usize = 0;
    if (i < s.len and (s[i] == '-' or s[i] == '+')) i += 1;
    const d0 = i;
    while (i < s.len and std.ascii.isDigit(s[i])) i += 1;
    if (i == d0) return term.tuple(&.{ term.a_error, term.atomOf("no_integer") });
    const v = std.fmt.parseInt(i64, s[0..i], 10) catch return term.tuple(&.{ term.a_error, term.atomOf("no_integer") });
    return term.tuple(&.{ term.mkInt(v), strResult(t, s[i..]) });
}
