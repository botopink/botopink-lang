//! The one order a comptime reply's JSON objects are read in: keys sorted by
//! their bytes, recursively.
//!
//! A reply is `json:encode` of an Erlang map, and a map's iteration order is
//! the BEAM's atom-table order for atom keys — which atoms the node created
//! first, a matter of which modules it happened to load and when. The wat
//! runtime cannot reproduce that order, and nothing should depend on it: the
//! `COMPTIME REPLY` snapshot section (`trace.zig`) and a map lifted by `@expr`
//! (`template_eval.zig` `typedValue` — a labeled tuple, whose field order is
//! its type) read the reply in this order on both runtimes, and the parity
//! check (`runtime.equivalent`) compares replies in it.
const std = @import("std");

/// Sort every object of `v` by key, in place.
pub fn sortObjects(v: *std.json.Value) void {
    switch (v.*) {
        .object => |*obj| {
            const Ctx = struct {
                keys: []const []const u8,
                pub fn lessThan(c: @This(), a: usize, b: usize) bool {
                    return std.mem.lessThan(u8, c.keys[a], c.keys[b]);
                }
            };
            obj.sort(Ctx{ .keys = obj.keys() });
            for (obj.values()) |*child| sortObjects(child);
        },
        .array => |*arr| for (arr.items) |*child| sortObjects(child),
        else => {},
    }
}

/// `text` re-encoded with its objects' keys sorted, or null when it is not
/// JSON. Owned by `alloc`.
pub fn canonical(alloc: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error!?[]u8 {
    var parsed = std.json.parseFromSlice(std.json.Value, alloc, text, .{}) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    defer parsed.deinit();
    sortObjects(&parsed.value);
    return try std.json.Stringify.valueAlloc(alloc, parsed.value, .{});
}

test "canonical: objects sorted at every depth, arrays kept in order" {
    const alloc = std.testing.allocator;
    const out = (try canonical(alloc, "{\"source\":\"x\",\"kind\":\"code\",\"ast\":{\"span\":1,\"label\":[{\"b\":1,\"a\":2}]}}")).?;
    defer alloc.free(out);
    try std.testing.expectEqualStrings("{\"ast\":{\"label\":[{\"a\":2,\"b\":1}],\"span\":1},\"kind\":\"code\",\"source\":\"x\"}", out);
    try std.testing.expect((try canonical(alloc, "the decorator body raised")) == null);
}
