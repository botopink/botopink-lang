//! Shared test harness for the parser stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");

pub fn slugify(comptime s: []const u8) []const u8 {
    // Pass 1: compute the output length.
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true; // start true so leading non-alnum is skipped
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1; // pending underscore
                sep = true;
            }
        }
        // Trim any trailing underscore that would be appended at end.
        if (sep and count > 0) count -= 1;
        break :blk count;
    };

    // Pass 2: fill a fixed-size buffer (struct pattern so the data is comptime).
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

pub fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

pub fn assertParser(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    var l = Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const slug = comptime slugFromSrc(loc);
    const snapName = try std.fmt.allocPrint(allocator, "parser/{s}", .{slug});
    defer allocator.free(snapName);
    try snapMod.check(allocator, snapName, program);
}

pub fn expectParseError(
    allocator: std.mem.Allocator,
    comptime expected: []const u8,
    src: []const u8,
) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = l.scanAll(allocator) catch {
        l.deinit(allocator);
        return error.LexErrorNotParseError;
    };
    defer l.deinit(allocator);

    var p = parserMod.Parser.initWithSource(tokens, src);
    if (p.parse(allocator)) |*prog| {
        var owned = prog.*;
        owned.deinit(allocator);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parseError orelse return;
        const actual = try print.renderAlloc(allocator, pe, src, "<test>");
        defer allocator.free(actual);
        try expectEqualOutput(allocator, expected, actual);
    }
}

pub fn expectParseFails(allocator: std.mem.Allocator, src: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = l.scanAll(allocator) catch {
        l.deinit(allocator);
        return; // a lexical error also counts as "does not parse"
    };
    defer l.deinit(allocator);

    var p = parserMod.Parser.initWithSource(tokens, src);
    if (p.parse(allocator)) |*prog| {
        var owned = prog.*;
        owned.deinit(allocator);
        return error.TestExpectedParseError;
    } else |_| {}
}

pub fn expectEqualOutput(
    allocator: std.mem.Allocator,
    expected: []const u8,
    actual: []const u8,
) !void {
    if (std.mem.eql(u8, expected, actual)) return;

    var expLines: std.ArrayList([]const u8) = .empty;
    defer expLines.deinit(allocator);
    var actLines: std.ArrayList([]const u8) = .empty;
    defer actLines.deinit(allocator);

    var it = std.mem.splitScalar(u8, expected, '\n');
    while (it.next()) |line| try expLines.append(allocator, line);
    it = std.mem.splitScalar(u8, actual, '\n');
    while (it.next()) |line| try actLines.append(allocator, line);

    const maxLines = @max(expLines.items.len, actLines.items.len);

    std.debug.print("\n-- parse error output mismatch ------------------------------\n", .{});
    var hasDiff = false;
    for (0..maxLines) |i| {
        const e = if (i < expLines.items.len) expLines.items[i] else "<missing>";
        const a = if (i < actLines.items.len) actLines.items[i] else "<missing>";
        if (!std.mem.eql(u8, e, a)) {
            if (!hasDiff) std.debug.print("{s:>4}  {s:<40}  {s}\n", .{ "line", "expected", "actual" });
            std.debug.print("{d:>4}  -{s}\n      +{s}\n", .{ i + 1, e, a });
            hasDiff = true;
        }
    }
    std.debug.print("-------------------------------------------------------------\n\n", .{});
    if (hasDiff) return error.TestOutputMismatch;
}
