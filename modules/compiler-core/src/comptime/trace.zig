/// What a decorator or template evaluation exchanged with its comptime
/// runtime, kept for snapshots.
///
/// `template_eval` / `decorator_eval` record one `Entry` per evaluation: the
/// module that ran (`Lang`) and the reply the runtime sent back to the
/// compiler. `render` writes them as `COMPTIME BEAM ASSEMBLY` or
/// `COMPTIME WAT`, then `COMPTIME REPLY`, snapshot sections.
const std = @import("std");
const replyOrder = @import("runtime/reply_order.zig");

pub const Kind = enum { template, decorator };

/// What the listing of an evaluation is: the BEAM assembly the BEAM runtime
/// loaded (front 14 step 3), or the wasm the wat runtime lowered the module
/// to.
pub const Lang = enum {
    beam,
    wat,

    fn section(l: Lang) []const u8 {
        return switch (l) {
            .beam => "COMPTIME BEAM ASSEMBLY",
            .wat => "COMPTIME WAT",
        };
    }

    /// The fence's info string: `.S` is Erlang term syntax, fenced as the
    /// codegen `BEAM ASSEMBLY` sections are.
    fn fence(l: Lang) []const u8 {
        return switch (l) {
            .beam => "erlang",
            .wat => "wat",
        };
    }
};

pub const Entry = struct {
    kind: Kind,
    /// Name of the template / decorator function.
    name: []const u8,
    /// The module that ran: its BEAM assembly, or the generated module's
    /// functions in wat (`lang`), then `main/1`'s argument as comments.
    listing: []const u8,
    lang: Lang = .beam,
    /// The runtime's reply: the JSON `main/0` printed, or the compile/runtime
    /// error text when the module did not compile or raised.
    reply: []const u8,
};

/// Append the listing and `COMPTIME REPLY` sections of every entry.
pub fn render(allocator: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), entries: []const Entry) !void {
    for (entries) |e| {
        const kind = @tagName(e.kind);
        try buf.print(allocator, "----- {s} -- {s} {s}\n```{s}\n", .{ e.lang.section(), kind, e.name, e.lang.fence() });
        try appendBlock(allocator, buf, e.listing);
        try buf.print(allocator, "----- COMPTIME REPLY -- {s} {s}\n", .{ kind, e.name });
        if (try prettyJson(allocator, e.reply)) |json| {
            defer allocator.free(json);
            try buf.appendSlice(allocator, "```json\n");
            try appendBlock(allocator, buf, json);
        } else {
            try buf.appendSlice(allocator, "```text\n");
            try appendBlock(allocator, buf, e.reply);
        }
    }
}

/// `render` into a fresh owned slice; null when there are no entries.
pub fn renderAlloc(allocator: std.mem.Allocator, entries: []const Entry) !?[]u8 {
    if (entries.len == 0) return null;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);
    try render(allocator, &buf, entries);
    return try buf.toOwnedSlice(allocator);
}

fn appendBlock(allocator: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), text: []const u8) !void {
    try buf.appendSlice(allocator, std.mem.trim(u8, text, "\n"));
    try buf.appendSlice(allocator, "\n```\n\n");
}

/// The reply re-indented with its objects' keys sorted (`runtime/reply_order.zig`:
/// the order the runtime happened to emit them in is not part of the answer),
/// or null when it is not JSON (an error text).
fn prettyJson(allocator: std.mem.Allocator, text: []const u8) !?[]u8 {
    var parsed = std.json.parseFromSlice(std.json.Value, allocator, text, .{}) catch return null;
    defer parsed.deinit();
    replyOrder.sortObjects(&parsed.value);
    return try std.json.Stringify.valueAlloc(allocator, parsed.value, .{ .whitespace = .indent_2 });
}

test "trace: json replies are re-indented, error texts kept" {
    const alloc = std.testing.allocator;
    const out = (try renderAlloc(alloc, &.{
        .{ .kind = .template, .name = "shout", .listing = "{function, shout, 1, 2}.\n    return.\n", .reply = "{\"kind\":\"code\",\"source\":\"1\"}" },
        .{ .kind = .decorator, .name = "route", .listing = "(func $route)", .lang = .wat, .reply = "the decorator body raised: badarg" },
    })).?;
    defer alloc.free(out);
    try std.testing.expectEqualStrings(
        \\----- COMPTIME BEAM ASSEMBLY -- template shout
        \\```erlang
        \\{function, shout, 1, 2}.
        \\    return.
        \\```
        \\
        \\----- COMPTIME REPLY -- template shout
        \\```json
        \\{
        \\  "kind": "code",
        \\  "source": "1"
        \\}
        \\```
        \\
        \\----- COMPTIME WAT -- decorator route
        \\```wat
        \\(func $route)
        \\```
        \\
        \\----- COMPTIME REPLY -- decorator route
        \\```text
        \\the decorator body raised: badarg
        \\```
        \\
        \\
    , out);
}
