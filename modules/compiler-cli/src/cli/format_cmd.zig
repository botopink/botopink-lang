/// `botopink format` — format source files with the Wadler-Lindig pretty-printer.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const scanner = @import("./scanner.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    /// Only check formatting; exit 1 if any file would change.
    check: bool = false,
    /// Explicit list of files to format. Empty → scan `src/`.
    files: []const []const u8 = &.{},
};

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    var changed: usize = 0;
    var errors: usize = 0;

    if (opts.files.len > 0) {
        // Format explicit file list.
        for (opts.files) |path| {
            const result = formatFile(gpa, io, path, opts.check) catch |err| {
                std.debug.print("  error formatting {s}: {s}\n", .{ path, @errorName(err) });
                errors += 1;
                continue;
            };
            if (result) changed += 1;
        }
    } else {
        // Scan src/.
        const modules = try scanner.scanSources(gpa, io, "src");
        defer scanner.freeModules(gpa, modules);

        for (modules) |m| {
            // Reconstruct the file path: src/<module.path>.bp
            const file_path = try std.fmt.allocPrint(gpa, "src/{s}.bp", .{m.path});
            defer gpa.free(file_path);

            const result = formatFile(gpa, io, file_path, opts.check) catch |err| {
                std.debug.print("  error formatting {s}: {s}\n", .{ file_path, @errorName(err) });
                errors += 1;
                continue;
            };
            if (result) changed += 1;
        }
    }

    if (errors > 0) return 1;
    if (opts.check and changed > 0) {
        const msg = try std.fmt.allocPrint(gpa, "{d} file(s) would be reformatted", .{changed});
        defer gpa.free(msg);
        reporter.errMsg(msg);
        return 1;
    }
    return 0;
}

// ── Per-file formatter ────────────────────────────────────────────────────────

/// Format one source file. Returns `true` if the file was changed (or would
/// be changed in --check mode). Prints appropriate status.
fn formatFile(
    gpa: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    check_only: bool,
) !bool {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const source = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited) catch |err| {
        return err;
    };

    // Lex and parse.
    var lexer = bp.Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch |err| {
        std.debug.print("  lex error in {s}: {s}\n", .{ path, @errorName(err) });
        return false;
    };

    var parser = bp.Parser.init(tokens);
    const program = parser.parse(arena) catch {
        if (parser.parseError) |info| {
            var aw: std.Io.Writer.Allocating = .init(gpa);
            defer aw.deinit();
            bp.print_errors.render(&aw.writer, info, source, path) catch {};
            const rendered = aw.toOwnedSlice() catch "";
            defer if (rendered.len > 0) gpa.free(rendered);
            std.debug.print("{s}", .{rendered});
        }
        return false;
    };

    // Format.
    const formatted = try bp.format.format(arena, program);

    const unchanged = std.mem.eql(u8, source, formatted);
    if (unchanged) {
        reporter.formatUnchanged(path);
        return false;
    }

    if (check_only) {
        reporter.formatChanged(path);
        return true;
    }

    // Write back.
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = formatted });
    reporter.formatChanged(path);
    return true;
}
