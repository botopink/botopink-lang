/// Subcommand dispatcher — table-driven so adding a command is one line.
///
/// Each `Command` carries a name and a runner. The runner receives the
/// parsed `Context` and the per-command argv (everything after the
/// subcommand name). Help / version are handled at the dispatch level so
/// every subcommand can rely on a populated `Context`.
const std = @import("std");

pub const Context = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    env_map: ?*const std.process.Environ.Map,
};

pub const Command = struct {
    name: []const u8,
    summary: []const u8,
    run: *const fn (ctx: Context, args: []const []const u8) anyerror!u8,
};

pub fn findCommand(table: []const Command, name: []const u8) ?Command {
    for (table) |c| {
        if (std.mem.eql(u8, c.name, name)) return c;
    }
    return null;
}

/// Render the available commands as a help block.
pub fn renderHelp(gpa: std.mem.Allocator, table: []const Command) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    try aw.writer.writeAll("bpmp — Boto Pink Package Manager\n\nUsage: bpmp <command> [options]\n\nCommands:\n");
    for (table) |c| {
        try aw.writer.print("  {s: <14}  {s}\n", .{ c.name, c.summary });
    }
    try aw.writer.writeAll("\nRun `bpmp <command> --help` for command-specific options.\n");
    return aw.toOwnedSlice();
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

fn dummy(ctx: Context, args: []const []const u8) anyerror!u8 {
    _ = ctx;
    _ = args;
    return 0;
}

test "findCommand: hit / miss" {
    const table = [_]Command{
        .{ .name = "install", .summary = "install deps", .run = dummy },
        .{ .name = "run", .summary = "exec compiler", .run = dummy },
    };
    try testing.expect(findCommand(&table, "install") != null);
    try testing.expect(findCommand(&table, "nope") == null);
}

test "renderHelp lists every command" {
    const table = [_]Command{
        .{ .name = "install", .summary = "install deps", .run = dummy },
        .{ .name = "run", .summary = "exec compiler", .run = dummy },
    };
    const text = try renderHelp(testing.allocator, &table);
    defer testing.allocator.free(text);
    try testing.expect(std.mem.indexOf(u8, text, "install") != null);
    try testing.expect(std.mem.indexOf(u8, text, "run") != null);
    try testing.expect(std.mem.indexOf(u8, text, "install deps") != null);
}
