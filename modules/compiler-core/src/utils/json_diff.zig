/// Structural JSON diff styled after https://github.com/andreyvit/json-diff
///
/// Output format ---- every line has a 2-char prefix:
///   "  " unchanged context
///   "- " removed  (red)
///   "+ " added    (green)
///
/// Changed scalar fields repeat the key on both lines:
///   -   "name": "old"
///   +   "name": "new"
///
/// Changed compound fields show the key once and recurse into the diff:
///     "obj": {
///   -   "x": 1
///   +   "x": 2
///     }
///
const std = @import("std");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ObjectMap = std.json.ObjectMap;

const red = "\x1b[31m";
const green = "\x1b[32m";
const reset = "\x1b[0m";

// ── public API ────────────────────────────────────────────────────────────────

/// Prints a colored structural diff to `writer`.
/// Returns `true` if the values differ, `false` if they are equal.
pub fn diff(
    allocator: Allocator,
    expectedJson: []const u8,
    actualJson: []const u8,
    writer: anytype,
) !bool {
    const exp = try std.json.parseFromSlice(Value, allocator, expectedJson, .{});
    defer exp.deinit();
    const act = try std.json.parseFromSlice(Value, allocator, actualJson, .{});
    defer act.deinit();
    var differs = false;
    try diffvalue(allocator, writer, exp.value, act.value, 0, false, &differs);
    return differs;
}

// ── line helpers ──────────────────────────────────────────────────────────────

/// Write the line prefix: sign + space + depth indent.
fn pfx(writer: anytype, sign: u8, depth: usize) !void {
    switch (sign) {
        '-' => try writer.writeAll(red ++ "- "),
        '+' => try writer.writeAll(green ++ "+ "),
        else => try writer.writeAll("  "),
    }
    for (0..depth * 2) |_| try writer.writeByte(' ');
}

/// Write the line suffix: optional comma, color reset, newline.
fn sfx(writer: anytype, sign: u8, comma: bool) !void {
    if (comma) try writer.writeByte(',');
    if (sign != ' ') try writer.writeAll(reset);
    try writer.writeByte('\n');
}

fn writeScalar(writer: anytype, v: Value) !void {
    switch (v) {
        .null => try writer.writeAll("null"),
        .bool => |b| try writer.writeAll(if (b) "true" else "false"),
        .integer => |n| try writer.print("{d}", .{n}),
        .float => |f| try writer.print("{d}", .{f}),
        .number_string => |s| try writer.writeAll(s),
        .string => |s| try writer.print("\"{s}\"", .{s}),
        else => unreachable,
    }
}

fn isCompound(v: Value) bool {
    return v == .object or v == .array;
}

// ── equality ──────────────────────────────────────────────────────────────────

fn eq(a: Value, b: Value) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .null => true,
        .bool => |v| v == b.bool,
        .integer => |v| v == b.integer,
        .float => |v| v == b.float,
        .number_string => |v| std.mem.eql(u8, v, b.number_string),
        .string => |v| std.mem.eql(u8, v, b.string),
        .array => |arr| blk: {
            if (arr.items.len != b.array.items.len) break :blk false;
            for (arr.items, b.array.items) |x, y| if (!eq(x, y)) break :blk false;
            break :blk true;
        },
        .object => |obj| blk: {
            if (obj.count() != b.object.count()) break :blk false;
            var it = obj.iterator();
            while (it.next()) |e| {
                const bv = b.object.get(e.key_ptr.*) orelse break :blk false;
                if (!eq(e.value_ptr.*, bv)) break :blk false;
            }
            break :blk true;
        },
    };
}

// ── expand (single side) ──────────────────────────────────────────────────────

/// Write an entire value ---- every line prefixed with `sign`.
fn expand(writer: anytype, v: Value, sign: u8, depth: usize, comma: bool) anyerror!void {
    switch (v) {
        .object => |obj| {
            if (obj.count() == 0) {
                try pfx(writer, sign, depth);
                try writer.writeAll("{}");
                try sfx(writer, sign, comma);
            } else {
                try pfx(writer, sign, depth);
                try writer.writeByte('{');
                try sfx(writer, sign, false);
                var it = obj.iterator();
                var i: usize = 0;
                while (it.next()) |e| : (i += 1)
                    try expandField(writer, e.key_ptr.*, e.value_ptr.*, sign, depth + 1, i + 1 < obj.count());
                try pfx(writer, sign, depth);
                try writer.writeByte('}');
                try sfx(writer, sign, comma);
            }
        },
        .array => |arr| {
            if (arr.items.len == 0) {
                try pfx(writer, sign, depth);
                try writer.writeAll("[]");
                try sfx(writer, sign, comma);
            } else {
                try pfx(writer, sign, depth);
                try writer.writeByte('[');
                try sfx(writer, sign, false);
                for (arr.items, 0..) |item, i|
                    try expand(writer, item, sign, depth + 1, i + 1 < arr.items.len);
                try pfx(writer, sign, depth);
                try writer.writeByte(']');
                try sfx(writer, sign, comma);
            }
        },
        else => {
            try pfx(writer, sign, depth);
            try writeScalar(writer, v);
            try sfx(writer, sign, comma);
        },
    }
}

/// Write a `"key": value` field ---- every line prefixed with `sign`.
fn expandField(writer: anytype, key: []const u8, val: Value, sign: u8, depth: usize, comma: bool) anyerror!void {
    switch (val) {
        .object => |obj| {
            if (obj.count() == 0) {
                try pfx(writer, sign, depth);
                try writer.print("\"{s}\": {{}}", .{key});
                try sfx(writer, sign, comma);
            } else {
                try pfx(writer, sign, depth);
                try writer.print("\"{s}\": {{", .{key});
                try sfx(writer, sign, false);
                var it = obj.iterator();
                var i: usize = 0;
                while (it.next()) |e| : (i += 1)
                    try expandField(writer, e.key_ptr.*, e.value_ptr.*, sign, depth + 1, i + 1 < obj.count());
                try pfx(writer, sign, depth);
                try writer.writeByte('}');
                try sfx(writer, sign, comma);
            }
        },
        .array => |arr| {
            if (arr.items.len == 0) {
                try pfx(writer, sign, depth);
                try writer.print("\"{s}\": []", .{key});
                try sfx(writer, sign, comma);
            } else {
                try pfx(writer, sign, depth);
                try writer.print("\"{s}\": [", .{key});
                try sfx(writer, sign, false);
                for (arr.items, 0..) |item, i|
                    try expand(writer, item, sign, depth + 1, i + 1 < arr.items.len);
                try pfx(writer, sign, depth);
                try writer.writeByte(']');
                try sfx(writer, sign, comma);
            }
        },
        else => {
            try pfx(writer, sign, depth);
            try writer.print("\"{s}\": ", .{key});
            try writeScalar(writer, val);
            try sfx(writer, sign, comma);
        },
    }
}

// ── diff (two sides) ──────────────────────────────────────────────────────────

fn diffvalue(
    allocator: Allocator,
    writer: anytype,
    expval: Value,
    actval: Value,
    depth: usize,
    comma: bool,
    differs: *bool,
) anyerror!void {
    if (eq(expval, actval)) {
        try expand(writer, expval, ' ', depth, comma);
        return;
    }
    if (std.meta.activeTag(expval) == std.meta.activeTag(actval)) {
        switch (expval) {
            .object => {
                try pfx(writer, ' ', depth);
                try writer.writeByte('{');
                try sfx(writer, ' ', false);
                try diffObjectContent(allocator, writer, expval.object, actval.object, depth, differs);
                try pfx(writer, ' ', depth);
                try writer.writeByte('}');
                try sfx(writer, ' ', comma);
                return;
            },
            .array => {
                try pfx(writer, ' ', depth);
                try writer.writeByte('[');
                try sfx(writer, ' ', false);
                try diffArrayContent(allocator, writer, expval.array.items, actval.array.items, depth, differs);
                try pfx(writer, ' ', depth);
                try writer.writeByte(']');
                try sfx(writer, ' ', comma);
                return;
            },
            else => {},
        }
    }
    differs.* = true;
    try expand(writer, expval, '-', depth, comma);
    try expand(writer, actval, '+', depth, comma);
}

fn diffObjectContent(
    allocator: Allocator,
    writer: anytype,
    expObj: ObjectMap,
    actObj: ObjectMap,
    depth: usize,
    differs: *bool,
) anyerror!void {
    // Build ordered key list: expected keys first, then extra actual keys.
    var keys: std.ArrayList([]const u8) = .empty;
    defer keys.deinit(allocator);
    var it = expObj.iterator();
    while (it.next()) |e| try keys.append(allocator, e.key_ptr.*);
    it = actObj.iterator();
    while (it.next()) |e| if (!expObj.contains(e.key_ptr.*)) try keys.append(allocator, e.key_ptr.*);

    for (keys.items, 0..) |key, ki| {
        const comma = ki + 1 < keys.items.len;
        const ev = expObj.get(key);
        const av = actObj.get(key);

        if (ev != null and av != null) {
            if (eq(ev.?, av.?)) {
                try expandField(writer, key, ev.?, ' ', depth + 1, comma);
            } else {
                differs.* = true;
                try diffFieldvalue(allocator, writer, key, ev.?, av.?, depth + 1, comma, differs);
            }
        } else if (ev != null) {
            differs.* = true;
            try expandField(writer, key, ev.?, '-', depth + 1, comma);
        } else {
            differs.* = true;
            try expandField(writer, key, av.?, '+', depth + 1, comma);
        }
    }
}

/// Diff a single object field where `expval != actval`.
fn diffFieldvalue(
    allocator: Allocator,
    writer: anytype,
    key: []const u8,
    expval: Value,
    actval: Value,
    depth: usize,
    comma: bool,
    differs: *bool,
) anyerror!void {
    if (std.meta.activeTag(expval) == std.meta.activeTag(actval) and isCompound(expval)) {
        // Same compound type ---- keep the key line, recurse inside.
        switch (expval) {
            .object => {
                try pfx(writer, ' ', depth);
                try writer.print("\"{s}\": {{", .{key});
                try sfx(writer, ' ', false);
                try diffObjectContent(allocator, writer, expval.object, actval.object, depth, differs);
                try pfx(writer, ' ', depth);
                try writer.writeByte('}');
                try sfx(writer, ' ', comma);
            },
            .array => {
                try pfx(writer, ' ', depth);
                try writer.print("\"{s}\": [", .{key});
                try sfx(writer, ' ', false);
                try diffArrayContent(allocator, writer, expval.array.items, actval.array.items, depth, differs);
                try pfx(writer, ' ', depth);
                try writer.writeByte(']');
                try sfx(writer, ' ', comma);
            },
            else => unreachable,
        }
    } else {
        // Scalar or type mismatch ---- show full field on both - and + lines.
        try expandField(writer, key, expval, '-', depth, comma);
        try expandField(writer, key, actval, '+', depth, comma);
    }
}

fn diffArrayContent(
    allocator: Allocator,
    writer: anytype,
    expItems: []const Value,
    actItems: []const Value,
    depth: usize,
    differs: *bool,
) anyerror!void {
    const max = @max(expItems.len, actItems.len);
    for (0..max) |i| {
        const comma = i + 1 < max;
        if (i < expItems.len and i < actItems.len) {
            try diffvalue(allocator, writer, expItems[i], actItems[i], depth + 1, comma, differs);
        } else if (i < expItems.len) {
            differs.* = true;
            try expand(writer, expItems[i], '-', depth + 1, comma);
        } else {
            differs.* = true;
            try expand(writer, actItems[i], '+', depth + 1, comma);
        }
    }
}
