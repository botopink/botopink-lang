/// `botopink format` — format source files with the Wadler-Lindig pretty-printer.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const scanner = @import("./scanner.zig");
const diagnostics = @import("./diagnostics.zig");

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

    var owned_paths: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (owned_paths.items) |p| gpa.free(p);
        owned_paths.deinit(gpa);
    }
    var scanned: []bp.Module = &.{};
    defer if (opts.files.len == 0) scanner.freeModules(gpa, scanned);

    const paths: []const []const u8 = if (opts.files.len > 0) opts.files else blk: {
        // Scan src/: src/<module.path>.bp
        scanned = try scanner.scanSources(gpa, io, "src");
        for (scanned) |m| {
            try owned_paths.append(gpa, try std.fmt.allocPrint(gpa, "src/{s}.bp", .{m.path}));
        }
        break :blk owned_paths.items;
    };

    for (paths) |path| {
        const result = formatFile(gpa, io, path, opts.check) catch |err| {
            std.debug.print("  error formatting {s}: {s}\n", .{ path, @errorName(err) });
            errors += 1;
            continue;
        };
        switch (result) {
            .unchanged => {},
            .changed => changed += 1,
            // Already rendered with its location; a file that cannot be
            // formatted is an error in both modes, never "unchanged".
            .invalid => errors += 1,
        }
    }

    if (errors > 0) {
        const msg = try std.fmt.allocPrint(gpa, "{d} file(s) could not be formatted", .{errors});
        defer gpa.free(msg);
        reporter.errMsg(msg);
        return 1;
    }
    if (opts.check and changed > 0) {
        const msg = try std.fmt.allocPrint(gpa, "{d} file(s) would be reformatted", .{changed});
        defer gpa.free(msg);
        reporter.errMsg(msg);
        return 1;
    }
    return 0;
}

// ── Per-file formatter ────────────────────────────────────────────────────────

const FileResult = enum { unchanged, changed, invalid };

/// Format one source file. `.changed` when the file was rewritten (or would be,
/// in --check mode); `.invalid` when it does not lex or parse — the located
/// diagnostic has already been printed.
fn formatFile(
    gpa: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    check_only: bool,
) !FileResult {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited);

    // Lex and parse.
    var lexer = bp.Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch |err| {
        diagnostics.printLexError(gpa, &lexer, err, source, path);
        return .invalid;
    };

    var parser = bp.Parser.init(tokens);
    const program = parser.parse(arena) catch |err| {
        diagnostics.printParseError(gpa, &parser, err, source, path);
        return .invalid;
    };

    // Format.
    const formatted = try bp.format.format(arena, program);

    if (std.mem.eql(u8, source, formatted)) {
        reporter.formatUnchanged(path);
        return .unchanged;
    }

    if (check_only) {
        reporter.formatChanged(path);
        return .changed;
    }

    // Write back.
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = formatted });
    reporter.formatChanged(path);
    return .changed;
}
