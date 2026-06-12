/// Tests for `textDocument/foldingRange` — covers `engine.foldingRanges`.
/// Snapshots in: snapshots/lsp/folding_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

test "foldingRange: fn block" {
    const gpa = std.testing.allocator;
    const source =
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try std.testing.expect(ranges.len >= 1);
    try snap.assertFoldingRanges(gpa, "folding_fn_block", source, ranges);
}

test "foldingRange: enum block" {
    const gpa = std.testing.allocator;
    const source =
        \\enum Color {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try std.testing.expect(ranges.len >= 1);
    try snap.assertFoldingRanges(gpa, "folding_enum_block", source, ranges);
}

test "foldingRange: consecutive use imports" {
    const gpa = std.testing.allocator;
    const source =
        \\import { foo } from "a";
        \\import { bar } from "b";
        \\import { baz } from "c";
        \\val x = 1;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try snap.assertFoldingRanges(gpa, "folding_use_imports", source, ranges);
}

test "foldingRange: struct with methods" {
    const gpa = std.testing.allocator;
    const source =
        \\struct Counter {
        \\    _count: i32 = 0,
        \\    fn increment(self: Self) {
        \\        self._count += 1;
        \\    }
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try std.testing.expect(ranges.len >= 1);
    try snap.assertFoldingRanges(gpa, "folding_struct_methods", source, ranges);
}

test "foldingRange: empty source" {
    const gpa = std.testing.allocator;
    const source = "";

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try std.testing.expectEqual(@as(usize, 0), ranges.len);
    try snap.assertFoldingRanges(gpa, "folding_empty", source, ranges);
}

test "foldingRange: test block" {
    const gpa = std.testing.allocator;
    const source =
        \\test "adds" {
        \\    assert 1 + 1 == 2, "math";
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const ranges = try engine.foldingRanges(gpa, source, tokens);
    defer gpa.free(ranges);

    try std.testing.expect(ranges.len >= 1);
    try std.testing.expectEqual(@as(u32, 0), ranges[0].startLine);
    try std.testing.expectEqual(@as(u32, 2), ranges[0].endLine);
    try snap.assertFoldingRanges(gpa, "folding_test_block", source, ranges);
}
