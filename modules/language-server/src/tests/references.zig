/// Find references tests — covers `engine.references`.
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── R1 — includes declaration ──

test "references: include_declaration=true returns decl + usages" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
        \\val z = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // cursor on declaration 'x' line 0, col 4
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // declaration + 2 usages = 3
    try std.testing.expectEqual(@as(usize, 3), locs.len);
    try snap.assertReferences(gpa, "references_include_decl", source, cursor, locs);
}

// ── R2 — excludes declaration ──

test "references: include_declaration=false returns only usages" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
        \\val z = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, false);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // only 2 usages (no declaration)
    try std.testing.expectEqual(@as(usize, 2), locs.len);
    try snap.assertReferences(gpa, "references_exclude_decl", source, cursor, locs);
}

// ── R3 — unused symbol ──

test "references: unused binding has no references" {
    const gpa = std.testing.allocator;
    const source =
        \\val unused = 1;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // col 4 = 'unused'
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, false);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try std.testing.expectEqual(@as(usize, 0), locs.len);
    try snap.assertReferences(gpa, "references_unused", source, cursor, locs);
}

// ── R4 — cursor on non-identifier ──

test "references: cursor on literal returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // col 8 = '4' em '42'
    const cursor = h.pos(0, 8);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try snap.assertReferences(gpa, "references_literal", source, cursor, locs);
}

// ── R5 — ranges corretos ──────────────────────────────────────────────────────
//
// No snapshot: this source is `references_include_decl`'s with one usage fewer,
// and its rendered output was a strict subset of that file's. What is left here
// is the part a snapshot cannot state — that *every* returned range covers
// exactly the identifier token, end included — so it is asserted in full below.

test "references: returned ranges match token positions" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const locs = try engine.references(gpa, h.TEST_URI, source, h.pos(0, 4), tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // Declaration (0,4)–(0,5) and usage (1,8)–(1,9); `x` is one char wide, so a
    // range that is off by one in either direction is caught here.
    try std.testing.expectEqual(@as(usize, 2), locs.len);
    const want = [_]proto.Range{
        .{ .start = .{ .line = 0, .character = 4 }, .end = .{ .line = 0, .character = 5 } },
        .{ .start = .{ .line = 1, .character = 8 }, .end = .{ .line = 1, .character = 9 } },
    };
    for (want, 0..) |w, i| {
        try std.testing.expectEqual(w.start.line, locs[i].range.start.line);
        try std.testing.expectEqual(w.start.character, locs[i].range.start.character);
        try std.testing.expectEqual(w.end.line, locs[i].range.end.line);
        try std.testing.expectEqual(w.end.character, locs[i].range.end.character);
    }
}

// ── R6 — fn references ──

test "references: fn references across multiple usages" {
    const gpa = std.testing.allocator;
    const source =
        \\fn id(a: i32) { return a; }
        \\val r1 = id(1);
        \\val r2 = id(2);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'id' na col 3, linha 0
    const cursor = h.pos(0, 3);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try snap.assertReferences(gpa, "references_fn_usages", source, cursor, locs);
}
