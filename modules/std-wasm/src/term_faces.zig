//! Each `exports` entry's comptime face over Erlang terms (decision 454 (1)):
//! `rt_std_<symbol>`, what a comptime module's `bp_std_wasm:<symbol>(…)` call
//! reaches. A `string` crosses as a binary, a `string[]` as a list of
//! binaries, a `bool` as its atom, a `?string` as the binary or `undefined`.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("root.zig");
const term = @import("term.zig");
const erlang = @import("otp/erlang.zig");
const lists = @import("otp/lists.zig");
const maps = @import("otp/maps.zig");
const string = @import("otp/string.zig");
const binary = @import("otp/binary.zig");
const unicode = @import("otp/unicode.zig");
const math = @import("otp/math.zig");
const io_lib = @import("otp/io_lib.zig");
const json = @import("otp/json.zig");
const etf = @import("otp/etf.zig");
const T = term.T;

// ── the functions std-wasm implements (`stdWasm.exports`) ───────────────────
// One export per entry, `rt_std_<symbol>`: a comptime module's call
// `bp_std_wasm:<symbol>(…)` — what `host_cells.forRuntime` makes of a host
// function whose `@External.Wasm(std: "<module>.<function>")` cell names the
// entry (decision 440 (3)) — lowers to it (`lower.zig`). A `string` crosses
// as a binary, an `f64` as a float.

pub fn rt_std_hash__contentHash(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    var buf: [8]u8 = undefined;
    const h = stdWasm.hash.contentHash(&buf, s) catch return term.badarg();
    return term.binCopy(h);
}

pub fn rt_std_text__trim(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.trim(s, .both));
}

pub fn rt_std_text__trimStart(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.trim(s, .leading));
}

pub fn rt_std_text__trimEnd(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.trim(s, .trailing));
}

pub fn rt_std_number__floatToString(f: T) callconv(.c) term.T {
    if (term.tagOf(f) != .float) return term.badarg();
    var buf: [64]u8 = undefined;
    return term.binCopy(term.shortFloat(term.as(term.Float, f).value, &buf));
}

// `String`'s methods std-wasm implements (decision 442 (2)): a `string[]`
// crosses as a list of binaries, a `bool` as its atom, a `?string` as the
// binary or `undefined`. A comptime module's primitive method calls its
// `@External.Erlang` cell; these answer a host function whose `std:` cell
// names them.

fn intArgI32(t: T) ?i32 {
    const v = erlang.intArg(t) orelse return null;
    return std.math.cast(i32, v) orelse {
        _ = term.badarg();
        return null;
    };
}

fn piecesList(it0: anytype) term.T {
    var it = it0;
    var n: usize = 0;
    while (it.next()) |_| n += 1;
    const items = term.allocTerms(n);
    it = it0;
    for (items[0..n]) |*x| x.* = term.binCopy(it.next().?);
    return term.listFrom(items[0..n]);
}

pub fn rt_std_text__length(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.mkInt(@intCast(stdWasm.text.cpLength(s)));
}

pub fn rt_std_text__split(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const sep = string.strArg(p) orelse return &term.nil_cell;
    return piecesList(stdWasm.text.Split.init(s, sep));
}

pub fn rt_std_text__chars(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return piecesList(stdWasm.text.Split.init(s, ""));
}

pub fn rt_std_text__lines(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return piecesList(stdWasm.text.Lines{ .s = s });
}

pub fn rt_std_text__words(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return piecesList(stdWasm.text.Words{ .s = s });
}

pub fn rt_std_text__contains(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const x = string.strArg(p) orelse return &term.nil_cell;
    return term.boolAtom(stdWasm.text.find(s, x) != null);
}

pub fn rt_std_text__startsWith(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const x = string.strArg(p) orelse return &term.nil_cell;
    return term.boolAtom(stdWasm.text.startsWith(s, x));
}

pub fn rt_std_text__endsWith(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const x = string.strArg(p) orelse return &term.nil_cell;
    return term.boolAtom(stdWasm.text.endsWith(s, x));
}

pub fn rt_std_text__indexOf(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const x = string.strArg(p) orelse return &term.nil_cell;
    return term.mkInt(stdWasm.text.indexOf(s, x));
}

pub fn rt_std_text__lastIndexOf(t: T, p: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const x = string.strArg(p) orelse return &term.nil_cell;
    return term.mkInt(stdWasm.text.lastIndexOf(s, x));
}

pub fn rt_std_text__at(t: T, i: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const k = intArgI32(i) orelse return &term.nil_cell;
    return if (stdWasm.text.cpAt(s, k)) |c| term.binCopy(c) else term.a_undefined;
}

pub fn rt_std_text__charCodeAt(t: T, i: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const k = intArgI32(i) orelse return &term.nil_cell;
    return term.mkInt(stdWasm.text.charCodeAt(s, k));
}

pub fn rt_std_text__byteLength(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.mkInt(@intCast(s.len));
}

pub fn rt_std_text__byteAt(t: T, i: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const k = intArgI32(i) orelse return &term.nil_cell;
    return term.mkInt(stdWasm.text.byteAt(s, k));
}

pub fn rt_std_text__byteSlice(t: T, a: T, b: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const from = intArgI32(a) orelse return &term.nil_cell;
    const to = intArgI32(b) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.byteSlice(s, from, to));
}

fn padTerm(t: T, w: T, p: T, start: bool) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const width = intArgI32(w) orelse return &term.nil_cell;
    const pad = string.strArg(p) orelse return &term.nil_cell;
    const n = stdWasm.text.padLength(s, width, pad);
    const out = term.alloc(n);
    stdWasm.text.padInto(out[0..n], s, pad, start);
    return term.binOf(out[0..n]);
}

pub fn rt_std_text__padStart(t: T, w: T, p: T) callconv(.c) term.T {
    return padTerm(t, w, p, true);
}

pub fn rt_std_text__padEnd(t: T, w: T, p: T) callconv(.c) term.T {
    return padTerm(t, w, p, false);
}

pub fn rt_std_text__repeat(t: T, k: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const times = intArgI32(k) orelse return &term.nil_cell;
    const n = stdWasm.text.repeatLength(s, times);
    const out = term.alloc(n);
    stdWasm.text.repeatInto(out[0..n], s);
    return term.binOf(out[0..n]);
}

fn replaceTerm(t: T, p: T, w: T, all: bool) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const pat = string.strArg(p) orelse return &term.nil_cell;
    const with = string.strArg(w) orelse return &term.nil_cell;
    const n = stdWasm.text.replacedLength(s, pat, with, all);
    const out = term.alloc(n);
    stdWasm.text.replaceInto(out[0..n], s, pat, with, all);
    return term.binOf(out[0..n]);
}

pub fn rt_std_text__replace(t: T, p: T, w: T) callconv(.c) term.T {
    return replaceTerm(t, p, w, false);
}

pub fn rt_std_text__replaceAll(t: T, p: T, w: T) callconv(.c) term.T {
    return replaceTerm(t, p, w, true);
}

pub fn rt_std_text__toUpper(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.binCopy(string.caseBytes(s, .upper, false));
}

pub fn rt_std_text__toLower(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.binCopy(string.caseBytes(s, .lower, false));
}

// `io/random`'s seeded stream (decision 451 (3)): a comptime evaluation
// starts from a fresh instance (`persistent_wat.zig`), so the stream is
// unseeded until the body seeds it, and one seed answers the same draws on
// every build. A draw before any seed is refused: a build has no entropy.
var random_stream: stdWasm.random.Stream = .{};

pub fn rt_std_random__seed(s: T) callconv(.c) term.T {
    const v = intArgI32(s) orelse return &term.nil_cell;
    random_stream.seed(v);
    return term.a_ok;
}

/// `random.float` is an unseeded draw (decision 456): at build it is refused
/// as `seededFloat` is before any seed, never `comptime-host-cell-unavailable`.
pub fn rt_std_random__float() callconv(.c) term.T {
    term.raiseWat("an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)");
    return &term.nil_cell;
}

pub fn rt_std_random__seededFloat() callconv(.c) term.T {
    const v = random_stream.next() orelse {
        term.raiseWat("an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)");
        return &term.nil_cell;
    };
    return term.mkFloat(v);
}

pub fn rt_std_text__fromCodepoint(c: T) callconv(.c) term.T {
    const cp = intArgI32(c) orelse return &term.nil_cell;
    var buf: [4]u8 = undefined;
    return term.binCopy(stdWasm.text.encodeCodepoint(&buf, cp) orelse return term.badarg());
}

// Decision 346 — `Bytes`' codecs: a `Bytes` crosses as a binary, a `?Bytes`
// as the binary or `undefined`.

pub fn rt_std_encoding__base64EncodeBytes(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const n = stdWasm.encoding.base64EncodedLength(s.len);
    const out = term.alloc(n);
    stdWasm.encoding.base64Encode(out[0..n], s);
    return term.binOf(out[0..n]);
}

pub fn rt_std_encoding__base64DecodeBytes(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const n = stdWasm.encoding.base64DecodedLength(s) orelse return term.a_undefined;
    const out = term.alloc(n);
    stdWasm.encoding.base64Decode(out[0..n], s);
    return term.binOf(out[0..n]);
}

pub fn rt_std_encoding__hexEncodeBytes(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const out = term.alloc(2 * s.len);
    stdWasm.encoding.hexEncode(out[0 .. 2 * s.len], s);
    return term.binOf(out[0 .. 2 * s.len]);
}

pub fn rt_std_encoding__hexDecodeBytes(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const n = stdWasm.encoding.hexDecodedLength(s) orelse return term.a_undefined;
    const out = term.alloc(n);
    stdWasm.encoding.hexDecode(out[0..n], s);
    return term.binOf(out[0..n]);
}

// `String.slice`'s and the string numerals' cells (`primitives.bp`): a `?i32`
// crosses as the integer or `undefined`, a `@Result` as `{ok, V}` /
// `{error, Bin}` — the erlang target's values.

pub fn rt_std_text__sliceFrom(t: T, a: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const start = intArgI32(a) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.cpSlice(s, start, std.math.maxInt(i32)));
}

pub fn rt_std_text__sliceBetween(t: T, a: T, e: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    const start = intArgI32(a) orelse return &term.nil_cell;
    const end: i32 = if (e == term.a_undefined) std.math.maxInt(i32) else intArgI32(e) orelse return &term.nil_cell;
    return term.binCopy(stdWasm.text.cpSlice(s, start, end));
}

pub fn rt_std_number__isDigits(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    return term.boolAtom(stdWasm.number.isDigits(s));
}

/// `a`, `b` and `c` one after the other, as a binary — three parameters, not
/// a slice of slices, which would be a relocation in the module's data.
fn joinBin(a: []const u8, b: []const u8, c: []const u8) term.T {
    const n = a.len + b.len + c.len;
    const out = term.alloc(n);
    @memcpy(out[0..a.len], a);
    @memcpy(out[a.len..][0..b.len], b);
    @memcpy(out[a.len + b.len ..][0..c.len], c);
    return term.binOf(out[0..n]);
}

pub fn rt_std_number__toInteger(t: T) callconv(.c) term.T {
    const s = string.strArg(t) orelse return &term.nil_cell;
    if (stdWasm.number.integerOf(s)) |v| return term.tuple(&.{ term.a_ok, term.mkInt(v) });
    return term.tuple(&.{ term.a_error, joinBin("parseInt: \"", s, "\" is out of range") });
}

pub fn rt_std_number__toFloat(t: T, w: T, f: T, x: T) callconv(.c) term.T {
    const text = string.strArg(t) orelse return &term.nil_cell;
    const whole = string.strArg(w) orelse return &term.nil_cell;
    const fraction = string.strArg(f) orelse return &term.nil_cell;
    const exponent = string.strArg(x) orelse return &term.nil_cell;
    const neg = text.len > 0 and text[0] == '-';
    if (stdWasm.number.floatOf(neg, whole, fraction, exponent)) |v| return term.tuple(&.{ term.a_ok, term.mkFloat(v) });
    return term.tuple(&.{ term.a_error, joinBin("parseFloat: \"", text, "\" overflows f64") });
}

pub fn rt_std_number__numeralRefused(b: T, t: T, a: T) callconv(.c) term.T {
    const before = string.strArg(b) orelse return &term.nil_cell;
    const text = string.strArg(t) orelse return &term.nil_cell;
    const after = string.strArg(a) orelse return &term.nil_cell;
    return term.tuple(&.{ term.a_error, joinBin(before, text, after) });
}

comptime {
    // Every function std-wasm implements has its export here, by name.
    for (stdWasm.exports) |e| {
        if (!@hasDecl(@This(), "rt_std_" ++ e.symbol())) @compileError("std-wasm implements " ++ e.name ++ " but term_faces.zig has no rt_std_" ++ e.symbol());
    }
}
