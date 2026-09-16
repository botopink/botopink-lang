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

    // (1,4) is on `p` itself — `val p` is v0 a1 l2 ␠3 p4, so (1,5) is the space
    // after the name and resolves to nothing. The success case is the point of
    // this test, so the cursor sits on the identifier.
    const cursor = h.pos(1, 4);
    const result = try engine.typeDefinition(gpa, h.TEST_URI, source, cursor, tokens, bindings);
    defer if (result) |loc| gpa.free(loc.uri);

    const loc = result orelse return error.NoTypeDefinition;
    // → `record Point` on line 0, chars 7–12.
    try std.testing.expectEqualStrings(h.TEST_URI, loc.uri);
    try std.testing.expectEqual(@as(u32, 0), loc.range.start.line);
    try std.testing.expectEqual(@as(u32, 7), loc.range.start.character);
    try std.testing.expectEqual(@as(u32, 12), loc.range.end.character);

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

// A generic (`Array<i32>`) binding — beyond the named-record / literal cases.
//
// Intended behaviour **today**: null. `typeDefinition` resolves a *named* type
// to its declaration in the document; `Array<i32>` has no user declaration, and
// the server does not (yet) redirect builtin receivers to the embedded
// `interface Array<T>` in `primitives.bp` the way go-to-definition does for a
// builtin *method*. The assertion below pins that decision rather than leaving
// the result unchecked — when the redirect lands, this test must change to
// expect the primitives location.
test "typeDefinition: generic array binding resolves to nothing (documented gap)" {
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

    try std.testing.expect(result == null);
    try snap.assertTypeDefinition(gpa, "type_definition_generic_array", source, cursor, result);
}
