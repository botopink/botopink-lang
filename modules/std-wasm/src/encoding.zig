//! The byte codecs behind std's `Bytes` bridges (decision 346): what
//! `encoding.base64EncodeBytes`, `base64DecodeBytes`, `hexEncodeBytes` and
//! `hexDecodeBytes` answer on wasm and at comptime. Pure functions over bytes
//! — no term layout, no allocation of their own: a caller sizes the output
//! with the `…Length` function and hands the buffer. No table is data here
//! (the alphabet is computed, not indexed), so a program that links them
//! carries no relocation (`std_wasm_link.zig` refuses one).
const std = @import("std");

/// The base64 digit (RFC 4648 §4) of the sextet `v`.
fn base64Digit(v: u8) u8 {
    if (v < 26) return 'A' + v;
    if (v < 52) return 'a' + (v - 26);
    if (v < 62) return '0' + (v - 52);
    return if (v == 62) '+' else '/';
}

/// The sextet the base64 digit `c` spells, or null for any other byte.
fn base64Value(c: u8) ?u8 {
    return switch (c) {
        'A'...'Z' => c - 'A',
        'a'...'z' => c - 'a' + 26,
        '0'...'9' => c - '0' + 52,
        '+' => 62,
        '/' => 63,
        else => null,
    };
}

/// The length of `bytes`' base64 text, `=`-padded.
pub fn base64EncodedLength(n: usize) usize {
    return (n + 2) / 3 * 4;
}

/// Standard base64 of `bytes`, `=`-padded, into `out` (`base64EncodedLength`).
pub fn base64Encode(out: []u8, bytes: []const u8) void {
    var o: usize = 0;
    var i: usize = 0;
    while (i < bytes.len) : (i += 3) {
        const b0 = bytes[i];
        const b1: u8 = if (i + 1 < bytes.len) bytes[i + 1] else 0;
        const b2: u8 = if (i + 2 < bytes.len) bytes[i + 2] else 0;
        out[o] = base64Digit(b0 >> 2);
        out[o + 1] = base64Digit(((b0 & 3) << 4) | (b1 >> 4));
        out[o + 2] = if (i + 1 < bytes.len) base64Digit(((b1 & 15) << 2) | (b2 >> 6)) else '=';
        out[o + 3] = if (i + 2 < bytes.len) base64Digit(b2 & 63) else '=';
        o += 4;
    }
}

/// `text` without its trailing `=`.
fn unpadded(text: []const u8) []const u8 {
    var n = text.len;
    while (n > 0 and text[n - 1] == '=') n -= 1;
    return text[0..n];
}

/// The number of bytes `text` decodes to, or null when it is not base64 by
/// the Node cell's rule (`encoding.bp`'s `base64Decode`): trailing `=`
/// dropped, the rest digits of the `+/` alphabet, no length of the form
/// 4k + 1, and zero bits after the last whole byte.
pub fn base64DecodedLength(text: []const u8) ?usize {
    const t = unpadded(text);
    if (t.len % 4 == 1) return null;
    for (t) |c| if (base64Value(c) == null) return null;
    if (t.len % 4 == 2 and base64Value(t[t.len - 1]).? & 15 != 0) return null;
    if (t.len % 4 == 3 and base64Value(t[t.len - 1]).? & 3 != 0) return null;
    return t.len / 4 * 3 + switch (t.len % 4) {
        2 => @as(usize, 1),
        3 => 2,
        else => 0,
    };
}

/// The bytes `text` spells, into `out` (`base64DecodedLength`, non-null).
pub fn base64Decode(out: []u8, text: []const u8) void {
    const t = unpadded(text);
    var o: usize = 0;
    var i: usize = 0;
    while (i < t.len) : (i += 4) {
        const s0 = base64Value(t[i]).?;
        const s1 = base64Value(t[i + 1]).?;
        out[o] = (s0 << 2) | (s1 >> 4);
        o += 1;
        if (i + 2 < t.len) {
            const s2 = base64Value(t[i + 2]).?;
            out[o] = (s1 << 4) | (s2 >> 2);
            o += 1;
            if (i + 3 < t.len) {
                out[o] = (s2 << 6) | base64Value(t[i + 3]).?;
                o += 1;
            }
        }
    }
}

/// The lower-case hex digit of the nibble `v`.
fn hexDigit(v: u8) u8 {
    return if (v < 10) '0' + v else 'a' + (v - 10);
}

/// The nibble the hex digit `c` spells, either case, or null.
fn hexValue(c: u8) ?u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => null,
    };
}

/// Lower-case hex of `bytes` into `out` (`2 * bytes.len`).
pub fn hexEncode(out: []u8, bytes: []const u8) void {
    for (bytes, 0..) |b, i| {
        out[2 * i] = hexDigit(b >> 4);
        out[2 * i + 1] = hexDigit(b & 15);
    }
}

/// The number of bytes `text` decodes to, or null for an odd length or a
/// byte that is no hex digit.
pub fn hexDecodedLength(text: []const u8) ?usize {
    if (text.len % 2 != 0) return null;
    for (text) |c| if (hexValue(c) == null) return null;
    return text.len / 2;
}

/// The bytes `text` spells, into `out` (`hexDecodedLength`, non-null).
pub fn hexDecode(out: []u8, text: []const u8) void {
    for (out, 0..) |*b, i| b.* = (hexValue(text[2 * i]).? << 4) | hexValue(text[2 * i + 1]).?;
}

test "base64: std.base64's text both ways, every length to 64" {
    var src: [64]u8 = undefined;
    for (&src, 0..) |*b, i| b.* = @intCast((i * 37 + 11) % 256);
    for (0..src.len + 1) |n| {
        var mine: [100]u8 = undefined;
        var theirs: [100]u8 = undefined;
        const len = base64EncodedLength(n);
        base64Encode(mine[0..len], src[0..n]);
        try std.testing.expectEqualStrings(std.base64.standard.Encoder.encode(&theirs, src[0..n]), mine[0..len]);
        const back = base64DecodedLength(mine[0..len]).?;
        try std.testing.expectEqual(n, back);
        var dec: [64]u8 = undefined;
        base64Decode(dec[0..back], mine[0..len]);
        try std.testing.expectEqualSlices(u8, src[0..n], dec[0..back]);
    }
}

test "base64: the Node cell's refusals" {
    try std.testing.expectEqual(@as(?usize, 2), base64DecodedLength("aGk"));
    try std.testing.expectEqual(@as(?usize, 2), base64DecodedLength("aGk=="));
    try std.testing.expectEqual(@as(?usize, null), base64DecodedLength("aGk*"));
    try std.testing.expectEqual(@as(?usize, null), base64DecodedLength("a"));
    try std.testing.expectEqual(@as(?usize, null), base64DecodedLength("aGl"));
    try std.testing.expectEqual(@as(?usize, 0), base64DecodedLength(""));
}

test "hex: lower case out, either case in, odd or foreign refused" {
    var out: [6]u8 = undefined;
    hexEncode(&out, "\x00\xab\xff");
    try std.testing.expectEqualStrings("00abff", &out);
    var dec: [3]u8 = undefined;
    try std.testing.expectEqual(@as(?usize, 3), hexDecodedLength("00ABfF"));
    hexDecode(&dec, "00ABfF");
    try std.testing.expectEqualSlices(u8, "\x00\xab\xff", &dec);
    try std.testing.expectEqual(@as(?usize, null), hexDecodedLength("abc"));
    try std.testing.expectEqual(@as(?usize, null), hexDecodedLength("zz"));
}
