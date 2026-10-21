/// `botopink format` — format source files with the Wadler-Lindig pretty-printer.
///
/// **Scope** ([decision 66](../../../../../specs/1.0.5-beta/decisions-taken.md)):
/// with no argument the command reaches every `.bp` under
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
/// own), and a conformance cell's refused module: a `.bp` under a cell (a
/// directory holding `snapshot/output/`, decisions 457 and 475) whose
/// `snapshot/output/<module>.snap` holds a `refused` record — a module every
/// target refuses, written to be refused, which `format` may not be able to
/// parse by design (`conformance/modules/decisions-taken/refusal_snap_claims_label-485/cells/case_bare_name_arm/src/main.bp`,
/// `conformance/modules/lexer/cells/lexer_error_in_imported_module/src/pattern.bp`).
/// Decided by the cell's own evidence: a module only some targets refuse
/// (a `snapshot/targets/<t>/` departure) is reached like any other file. There
/// is no skip list, no pragma and no environment variable, and this file must
/// not grow one.
const std = @import("std");
const bp = @import("botopink");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");
const reporter = @import("./reporter.zig");
const diagnostics = @import("./diagnostics.zig");
const manifest = @import("manifest");
const bpp_unfold = @import("./bpp_unfold.zig");

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

/// Every source extension (`manifest.SOURCE_EXTENSIONS`, the one list every
/// tool reads) — a name ending in `.d.bp` is a module like any other (decision
/// 575 (1)) — and every `.bpp`, whose header `format` prints as a module (front 116 step 5).
fn hasSourceExt(name: []const u8) bool {
    return manifest.isSourceFile(name);
}

fn stripExt(name: []const u8) []const u8 {
    return manifest.stripSourceExt(name);
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

/// A conformance cell's refused module (decision 67's structural exemption,
/// read off the cell's own snapshots): the innermost directory above the file
/// that holds `snapshot/output/` is the cell, and the module is the file's
/// path from the cell — `src/` dropped, `.bp` dropped, as `botopink cell check`
/// names a module's snapshot (`src/shapes/circle.bp` → `shapes/circle`,
/// `deps/lib/src/x.bp` → `deps/lib/src/x`). The file is exempt when
/// `snapshot/output/<module>.snap` holds a `refused` record: every target
/// refuses it. A file outside any cell, a module with no `output/` snapshot,
/// and one whose `output/` answer is not a refusal are reached.
fn isRefusedCellModule(gpa: std.mem.Allocator, io: std.Io, prefix: []const u8, name: []const u8) !bool {
    var comps: std.ArrayListUnmanaged([]const u8) = .empty;
    defer comps.deinit(gpa);
    var it = std.mem.splitAny(u8, prefix, "/\\");
    while (it.next()) |c| {
        if (c.len > 0) try comps.append(gpa, c);
    }
    const absolute = prefix.len > 0 and (prefix[0] == '/' or prefix[0] == '\\');
    var i = comps.items.len;
    while (i > 0) : (i -= 1) {
        const joined = try std.mem.join(gpa, std.fs.path.sep_str, comps.items[0..i]);
        defer gpa.free(joined);
        const cell = if (absolute) try std.mem.concat(gpa, u8, &.{ std.fs.path.sep_str, joined }) else try gpa.dupe(u8, joined);
        defer gpa.free(cell);
        const output = try std.fs.path.join(gpa, &.{ cell, "snapshot", "output" });
        defer gpa.free(output);
        if (!isDirectory(io, output)) continue;

        // The module: the path from the cell, `/`-separated, `src/` and `.bp` dropped.
        var rel: std.ArrayListUnmanaged(u8) = .empty;
        defer rel.deinit(gpa);
        for (comps.items[i..]) |c| {
            try rel.appendSlice(gpa, c);
            try rel.append(gpa, '/');
        }
        try rel.appendSlice(gpa, name);
        var module: []const u8 = rel.items;
        if (std.mem.startsWith(u8, module, "src/")) module = module["src/".len..];
        if (std.mem.endsWith(u8, module, ".bp")) module = module[0 .. module.len - ".bp".len];
        const snap_name = try std.mem.concat(gpa, u8, &.{ module, ".snap" });
        defer gpa.free(snap_name);
        const snap_path = try std.fs.path.join(gpa, &.{ output, snap_name });
        defer gpa.free(snap_path);
        const text = std.Io.Dir.cwd().readFileAlloc(io, snap_path, gpa, .limited(1024 * 1024)) catch return false;
        defer gpa.free(text);
        var lines = std.mem.splitScalar(u8, text, '\n');
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "refused ")) return true;
        }
        return false;
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
                if (try isRefusedCellModule(gpa, io, prefix, entry.name)) continue;
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
    if (manifest.isBppFile(path)) return formatBpp(gpa, io, arena, path, source, check_only);

    // Lex and parse.
    var lexer = bp.Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch |err| {
        diagnostics.printLexError(gpa, &lexer, err, source, path);
        return .invalid;
    };

    var parser = bp.Parser.init(tokens);
    parser.keep_surface = true;
    const program = parser.parse(arena) catch |err| {
        diagnostics.printParseError(gpa, &parser, err, source, path);
        return .invalid;
    };

    // Decisions 622, 846 — the shortform `fn f(x: T) R` is refused, never rewritten.
    if (bp.format.firstReturnMissing(program)) |f| {
        var aw: std.Io.Writer.Allocating = .init(arena);
        const hint = f.arrowOmittedHint orelse "";
        const msg = try std.fmt.allocPrint(arena, "fn-return-missing: `{s}` writes no return type — write `-> {s}…`", .{ f.name, hint });
        try diagnostics.renderLocated(&aw.writer, msg, path, source, f.nameLoc.line, f.nameLoc.col, f.name.len);
        reporter.print("{s}", .{aw.written()});
        return .invalid;
    }

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

/// A `.bpp` file (front 116 step 5): its header is formatted as a module —
/// its declarations at the top, its statements as a function body's, the
/// decorator of its last line after them — and every byte from its first
/// separator line on (the style section, the markup) is left as written.
fn formatBpp(gpa: std.mem.Allocator, io: std.Io, arena: std.mem.Allocator, path: []const u8, source: []const u8, check_only: bool) !FileResult {
    const secs = switch (bpp_unfold.sections(source)) {
        .ok => |x| x,
        .refused => |r| {
            var aw: std.Io.Writer.Allocating = .init(arena);
            try diagnostics.renderLocated(&aw.writer, r.message, path, source, r.line, r.col, 1);
            reporter.print("{s}", .{aw.written()});
            return .invalid;
        },
    };
    const header = source[0..secs.header_end];
    const formatted_header = (try formatHeader(gpa, arena, path, source, header)) orelse return .invalid;
    const formatted = try std.mem.concat(arena, u8, &.{ formatted_header, source[secs.header_end..] });
    if (std.mem.eql(u8, source, formatted)) {
        reporter.formatUnchanged(path);
        return .unchanged;
    }
    if (check_only) {
        reporter.formatChanged(path);
        return .changed;
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = formatted });
    reporter.formatChanged(path);
    return .changed;
}

const HEADER_FN = "__bppHeader__";

/// The header (`header`, the start of `source`) formatted, ending with one
/// newline (empty for an empty header); null when it does not lex or parse —
/// the located diagnostic printed at the file's own line and column.
fn formatHeader(gpa: std.mem.Allocator, arena: std.mem.Allocator, path: []const u8, source: []const u8, header: []const u8) !?[]const u8 {
    if (std.mem.trim(u8, header, " \t\r\n").len == 0) return header;
    var lx = bp.Lexer.init(header);
    const all = lx.scanAll(arena) catch |err| {
        diagnostics.printLexError(gpa, &lx, err, source, path);
        return null;
    };
    var toks: std.ArrayListUnmanaged(bp.Token) = .empty;
    for (all) |t| switch (t.kind) {
        .endOfFile, .commentNormal, .commentDoc, .commentModule, .newLine => {},
        else => try toks.append(arena, t),
    };
    const its = (try bpp_unfold.items(arena, header, toks.items)) orelse return try refuseHeader(gpa, arena, path, source);
    // A module of the header: each item with the comments before it, the
    // declarations first, the statements in a function's body, the last
    // line's decorator on that function.
    var decls: std.ArrayListUnmanaged(u8) = .empty;
    var stmts: std.ArrayListUnmanaged(u8) = .empty;
    var decorator: []const u8 = "";
    var cursor: usize = 0;
    for (its) |it| {
        const gap = std.mem.trim(u8, header[cursor..it.start], " \t\r\n");
        const text = header[it.start..it.end];
        const into = switch (it.kind) {
            .declaration => &decls,
            .statement => &stmts,
            .annotations => blk: {
                decorator = text;
                break :blk &stmts;
            },
        };
        // A blank line before the item, as written, is kept.
        if (into.items.len > 0 and std.mem.count(u8, header[cursor..it.start], "\n") >= 2) try into.append(arena, '\n');
        if (gap.len > 0) {
            try into.appendSlice(arena, gap);
            try into.append(arena, '\n');
        }
        if (it.kind != .annotations) {
            try into.appendSlice(arena, text);
            try into.append(arena, '\n');
        }
        cursor = it.end;
    }
    const tail = std.mem.trim(u8, header[cursor..], " \t\r\n");
    const has_fn = stmts.items.len > 0 or decorator.len > 0 or tail.len > 0;
    const module = if (has_fn)
        try std.fmt.allocPrint(arena, "{s}\n{s}\nfn " ++ HEADER_FN ++ "() {{\n{s}{s}\n}}\n", .{ decls.items, decorator, stmts.items, tail })
    else
        decls.items;
    var mlx = bp.Lexer.init(module);
    const mtoks = mlx.scanAll(arena) catch return try refuseHeader(gpa, arena, path, source);
    var parser = bp.Parser.init(mtoks);
    parser.keep_surface = true;
    const program = parser.parse(arena) catch return try refuseHeader(gpa, arena, path, source);
    const body = std.mem.trimEnd(u8, try bp.format.format(arena, program), "\n");
    if (!has_fn) return try std.mem.concat(arena, u8, &.{ body, "\n" });
    // Split the formatted module at the function's head.
    const head = "fn " ++ HEADER_FN ++ "() {";
    const at = std.mem.indexOf(u8, body, head) orelse return try refuseHeader(gpa, arena, path, source);
    var before = std.mem.trimEnd(u8, body[0..at], " \t\n");
    // The decorator's lines, right above the head, move after the statements.
    var deco_out: []const u8 = "";
    if (decorator.len > 0) {
        const nl = std.mem.lastIndexOfScalar(u8, before, '\n');
        const start = if (nl) |n| n + 1 else 0;
        deco_out = before[start..];
        before = std.mem.trimEnd(u8, before[0..start], " \t\n");
    }
    var inner = body[at + head.len ..];
    inner = std.mem.trimStart(u8, inner, "\n");
    const close = std.mem.lastIndexOfScalar(u8, inner, '}') orelse inner.len;
    inner = std.mem.trimEnd(u8, inner[0..close], " \t\n");
    var out: std.ArrayListUnmanaged(u8) = .empty;
    if (before.len > 0) {
        try out.appendSlice(arena, before);
        try out.appendSlice(arena, if (inner.len > 0 or deco_out.len > 0) "\n\n" else "\n");
    }
    var lines = std.mem.splitScalar(u8, inner, '\n');
    while (lines.next()) |line| {
        if (inner.len == 0) break;
        const dedented = if (std.mem.startsWith(u8, line, "    ")) line[4..] else line;
        try out.appendSlice(arena, dedented);
        try out.append(arena, '\n');
    }
    if (deco_out.len > 0) {
        try out.appendSlice(arena, deco_out);
        try out.append(arena, '\n');
    }
    return out.items;
}

/// The header does not parse: the file is unfolded as the toolchain reads it,
/// and the parse error is printed at the file's own line and column.
fn refuseHeader(gpa: std.mem.Allocator, arena: std.mem.Allocator, path: []const u8, source: []const u8) !?[]const u8 {
    const spec: bpp_unfold.Spec = .{ .html = .{ .package = "bpp", .path = "", .name = "html" }, .style = .{ .package = "bpp", .path = "", .name = "style" }, .ret = "i32" };
    const unfolded = switch (try bpp_unfold.unfoldFile(gpa, arena, path, source, spec)) {
        .ok => |text| text,
        .refused => |r| {
            var aw: std.Io.Writer.Allocating = .init(arena);
            try diagnostics.renderLocated(&aw.writer, r.message, path, source, r.line, r.col, 1);
            reporter.print("{s}", .{aw.written()});
            return null;
        },
    };
    defer gpa.free(unfolded);
    var lx = bp.Lexer.init(unfolded);
    const toks = lx.scanAll(arena) catch |err| {
        diagnostics.printLexError(gpa, &lx, err, unfolded, path);
        return null;
    };
    var parser = bp.Parser.init(toks);
    _ = parser.parse(arena) catch |err| {
        diagnostics.printParseError(gpa, &parser, err, unfolded, path);
        return null;
    };
    reporter.errMsg(try std.fmt.allocPrint(arena, "{s}: the header could not be formatted as a module", .{path}));
    return null;
}

test "bpp format: the header is formatted as a module, the markup and the style section byte for byte" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const header =
        \\import {lib.db.Post};
        \\type   Props(title:string)
        \\   val n=props.title.length();
        \\#[page("/")]
        \\
    ;
    const got = (try formatHeader(std.testing.allocator, a, "Card.bpp", header, header)).?;
    try std.testing.expectEqualStrings(
        \\import {lib.db.Post};
        \\
        \\type Props(title: string)
        \\
        \\val n = props.title.length();
        \\#[page("/")]
        \\
    , got);
    const again = (try formatHeader(std.testing.allocator, a, "Card.bpp", got, got)).?;
    try std.testing.expectEqualStrings(got, again);
    try std.testing.expectEqualStrings("", (try formatHeader(std.testing.allocator, a, "Bare.bpp", "", "")).?);
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

test "decision 66: the walk reaches src/, test/, examples/, a nested project and a .d.bp (a module `types.d`)" {
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

test "decision 66/67: hidden directories and node_modules are not entered" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const root = test_scratch.path(io, "format-walk/exempt");
    test_scratch.remove(io, "format-walk");
    defer test_scratch.remove(io, "format-walk");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/src/main.bp"), "");
    // The old language suite's `reject/<n>.bp` beside `<n>.expect` is no
    // fixture any more: reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/reject/bad.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/reject/bad.expect"), "");
    // Tool state and another package manager's store. The build directory is
    // fixture CONTENT here — a hidden directory the walk must not enter — so it
    // is named relative to the scratch root, never at the cwd.
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/.botopinkbuild/tmp/scratch.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/.git/hooks/x.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/exempt/node_modules/dep/src/dep.bp"), "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        test_scratch.path(io, "format-walk/exempt/reject/bad.bp"),
        test_scratch.path(io, "format-walk/exempt/src/main.bp"),
    };
    try std.testing.expectEqual(want.len, paths.len);
    for (want, paths) |w, got| try std.testing.expectEqualStrings(w, got);
}

test "decision 67: a cell's module every target refuses (output/<module>.snap holds `refused`) is not reached; a departure's refusal, an answer, no snapshot or no cell is" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const refused = "botopink-cell 1\nrefused error: bad string escape\nat src/pattern.bp:3:2\n";
    const prints = "botopink-cell 1\nout ok\n";
    const root = test_scratch.path(io, "format-walk/cells");
    test_scratch.remove(io, "format-walk");
    defer test_scratch.remove(io, "format-walk");
    // The fixture: `output/pattern.snap` refuses the module — not reached; its
    // sibling `main` prints — reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/lexer_error/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/lexer_error/snapshot/output/pattern.snap"), refused);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/lexer_error/snapshot/output/main.snap"), prints);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/lexer_error/src/pattern.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/lexer_error/src/main.bp"), "");
    // A folder module and a dependency's module are named from the cell.
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/nested/snapshot/output/shapes/circle.snap"), refused);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/nested/snapshot/output/deps/lib/src/x.snap"), refused);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/nested/src/shapes/circle.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/nested/deps/lib/src/x.bp"), "");
    // Refused on one target only (a departure): reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/departs/snapshot/output/main.snap"), prints);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/departs/snapshot/targets/wasm/main.snap"), refused);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/departs/src/main.bp"), "");
    // A module with no output/ snapshot, and a refusal outside any cell: reached.
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/unanswered/snapshot/output/main.snap"), prints);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/modules/unanswered/src/other.bp"), "");
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/elsewhere/output/main.snap"), refused);
    try writeFileP(io, test_scratch.path(io, "format-walk/cells/elsewhere/src/main.bp"), "");

    const paths = try collectSorted(gpa, io, root);
    defer freePaths(gpa, paths);

    const want = [_][]const u8{
        test_scratch.path(io, "format-walk/cells/elsewhere/src/main.bp"),
        test_scratch.path(io, "format-walk/cells/modules/departs/src/main.bp"),
        test_scratch.path(io, "format-walk/cells/modules/lexer_error/src/main.bp"),
        test_scratch.path(io, "format-walk/cells/modules/unanswered/src/other.bp"),
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
