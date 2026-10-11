//! Numbers as text: the float formatting std's `Float.toString` answers at
//! comptime (decision 434 (5): one text for the four targets) — OTP's
//! `float_to_binary(F, [short])`: the shortest digits that round-trip,
//! fixed or exponent form, whichever is shorter.
const std = @import("std");

/// `float_to_binary(F, [short])`: the shortest digits that round-trip, written
/// in fixed notation or as `D.DDDeE`, whichever is shorter (fixed on a tie);
/// always one digit after the point at least. A value OTP has no float for —
/// `NaN`, `Infinity`, `-Infinity`, which only a `--target wasm` program's
/// arithmetic makes (erlang and beam raise `badarith` at the operation, and so
/// does the comptime runtime) — is written as those words, the one text such a
/// value has on any target.
///
/// Ryu's digits come from `std.fmt.float.render` and the exponent is written
/// by hand: no `std.Io.Writer`, so the function needs no function table and
/// no pointer in its data — what a `--target wasm` program links (144 B-00e).
pub fn shortFloat(f: f64, buf: []u8) []const u8 {
    if (std.math.isNan(f)) return "NaN";
    if (std.math.isInf(f)) return if (f < 0) "-Infinity" else "Infinity";
    if (f == 0) return if (std.math.signbit(f)) "-0.0" else "0.0";
    var sci: [std.fmt.float.min_buffer_size]u8 = undefined;
    const e_text = std.fmt.float.render(&sci, f, .{ .mode = .scientific }) catch unreachable;
    // e_text: [-]D[.DDD]e[-]X
    var neg = false;
    var s = e_text;
    if (s[0] == '-') {
        neg = true;
        s = s[1..];
    }
    const e_at = std.mem.indexOfScalar(u8, s, 'e').?;
    const mant = s[0..e_at];
    const exp = std.fmt.parseInt(i32, s[e_at + 1 ..], 10) catch 0;
    var digits: [32]u8 = undefined;
    var nd: usize = 0;
    for (mant) |c| if (c != '.') {
        digits[nd] = c;
        nd += 1;
    };
    while (nd > 1 and digits[nd - 1] == '0') nd -= 1;
    const d = digits[0..nd];

    // Scientific: D.DDDeX
    var sbuf: [64]u8 = undefined;
    var sl: usize = 0;
    if (neg) {
        sbuf[sl] = '-';
        sl += 1;
    }
    sbuf[sl] = d[0];
    sl += 1;
    sbuf[sl] = '.';
    sl += 1;
    if (nd > 1) {
        @memcpy(sbuf[sl..][0 .. nd - 1], d[1..]);
        sl += nd - 1;
    } else {
        sbuf[sl] = '0';
        sl += 1;
    }
    sbuf[sl] = 'e';
    sl += 1;
    sl += writeInt(sbuf[sl..], exp);

    // Fixed.
    var fbuf: [400]u8 = undefined;
    var fl: usize = 0;
    if (neg) {
        fbuf[fl] = '-';
        fl += 1;
    }
    const point: i32 = exp + 1; // digits before the point
    if (point <= 0) {
        fbuf[fl] = '0';
        fbuf[fl + 1] = '.';
        fl += 2;
        var z: i32 = 0;
        while (z < -point) : (z += 1) {
            fbuf[fl] = '0';
            fl += 1;
        }
        @memcpy(fbuf[fl..][0..nd], d);
        fl += nd;
    } else {
        const p: usize = @intCast(point);
        if (p >= nd) {
            @memcpy(fbuf[fl..][0..nd], d);
            fl += nd;
            for (0..p - nd) |_| {
                fbuf[fl] = '0';
                fl += 1;
            }
            fbuf[fl] = '.';
            fbuf[fl + 1] = '0';
            fl += 2;
        } else {
            @memcpy(fbuf[fl..][0..p], d[0..p]);
            fl += p;
            fbuf[fl] = '.';
            fl += 1;
            @memcpy(fbuf[fl..][0 .. nd - p], d[p..]);
            fl += nd - p;
        }
    }
    const pick = if (fl <= sl) fbuf[0..fl] else sbuf[0..sl];
    @memcpy(buf[0..pick.len], pick);
    return buf[0..pick.len];
}

/// The decimal digits of `v`, a `-` first when negative, into `out`; answers
/// how many bytes it wrote.
fn writeInt(out: []u8, v: i32) usize {
    var n: usize = 0;
    var m: u32 = @abs(v);
    if (v < 0) {
        out[0] = '-';
        n = 1;
    }
    var tmp: [10]u8 = undefined;
    var k: usize = 0;
    while (true) {
        tmp[k] = @intCast('0' + m % 10);
        k += 1;
        m /= 10;
        if (m == 0) break;
    }
    for (0..k) |i| out[n + i] = tmp[k - 1 - i];
    return n + k;
}

/// The decimal digits of the unsigned `v` into `out` (`out.len >= 20`);
/// answers how many it wrote.
pub fn unsignedText(out: []u8, v: u64) usize {
    var tmp: [20]u8 = undefined;
    var m = v;
    var k: usize = 0;
    while (true) {
        tmp[k] = @intCast('0' + m % 10);
        k += 1;
        m /= 10;
        if (m == 0) break;
    }
    for (0..k) |i| out[i] = tmp[k - 1 - i];
    return k;
}

/// The decimal text of `v` into `out` (`out.len >= 20`), a `-` first when
/// negative — the magnitude written unsigned, so `-2^63` (its own negation)
/// prints whole; answers how many bytes it wrote. An `i32`'s, an `i64`'s
/// (decision 442 (2): `i32` / `i64_to_str`).
pub fn signedText(out: []u8, v: i64) usize {
    if (v >= 0) return unsignedText(out, @intCast(v));
    out[0] = '-';
    return 1 + unsignedText(out[1..], @abs(v));
}

test "shortFloat: the shortest form, fixed on a tie" {
    const cases = [_]struct { f64, []const u8 }{
        .{ 0.1, "0.1" },                                     .{ 1.0e21, "1.0e21" },                                 .{ 1.0e20, "1.0e20" },
        .{ 123.0, "123.0" },                                 .{ 1.0e-5, "1.0e-5" },                                 .{ 0.0001, "0.0001" },
        .{ 1.0e15, "1.0e15" },                               .{ 123456789.0, "123456789.0" },                       .{ 0.30000000000000004, "0.30000000000000004" },
        .{ 1.2345678901234567e19, "1.2345678901234567e19" }, .{ -0.0, "-0.0" },                                     .{ 2.0e-10, "2.0e-10" },
        .{ 1.5, "1.5" },                                     .{ 100.0, "100.0" },                                   .{ 5.0e-324, "5.0e-324" },
        .{ -2.5e-7, "-2.5e-7" },                             .{ 1.7976931348623157e308, "1.7976931348623157e308" },
    };
    for (cases) |c| {
        var buf: [64]u8 = undefined;
        try std.testing.expectEqualStrings(c[1], shortFloat(c[0], &buf));
    }
}

test "shortFloat: the values OTP has no float for" {
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("NaN", shortFloat(std.math.nan(f64), &buf));
    try std.testing.expectEqualStrings("Infinity", shortFloat(std.math.inf(f64), &buf));
    try std.testing.expectEqualStrings("-Infinity", shortFloat(-std.math.inf(f64), &buf));
}

test "signedText and unsignedText: every digit, the extremes" {
    var b: [24]u8 = undefined;
    const cases = [_]struct { i64, []const u8 }{
        .{ 0, "0" },                                      .{ 7, "7" },                                       .{ -7, "-7" },
        .{ 2147483647, "2147483647" },                    .{ -2147483648, "-2147483648" },                   .{ 4294967295, "4294967295" },
        .{ std.math.maxInt(i64), "9223372036854775807" }, .{ std.math.minInt(i64), "-9223372036854775808" },
    };
    for (cases) |c| try std.testing.expectEqualStrings(c[1], b[0..signedText(&b, c[0])]);
    try std.testing.expectEqualStrings("18446744073709551615", b[0..unsignedText(&b, std.math.maxInt(u64))]);
    try std.testing.expectEqualStrings("10000000000000000000", b[0..unsignedText(&b, 10_000_000_000_000_000_000)]);
}
