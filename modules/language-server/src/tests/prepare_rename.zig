/// Tests for `textDocument/prepareRename` — covers `engine.prepareRename`.
/// Snapshots in: snapshots/lsp/prepare_rename_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

test "prepareRename: identifier is renameable" {
    const gpa = std.testing.allocator;
    const source =
        \\val greeting = "hello";
    ;

    const cursor = h.pos(0, 6);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("greeting", result.?.placeholder);
    try snap.assertPrepareRename(gpa, "prepare_rename_identifier", source, cursor, result);
}

test "prepareRename: keyword is not renameable" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
    ;

    const cursor = h.pos(0, 1);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result == null);
    try snap.assertPrepareRename(gpa, "prepare_rename_keyword_val", source, cursor, result);
}

test "prepareRename: fn keyword rejected" {
    const gpa = std.testing.allocator;
    const source =
        \\fn hello() { return 1; }
    ;

    const cursor = h.pos(0, 1);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result == null);
    try snap.assertPrepareRename(gpa, "prepare_rename_keyword_fn", source, cursor, result);
}

test "prepareRename: null literal rejected" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = null;
    ;

    const cursor = h.pos(0, 9);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result == null);
    try snap.assertPrepareRename(gpa, "prepare_rename_null_literal", source, cursor, result);
}

test "prepareRename: Self rejected" {
    const gpa = std.testing.allocator;
    const source =
        \\fn method(self: Self) { return 0; }
    ;

    const cursor = h.pos(0, 17);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result == null);
    try snap.assertPrepareRename(gpa, "prepare_rename_self_type", source, cursor, result);
}

test "prepareRename: fn name is renameable" {
    const gpa = std.testing.allocator;
    const source =
        \\fn double(x: i32) -> i32 { return x * 2; }
    ;

    const cursor = h.pos(0, 4);
    const result = engine.prepareRename(source, cursor);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("double", result.?.placeholder);
    try snap.assertPrepareRename(gpa, "prepare_rename_fn_name", source, cursor, result);
}
