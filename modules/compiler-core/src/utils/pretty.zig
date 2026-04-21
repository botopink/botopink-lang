const std = @import("std");

/// Serializes `value` as indented JSON wrapped in a ```json code block. Caller owns the returned slice.
pub fn formatAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    const json = try std.json.Stringify.valueAlloc(allocator, value, .{ .whitespace = .indent_2 });
    defer allocator.free(json);
    return std.fmt.allocPrint(allocator, "```json\n{s}\n```", .{json});
}
