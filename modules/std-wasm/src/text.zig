//! The text algorithms behind std's string primitives (decision 434 (2)):
//! what `String.toUpper`, `trim`, `split`, `contains`, `startsWith`,
//! `replaceAll`, `length`, `slice` and `reverse` answer at comptime, whatever
//! the build's target (434 (5)). Pure functions over UTF-8 bytes — no term
//! layout, no allocation of their own: a caller hands the output buffer.
//! The wat comptime runtime's `string:` / `binary:` BIFs answer through them
//! (`compiler-core/src/comptime/runtime/wat/rt.zig`).
const std = @import("std");

pub const CaseError = error{NonAsciiLetter};

/// `s` with its ASCII letters mapped to upper (`upper`) or lower case, into
/// `out` (`out.len >= s.len`). A byte at or above 0x80 is
/// `error.NonAsciiLetter`: Unicode case mapping is the comptime runtime's
/// limit 3 (`runtime/wat/AGENTS.md`), refused rather than answered
/// differently from a target.
pub fn caseMap(out: []u8, s: []const u8, upper: bool) CaseError![]u8 {
    for (s) |c| if (c >= 0x80) return error.NonAsciiLetter;
    for (s, 0..) |c, i| out[i] = if (upper) std.ascii.toUpper(c) else std.ascii.toLower(c);
    return out[0..s.len];
}

/// `s` with its first character title-cased (`string:titlecase/1`), the rest
/// as it is, into `out` (`out.len >= s.len`). The first character is mapped
/// for ASCII only: a first byte at or above 0x80 is `error.NonAsciiLetter`,
/// as `caseMap` refuses it (the comptime runtime's limit 3) — the bytes after
/// it are never mapped, whatever they are.
pub fn titlecase(out: []u8, s: []const u8) CaseError![]u8 {
    if (s.len == 0) return out[0..0];
    if (s[0] >= 0x80) return error.NonAsciiLetter;
    @memcpy(out[0..s.len], s);
    out[0] = std.ascii.toUpper(s[0]);
    return out[0..s.len];
}

/// The whitespace `trim` removes: space, tab, LF, CR, VT, FF.
pub fn isWhite(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r' or c == 11 or c == 12;
}

pub const TrimDir = enum { leading, trailing, both };

/// `s` without its leading, trailing or both runs of `isWhite` bytes.
pub fn trim(s: []const u8, dir: TrimDir) []const u8 {
    var a: usize = 0;
    var b: usize = s.len;
    if (dir != .trailing) while (a < b and isWhite(s[a])) : (a += 1) {};
    if (dir != .leading) while (b > a and isWhite(s[b - 1])) : (b -= 1) {};
    return s[a..b];
}

/// The byte offset of each grapheme of UTF-8 `s` into `out`
/// (`out.len >= s.len + 1`): `out[i]` starts the i-th, the last entry is
/// `s.len`. A `\r\n` pair is one grapheme, the only multi-code-point grapheme
/// a comptime body meets; a byte that starts no valid sequence is one.
pub fn graphemes(out: []usize, s: []const u8) []usize {
    var n: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        out[n] = i;
        n += 1;
        if (s[i] == '\r' and i + 1 < s.len and s[i + 1] == '\n') {
            i += 2;
            continue;
        }
        const len = std.unicode.utf8ByteSequenceLength(s[i]) catch 1;
        i += if (i + len <= s.len) len else 1;
    }
    out[n] = s.len;
    return out[0 .. n + 1];
}

/// The bytes of the graphemes `[start, start + len)` of `s` (`len` null: to
/// the end), both clamped to the text; `bounds` is `graphemes(…, s)`.
pub fn slice(s: []const u8, bounds: []const usize, start: usize, len: ?usize) []const u8 {
    const n = bounds.len - 1;
    const from = @min(n, start);
    const to = if (len) |l| @min(n, from + l) else n;
    return s[bounds[from]..bounds[to]];
}

/// `s` with its graphemes in reverse order, into `out` (`out.len >= s.len`).
pub fn reverse(out: []u8, s: []const u8, bounds: []const usize) []u8 {
    var o: usize = 0;
    var i = bounds.len - 1;
    while (i > 0) {
        i -= 1;
        const part = s[bounds[i]..bounds[i + 1]];
        @memcpy(out[o..][0..part.len], part);
        o += part.len;
    }
    return out[0..s.len];
}

/// Where `pat` first occurs in `s`, in bytes (an empty `pat` is at 0).
pub fn find(s: []const u8, pat: []const u8) ?usize {
    return std.mem.indexOf(u8, s, pat);
}

/// Whether `s` starts with `pat`.
pub fn startsWith(s: []const u8, pat: []const u8) bool {
    return std.mem.startsWith(u8, s, pat);
}

/// The pieces of `s` between the occurrences of a non-empty `sep`: every
/// one (`all`) or only the first cut.
pub const Splitter = struct {
    rest: ?[]const u8,
    sep: []const u8,
    all: bool,
    cut: bool = false,

    pub fn init(s: []const u8, sep: []const u8, all: bool) Splitter {
        std.debug.assert(sep.len > 0);
        return .{ .rest = s, .sep = sep, .all = all };
    }

    pub fn next(it: *Splitter) ?[]const u8 {
        const rest = it.rest orelse return null;
        if (it.all or !it.cut) if (std.mem.indexOf(u8, rest, it.sep)) |i| {
            it.cut = true;
            it.rest = rest[i + it.sep.len ..];
            return rest[0..i];
        };
        it.rest = null;
        return rest;
    }
};

/// `s` with the first (or every, `all`) occurrence of a non-empty `pat`
/// replaced by `rep`, appended to `out`.
pub fn replace(gpa: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), s: []const u8, pat: []const u8, rep: []const u8, all: bool) error{OutOfMemory}!void {
    std.debug.assert(pat.len > 0);
    var rest = s;
    while (std.mem.indexOf(u8, rest, pat)) |i| {
        try out.appendSlice(gpa, rest[0..i]);
        try out.appendSlice(gpa, rep);
        rest = rest[i + pat.len ..];
        if (!all) break;
    }
    try out.appendSlice(gpa, rest);
}

// ── a `--target wasm` program's string methods (decision 442 (2)) ────────────
//
// What `wat_prelude` answered by hand-written WAT until 144 B-00g, over a
// string's UTF-8 bytes: indices count code points (decision 240) — a byte
// starts one exactly when it is no `10xxxxxx` continuation byte — and every
// search compares bytes. Each answers what its WAT helper answered, byte for
// byte: the wasm `.out` of every `run/` cell is the oracle.

/// Whether byte `c` starts a code point (it is no continuation byte).
pub fn isLead(c: u8) bool {
    return c & 0xC0 != 0x80;
}

/// The code points of `s`: the bytes that start one, counted.
pub fn cpLength(s: []const u8) usize {
    var k: usize = 0;
    for (s) |c| {
        if (isLead(c)) k += 1;
    }
    return k;
}

/// The byte offset where code point `i` of `s` starts; `s.len` when `s` has
/// `i` code points or fewer.
pub fn cpOffset(s: []const u8, i: usize) usize {
    var k: usize = 0;
    for (s, 0..) |c, p| {
        if (!isLead(c)) continue;
        if (k == i) return p;
        k += 1;
    }
    return s.len;
}

/// The code point index of byte offset `off` of `s`: the code points that
/// start before it.
pub fn cpOf(s: []const u8, off: usize) usize {
    return cpLength(s[0..@min(off, s.len)]);
}

/// `slice`'s bound: a negative `x` counts from the end (`x + n`), then
/// clamped to `0..n`.
pub fn bound(x: i32, n: usize) usize {
    const len: i64 = @intCast(n);
    var v: i64 = x;
    if (v < 0) v += len;
    return @intCast(std.math.clamp(v, 0, len));
}

/// `s.slice(a, b)` in code points, with `slice`'s bounds (`bound`): an end
/// before the start is the start; an open end is any bound past the length.
pub fn cpSlice(s: []const u8, a: i32, b: i32) []const u8 {
    const n = cpLength(s);
    const from = bound(a, n);
    const to = @max(from, bound(b, n));
    return s[cpOffset(s, from)..cpOffset(s, to)];
}

/// `s.at(i)` in code points: a negative `i` counted from the end (decision
/// 139), then the code point's bytes, or null outside `0..length`.
pub fn cpAt(s: []const u8, i: i32) ?[]const u8 {
    const n: i64 = @intCast(cpLength(s));
    var j: i64 = i;
    if (j < 0) j += n;
    if (j < 0 or j >= n) return null;
    const k: usize = @intCast(j);
    return s[cpOffset(s, k)..cpOffset(s, k + 1)];
}

/// The last byte offset of `sub` in `s` (`s.len` for an empty `sub`, as
/// JavaScript answers), or null.
pub fn lastFind(s: []const u8, sub: []const u8) ?usize {
    if (sub.len > s.len) return null;
    var i = s.len - sub.len + 1;
    while (i > 0) {
        i -= 1;
        if (std.mem.eql(u8, s[i..][0..sub.len], sub)) return i;
    }
    return null;
}

/// `s.indexOf(sub)` in code points, `-1` when absent (`0` for an empty `sub`).
pub fn indexOf(s: []const u8, sub: []const u8) i32 {
    const off = find(s, sub) orelse return -1;
    return @intCast(cpOf(s, off));
}

/// `s.lastIndexOf(sub)` in code points, `-1` when absent (the length for an
/// empty `sub`).
pub fn lastIndexOf(s: []const u8, sub: []const u8) i32 {
    const off = lastFind(s, sub) orelse return -1;
    return @intCast(cpOf(s, off));
}

/// Whether `s` ends with `x`.
pub fn endsWith(s: []const u8, x: []const u8) bool {
    return std.mem.endsWith(u8, s, x);
}

/// `s.charCodeAt(i)`: the code point at code point index `i`, `-1` for a
/// negative `i` or one past the text. The sequence's width is read from its
/// lead byte and its bits are decoded as they stand (a string is valid UTF-8).
pub fn charCodeAt(s: []const u8, i: i32) i32 {
    if (i < 0) return -1;
    var left: usize = @intCast(i);
    var p: usize = 0;
    while (p < s.len) {
        const b = s[p];
        const w: usize = if (b >= 0xF0) 4 else if (b >= 0xE0) 3 else if (b >= 0xC0) 2 else 1;
        if (left == 0) {
            if (w == 1) return b;
            var cp: u32 = b & ((@as(u32, 0x80) >> @intCast(w)) - 1);
            var k: usize = 1;
            while (k < w) : (k += 1) cp = (cp << 6) | (if (p + k < s.len) s[p + k] & 0x3F else 0);
            return @intCast(cp);
        }
        left -= 1;
        p += w;
    }
    return -1;
}

/// The UTF-8 bytes of the Unicode scalar value `cp` into `out`
/// (`out.len >= 4`), or null for a value that is none — negative, a
/// surrogate (U+D800..U+DFFF), past U+10FFFF.
pub fn encodeCodepoint(out: []u8, cp: i32) ?[]u8 {
    if (cp < 0) return null;
    const c: u21 = std.math.cast(u21, cp) orelse return null;
    const n = std.unicode.utf8Encode(c, out[0..4]) catch return null;
    return out[0..n];
}

/// The pieces `s.split(sep)` answers: cut at every `sep` (bytes compared);
/// an empty `sep` cuts before every code point, and then `""` has no piece.
pub const Split = struct {
    s: []const u8,
    sep: []const u8,
    at: usize = 0,
    done: bool = false,

    pub fn init(s: []const u8, sep: []const u8) Split {
        return .{ .s = s, .sep = sep, .done = sep.len == 0 and s.len == 0 };
    }

    pub fn next(it: *Split) ?[]const u8 {
        if (it.done) return null;
        const rest = it.s[it.at..];
        if (it.sep.len == 0) {
            var e: usize = 1;
            while (e < rest.len and !isLead(rest[e])) e += 1;
            it.at += e;
            if (it.at >= it.s.len) it.done = true;
            return rest[0..e];
        }
        if (std.mem.indexOf(u8, rest, it.sep)) |i| {
            it.at += i + it.sep.len;
            return rest[0..i];
        }
        it.done = true;
        return rest;
    }
};

/// `s.lines()`: `s` cut at every `\n`, a `\r` right before it dropped with it
/// — what the `/\r?\n/` split answers on node and `[<<"\r\n">>, <<"\n">>]` on
/// erlang. The last piece keeps a trailing `\r` (no `\n` follows it); `""` is
/// one empty line.
pub const Lines = struct {
    s: []const u8,
    at: usize = 0,
    done: bool = false,

    pub fn next(it: *Lines) ?[]const u8 {
        if (it.done) return null;
        const rest = it.s[it.at..];
        if (std.mem.indexOfScalar(u8, rest, '\n')) |i| {
            it.at += i + 1;
            const e = if (i > 0 and rest[i - 1] == '\r') i - 1 else i;
            return rest[0..e];
        }
        it.done = true;
        return rest;
    }
};

/// The bytes `words` separates on: space, tab, LF, CR.
pub fn isWordSpace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

/// `s.words()`: the maximal runs of bytes that are not `isWordSpace`.
pub const Words = struct {
    s: []const u8,
    at: usize = 0,

    pub fn next(it: *Words) ?[]const u8 {
        while (it.at < it.s.len and isWordSpace(it.s[it.at])) it.at += 1;
        if (it.at >= it.s.len) return null;
        const start = it.at;
        while (it.at < it.s.len and !isWordSpace(it.s[it.at])) it.at += 1;
        return it.s[start..it.at];
    }
};

/// The byte length `s.padStart(width, pad)` / `padEnd` answers: `width`
/// when the gap is real, else `s.len` (`s` itself — already as long, or an
/// empty pad).
pub fn padLength(s: []const u8, width: i32, pad: []const u8) usize {
    if (width <= @as(i64, @intCast(s.len)) or pad.len == 0) return s.len;
    return @intCast(width);
}

/// `s` padded to `out.len` bytes (`padLength`) with `pad` cycled through the
/// gap (JavaScript's), the text after the gap (`start`, `padStart`) or
/// before it (`padEnd`).
pub fn padInto(out: []u8, s: []const u8, pad: []const u8, start: bool) void {
    if (out.len == s.len) {
        @memcpy(out, s);
        return;
    }
    const k = out.len - s.len;
    const text_at: usize = if (start) k else 0;
    const gap_at: usize = if (start) 0 else s.len;
    @memcpy(out[text_at..][0..s.len], s);
    for (0..k) |i| out[gap_at + i] = pad[i % pad.len];
}

/// The byte length `s.repeat(times)` answers (a negative `times` is 0).
pub fn repeatLength(s: []const u8, times: i32) usize {
    return s.len * @as(usize, @intCast(@max(times, 0)));
}

/// `s` repeated to fill `out` (`repeatLength`).
pub fn repeatInto(out: []u8, s: []const u8) void {
    var o: usize = 0;
    while (o < out.len) : (o += s.len) @memcpy(out[o..][0..s.len], s);
}

/// The byte length `s.replace(pat, with)` (`all` false) or `replaceAll`
/// answers. An empty `pat` matches before every byte and at the end, as
/// JavaScript's does over its units: `replace` puts `with` in front,
/// `replaceAll` around every byte.
pub fn replacedLength(s: []const u8, pat: []const u8, with: []const u8, all: bool) usize {
    if (pat.len == 0) return if (all) s.len + (s.len + 1) * with.len else s.len + with.len;
    var n: usize = 0;
    var rest = s;
    while (std.mem.indexOf(u8, rest, pat)) |i| {
        n += i + with.len;
        rest = rest[i + pat.len ..];
        if (!all) break;
    }
    return n + rest.len;
}

/// `s` with `pat` replaced (`replacedLength` gives `out.len`).
pub fn replaceInto(out: []u8, s: []const u8, pat: []const u8, with: []const u8, all: bool) void {
    var o: usize = 0;
    const put = struct {
        fn f(dst: []u8, at: *usize, bytes: []const u8) void {
            @memcpy(dst[at.*..][0..bytes.len], bytes);
            at.* += bytes.len;
        }
    }.f;
    if (pat.len == 0) {
        put(out, &o, with);
        if (!all) {
            put(out, &o, s);
            return;
        }
        for (0..s.len) |i| {
            put(out, &o, s[i .. i + 1]);
            put(out, &o, with);
        }
        return;
    }
    var rest = s;
    while (std.mem.indexOf(u8, rest, pat)) |i| {
        put(out, &o, rest[0..i]);
        put(out, &o, with);
        rest = rest[i + pat.len ..];
        if (!all) break;
    }
    put(out, &o, rest);
}

test "caseMap: ASCII mapped, a non-ASCII letter refused" {
    var buf: [16]u8 = undefined;
    try std.testing.expectEqualStrings("HELLO, WORLD 1", try caseMap(&buf, "Hello, world 1", true));
    try std.testing.expectEqualStrings("hello", try caseMap(&buf, "HeLLo", false));
    try std.testing.expectError(error.NonAsciiLetter, caseMap(&buf, "héllo", true));
}

test "titlecase: the first character, ASCII; the rest untouched" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualStrings("World", try titlecase(&buf, "world"));
    try std.testing.expectEqualStrings("HELLO wORLD", try titlecase(&buf, "hELLO wORLD"));
    try std.testing.expectEqualStrings("1st", try titlecase(&buf, "1st"));
    try std.testing.expectEqualStrings("Ana é", try titlecase(&buf, "ana é"));
    try std.testing.expectEqualStrings("", try titlecase(&buf, ""));
    try std.testing.expectError(error.NonAsciiLetter, titlecase(&buf, "élan"));
}

test "trim: each direction" {
    try std.testing.expectEqualStrings("a b", trim(" \t a b\r\n", .both));
    try std.testing.expectEqualStrings("a b\r\n", trim(" \t a b\r\n", .leading));
    try std.testing.expectEqualStrings(" \t a b", trim(" \t a b\r\n", .trailing));
    try std.testing.expectEqualStrings("", trim("   ", .both));
}

test "graphemes, slice and reverse: code points, CRLF one" {
    var b: [32]usize = undefined;
    const s = "aé\r\nz";
    const g = graphemes(&b, s);
    try std.testing.expectEqual(@as(usize, 5), g.len);
    try std.testing.expectEqualStrings("é\r\n", slice(s, g, 1, 2));
    try std.testing.expectEqualStrings("z", slice(s, g, 3, null));
    try std.testing.expectEqualStrings("", slice(s, g, 9, 1));
    var r: [16]u8 = undefined;
    try std.testing.expectEqualStrings("z\r\néa", reverse(&r, s, g));
}

test "find and startsWith" {
    try std.testing.expectEqual(@as(?usize, 2), find("abcd", "cd"));
    try std.testing.expectEqual(@as(?usize, null), find("abcd", "x"));
    try std.testing.expect(startsWith("prefix-rest", "prefix"));
    try std.testing.expect(!startsWith("pre", "prefix"));
}

test "Splitter: every cut, and the first only" {
    var all = Splitter.init("a,b,,c", ",", true);
    const want = [_][]const u8{ "a", "b", "", "c" };
    for (want) |w| try std.testing.expectEqualStrings(w, all.next().?);
    try std.testing.expect(all.next() == null);
    var first = Splitter.init("a,b,c", ",", false);
    try std.testing.expectEqualStrings("a", first.next().?);
    try std.testing.expectEqualStrings("b,c", first.next().?);
    try std.testing.expect(first.next() == null);
}

test "replace: first and every occurrence" {
    const gpa = std.testing.allocator;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(gpa);
    try replace(gpa, &out, "a-b-c", "-", "+", true);
    try std.testing.expectEqualStrings("a+b+c", out.items);
    out.clearRetainingCapacity();
    try replace(gpa, &out, "a-b-c", "-", "+", false);
    try std.testing.expectEqualStrings("a+b-c", out.items);
}

test "cpLength, cpOffset, cpOf: code points over UTF-8 bytes" {
    const s = "aé€😀z";
    try std.testing.expectEqual(@as(usize, 5), cpLength(s));
    try std.testing.expectEqual(@as(usize, 0), cpLength(""));
    try std.testing.expectEqual(@as(usize, 1), cpOffset(s, 1));
    try std.testing.expectEqual(@as(usize, 3), cpOffset(s, 2));
    try std.testing.expectEqual(@as(usize, 6), cpOffset(s, 3));
    try std.testing.expectEqual(s.len, cpOffset(s, 5));
    try std.testing.expectEqual(s.len, cpOffset(s, 9));
    try std.testing.expectEqual(@as(usize, 2), cpOf(s, 3));
}

test "cpSlice: negative bounds from the end, clamped, an end before the start empty" {
    const s = "héllo";
    try std.testing.expectEqualStrings("él", cpSlice(s, 1, 3));
    try std.testing.expectEqualStrings("lo", cpSlice(s, -2, std.math.maxInt(i32)));
    try std.testing.expectEqualStrings("", cpSlice(s, 3, 1));
    try std.testing.expectEqualStrings("héllo", cpSlice(s, -99, 99));
    try std.testing.expectEqualStrings("", cpSlice("", 0, 5));
}

test "cpAt: a code point, negative from the end, null outside" {
    try std.testing.expectEqualStrings("é", cpAt("héllo", 1).?);
    try std.testing.expectEqualStrings("o", cpAt("héllo", -1).?);
    try std.testing.expect(cpAt("héllo", 5) == null);
    try std.testing.expect(cpAt("héllo", -6) == null);
    try std.testing.expect(cpAt("", 0) == null);
}

test "indexOf and lastIndexOf: code points, the empty needle" {
    try std.testing.expectEqual(@as(i32, 2), indexOf("héllo", "ll"));
    try std.testing.expectEqual(@as(i32, -1), indexOf("héllo", "x"));
    try std.testing.expectEqual(@as(i32, 0), indexOf("héllo", ""));
    try std.testing.expectEqual(@as(i32, 4), lastIndexOf("éaéa", "a") + 1);
    try std.testing.expectEqual(@as(i32, 5), lastIndexOf("héllo", ""));
    try std.testing.expectEqual(@as(i32, -1), lastIndexOf("ab", "abc"));
    try std.testing.expect(endsWith("file.bp", ".bp"));
    try std.testing.expect(!endsWith("bp", ".bp"));
}

test "charCodeAt: decoded code points, -1 outside" {
    try std.testing.expectEqual(@as(i32, 233), charCodeAt("héllo", 1));
    try std.testing.expectEqual(@as(i32, 'h'), charCodeAt("héllo", 0));
    try std.testing.expectEqual(@as(i32, 0x1F600), charCodeAt("a😀", 1));
    try std.testing.expectEqual(@as(i32, 0x20AC), charCodeAt("€", 0));
    try std.testing.expectEqual(@as(i32, -1), charCodeAt("ab", 2));
    try std.testing.expectEqual(@as(i32, -1), charCodeAt("ab", -1));
}

test "encodeCodepoint: one to four bytes, no scalar value refused" {
    var b: [4]u8 = undefined;
    try std.testing.expectEqualStrings("A", encodeCodepoint(&b, 65).?);
    try std.testing.expectEqualStrings("é", encodeCodepoint(&b, 233).?);
    try std.testing.expectEqualStrings("€", encodeCodepoint(&b, 0x20AC).?);
    try std.testing.expectEqualStrings("😀", encodeCodepoint(&b, 0x1F600).?);
    try std.testing.expect(encodeCodepoint(&b, -1) == null);
    try std.testing.expect(encodeCodepoint(&b, 0xD800) == null);
    try std.testing.expect(encodeCodepoint(&b, 0x110000) == null);
}

fn expectPieces(it: anytype, want: []const []const u8) !void {
    var i = it;
    for (want) |w| try std.testing.expectEqualStrings(w, i.next().?);
    try std.testing.expect(i.next() == null);
}

test "Split: a separator, an empty one by code point, the empty text" {
    try expectPieces(Split.init("a,b,,c", ","), &.{ "a", "b", "", "c" });
    try expectPieces(Split.init("", ","), &.{""});
    try expectPieces(Split.init("a,", ","), &.{ "a", "" });
    try expectPieces(Split.init("aéz", ""), &.{ "a", "é", "z" });
    try expectPieces(Split.init("", ""), &.{});
    try expectPieces(Split.init("a--b", "--"), &.{ "a", "b" });
}

test "Lines: LF and CRLF, a trailing CR kept, the empty text one line" {
    try expectPieces(Lines{ .s = "a\r\nb\nc" }, &.{ "a", "b", "c" });
    try expectPieces(Lines{ .s = "" }, &.{""});
    try expectPieces(Lines{ .s = "a\n" }, &.{ "a", "" });
    try expectPieces(Lines{ .s = "a\r" }, &.{"a\r"});
    try expectPieces(Lines{ .s = "\r\n" }, &.{ "", "" });
}

test "Words: runs between spaces, tabs, LF, CR" {
    try expectPieces(Words{ .s = "  a bc\t\nd\r " }, &.{ "a", "bc", "d" });
    try expectPieces(Words{ .s = "" }, &.{});
    try expectPieces(Words{ .s = " \t " }, &.{});
}

test "padInto: the pad cycled through the gap, each side" {
    var b: [16]u8 = undefined;
    const n = padLength("7", 5, "ab");
    try std.testing.expectEqual(@as(usize, 5), n);
    padInto(b[0..n], "7", "ab", true);
    try std.testing.expectEqualStrings("abab7", b[0..n]);
    padInto(b[0..n], "7", "ab", false);
    try std.testing.expectEqualStrings("7abab", b[0..n]);
    try std.testing.expectEqual(@as(usize, 3), padLength("abc", 2, "x"));
    try std.testing.expectEqual(@as(usize, 1), padLength("a", 4, ""));
}

test "repeatInto: times copies, a negative count none" {
    var b: [16]u8 = undefined;
    const n = repeatLength("ab", 3);
    repeatInto(b[0..n], "ab");
    try std.testing.expectEqualStrings("ababab", b[0..n]);
    try std.testing.expectEqual(@as(usize, 0), repeatLength("ab", -2));
}

test "replaceInto: first, every, and the empty pattern" {
    var b: [32]u8 = undefined;
    const cases = .{
        .{ "a-b-c", "-", "+", false, "a+b-c" },
        .{ "a-b-c", "-", "+", true, "a+b+c" },
        .{ "abc", "x", "+", true, "abc" },
        .{ "ab", "", "-", false, "-ab" },
        .{ "ab", "", "-", true, "-a-b-" },
        .{ "", "", "-", true, "-" },
        .{ "aaa", "aa", "b", true, "ba" },
    };
    inline for (cases) |c| {
        const n = replacedLength(c[0], c[1], c[2], c[3]);
        replaceInto(b[0..n], c[0], c[1], c[2], c[3]);
        try std.testing.expectEqualStrings(c[4], b[0..n]);
    }
}
