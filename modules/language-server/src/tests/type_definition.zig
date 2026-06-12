/// Tests for `textDocument/typeDefinition` — covers `engine.typeDefinition`.
/// Snapshots in: snapshots/lsp/type_definition_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

test "typeDefinition: val of named type" {
    const gpa = std.testing.allocator;
    const source =
        \\record Point { x: i32, y: i32 }
        \\val p = Point(1, 2);
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const cursor = h.pos(1, 5);
    const result = try engine.typeDefinition(gpa, h.TEST_URI, source, cursor, tokens, bindings);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertTypeDefinition(gpa, "type_definition_record_val", source, cursor, result);
}

test "typeDefinition: literal returns null" {
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

    const cursor = h.pos(0, 9);
    const result = try engine.typeDefinition(gpa, h.TEST_URI, source, cursor, tokens, bindings);

    try std.testing.expect(result == null);
    try snap.assertTypeDefinition(gpa, "type_definition_literal_null", source, cursor, result);
}

// A generic (Array<i32>) binding — beyond the named-record / literal cases. The
// element type is a builtin, so there is no user declaration to jump to; this
// pins that typeDefinition stays well-behaved (no crash, captured result).
test "typeDefinition: generic array binding" {
    const gpa = std.testing.allocator;
    const source =
        \\val xs = [1, 2, 3];
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const cursor = h.pos(0, 4); // on `xs`
    const result = try engine.typeDefinition(gpa, h.TEST_URI, source, cursor, tokens, bindings);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertTypeDefinition(gpa, "type_definition_generic_array", source, cursor, result);
}
