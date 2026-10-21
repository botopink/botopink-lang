//! The array algorithms behind std's `Array` methods on a `--target wasm`
//! program (decision 442 (2)): what `wat_prelude` answered by hand-written
//! WAT until 144 B-00g. Pure functions over an array's slots — each slot one
//! 32-bit word, as the codegen lays an array out (`[n][e0][e1]…`; a float is
//! the address of its 8-byte cell, a string the address of its text) — no
//! layout of their own, no allocation: the program face (`wasm.zig`) reads
//! and allocates.
const std = @import("std");

/// The slots `xs.slice(a, b)` keeps, with the host's bounds: a negative
/// bound counts from the end, both clamp to `0..n`, a reversed range is
/// empty.
pub const Range = struct { from: usize, len: usize };

pub fn sliceRange(n: usize, a: i32, b: i32) Range {
    const len: i64 = @intCast(n);
    const from = clampBound(a, len);
    const to = clampBound(b, len);
    return .{ .from = @intCast(from), .len = @intCast(@max(to - from, 0)) };
}

fn clampBound(x: i32, len: i64) i64 {
    if (x < 0) return @max(len + x, 0);
    return @min(@as(i64, x), len);
}

/// How many chunks `xs.chunked(m)` answers: `ceil(n / m)`, none for `m <= 0`.
pub fn chunkCount(n: usize, m: i32) usize {
    if (m <= 0) return 0;
    const k: usize = @intCast(m);
    return n / k + @intFromBool(n % k != 0);
}

/// How many windows `xs.sliding(m)` answers: `n - m + 1`, none for `m <= 0`
/// or `m > n`.
pub fn slidingCount(n: usize, m: i32) usize {
    if (m <= 0) return 0;
    const cnt = @as(i64, @intCast(n)) - m + 1;
    return @intCast(@max(cnt, 0));
}

/// `xs.unique()` into `out` (`out.len >= xs.len`): each slot kept at its first
/// occurrence, in order, by `eq` (decision 217); answers how many it kept.
pub fn uniqueInto(out: []u32, xs: []const u32, ctx: anytype, comptime eq: fn (@TypeOf(ctx), u32, u32) bool) usize {
    var k: usize = 0;
    for (xs) |x| {
        const seen = for (out[0..k]) |y| {
            if (eq(ctx, x, y)) break true;
        } else false;
        if (!seen) {
            out[k] = x;
            k += 1;
        }
    }
    return k;
}

/// The first slot `pred` holds for, from the front (`last` false) or the
/// back; `-1` for none — `indexOf` / `lastIndexOf`.
pub fn search(xs: []const u32, last: bool, ctx: anytype, comptime pred: fn (@TypeOf(ctx), u32) bool) i32 {
    if (last) {
        var i = xs.len;
        while (i > 0) {
            i -= 1;
            if (pred(ctx, xs[i])) return @intCast(i);
        }
        return -1;
    }
    for (xs, 0..) |x, i| if (pred(ctx, x)) return @intCast(i);
    return -1;
}

test "sliceRange: negative from the end, clamped, reversed empty" {
    try std.testing.expectEqual(Range{ .from = 1, .len = 2 }, sliceRange(5, 1, 3));
    try std.testing.expectEqual(Range{ .from = 3, .len = 2 }, sliceRange(5, -2, std.math.maxInt(i32)));
    try std.testing.expectEqual(Range{ .from = 0, .len = 5 }, sliceRange(5, -9, 9));
    try std.testing.expectEqual(Range{ .from = 4, .len = 0 }, sliceRange(5, 4, 2));
    try std.testing.expectEqual(Range{ .from = 0, .len = 0 }, sliceRange(0, 0, 3));
}

test "chunkCount and slidingCount" {
    try std.testing.expectEqual(@as(usize, 3), chunkCount(5, 2));
    try std.testing.expectEqual(@as(usize, 2), chunkCount(4, 2));
    try std.testing.expectEqual(@as(usize, 0), chunkCount(4, 0));
    try std.testing.expectEqual(@as(usize, 0), chunkCount(0, 3));
    try std.testing.expectEqual(@as(usize, 4), slidingCount(5, 2));
    try std.testing.expectEqual(@as(usize, 0), slidingCount(2, 3));
    try std.testing.expectEqual(@as(usize, 0), slidingCount(2, -1));
}

fn wordEq(_: void, a: u32, b: u32) bool {
    return a == b;
}

test "uniqueInto: first occurrences, in order" {
    var out: [8]u32 = undefined;
    const n = uniqueInto(&out, &.{ 3, 1, 3, 2, 1 }, {}, wordEq);
    try std.testing.expectEqualSlices(u32, &.{ 3, 1, 2 }, out[0..n]);
    try std.testing.expectEqual(@as(usize, 0), uniqueInto(&out, &.{}, {}, wordEq));
}

fn isTwo(_: void, a: u32) bool {
    return a == 2;
}

test "search: from either end, -1 for none" {
    try std.testing.expectEqual(@as(i32, 1), search(&.{ 1, 2, 2 }, false, {}, isTwo));
    try std.testing.expectEqual(@as(i32, 2), search(&.{ 1, 2, 2 }, true, {}, isTwo));
    try std.testing.expectEqual(@as(i32, -1), search(&.{ 1, 3 }, true, {}, isTwo));
}
