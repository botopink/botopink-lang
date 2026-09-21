/// `botopink format` — format source files with the Wadler-Lindig pretty-printer.
///
/// **Scope** ([decision 66](../../../../../specs/1.0.5-beta/decisions-taken.md)):
/// with no argument the command reaches every `.bp` — `.d.bp` included — under
/// the current directory: `src/**`, `test/**`, `examples/**` and every project
/// nested inside, because one walk from the root sees them all. An argument is a
/// file, or a directory walked the same way. Before this the command scanned
/// `src/**.bp` alone, and the drift collected exactly where it did not look —
/// the nested example projects.
///
/// **What the walk does not enter is structural, never configured**
/// ([decision 67](../../../../../specs/1.0.5-beta/decisions-taken.md)): a hidden
/// directory (`.git`, `.botopinkbuild`, `.zig-cache` — tool state, not sources),
/// `node_modules` (another package manager's store — files this project does not
/// own), and the language suite's rejected programs: a `.bp` in a directory named
/// `reject` beside its `<name>.expect`, a program whose purpose is to be refused
/// (`tests/language/reject/`, the one place where a red is the fixture working).
/// A `reject/` `.bp` without its `.expect` is not that fixture and is reached.
/// There is no skip list, no pragma and no environment variable, and this file
/// must not grow one.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const diagnostics = @import("./diagnostics.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    /// Only check formatting; exit 1 if any file would change.
    check: bool = false,
    /// Explicit files or directories. Empty → the current directory, walked whole.
    files: []const []const u8 = &.{},
};

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    var changed: usize = 0;
    var errors: usize = 0;

    var paths: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (paths.items) |p| gpa.free(p);
        paths.deinit(gpa);
    }
    if (opts.files.len == 0) {
        try collectTree(gpa, io, ".", &paths);
    } else for (opts.files) |arg| {
        if (isDirectory(io, arg)) {
            try collectTree(gpa, io, arg, &paths);
        } else {
            try paths.append(gpa, try gpa.dupe(u8, arg));
        }
    }
    // Directory order is the file system's; the report's is the path's.
    std.mem.sort([]const u8, paths.items, {}, pathLessThan);

    for (paths.items) |path| {
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

// ── The walk ──────────────────────────────────────────────────────────────────

const EXTS = [_][]const u8{ ".bp", ".botopink" };

/// `.bp` and `.botopink` — which includes every `.d.bp`: a declaration module is
/// source the project owns and `format` prints it like any other (decision 66).
fn hasSourceExt(name: []const u8) bool {
    for (EXTS) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return true;
    }
    return false;
}

fn stripExt(name: []const u8) []const u8 {
    for (EXTS) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return name[0 .. name.len - ext.len];
    }
    return name;
}

/// The directories the walk does not enter — each one a directory whose
/// meaning the tool knows, not a name someone configured:
///   - a hidden directory is tool state (`.git`, `.botopinkbuild`, `.zig-cache`);
///   - `node_modules` is another package manager's store; what is in it belongs
///     to a dependency, not to this project.
fn entersDirectory(name: []const u8) bool {
    if (name.len == 0 or name[0] == '.') return false;
    if (std.mem.eql(u8, name, "node_modules")) return false;
    return true;
}

/// The language suite's rejected program: `reject/<name>.bp` beside its
/// `<name>.expect` (`tests/language/run.sh` runs `botopink check` on the first
/// and matches the second). It is exempt because of what it *is* — a program
/// written to be refused, which `format` cannot parse by design — recognised by
/// the directory's name and the pair, at any depth. A lone `.bp` in a `reject/`
/// is not that fixture (the runner fails it too, "missing .expect") and is
/// reached like any other file.
fn isRejectedProgram(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, dir_path: []const u8, name: []const u8) !bool {
    if (!std.mem.eql(u8, std.fs.path.basename(dir_path), "reject")) return false;
    const expect = try std.mem.concat(gpa, u8, &.{ stripExt(name), ".expect" });
    defer gpa.free(expect);
    dir.access(io, expect, .{}) catch return false;
    return true;
}

/// `prefix/name`; a `"."` root contributes no prefix, so the paths read
/// `src/main.bp` exactly as the `src/`-only scan printed them.
fn childPath(gpa: std.mem.Allocator, prefix: []const u8, name: []const u8) ![]const u8 {
    if (prefix.len == 0) return gpa.dupe(u8, name);
    return std.fs.path.join(gpa, &.{ prefix, name });
}

fn isDirectory(io: std.Io, path: []const u8) bool {
    const st = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    return st.kind == .directory;
}

fn pathLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

/// Every source file under `root` (a path relative to cwd, or `"."`), appended
/// to `out` as `gpa`-owned paths that join `root` and the walk. Symlinks are not
/// followed: what one points at is reached where it lives.
pub fn collectTree(
    gpa: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    out: *std.ArrayListUnmanaged([]const u8),
) !void {
    var dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true, .access_sub_paths = true });
    defer dir.close(io);
    const prefix: []const u8 = if (std.mem.eql(u8, root, ".")) "" else root;
    try collectDir(gpa, io, dir, prefix, out);
}

fn collectDir(
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    prefix: []const u8,
    out: *std.ArrayListUnmanaged([]const u8),
) anyerror!void {
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        switch (entry.kind) {
            .directory => {
                if (!entersDirectory(entry.name)) continue;
                var sub = try dir.openDir(io, entry.name, .{ .iterate = true, .access_sub_paths = true });
                defer sub.close(io);
                const sub_prefix = try childPath(gpa, prefix, entry.name);
                defer gpa.free(sub_prefix);
                try collectDir(gpa, io, sub, sub_prefix, out);
            },
            .file => {
                if (!hasSourceExt(entry.name)) continue;
                if (try isRejectedProgram(gpa, io, dir, prefix, entry.name)) continue;
                try out.append(gpa, try childPath(gpa, prefix, entry.name));
            },
            else => {},
        }
    }
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

    // Format. A file ends with exactly one newline.
    const body = try bp.format.format(arena, program);
    const formatted = if (body.len == 0) body else try std.mem.concat(arena, u8, &.{ std.mem.trimEnd(u8, body, "\n"), "\n" });

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

// ── tests ─────────────────────────────────────────────────────────────────────
//
// The walk is exercised on a synthetic tree under a unique relative directory
// (resolved against the test cwd, as `libs.zig`'s tests do), so neither the
// process cwd nor the real repository layout is touched. The exit codes and the
// report are `tests/cli_contract.sh`'s (decision 66's row), against the binary.

fn writeFileP(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

fn collectSorted(gpa: std.mem.Allocator, io: std.Io, root: []const u8) ![]const []const u8 {
    var paths: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer {
        for (paths.items) |p| gpa.free(p);
        paths.deinit(gpa);
    }
    try collectTree(gpa, io, root, &paths);
    std.mem.sort([]const u8, paths.items, {}, pathLessThan);
    return paths.toOwnedSlice(gpa);
}

fn freePaths(gpa: std.mem.Allocator, paths: []const []const u8) void {
    for (paths) |p| gpa.free(p);
    gpa.free(paths);
}

test "decision 66: the walk reaches src/, test/, examples/, a nested project and every .d.bp" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const root = ".botopinkbuild/format-walk/whole";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/format-walk") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/format-walk") catch {};
    try writeFileP(io, root ++ "/botopink.json", "{}");
    try writeFileP(io, root ++ "/src/main.bp", "");
    try writeFileP(io, root ++ "/src/types.d.bp", "");
    try writeFileP(io, root ++ "/src/README.md", "");
    try writeFileP(io, root ++ "/test/main_test.bp", "");
    try writeFileP(io, root ++ "/examples/nested/botopink.json", "{}");
    try writeFileP(io, root ++ "/examples/nested/src/main.bp", "");
    try writeFileP(io, root ++ "/examples/nested/test/app_test.botopink", "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        root ++ "/examples/nested/src/main.bp",
        root ++ "/examples/nested/test/app_test.botopink",
        root ++ "/src/main.bp",
        root ++ "/src/types.d.bp",
        root ++ "/test/main_test.bp",
    };
    try std.testing.expectEqual(want.len, paths.len);
    for (want, paths) |w, got| try std.testing.expectEqualStrings(w, got);
}

test "decision 66/67: hidden directories and node_modules are not entered; reject/<n>.bp beside <n>.expect is not reached, a lone reject/ .bp is" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const root = ".botopinkbuild/format-walk/exempt";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/format-walk") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/format-walk") catch {};
    try writeFileP(io, root ++ "/src/main.bp", "");
    // The language suite's shape, at the depth the suite has it and at the root.
    try writeFileP(io, root ++ "/tests/language/reject/case_bare_name_arm.bp", "");
    try writeFileP(io, root ++ "/tests/language/reject/case_bare_name_arm.expect", "");
    try writeFileP(io, root ++ "/reject/bad.bp", "");
    try writeFileP(io, root ++ "/reject/bad.expect", "");
    // Not the fixture: no `.expect`, so the runner would fail it too — reached.
    try writeFileP(io, root ++ "/reject/lone.bp", "");
    // A directory merely *containing* the word is not the directory.
    try writeFileP(io, root ++ "/rejected/ok.bp", "");
    try writeFileP(io, root ++ "/rejected/ok.expect", "");
    // Tool state and another package manager's store.
    try writeFileP(io, root ++ "/.botopinkbuild/tmp/scratch.bp", "");
    try writeFileP(io, root ++ "/.git/hooks/x.bp", "");
    try writeFileP(io, root ++ "/node_modules/dep/src/dep.bp", "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        root ++ "/reject/lone.bp",
        root ++ "/rejected/ok.bp",
        root ++ "/src/main.bp",
    };
    try std.testing.expectEqual(want.len, paths.len);
    for (want, paths) |w, got| try std.testing.expectEqualStrings(w, got);
}

test "decision 66: a `.` root contributes no prefix, an explicit root is kept" {
    const gpa = std.testing.allocator;
    const bare = try childPath(gpa, "", "src");
    defer gpa.free(bare);
    try std.testing.expectEqualStrings("src", bare);
    const nested = try childPath(gpa, "examples/nested", "src");
    defer gpa.free(nested);
    try std.testing.expectEqualStrings("examples" ++ std.fs.path.sep_str ++ "nested" ++ std.fs.path.sep_str ++ "src", nested);
    try std.testing.expect(hasSourceExt("a.d.bp"));
    try std.testing.expect(!hasSourceExt("a.bp.md"));
    try std.testing.expect(!entersDirectory(".zig-cache"));
    try std.testing.expect(entersDirectory("reject"));
}
