const std = @import("std");

/// Serializes `value` as indented JSON. Caller owns the returned slice.
pub fn formatAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    return std.json.Stringify.valueAlloc(allocator, value, .{ .whitespace = .indent_2 });
}
