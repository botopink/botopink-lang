//! `bigint` arithmetic (decisions 332, 442 (2)): what `wat_prelude`'s
//! `$__bn_*` answered by hand-written WAT until 144 B-00g. Pure functions over
//! magnitudes — little-endian `u32` limbs, normalised (no zero limb on top, so
//! zero is no limb at all) — each writing into a buffer its caller sizes; the
//! sign travels beside. The limbs are this module's own business: a program
//! holds a `bigint` as the address of a `[L][limb0][limb1]…` block, `L` the
//! limbs' byte count negated for a negative value, and the program face
//! (`wasm.zig`) reads and writes that block, the codegen passing pointers.
const std = @import("std");

pub const Limb = u32;

/// A signed value over borrowed limbs.
pub const Big = struct {
    neg: bool = false,
    limbs: []const Limb = &.{},

    pub fn isZero(b: Big) bool {
        return b.limbs.len == 0;
    }
};

/// `limbs` without its zero limbs on top.
pub fn normalized(limbs: []const Limb) []const Limb {
    var n = limbs.len;
    while (n > 0 and limbs[n - 1] == 0) n -= 1;
    return limbs[0..n];
}

/// `-1` / `0` / `1` as `|a|` is below, equal to or above `|b|`.
pub fn cmpMag(a: []const Limb, b: []const Limb) i32 {
    if (a.len != b.len) return if (a.len > b.len) 1 else -1;
    var i = a.len;
    while (i > 0) {
        i -= 1;
        if (a[i] != b[i]) return if (a[i] > b[i]) 1 else -1;
    }
    return 0;
}

/// `-1` / `0` / `1` as `x` is below, equal to or above `y`.
pub fn cmp(x: Big, y: Big) i32 {
    const xn = x.neg and !x.isZero();
    const yn = y.neg and !y.isZero();
    if (xn != yn) return if (xn) -1 else 1;
    const c = cmpMag(x.limbs, y.limbs);
    return if (xn) -c else c;
}

/// `|a| + |b|` into `out` (`out.len >= max(a.len, b.len) + 1`); the
/// normalised limbs.
pub fn addMag(out: []Limb, a: []const Limb, b: []const Limb) []Limb {
    const long = if (a.len >= b.len) a else b;
    const short = if (a.len >= b.len) b else a;
    var carry: u64 = 0;
    for (long, 0..) |x, i| {
        var s: u64 = @as(u64, x) + carry;
        if (i < short.len) s += short[i];
        out[i] = @truncate(s);
        carry = s >> 32;
    }
    out[long.len] = @truncate(carry);
    return out[0..normalized(out[0 .. long.len + 1]).len];
}

/// `|a| - |b|` where `|a| >= |b|`, into `out` (`out.len >= a.len`).
pub fn subMag(out: []Limb, a: []const Limb, b: []const Limb) []Limb {
    var borrow: u64 = 0;
    for (a, 0..) |x, i| {
        var s: u64 = @as(u64, x) -% borrow;
        if (i < b.len) s -%= b[i];
        out[i] = @truncate(s);
        borrow = s >> 63;
    }
    return out[0..normalized(out[0..a.len]).len];
}

/// `|a| * |b|`, schoolbook, into `out` (`out.len >= a.len + b.len`).
pub fn mulMag(out: []Limb, a: []const Limb, b: []const Limb) []Limb {
    if (a.len == 0 or b.len == 0) return out[0..0];
    @memset(out[0 .. a.len + b.len], 0);
    for (a, 0..) |ai, i| {
        var carry: u64 = 0;
        for (b, 0..) |bj, j| {
            const t: u64 = @as(u64, ai) * bj + out[i + j] + carry;
            out[i + j] = @truncate(t);
            carry = t >> 32;
        }
        out[i + b.len] = @truncate(carry);
    }
    return out[0..normalized(out[0 .. a.len + b.len]).len];
}

/// The limbs `w` divided in place by the word `d` (`d != 0`); the remainder.
pub fn divWord(w: []Limb, d: Limb) Limb {
    var r: u64 = 0;
    var i = w.len;
    while (i > 0) {
        i -= 1;
        const cur = (r << 32) | w[i];
        w[i] = @truncate(cur / d);
        r = cur % d;
    }
    return @truncate(r);
}

/// `|a| / |b|` and `|a| % |b|` (`b` nonzero), truncated: the quotient into
/// `q` (`q.len >= a.len`), the remainder into `r` (`r.len >= b.len + 1`),
/// the bits of `a` shifted in one at a time — quadratic, and the numbers a
/// program writes are short.
pub fn divMag(q: []Limb, r: []Limb, a: []const Limb, b: []const Limb) struct { q: []Limb, r: []Limb } {
    std.debug.assert(b.len > 0);
    if (cmpMag(a, b) < 0) {
        @memcpy(r[0..a.len], a);
        return .{ .q = q[0..0], .r = r[0..a.len] };
    }
    if (b.len == 1) {
        @memcpy(q[0..a.len], a);
        const rem = divWord(q[0..a.len], b[0]);
        r[0] = rem;
        return .{ .q = q[0..normalized(q[0..a.len]).len], .r = r[0..@intFromBool(rem != 0)] };
    }
    const m = b.len;
    @memset(q[0..a.len], 0);
    @memset(r[0 .. m + 1], 0);
    var k: usize = a.len * 32;
    while (k > 0) {
        k -= 1;
        // r = r << 1 | bit k of a
        var cb: Limb = 0;
        for (r[0 .. m + 1]) |*v| {
            const top = v.* >> 31;
            v.* = (v.* << 1) | cb;
            cb = top;
        }
        r[0] |= (a[k >> 5] >> @intCast(k & 31)) & 1;
        if (geWindow(r[0 .. m + 1], b)) {
            _ = subMag(r[0 .. m + 1], r[0 .. m + 1], b);
            q[k >> 5] |= @as(Limb, 1) << @intCast(k & 31);
        }
    }
    return .{ .q = q[0..normalized(q[0..a.len]).len], .r = r[0..normalized(r[0 .. m + 1]).len] };
}

/// Whether the `m + 1` limbs of `r` hold at least the `m` limbs of `b`.
fn geWindow(r: []const Limb, b: []const Limb) bool {
    if (r[b.len] != 0) return true;
    var i = b.len;
    while (i > 0) {
        i -= 1;
        if (r[i] != b[i]) return r[i] > b[i];
    }
    return true;
}

/// The magnitude of the `i64` `v` into `out` (`out.len >= 2`).
pub fn ofI64(out: []Limb, v: i64) Big {
    const m = @abs(v);
    out[0] = @truncate(m);
    out[1] = @truncate(m >> 32);
    return .{ .neg = v < 0, .limbs = normalized(out[0..2]) };
}

/// The `i64` equal to `x`, or null past −2^63 … 2^63 − 1 (`toI64()`).
pub fn toI64(x: Big) ?i64 {
    if (x.limbs.len > 2) return null;
    var m: u64 = 0;
    if (x.limbs.len > 0) m = x.limbs[0];
    if (x.limbs.len > 1) m |= @as(u64, x.limbs[1]) << 32;
    if (x.neg) {
        if (m > @as(u64, 1) << 63) return null;
        return @bitCast(0 -% m);
    }
    if (m >> 63 != 0) return null;
    return @intCast(m);
}

/// The `f64` equal to `x`, or null when no `f64` holds it exactly
/// (`toF64()`): more than 53 significant bits, or past 2^1024.
pub fn toF64(x: Big) ?f64 {
    const n = x.limbs.len;
    if (n == 0) return 0;
    const bits: usize = (n - 1) * 32 + (32 - @clz(x.limbs[n - 1]));
    var z: usize = 0;
    while (x.limbs[z] == 0) z += 1;
    const tz: usize = z * 32 + @ctz(x.limbs[z]);
    if (bits - tz > 53 or bits > 1024) return null;
    // The significant bits, shifted down to bit 0: at most 53, so they span
    // at most three limbs from `w`.
    const w = tz >> 5;
    const s: u6 = @intCast(tz & 31);
    var v: u64 = x.limbs[w];
    if (w + 1 < n) v |= @as(u64, x.limbs[w + 1]) << 32;
    v >>= s;
    if (s != 0 and w + 2 < n) v |= @as(u64, x.limbs[w + 2]) << @intCast(64 - @as(u7, s));
    const f = std.math.ldexp(@as(f64, @floatFromInt(v)), @intCast(tz));
    return if (x.neg) -f else f;
}

/// How many bytes `toDecimal` may write for `limbs` (a sign and every digit).
pub fn decimalCapacity(limbs: []const Limb) usize {
    return limbs.len * 10 + 2;
}

/// `x`'s decimal text into `out` (`decimalCapacity`), a `-` first when
/// negative; `scratch.len >= x.limbs.len` holds the dividend. Answers the text.
pub fn toDecimal(out: []u8, scratch: []Limb, x: Big) []const u8 {
    if (x.isZero()) {
        out[0] = '0';
        return out[0..1];
    }
    var w = scratch[0..x.limbs.len];
    @memcpy(w, x.limbs);
    // Digits written backwards from the end, nine at a time.
    var pos = out.len;
    while (true) {
        var chunk = divWord(w, 1_000_000_000);
        w = w[0..normalized(w).len];
        if (w.len == 0) {
            while (chunk != 0) : (chunk /= 10) {
                pos -= 1;
                out[pos] = @intCast('0' + chunk % 10);
            }
            break;
        }
        for (0..9) |_| {
            pos -= 1;
            out[pos] = @intCast('0' + chunk % 10);
            chunk /= 10;
        }
    }
    if (x.neg) {
        pos -= 1;
        out[pos] = '-';
    }
    const len = out.len - pos;
    std.mem.copyForwards(u8, out[0..len], out[pos..]);
    return out[0..len];
}

/// How many limbs `fromDecimal` may need for `text`.
pub fn decimalLimbs(text: []const u8) usize {
    return text.len / 8 + 2;
}

/// The value a decimal numeral spells — an optional `+` or `-`, then one or
/// more digits and nothing else — into `out` (`decimalLimbs`), or null for
/// any other text.
pub fn fromDecimal(out: []Limb, text: []const u8) ?Big {
    if (text.len == 0) return null;
    var i: usize = 0;
    var neg = false;
    if (text[0] == '-' or text[0] == '+') {
        neg = text[0] == '-';
        i = 1;
    }
    if (i >= text.len) return null;
    for (text[i..]) |c| if (c < '0' or c > '9') return null;
    var n: usize = 0;
    for (text[i..]) |c| {
        var carry: u64 = c - '0';
        for (out[0..n]) |*l| {
            const t = @as(u64, l.*) * 10 + carry;
            l.* = @truncate(t);
            carry = t >> 32;
        }
        if (carry != 0) {
            out[n] = @truncate(carry);
            n += 1;
        }
    }
    return .{ .neg = neg, .limbs = out[0..n] };
}

// ── tests: each operation against `std.math.big.int`, the reference ─────────

const Managed = std.math.big.int.Managed;

/// `x` built in the reference from its limbs alone (`m = m·2^32 + limb`,
/// from the top), never through this module's text.
fn reference(gpa: std.mem.Allocator, x: Big) !Managed {
    var m = try Managed.init(gpa);
    errdefer m.deinit();
    var i = x.limbs.len;
    while (i > 0) {
        i -= 1;
        try m.shiftLeft(&m, 32);
        try m.addScalar(&m, x.limbs[i]);
    }
    if (x.neg) m.negate();
    return m;
}

fn expectSame(gpa: std.mem.Allocator, want: Managed, got: Big) !void {
    const w = try want.toString(gpa, 10, .lower);
    defer gpa.free(w);
    var text_buf: [2048]u8 = undefined;
    var scratch: [256]Limb = undefined;
    try std.testing.expectEqualStrings(w, toDecimal(&text_buf, &scratch, got));
}

/// A pseudo-random value of up to `max_limbs` limbs, every carry pattern
/// likely: limbs drawn from the edges (`0`, `1`, `0xFFFFFFFF`) and anywhere.
fn draw(rng: std.Random, buf: []Limb, max_limbs: usize) Big {
    const n = rng.uintAtMost(usize, max_limbs);
    for (buf[0..n]) |*l| l.* = switch (rng.uintLessThan(u8, 4)) {
        0 => 0,
        1 => 0xFFFF_FFFF,
        2 => rng.uintAtMost(Limb, 3),
        else => rng.int(Limb),
    };
    return .{ .neg = rng.boolean(), .limbs = normalized(buf[0..n]) };
}

/// `x + y` (signed) through the magnitudes, as the program face composes it.
fn addSigned(out: []Limb, x: Big, y: Big) Big {
    if (x.neg == y.neg) return .{ .neg = x.neg, .limbs = addMag(out, x.limbs, y.limbs) };
    if (cmpMag(x.limbs, y.limbs) >= 0) return .{ .neg = x.neg, .limbs = subMag(out, x.limbs, y.limbs) };
    return .{ .neg = y.neg, .limbs = subMag(out, y.limbs, x.limbs) };
}

test "property: add, sub, mul, divmod and compare agree with std.math.big" {
    const gpa = std.testing.allocator;
    var prng = std.Random.DefaultPrng.init(0x5eed_b16);
    const rng = prng.random();
    var xb: [12]Limb = undefined;
    var yb: [12]Limb = undefined;
    var out: [32]Limb = undefined;
    var rb: [32]Limb = undefined;
    for (0..3000) |_| {
        const x = draw(rng, &xb, 6);
        const y = draw(rng, &yb, 6);
        var rx = try reference(gpa, x);
        defer rx.deinit();
        var ry = try reference(gpa, y);
        defer ry.deinit();
        var want = try Managed.init(gpa);
        defer want.deinit();

        try want.add(&rx, &ry);
        try expectSame(gpa, want, addSigned(&out, x, y));

        try want.mul(&rx, &ry);
        try expectSame(gpa, want, .{ .neg = x.neg != y.neg, .limbs = mulMag(&out, x.limbs, y.limbs) });

        try std.testing.expectEqual(@as(i32, switch (rx.order(ry)) {
            .lt => -1,
            .eq => 0,
            .gt => 1,
        }), cmp(x, y));

        if (!y.isZero()) {
            var wq = try Managed.init(gpa);
            defer wq.deinit();
            var wr = try Managed.init(gpa);
            defer wr.deinit();
            try wq.divTrunc(&wr, &rx, &ry);
            const d = divMag(&out, &rb, x.limbs, y.limbs);
            try expectSame(gpa, wq, .{ .neg = x.neg != y.neg, .limbs = d.q });
            try expectSame(gpa, wr, .{ .neg = x.neg, .limbs = d.r });
        }
    }
}

test "property: decimal text round-trips, and agrees with std.math.big" {
    const gpa = std.testing.allocator;
    var prng = std.Random.DefaultPrng.init(0xdec1_3a1);
    const rng = prng.random();
    var xb: [16]Limb = undefined;
    var back: [64]Limb = undefined;
    for (0..2000) |_| {
        const x = draw(rng, &xb, 12);
        var text_buf: [2048]u8 = undefined;
        var scratch: [64]Limb = undefined;
        const text = toDecimal(&text_buf, &scratch, x);
        var rx = try reference(gpa, x);
        defer rx.deinit();
        try expectSame(gpa, rx, x);
        const again = fromDecimal(&back, text).?;
        try std.testing.expectEqual(@as(i32, 0), cmp(x, again));
    }
}

test "carry across every limb, and a borrow down through them" {
    var out: [8]Limb = undefined;
    const ones = [_]Limb{ 0xFFFF_FFFF, 0xFFFF_FFFF, 0xFFFF_FFFF };
    try std.testing.expectEqualSlices(Limb, &.{ 0, 0, 0, 1 }, addMag(&out, &ones, &.{1}));
    try std.testing.expectEqualSlices(Limb, &ones, subMag(&out, &.{ 0, 0, 0, 1 }, &.{1}));
    try std.testing.expectEqualSlices(Limb, &.{}, subMag(&out, &ones, &ones));
}

test "divmod: by one limb, by many, a smaller dividend, signs truncated" {
    var q: [8]Limb = undefined;
    var r: [8]Limb = undefined;
    const d1 = divMag(&q, &r, &.{ 0, 1 }, &.{10}); // 2^32 / 10
    try std.testing.expectEqualSlices(Limb, &.{429496729}, d1.q);
    try std.testing.expectEqualSlices(Limb, &.{6}, d1.r);
    const d2 = divMag(&q, &r, &.{ 5, 0, 1 }, &.{ 0, 1 }); // (2^64 + 5) / 2^32
    try std.testing.expectEqualSlices(Limb, &.{ 0, 1 }, d2.q);
    try std.testing.expectEqualSlices(Limb, &.{5}, d2.r);
    const d3 = divMag(&q, &r, &.{3}, &.{ 0, 1 });
    try std.testing.expectEqual(@as(usize, 0), d3.q.len);
    try std.testing.expectEqualSlices(Limb, &.{3}, d3.r);
}

test "toI64 and toF64: the edges, and what does not fit" {
    var b: [2]Limb = undefined;
    try std.testing.expectEqual(@as(?i64, std.math.minInt(i64)), toI64(ofI64(&b, std.math.minInt(i64))));
    try std.testing.expectEqual(@as(?i64, std.math.maxInt(i64)), toI64(ofI64(&b, std.math.maxInt(i64))));
    try std.testing.expectEqual(@as(?i64, null), toI64(.{ .limbs = &.{ 0, 0x8000_0000 } }));
    try std.testing.expectEqual(@as(?i64, null), toI64(.{ .limbs = &.{ 0, 0, 1 } }));
    try std.testing.expectEqual(@as(?f64, 0), toF64(.{}));
    try std.testing.expectEqual(@as(?f64, -18446744073709551616.0), toF64(.{ .neg = true, .limbs = &.{ 0, 0, 1 } }));
    try std.testing.expectEqual(@as(?f64, 9007199254740992.0), toF64(.{ .limbs = &.{ 0, 0x20_0000 } }));
    try std.testing.expectEqual(@as(?f64, null), toF64(.{ .limbs = &.{ 1, 0x20_0000 } }));
    try std.testing.expectEqual(@as(?f64, 3.0 * 4294967296.0 * 4294967296.0 * 0.5), toF64(.{ .limbs = &.{ 0, 0x8000_0000, 1 } }));
}

test "fromDecimal: a sign, digits, nothing else" {
    var b: [8]Limb = undefined;
    try std.testing.expect(fromDecimal(&b, "") == null);
    try std.testing.expect(fromDecimal(&b, "-") == null);
    try std.testing.expect(fromDecimal(&b, "1x") == null);
    try std.testing.expect(fromDecimal(&b, " 1") == null);
    const z = fromDecimal(&b, "-000").?;
    try std.testing.expect(z.isZero());
    const v = fromDecimal(&b, "+4294967296").?;
    try std.testing.expectEqualSlices(Limb, &.{ 0, 1 }, v.limbs);
}
