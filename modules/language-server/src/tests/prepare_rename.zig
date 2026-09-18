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

// ── PR-14 — the keyword list is the lexer's ────────────────────────────────────

// `record`, `enum`, `interface`, `new`, `delegate`, `struct`, `const` and the
// seven dead keywords left `keywordOrIdent`; a binding may be named after any
// of them, and a rename must be offered. The four words the LSP list was
// missing must be refused.

test "prepareRename: a binding named after a removed keyword is renameable" {
    const removed = [_][]const u8{
        "record", "enum",   "interface", "new",    "delegate",
        "struct", "const",  "auto",      "derive", "get",
        "macro",  "opaque", "private",   "set",    "echo",
        "todo",
    };
    var buf: [64]u8 = undefined;
    for (removed) |word| {
        const source = try std.fmt.bufPrint(&buf, "val {s} = 1;\n", .{word});
        // Cursor one char into the name.
        const result = engine.prepareRename(source, h.pos(0, 5));
        try std.testing.expect(result != null);
        try std.testing.expectEqualStrings(word, result.?.placeholder);
    }
}

test "prepareRename: a lexer keyword the list used to miss is refused" {
    // `behavior`, `extend`, `is` and `mod` are keyword tokens; renaming one is
    // never a rename of a binding.
    const keywords = [_][]const u8{ "behavior", "extend", "is", "mod" };
    var buf: [64]u8 = undefined;
    for (keywords) |word| {
        const source = try std.fmt.bufPrint(&buf, "{s} Thing;\n", .{word});
        try std.testing.expect(engine.prepareRename(source, h.pos(0, 1)) == null);
    }
}
