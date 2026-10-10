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
/// The same rule one step further (gate-c of `specs/1.0.11-beta/00-gate`): a
/// `.bp` under a `modules/<cell>/` directory that one of the cell's
/// `<target>.expect` files names and that does not lex or parse is a project
/// cell's refused module — `tests/language/modules/lexer_error_in_imported_module/
/// src/pattern.bp`, a bad string escape on purpose — and is left out the same
/// way, decided by the cell's own evidence. There is no skip list, no pragma and
/// no environment variable, and this file must not grow one.
const std = @import("std");
const bp = @import("botopink");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");
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

/// A project cell's refused module (gate-c: decision 67's `reject/` rule
/// generalised to a `modules/<cell>/` directory). The file is the fixture
/// working when both halves of the cell's own evidence hold:
///   - one of the cell's `<target>.expect` files (a file directly in the cell,
///     `tests/language/run.sh`'s shape: line 1 the message, line 2
///     `<path from the cell>:<L>:<C>`) names *this* file on its second line;
///   - the file does not lex or parse — the refusal the cell pins is the one
///     `format` would print.
/// An `.expect` naming another file leaves this one in the walk; so does a named
/// file that parses (its refusal is the checker's, and the formatter prints it
/// like any other file). The cell is the child of the innermost `modules`
/// component of the path; a file outside a `modules/<cell>/` is never this
/// fixture, whatever sits beside it. The line and column are the runner's to
/// compare, not the formatter's.
fn isRefusedProjectModule(gpa: std.mem.Allocator, io: std.Io, prefix: []const u8, name: []const u8) !bool {
    // Find `modules/<cell>` — the innermost `modules` component that has a child.
    var comps: std.ArrayListUnmanaged([]const u8) = .empty;
    defer comps.deinit(gpa);
    var it = std.mem.splitAny(u8, prefix, "/\\");
    while (it.next()) |c| {
        if (c.len > 0) try comps.append(gpa, c);
    }
    var cell_end: ?usize = null;
    var i = comps.items.len;
    while (i > 1) : (i -= 1) {
        if (std.mem.eql(u8, comps.items[i - 2], "modules")) {
            cell_end = i;
            break;
        }
    }
    const end = cell_end orelse return false;
    const cell_path = try std.mem.join(gpa, std.fs.path.sep_str, comps.items[0..end]);
    defer gpa.free(cell_path);
    // Absolute roots keep their leading separator (`join` drops it).
    const cell_abs = if (prefix.len > 0 and (prefix[0] == '/' or prefix[0] == '\\'))
        try std.mem.concat(gpa, u8, &.{ std.fs.path.sep_str, cell_path })
    else
        try gpa.dupe(u8, cell_path);
    defer gpa.free(cell_abs);
    // The file's path from the cell, with `/` — the shape the `.expect` writes.
    var rel: std.ArrayListUnmanaged(u8) = .empty;
    defer rel.deinit(gpa);
    for (comps.items[end..]) |c| {
        try rel.appendSlice(gpa, c);
        try rel.append(gpa, '/');
    }
    try rel.appendSlice(gpa, name);

    if (!try expectNamesFile(gpa, io, cell_abs, rel.items)) return false;

    // Named by the cell: exempt only if it really does not lex or parse.
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    const path = try childPath(gpa, prefix, name);
    defer gpa.free(path);
    const source = try std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited);
    var lexer = bp.Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch return true;
    var parser = bp.Parser.init(tokens);
    _ = parser.parse(arena) catch return true;
    return false;
}

/// Does a `<target>.expect` directly in `cell_path` name `rel` (its second line,
/// up to the first `:`) as the refused file? Separators are compared as `/`.
fn expectNamesFile(gpa: std.mem.Allocator, io: std.Io, cell_path: []const u8, rel: []const u8) !bool {
    var cell = std.Io.Dir.cwd().openDir(io, cell_path, .{ .iterate = true }) catch return false;
    defer cell.close(io);
    var it = cell.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".expect")) continue;
        const text = cell.readFileAlloc(io, entry.name, gpa, .limited(64 * 1024)) catch continue;
        defer gpa.free(text);
        var lines = std.mem.splitScalar(u8, text, '\n');
        _ = lines.next() orelse continue;
        const second = std.mem.trimEnd(u8, lines.next() orelse continue, "\r");
        const named = second[0 .. std.mem.indexOfScalar(u8, second, ':') orelse second.len];
        if (named.len != rel.len) continue;
        var same = true;
        for (named, rel) |a, b| {
            const na: u8 = if (a == '\\') '/' else a;
            if (na != b) {
                same = false;
                break;
            }
        }
        if (same) return true;
    }
    return false;
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
                if (try isRefusedProjectModule(gpa, io, prefix, entry.name)) continue;
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

    const root = test_scratch.path(io, "format-walk/whole");
    test_scratch.remove(io, "format-walk");
    defer test_scratch.remove(io, "format-walk");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/src/main.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/src/types.d.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/src/README.md"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/test/main_test.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/examples/nested/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/examples/nested/src/main.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/whole/examples/nested/test/app_test.botopink"), "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        test_scratch.path(io, "format-walk/whole/examples/nested/src/main.bp"),
        test_scratch.path(io, "format-walk/whole/examples/nested/test/app_test.botopink"),
        test_scratch.path(io, "format-walk/whole/src/main.bp"),
        test_scratch.path(io, "format-walk/whole/src/types.d.bp"),
        test_scratch.path(io, "format-walk/whole/test/main_test.bp"),
    };
    try std.testing.expectEqual(want.len, paths.len);
    for (want, paths) |w, got| try std.testing.expectEqualStrings(w, got);
}

test "decision 66/67: hidden directories and node_modules are not entered; reject/<n>.bp beside <n>.expect is not reached, a lone reject/ .bp is" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const root = test_scratch.path(io, "format-walk/exempt");
    test_scratch.remove(io, "format-walk");
    defer test_scratch.remove(io, "format-walk");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/src/main.bp"), "");
    // The language suite's shape, at the depth the suite has it and at the root.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/tests/language/reject/case_bare_name_arm.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/tests/language/reject/case_bare_name_arm.expect"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/reject/bad.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/reject/bad.expect"), "");
    // Not the fixture: no `.expect`, so the runner would fail it too — reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/reject/lone.bp"), "");
    // A directory merely *containing* the word is not the directory.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/rejected/ok.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/rejected/ok.expect"), "");
    // Tool state and another package manager's store. The build directory is
    // fixture CONTENT here — a hidden directory the walk must not enter — so it
    // is named relative to the scratch root, never at the cwd.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/.botopinkbuild/tmp/scratch.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/.git/hooks/x.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/node_modules/dep/src/dep.bp"), "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        test_scratch.path(io, "format-walk/exempt/reject/lone.bp"),
        test_scratch.path(io, "format-walk/exempt/rejected/ok.bp"),
        test_scratch.path(io, "format-walk/exempt/src/main.bp"),
    };
    try std.testing.expectEqual(want.len, paths.len);
    for (want, paths) |w, got| try std.testing.expectEqualStrings(w, got);
}

test "gate-c: a modules/<cell>/ file named by the cell's .expect and unlexable is not reached; named-but-parsing, unnamed, or outside modules/ is" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    // `tests/language/modules/lexer_error_in_imported_module/src/pattern.bp`'s
    // bytes: a bad string escape on line 3, what the cell exists to refuse.
    const unlexable =
        \\pub fn dotted() -> string {
        \\    return """
        \\a\.b
        \\""";
        \\}
        \\
    ;
    const parses =
        \\pub fn main() {
        \\}
        \\
    ;

    const root = test_scratch.path(io, "format-walk/refused");
    test_scratch.remove(io, "format-walk");
    defer test_scratch.remove(io, "format-walk");
    // The fixture: every `.expect` of the cell names the file, and it does not lex.
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/lexer_error/commonJS.expect"), "bad string escape\nsrc/pattern.bp:3:2\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/lexer_error/erlang.expect"), "bad string escape\nsrc/pattern.bp:3:2\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/lexer_error/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/lexer_error/src/pattern.bp"), unlexable);
    // Its sibling module is not named — reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/lexer_error/src/main.bp"), parses);
    // The `.expect` names another file — this one is reached (and fails there).
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/other_file/wasm.expect"), "bad string escape\nsrc/other.bp:3:2\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/other_file/src/pattern.bp"), unlexable);
    // Named, but it parses: the refusal is the checker's — reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/checker_error/commonJS.expect"), "unbound variable\nsrc/main.bp:1:1\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/checker_error/src/main.bp"), parses);
    // A nested project inside a cell (`deps/<dep>/src`) is named from the cell.
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/dep_error/beam.expect"), "bad string escape\ndeps/lib/src/pattern.bp:3:2\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/modules/dep_error/deps/lib/src/pattern.bp"), unlexable);
    // The same pair outside a `modules/` directory is not this fixture — reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/cells/lexer_error/commonJS.expect"), "bad string escape\nsrc/pattern.bp:3:2\n");
    try writeFileP(io, test_scratch.path(io, "format-walk/refused/cells/lexer_error/src/pattern.bp"), unlexable);

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        test_scratch.path(io, "format-walk/refused/cells/lexer_error/src/pattern.bp"),
        test_scratch.path(io, "format-walk/refused/modules/checker_error/src/main.bp"),
        test_scratch.path(io, "format-walk/refused/modules/lexer_error/src/main.bp"),
        test_scratch.path(io, "format-walk/refused/modules/other_file/src/pattern.bp"),
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
