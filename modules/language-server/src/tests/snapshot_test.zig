/// Unit tests for snapshot.zig helpers.
const std = @import("std");
const proto = @import("../protocol.zig");
const snapshot = @import("snapshot.zig");

test "appendSourceWithCursor - cursor in middle of line" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;";
    const cursor = proto.Position{ .line = 0, .character = 6 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\      ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor at end of line" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;";
    const cursor = proto.Position{ .line = 0, .character = 11 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\           ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor beyond line length" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;";
    const cursor = proto.Position{ .line = 0, .character = 15 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\                ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor on last line without trailing newline" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;\nval y = 10;";
    const cursor = proto.Position{ .line = 1, .character = 6 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\val y = 10;
        \\      ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor on last line with trailing newline" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;\nval y = 10;\n";
    const cursor = proto.Position{ .line = 1, .character = 6 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\val y = 10;
        \\      ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor in empty string" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = \"\";";
    const cursor = proto.Position{ .line = 0, .character = 9 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = "";
        \\         ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - null cursor" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = 42;";
    const cursor: ?proto.Position = null;

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = 42;
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}

test "appendSourceWithCursor - cursor in middle of string" {
    var gpa = std.testing.allocator;
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    const source = "val x = \"hello\";";
    const cursor = proto.Position{ .line = 0, .character = 12 };

    try snapshot.appendSourceWithCursor(&buf, gpa, source, cursor);

    const expected =
        \\----- SOURCE
        \\```botopink
        \\val x = "hello";
        \\            ↑
        \\```
        \\
    ;
    try std.testing.expectEqualStrings(expected, buf.items);
}
