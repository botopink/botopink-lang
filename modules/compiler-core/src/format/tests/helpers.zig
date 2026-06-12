//! Shared test harness for the format stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");

pub fn assertFormat(allocator: Allocator, src: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const actual = try formatMod.format(allocator, program);
    defer allocator.free(actual);

    const want = std.mem.trim(u8, src, "\n\r");
    const got = std.mem.trim(u8, actual, "\n\r");

    if (std.mem.eql(u8, want, got)) return;

    // Line-by-line diff
    var expLines: std.ArrayList([]const u8) = .empty;
    defer expLines.deinit(allocator);
    var actLines: std.ArrayList([]const u8) = .empty;
    defer actLines.deinit(allocator);

    var it = std.mem.splitScalar(u8, want, '\n');
    while (it.next()) |ln| try expLines.append(allocator, ln);
    it = std.mem.splitScalar(u8, got, '\n');
    while (it.next()) |ln| try actLines.append(allocator, ln);

    const maxLen = @max(expLines.items.len, actLines.items.len);
    std.debug.print("\n-- format output mismatch ------------------------------\n", .{});
    std.debug.print("{s:>4}  {s:<50}  {s}\n", .{ "line", "expected", "actual" });
    for (0..maxLen) |i| {
        const e = if (i < expLines.items.len) expLines.items[i] else "<missing>";
        const a = if (i < actLines.items.len) actLines.items[i] else "<missing>";
        const marker: u8 = if (std.mem.eql(u8, e, a)) ' ' else '!';
        std.debug.print("{d:>4}{c} -{s}\n     +{s}\n", .{ i + 1, marker, e, a });
    }
    std.debug.print("--------------------------------------------------------\n\n", .{});
    return error.TestOutputMismatch;
}

pub fn assertIdempotent(allocator: Allocator, src: []const u8) !void {
    const pass1 = blk: {
        var l = lexerMod.Lexer.init(src);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass1);

    const pass2 = blk: {
        var l = lexerMod.Lexer.init(pass1);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass2);

    if (!std.mem.eql(u8, pass1, pass2)) {
        std.debug.print(
            "\n-- formatter is not idempotent --\n-- pass 1 --\n{s}\n-- pass 2 --\n{s}\n",
            .{ pass1, pass2 },
        );
        return error.NotIdempotent;
    }
}
