/// Generic Erlang term emitter — reusable by any struct that needs to emit Erlang.
///
/// This module provides functions to emit Erlang terms (strings, variables, maps, lists)
/// in a generic way, decoupled from specific data structures. Any struct that needs to
/// emit itself as Erlang can use these functions.
///
/// Benefits:
/// - Reusability: Can emit any struct to Erlang
/// - Testability: Easier to test emitters in isolation
/// - Maintainability: Clear separation between model and serialization
/// - Extensibility: Easier to add new handle types in the future

const std = @import("std");

/// Emit a string as an Erlang binary: <<"value">>
pub fn emitString(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, s: []const u8) std.mem.Allocator.Error!void {
    try buf.appendSlice(arena, "<<\"");
    for (s) |c| {
        if (c == '"' or c == '\\') {
            try buf.append(arena, '\\');
        }
        try buf.append(arena, c);
    }
    try buf.appendSlice(arena, "\">>");
}

/// Emit a variable name (uppercase first letter for Erlang convention)
pub fn emitVar(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, name: []const u8) std.mem.Allocator.Error!void {
    if (name.len == 0) {
        try buf.appendSlice(arena, "_");
        return;
    }
    const var_name = try arena.alloc(u8, name.len);
    var_name[0] = std.ascii.toUpper(name[0]);
    for (name[1..], 1..) |c, i| {
        var_name[i] = c;
    }
    try buf.appendSlice(arena, var_name);
}

/// Emit a map: #{key1 => value1, key2 => value2}
pub fn emitMap(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, var_name: []const u8, entries: []const MapEntry) std.mem.Allocator.Error!void {
    try emitVar(buf, arena, var_name);
    try buf.appendSlice(arena, " = #{");
    for (entries, 0..) |entry, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try buf.appendSlice(arena, entry.key);
        try buf.appendSlice(arena, " => ");
        try entry.value.emitErl(buf, arena);
    }
    try buf.appendSlice(arena, "}");
}

/// Emit a list: [value1, value2, value3]
pub fn emitList(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, items: []const ErlValue) std.mem.Allocator.Error!void {
    try buf.appendSlice(arena, "[");
    for (items, 0..) |item, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try item.emitErl(buf, arena);
    }
    try buf.appendSlice(arena, "]");
}

/// Map entry: key-value pair for Erlang maps
pub const MapEntry = struct {
    key: []const u8,
    value: ErlValue,
};

/// Erlang value — union of all possible Erlang term types
pub const ErlValue = union(enum) {
    string: []const u8,
    int: i64,
    float: f64,
    bool: bool,
    atom: []const u8,
    list: []const ErlValue,
    map: []const MapEntry,

    /// Emit this value as Erlang syntax
    pub fn emitErl(self: ErlValue, buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator) std.mem.Allocator.Error!void {
        switch (self) {
            .string => |s| try emitString(buf, arena, s),
            .int => |n| {
                const text = try std.fmt.allocPrint(arena, "{d}", .{n});
                try buf.appendSlice(arena, text);
            },
            .float => |f| {
                const text = try std.fmt.allocPrint(arena, "{d}", .{f});
                try buf.appendSlice(arena, text);
            },
            .bool => |b| try buf.appendSlice(arena, if (b) "true" else "false"),
            .atom => |a| {
                try buf.appendSlice(arena, "'");
                try buf.appendSlice(arena, a);
                try buf.appendSlice(arena, "'");
            },
            .list => |items| try emitList(buf, arena, items),
            .map => |entries| {
                try buf.appendSlice(arena, "#{");
                for (entries, 0..) |entry, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, entry.key);
                    try buf.appendSlice(arena, " => ");
                    try entry.value.emitErl(buf, arena);
                }
                try buf.appendSlice(arena, "}");
            },
        }
    }
};

// ── Tests ─────────────────────────────────────────────────────────────────────

test "emitString" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    try emitString(&buf, allocator, "hello");
    try std.testing.expectEqualStrings("<<\"hello\">>", buf.items);
}

test "emitString with quotes" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    try emitString(&buf, allocator, "hello \"world\"");
    try std.testing.expectEqualStrings("<<\"hello \\\"world\\\"\">>", buf.items);
}

test "emitVar" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    try emitVar(&buf, allocator, "decl");
    try std.testing.expectEqualStrings("Decl", buf.items);
}

test "emitVar empty" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    try emitVar(&buf, allocator, "");
    try std.testing.expectEqualStrings("_", buf.items);
}

test "emitMap" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    const entries = [_]MapEntry{
        .{ .key = "kind", .value = .{ .string = "Record" } },
        .{ .key = "name", .value = .{ .string = "UserService" } },
    };

    try emitMap(&buf, allocator, "decl", &entries);
    try std.testing.expectEqualStrings("Decl = #{kind => <<\"Record\">>, name => <<\"UserService\">>}", buf.items);
}

test "emitList" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    const items = [_]ErlValue{
        .{ .string = "a" },
        .{ .string = "b" },
        .{ .int = 42 },
    };

    try emitList(&buf, allocator, &items);
    try std.testing.expectEqualStrings("[<<\"a\">>, <<\"b\">>, 42]", buf.items);
}

test "ErlValue emitErl" {
    const allocator = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    const value = ErlValue{ .map = &.{
        .{ .key = "kind", .value = .{ .string = "Record" } },
        .{ .key = "count", .value = .{ .int = 5 } },
        .{ .key = "active", .value = .{ .bool = true } },
    } };

    try value.emitErl(&buf, allocator);
    try std.testing.expectEqualStrings("#{kind => <<\"Record\">>, count => 5, active => true}", buf.items);
}
