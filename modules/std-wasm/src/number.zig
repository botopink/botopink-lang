//! Numbers as text: the float formatting std's `Float.toString` answers at
//! comptime (decision 434 (5): one text for the four targets) — OTP's
//! `float_to_binary(F, [short])`: the shortest digits that round-trip,
//! fixed or exponent form, whichever is shorter.
const std = @import("std");

/// `float_to_binary(F, [short])`: the shortest digits that round-trip, written
/// in fixed notation or as `D.DDDeE`, whichever is shorter (fixed on a tie);
/// always one digit after the point at least.
pub fn shortFloat(f: f64, buf: []u8) []const u8 {
    if (f == 0) return if (std.math.signbit(f)) "-0.0" else "0.0";
    var sci: [64]u8 = undefined;
    const e_text = std.fmt.bufPrint(&sci, "{e}", .{f}) catch unreachable;
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
    const et = std.fmt.bufPrint(sbuf[sl..], "e{d}", .{exp}) catch unreachable;
    sl += et.len;

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

test "shortFloat: the shortest form, fixed on a tie" {
    const cases = [_]struct { f64, []const u8 }{
        .{ 0.1, "0.1" },                                     .{ 1.0e21, "1.0e21" },           .{ 1.0e20, "1.0e20" },
        .{ 123.0, "123.0" },                                 .{ 1.0e-5, "1.0e-5" },           .{ 0.0001, "0.0001" },
        .{ 1.0e15, "1.0e15" },                               .{ 123456789.0, "123456789.0" }, .{ 0.30000000000000004, "0.30000000000000004" },
        .{ 1.2345678901234567e19, "1.2345678901234567e19" }, .{ -0.0, "-0.0" },               .{ 2.0e-10, "2.0e-10" },
        .{ 1.5, "1.5" },                                     .{ 100.0, "100.0" },
    };
    for (cases) |c| {
        var buf: [64]u8 = undefined;
        try std.testing.expectEqualStrings(c[1], shortFloat(c[0], &buf));
    }
}
