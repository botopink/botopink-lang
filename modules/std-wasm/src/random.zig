//! `io/random`'s seeded stream (decision 451): Mulberry32 over one word of
//! state, as the commonJS sidecar draws it (`libs/std/src/sidecars/random.mjs`)
//! — the same `seed` gives the same draws on wasm, commonJS and at comptime.
//!
//! The stream holds no entropy of its own: a draw before any `seed` answers
//! null, and the caller decides what an unseeded draw is — the program's face
//! (`wasm.zig`) asks the host (`env.bp_random_f64`, the program's
//! `$__wasi_random_f64`), the comptime face (`term_faces.zig`) refuses it, because a
//! build has no entropy (451 (3)).
const std = @import("std");

/// The refusal of a draw before any `seed` at build (decisions 451 (3), 456,
/// 1063 (2)): the one text, raised by the comptime face and the comptime host.
pub const unseeded_text = "an unseeded draw: a build has no entropy, call `random.seed` first";

pub const Stream = struct {
    state: u32 = 0,
    seeded: bool = false,

    /// `seed(s)`: the stream restarts from `s`'s bits.
    pub fn seed(st: *Stream, s: i32) void {
        st.state = @bitCast(s);
        st.seeded = true;
    }

    /// The next draw in `[0.0, 1.0)`, or null before any `seed`.
    pub fn next(st: *Stream) ?f64 {
        if (!st.seeded) return null;
        st.state +%= 0x6D2B79F5;
        var t = st.state;
        t = (t ^ (t >> 15)) *% (t | 1);
        t ^= t +% ((t ^ (t >> 7)) *% (t | 61));
        const r = t ^ (t >> 14);
        return @as(f64, @floatFromInt(r)) / 4294967296.0;
    }
};

test "Stream: no draw before a seed" {
    var s: Stream = .{};
    try std.testing.expect(s.next() == null);
}

test "Stream: the sidecar's Mulberry32 draws, bit for bit" {
    // node: the sidecar's `seed(42)` then three `seededFloat()`, and `seed(-7)`.
    var s: Stream = .{};
    s.seed(42);
    try std.testing.expectEqual(@as(f64, 0.6011037519201636), s.next().?);
    try std.testing.expectEqual(@as(f64, 0.44829055899754167), s.next().?);
    try std.testing.expectEqual(@as(f64, 0.8524657934904099), s.next().?);
    s.seed(-7);
    try std.testing.expectEqual(@as(f64, 0.43306733411736786), s.next().?);
}

test "Stream: the same seed restarts the same stream" {
    var s: Stream = .{};
    s.seed(9);
    const a = s.next().?;
    const b = s.next().?;
    s.seed(9);
    try std.testing.expectEqual(a, s.next().?);
    try std.testing.expectEqual(b, s.next().?);
    try std.testing.expect(a >= 0.0 and a < 1.0);
}
