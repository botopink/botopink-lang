//! Numbers as text: the float formatting std's `Float.toString` answers at
//! comptime (decision 434 (5): one text for the four targets) — OTP's
//! `float_to_binary(F, [short])`: the shortest digits that round-trip,
//! fixed or exponent form, whichever is shorter.
const std = @import("std");
const bigint = @import("bigint.zig");

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

// ── string numerals (std's `String.parseInt` / `parseFloat`) ───────────────
// The methods decide in botopink which strings are numerals
// (`primitives.bp`); these convert what they accepted.

/// Whether `s` is one or more of the digits `0`–`9` and nothing else.
pub fn isDigits(s: []const u8) bool {
    if (s.len == 0) return false;
    for (s) |c| if (c < '0' or c > '9') return false;
    return true;
}

/// The integer an optional `+` / `-` and decimal digits spell, or null past
/// −2^63 … 2^63 − 1 (or for text that is no such numeral).
pub fn integerOf(s: []const u8) ?i64 {
    var digits = s;
    var neg = false;
    if (digits.len > 0 and (digits[0] == '+' or digits[0] == '-')) {
        neg = digits[0] == '-';
        digits = digits[1..];
    }
    if (!isDigits(digits)) return null;
    // The magnitude, bounded by 2^63 (the negative end's).
    const limit: u64 = @as(u64, 1) << 63;
    var m: u64 = 0;
    for (digits) |c| {
        m = std.math.mul(u64, m, 10) catch return null;
        m = std.math.add(u64, m, c - '0') catch return null;
        if (m > limit) return null;
    }
    if (neg) return if (m == limit) std.math.minInt(i64) else -@as(i64, @intCast(m));
    return if (m == limit) null else @intCast(m);
}

/// Significant digits `floatOf` keeps; the rest only say whether the value
/// lies past the kept ones. A halfway point between two `f64`s has at most
/// 767 significant digits, so the rounding never needs more.
const float_digits = 800;

/// Limbs of the numbers `floatOf` computes over: the numerator of the
/// smallest numeral it divides (`float_digits` digits over 10^1124, shifted
/// 64 bits past it) fits 4 096 bits.
const float_limbs = 136;

/// `x * m + a` in place over `x.len` limbs; the new length (the caller sizes
/// the buffer, one limb past every value it holds).
fn mulAddSmall(buf: []bigint.Limb, len: usize, m: u32, a: u32) usize {
    var carry: u64 = a;
    for (buf[0..len]) |*l| {
        const t: u64 = @as(u64, l.*) * m + carry;
        l.* = @truncate(t);
        carry = t >> 32;
    }
    if (carry == 0) return len;
    buf[len] = @truncate(carry);
    return len + 1;
}

/// `x * 10^k` in place; the new length.
fn mulPow10(buf: []bigint.Limb, len: usize, k: u64) usize {
    var n = len;
    var left = k;
    while (left >= 9) : (left -= 9) n = mulAddSmall(buf, n, 1_000_000_000, 0);
    var tail: u32 = 1;
    while (left > 0) : (left -= 1) tail *= 10;
    return mulAddSmall(buf, n, tail, 0);
}

/// `limbs` shifted left by `s` bits into `out`; the normalised limbs.
fn shiftLeft(out: []bigint.Limb, limbs: []const bigint.Limb, s: u64) []bigint.Limb {
    const words: usize = @intCast(s / 32);
    const bits: u5 = @intCast(s % 32);
    @memset(out[0 .. limbs.len + words + 1], 0);
    for (limbs, 0..) |l, i| {
        out[i + words] |= l << bits;
        if (bits != 0) out[i + words + 1] |= l >> @intCast(@as(u6, 32) - bits);
    }
    return out[0..bigint.normalized(out[0 .. limbs.len + words + 1]).len];
}

fn bitLength(limbs: []const bigint.Limb) u64 {
    if (limbs.len == 0) return 0;
    return @as(u64, limbs.len) * 32 - @clz(limbs[limbs.len - 1]);
}

/// The top 63 bits of `limbs` (nonzero) as `m * 2^shift`, and whether a bit
/// below them is set.
fn topBits(limbs: []const bigint.Limb) struct { m: u64, shift: i64, sticky: bool } {
    const len = bitLength(limbs);
    const drop: u64 = if (len > 63) len - 63 else 0;
    var m: u64 = 0;
    var i: u64 = len;
    while (i > drop) {
        i -= 1;
        m = (m << 1) | ((limbs[@intCast(i / 32)] >> @intCast(i % 32)) & 1);
    }
    var sticky = false;
    var w: usize = 0;
    while (w < drop / 32) : (w += 1) sticky = sticky or limbs[w] != 0;
    const rest: u5 = @intCast(drop % 32);
    if (rest != 0) sticky = sticky or (limbs[@intCast(drop / 32)] & ((@as(u32, 1) << rest) - 1)) != 0;
    return .{ .m = m, .shift = @intCast(drop), .sticky = sticky };
}

/// The `f64` nearest to `m * 2^shift` (`m` nonzero, at most 63 bits),
/// `sticky` when the true value lies a little past it; ties to even. Null
/// past the largest `f64`.
fn roundToF64(m: u64, shift: i64, sticky: bool) ?f64 {
    const len: i64 = 64 - @as(i64, @clz(m));
    const top = shift + len - 1; // the value is in [2^top, 2^(top+1))
    if (top > 1023) return null;
    if (top < -1075) return 0.0;
    const lsb = @max(top - 52, -1074);
    const drop = lsb - shift;
    var keep: u64 = undefined;
    if (drop <= 0) {
        keep = m << @intCast(-drop);
    } else {
        const d: u7 = @intCast(drop);
        const wide: u128 = m;
        keep = @intCast(wide >> d);
        const rem = wide & ((@as(u128, 1) << d) - 1);
        const half = @as(u128, 1) << (d - 1);
        if (rem > half or (rem == half and (sticky or keep & 1 == 1))) keep += 1;
    }
    var exp = lsb;
    if (keep == @as(u64, 1) << 53) {
        keep >>= 1;
        exp += 1;
    }
    if (keep < @as(u64, 1) << 52) return @bitCast(keep); // subnormal, `exp` is -1074
    const biased = exp + 1075;
    if (biased >= 2047) return null;
    return @bitCast((@as(u64, @intCast(biased)) << 52) | (keep & ((@as(u64, 1) << 52) - 1)));
}

/// The `f64` nearest to `<-?><whole>.<fraction>e<exponent>` (the pieces
/// `parseFloat` accepted: digits, `exponent` with an optional sign),
/// correctly rounded, ties to even; null when it does not fit an `f64`. One
/// too small to tell from zero is `0.0`, as OTP's `binary_to_float/1` and
/// JavaScript's `Number` answer. Computed over big integers by hand:
/// `std.fmt.parseFloat`'s slow path holds a table of slices, a relocation in
/// the module's data (§ The two value representations).
pub fn floatOf(neg: bool, whole: []const u8, fraction: []const u8, exponent: []const u8) ?f64 {
    var e10: i64 = 0;
    {
        var x = exponent;
        var negative = false;
        if (x.len > 0 and (x[0] == '+' or x[0] == '-')) {
            negative = x[0] == '-';
            x = x[1..];
        }
        for (x) |c| e10 = @min(e10 * 10 + (c - '0'), 10_000_000);
        if (negative) e10 = -e10;
    }
    var digits: [float_digits]u8 = undefined;
    var n: usize = 0;
    var sticky = false;
    for (whole) |c| {
        if (n == 0 and c == '0') continue;
        if (n < float_digits) {
            digits[n] = c - '0';
            n += 1;
        } else {
            sticky = sticky or c != '0';
            e10 += 1;
        }
    }
    for (fraction) |c| {
        if (n == 0 and c == '0') {
            e10 -= 1;
            continue;
        }
        if (n < float_digits) {
            digits[n] = c - '0';
            n += 1;
            e10 -= 1;
        } else sticky = sticky or c != '0';
    }
    const sign: f64 = if (neg) -1.0 else 1.0;
    // The value is in [10^(n+e10-1), 10^(n+e10)).
    const magnitude = @as(i64, @intCast(n)) + e10;
    if (n == 0 or magnitude <= -325) return sign * 0.0;
    if (magnitude >= 310) return null;

    var num: [float_limbs]bigint.Limb = undefined;
    var num_len: usize = 0;
    for (digits[0..n]) |d| num_len = mulAddSmall(&num, num_len, 10, d);
    if (e10 >= 0) {
        num_len = mulPow10(&num, num_len, @intCast(e10));
        const t = topBits(num[0..num_len]);
        const v = roundToF64(t.m, t.shift, t.sticky or sticky) orelse return null;
        return sign * v;
    }
    var den: [float_limbs]bigint.Limb = undefined;
    den[0] = 1;
    const den_len = mulPow10(&den, 1, @intCast(-e10));
    // num * 2^s / den, `s` so the quotient has 64 bits at least.
    const nb = bitLength(num[0..num_len]);
    const db = bitLength(den[0..den_len]);
    const s: u64 = if (db + 64 > nb) db + 64 - nb else 0;
    var shifted: [float_limbs]bigint.Limb = undefined;
    const a = shiftLeft(&shifted, num[0..num_len], s);
    var q: [float_limbs]bigint.Limb = undefined;
    var r: [float_limbs + 1]bigint.Limb = undefined;
    const qr = bigint.divMag(&q, &r, a, den[0..den_len]);
    const t = topBits(qr.q);
    const v = roundToF64(t.m, t.shift - @as(i64, @intCast(s)), t.sticky or qr.r.len > 0 or sticky) orelse return null;
    return sign * v;
}

test "isDigits: digits only, one at least" {
    try std.testing.expect(isDigits("0"));
    try std.testing.expect(isDigits("0123456789"));
    try std.testing.expect(!isDigits(""));
    try std.testing.expect(!isDigits("-1"));
    try std.testing.expect(!isDigits("1_0"));
    try std.testing.expect(!isDigits(" 1"));
}

test "integerOf: every i64, nothing past either end" {
    try std.testing.expectEqual(@as(?i64, 42), integerOf("42"));
    try std.testing.expectEqual(@as(?i64, 42), integerOf("+0042"));
    try std.testing.expectEqual(@as(?i64, -7), integerOf("-7"));
    try std.testing.expectEqual(@as(?i64, std.math.maxInt(i64)), integerOf("9223372036854775807"));
    try std.testing.expectEqual(@as(?i64, std.math.minInt(i64)), integerOf("-9223372036854775808"));
    try std.testing.expectEqual(@as(?i64, null), integerOf("9223372036854775808"));
    try std.testing.expectEqual(@as(?i64, null), integerOf("-9223372036854775809"));
    try std.testing.expectEqual(@as(?i64, null), integerOf("99999999999999999999999999"));
    try std.testing.expectEqual(@as(?i64, null), integerOf("1_0"));
    try std.testing.expectEqual(@as(?i64, null), integerOf("-"));
}

test "floatOf: correctly rounded, an overflow refused, an underflow zero" {
    const cases = [_]struct { []const u8, []const u8, []const u8, f64 }{
        .{ "1", "5", "0", 1.5 },
        .{ "2", "5", "-1", 0.25 },
        .{ "0", "1", "0", 0.1 },
        .{ "0", "3", "0", 0.3 },
        .{ "123", "456", "+2", 12345.6 },
        .{ "1", "7976931348623157", "308", 1.7976931348623157e308 },
        .{ "2", "2250738585072014", "-308", 2.2250738585072014e-308 },
        .{ "4", "9406564584124654", "-324", 4.9406564584124654e-324 },
        .{ "2", "4703282292062328", "-324", 4.9406564584124654e-324 },
        .{ "2", "4703282292062327", "-324", 0.0 },
        .{ "9007199254740993", "0", "0", 9007199254740992.0 },
        .{ "9007199254740995", "0", "0", 9007199254740996.0 },
        .{ "1", "0", "-400", 0.0 },
        .{ "0", "0", "0", 0.0 },
        .{ "000", "000123", "3", 0.123 },
    };
    for (cases) |c| try std.testing.expectEqual(@as(?f64, c[3]), floatOf(false, c[0], c[1], c[2]));
    try std.testing.expectEqual(@as(?f64, -1200.0), floatOf(true, "12", "0", "+2"));
    try std.testing.expect(std.math.signbit(floatOf(true, "0", "0", "0").?));
    try std.testing.expectEqual(@as(?f64, null), floatOf(false, "1", "0", "400"));
    try std.testing.expectEqual(@as(?f64, null), floatOf(false, "1", "8", "308"));
    try std.testing.expectEqual(@as(?f64, null), floatOf(false, "1", "0", "99999999999999999999"));
    try std.testing.expectEqual(@as(?f64, 0.0), floatOf(false, "1", "0", "-99999999999999999999"));
}

test "floatOf: every shortest form reads back, and agrees with std.fmt.parseFloat" {
    var prng = std.Random.DefaultPrng.init(0x5eed);
    const rnd = prng.random();
    var buf: [64]u8 = undefined;
    var i: usize = 0;
    while (i < 20_000) : (i += 1) {
        const bits = rnd.int(u64) & 0x7fff_ffff_ffff_ffff;
        const f: f64 = @bitCast(bits);
        if (std.math.isNan(f) or std.math.isInf(f)) continue;
        const text = std.fmt.bufPrint(&buf, "{e}", .{f}) catch unreachable;
        // `D[.DDD]e[-]X`
        const e_at = std.mem.indexOfScalar(u8, text, 'e').?;
        const mant = text[0..e_at];
        const dot = std.mem.indexOfScalar(u8, mant, '.');
        const w = if (dot) |d| mant[0..d] else mant;
        const fr = if (dot) |d| mant[d + 1 ..] else "0";
        try std.testing.expectEqual(@as(?f64, f), floatOf(false, w, fr, text[e_at + 1 ..]));
    }
    // Long numerals near halfway points, against Zig's reader.
    var long: [40]u8 = undefined;
    i = 0;
    while (i < 5_000) : (i += 1) {
        for (&long) |*c| c.* = '0' + rnd.uintLessThan(u8, 10);
        long[0] = '1' + rnd.uintLessThan(u8, 9);
        const ex = rnd.intRangeAtMost(i32, -330, 300);
        var ebuf: [16]u8 = undefined;
        const etext = std.fmt.bufPrint(&ebuf, "{d}", .{ex}) catch unreachable;
        var all: [80]u8 = undefined;
        const joined = std.fmt.bufPrint(&all, "{s}.{s}e{s}", .{ long[0..1], long[1..], etext }) catch unreachable;
        const want = std.fmt.parseFloat(f64, joined) catch unreachable;
        const got = floatOf(false, long[0..1], long[1..], etext);
        if (std.math.isInf(want)) try std.testing.expectEqual(@as(?f64, null), got) else try std.testing.expectEqual(@as(?f64, want), got);
    }
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
