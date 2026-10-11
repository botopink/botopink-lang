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
