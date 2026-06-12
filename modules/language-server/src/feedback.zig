/// Tracks which files currently have diagnostics in the editor.
///
/// The LSP requires the server to publish an EMPTY diagnostics list to
/// clear prior errors from a file. `FeedbackBookkeeper` records which
/// URIs are currently flagged so the server can publish that empty list
/// the next time the file is fixed or closed.
const std = @import("std");
const proto = @import("./protocol.zig");

pub const FeedbackBookkeeper = struct {
    gpa: std.mem.Allocator,
    /// Set of URIs with diagnostics still in flight (errors or warnings).
    active: std.StringHashMap(void),

    pub fn init(gpa: std.mem.Allocator) FeedbackBookkeeper {
        return .{
            .gpa = gpa,
            .active = std.StringHashMap(void).init(gpa),
        };
    }

    pub fn deinit(self: *FeedbackBookkeeper) void {
        var it = self.active.keyIterator();
        while (it.next()) |k| self.gpa.free(k.*);
        self.active.deinit();
    }

    /// Record that `uri` has diagnostics in flight.
    pub fn mark(self: *FeedbackBookkeeper, uri: []const u8) !void {
        if (self.active.contains(uri)) return;
        const owned = try self.gpa.dupe(u8, uri);
        try self.active.put(owned, {});
    }

    /// Drop `uri` from the in-flight diagnostics set.
    pub fn clear(self: *FeedbackBookkeeper, uri: []const u8) void {
        if (self.active.fetchRemove(uri)) |kv| {
            self.gpa.free(kv.key);
        }
    }

    /// True if the URI has diagnostics recorded as in flight.
    pub fn has(self: *const FeedbackBookkeeper, uri: []const u8) bool {
        return self.active.contains(uri);
    }
};
