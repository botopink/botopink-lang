/// Tests for `textDocument/codeAction` — covers `engine.codeActions`.
/// Snapshots in: snapshots/lsp/code_action_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

fn freeActions(gpa: std.mem.Allocator, actions: []proto.CodeAction) void {
    for (actions) |a| {
        gpa.free(a.title);
        if (a.edit) |edit| {
            if (edit.documentChanges) |dcs| {
                for (dcs) |dc| {
                    for (dc.edits) |e| gpa.free(e.newText);
                    gpa.free(dc.edits);
                }
                gpa.free(dcs);
            }
        }
    }
    gpa.free(actions);
}

test "codeAction: add type annotation for val" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const range = h.range(0, 0, 0, 11);
    const actions = try engine.codeActions(gpa, h.TEST_URI, source, range, tokens, bindings, null);
    defer freeActions(gpa, actions);

    try std.testing.expect(actions.len >= 1);
    try snap.assertCodeActions(gpa, "code_action_add_type_annotation", source, range, actions);
}

test "codeAction: no action when already annotated" {
    const gpa = std.testing.allocator;
    const source =
        \\val x: i32 = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const range = h.range(0, 0, 0, 16);
    const actions = try engine.codeActions(gpa, h.TEST_URI, source, range, tokens, bindings, null);
    defer freeActions(gpa, actions);

    // Should have no "Add type annotation" since it's already annotated
    for (actions) |a| {
        try std.testing.expect(!std.mem.startsWith(u8, a.title, "Add type annotation"));
    }
    try snap.assertCodeActions(gpa, "code_action_already_annotated", source, range, actions);
}

test "codeAction: no actions on empty source" {
    const gpa = std.testing.allocator;
    const source = "";

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const range = h.range(0, 0, 0, 0);
    const actions = try engine.codeActions(gpa, h.TEST_URI, source, range, tokens, &.{}, null);
    defer freeActions(gpa, actions);

    try std.testing.expectEqual(@as(usize, 0), actions.len);
    try snap.assertCodeActions(gpa, "code_action_empty", source, range, actions);
}
