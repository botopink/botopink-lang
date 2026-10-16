/// What a decorator, template or `comptime` block evaluation exchanged with
/// its comptime runtime, kept for snapshots.
///
/// `template_eval` / `decorator_eval` / `block_eval` record one `Entry` per
/// evaluation: the module that ran, as the wasm the comptime runtime lowered
/// it to (decision 434: the one runtime), and the reply the runtime sent back
/// to the compiler. `render` writes them as `COMPTIME WAT`, then
/// `COMPTIME REPLY`, snapshot sections.
const std = @import("std");
const replyOrder = @import("runtime/reply_order.zig");
const watProgram = @import("runtime/wat/program.zig");

/// `comptime`: a `comptime` block or expression the runtime evaluated
/// (`block_eval.zig`, decisions 266 and 331).
pub const Kind = enum { template, decorator, @"comptime" };

pub const Entry = struct {
    kind: Kind,
    /// Name of the template / decorator function.
    name: []const u8,
    /// The module that ran: the generated module's functions in wat, then
    /// `main/1`'s argument as comments.
    listing: Listing,
    /// The runtime's reply: the JSON `main/0` printed, or the compile/runtime
    /// error text when the module did not compile or raised.
    reply: []const u8,
};

/// An entry's listing, built when it is read (144 B-127): an evaluation keeps
/// the atom of the module that ran and what follows its lowered functions —
/// `main/1`'s argument as `;;` lines — and the functions are lowered again,
/// from the text the wat runtime's process-wide cache keeps by atom
/// (`wat/program.zig` `listing`), when a snapshot or the code cache reads the
/// listing. A project of many decorator calls kept the functions per call
/// (~1.7 MB each) for a listing nothing of a `check` reads.
pub const Listing = struct {
    /// The atom of the module whose lowered functions open the listing; empty
    /// when `text` is the whole listing (a refused build, a listing read back
    /// from the code cache).
    module: []const u8 = "",
    /// What follows the lowered functions, or the whole listing.
    text: []const u8,

    /// The code cache writes a listing as the text it renders and reads it
    /// back whole (`analysis_entry.zig`), so an entry holds the same bytes
    /// as when the listing was a string.
    pub const entry_as_string = {};

    /// A listing that is `text` whole.
    pub fn whole(text: []const u8) Listing {
        return .{ .text = text };
    }

    /// The listing with its atom and text copied into `allocator`.
    pub fn dupe(self: Listing, allocator: std.mem.Allocator) std.mem.Allocator.Error!Listing {
        return .{ .module = try allocator.dupe(u8, self.module), .text = try allocator.dupe(u8, self.text) };
    }

    /// The listing's text, owned by `allocator`.
    pub fn render(self: Listing, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        errdefer buf.deinit(allocator);
        try self.appendTo(allocator, &buf);
        return buf.toOwnedSlice(allocator);
    }

    /// Append the listing's text to `buf`.
    pub fn appendTo(self: Listing, allocator: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8)) std.mem.Allocator.Error!void {
        if (self.module.len > 0) {
            // The cache keeps every module it built for the process: an
            // evaluation's listing names a module that was built.
            if (try watProgram.listing(allocator, self.module)) |body| {
                defer allocator.free(body);
                try buf.appendSlice(allocator, std.mem.trimEnd(u8, body, "\n"));
            }
            try buf.append(allocator, '\n');
        }
        try buf.appendSlice(allocator, self.text);
    }

    /// `render` for the code cache's encoder.
    pub fn entryText(self: Listing, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        return self.render(allocator);
    }

    /// A listing the code cache read back (`entryText`'s bytes).
    pub fn fromEntryText(text: []const u8) Listing {
        return whole(text);
    }
};

/// Append the listing and `COMPTIME REPLY` sections of every entry.
pub fn render(allocator: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), entries: []const Entry) !void {
    for (entries) |e| {
        const kind = @tagName(e.kind);
        try buf.print(allocator, "----- COMPTIME WAT -- {s} {s}\n```wat\n", .{ kind, e.name });
        const listing = try e.listing.render(allocator);
        defer allocator.free(listing);
        try appendBlock(allocator, buf, listing);
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
        .{ .kind = .template, .name = "shout", .listing = .whole("(func $shout/1)\n"), .reply = "{\"kind\":\"code\",\"source\":\"1\"}" },
        .{ .kind = .decorator, .name = "route", .listing = .whole("(func $route)"), .reply = "the decorator body raised: badarg" },
    })).?;
    defer alloc.free(out);
    try std.testing.expectEqualStrings(
        \\----- COMPTIME WAT -- template shout
        \\```wat
        \\(func $shout/1)
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
