//! What a body marker admits — decisions 553 (1), (4) and 573.
//!
//! A body writes `await`, `yield` or `use` only under the marker that admits
//! it, never by its return type alone:
//!
//!     async        await
//!     iter         yield
//!     async iter   yield · await
//!     component    use · await
//!
//! `Result` takes no marker and admits none of the three: `throw` / `try`
//! follow the fallible channel (decision 121), which the checker reads off
//! the return type (`comptime/infer.zig` `fallibleErrorOf`). An unmarked body
//! is an ordinary function (decision 570) and admits nothing. Every legality
//! check asks `grants`, and a refusal names the markers that would admit the
//! keyword (`refusal`).

const std = @import("std");
const ast = @import("../ast.zig");

/// A body operation whose legality the marker decides. `throw` / `try` are
/// not here: they follow the fallible channel, not the marker (decision 121).
pub const Capability = enum {
    await_,
    use_,
    yield_,

    /// How the capability is written in source — what a diagnostic quotes.
    pub fn spelling(self: Capability) []const u8 {
        return switch (self) {
            .await_ => "await",
            .use_ => "use",
            .yield_ => "yield",
        };
    }
};

/// True when a body marked `eff` may write `cap`. An unmarked body (null, or
/// `Result`, which takes no marker) admits nothing.
pub fn grants(eff: ?ast.EffectKind, cap: Capability) bool {
    const e = eff orelse return false;
    return switch (cap) {
        .await_ => e == .task or e == .stream or e == .component,
        .yield_ => e == .iterator or e == .stream,
        .use_ => e == .component,
    };
}

/// The markers that admit `cap`, spelled — "`async`, `async iter` or
/// `component`".
pub fn grantingMarkersSpelled(arena: std.mem.Allocator, cap: Capability) ![]const u8 {
    var names: std.ArrayListUnmanaged(u8) = .empty;
    var granting: [ast.EffectKind.all.len]ast.EffectKind = undefined;
    var n: usize = 0;
    for (ast.EffectKind.all) |e| {
        if (!grants(e, cap)) continue;
        granting[n] = e;
        n += 1;
    }
    for (granting[0..n], 0..) |e, i| {
        if (i > 0) try names.appendSlice(arena, if (i + 1 == n) " or " else ", ");
        try names.print(arena, "`{s}`", .{e.markerWord()});
    }
    return names.items;
}

/// The refusal for `cap` written in a body marked `eff` (null: no marker).
/// Decision 573 — named after the marker, located, naming the markers that
/// admit it.
pub fn refusal(arena: std.mem.Allocator, code: []const u8, cap: Capability, eff: ?ast.EffectKind) ![]const u8 {
    const names = try grantingMarkersSpelled(arena, cap);
    const marker: ?ast.EffectKind = if (eff) |e| (if (e == .result) null else e) else null;
    const body: []const u8 = if (marker) |e|
        try std.fmt.allocPrint(arena, "this body is marked `{s}`", .{e.markerWord()})
    else
        "this body carries no marker";
    return std.fmt.allocPrint(arena, "{s}: `{s}` needs a body marked {s} — {s}", .{ code, cap.spelling(), names, body });
}

test "body markers: what each marker admits" {
    // `async` — await.
    try std.testing.expect(grants(.task, .await_));
    try std.testing.expect(!grants(.task, .use_));
    try std.testing.expect(!grants(.task, .yield_));
    // `component` — use · await.
    try std.testing.expect(grants(.component, .await_));
    try std.testing.expect(grants(.component, .use_));
    try std.testing.expect(!grants(.component, .yield_));
    // `iter` — yield, and nothing else (`iter-await`).
    try std.testing.expect(!grants(.iterator, .await_));
    try std.testing.expect(!grants(.iterator, .use_));
    try std.testing.expect(grants(.iterator, .yield_));
    // `async iter` — yield · await.
    try std.testing.expect(grants(.stream, .await_));
    try std.testing.expect(!grants(.stream, .use_));
    try std.testing.expect(grants(.stream, .yield_));
    // `Result` takes no marker, and an unmarked body admits nothing.
    for ([_]?ast.EffectKind{ .result, null }) |e| {
        try std.testing.expect(!grants(e, .await_));
        try std.testing.expect(!grants(e, .use_));
        try std.testing.expect(!grants(e, .yield_));
    }
}

test "body markers: a refusal names the markers that admit the keyword" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try std.testing.expectEqualStrings(
        "await-without-async: `await` needs a body marked `async`, `async iter` or `component` — this body carries no marker",
        try refusal(arena, "await-without-async", .await_, null),
    );
    try std.testing.expectEqualStrings(
        "yield-without-iter: `yield` needs a body marked `iter` or `async iter` — this body is marked `async`",
        try refusal(arena, "yield-without-iter", .yield_, .task),
    );
}
