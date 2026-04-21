/// Snapshot infrastructure for LSP engine tests.
///
/// Unified module: handles both file I/O (write/compare .snap.md files)
/// and LSP-specific result rendering.
///
/// Mirrors `compiler-core/src/comptime/snapshot.zig` but for LSP responses.
///
/// On the **first run** a missing snapshot is created from the actual output.
/// On subsequent runs the saved file is compared against the new output.
/// A mismatch writes a `.new` file and returns `error.SnapshotMismatch`.
///
/// Snapshot files: `snapshots/lsp/{slug}.snap.md` (relative to test CWD,
/// which build.zig sets to `modules/language-server/`).
///
/// Snap format (inspired by Gleam's language-server snapshots):
///   ----- SOURCE
///   ```botopink
///   val x = 42;
///   ```
///   ----- HOVER at (line 0, char 4)
///   kind: markdown
///   ```botopink
///   x : i32
///   ```
const std = @import("std");
const proto = @import("../protocol.zig");

pub const SNAP_DIR = "snapshots/lsp";

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  File I/O — create / compare .snap.md files                                ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

/// Compare `text` against `snapshots/lsp/{slug}.snap.md`.
/// Creates the file on first run. Returns `error.SnapshotMismatch` on diff.
pub fn checkText(allocator: std.mem.Allocator, slug: []const u8, text: []const u8) !void {
    const path = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.snap.md", .{slug});
    defer allocator.free(path);
    try compareOrCreate(allocator, path, text);
}

fn compareOrCreate(allocator: std.mem.Allocator, snap_path: []const u8, got: []const u8) !void {
    const existing = readFile(allocator, snap_path) catch |err| switch (err) {
        error.FileNotFound => {
            try writeFile(snap_path, got);
            std.debug.print("snap created: {s}\n", .{snap_path});
            return;
        },
        else => return err,
    };
    defer allocator.free(existing);

    const expected = std.mem.trim(u8, existing, "\n\r ");
    const actual = std.mem.trim(u8, got, "\n\r ");

    if (std.mem.eql(u8, expected, actual)) {
        const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snap_path});
        defer allocator.free(new_path);
        deleteFile(new_path);
        return;
    }

    const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snap_path});
    defer allocator.free(new_path);
    try writeFile(new_path, got);
    std.debug.print("\nsnap mismatch: {s}\nnew output → {s}\n", .{ snap_path, new_path });
    return error.SnapshotMismatch;
}

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(std.testing.io, path, allocator, .unlimited);
}

fn writeFile(path: []const u8, content: []const u8) !void {
    const io = std.testing.io;
    const cwd = std.Io.Dir.cwd();
    const dir_part: []const u8 = blk: {
        var i = path.len;
        while (i > 0) : (i -= 1) {
            if (path[i - 1] == '/' or path[i - 1] == '\\') break :blk path[0 .. i - 1];
        }
        break :blk "";
    };
    if (dir_part.len > 0) {
        cwd.createDirPath(io, dir_part) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
    try cwd.writeFile(io, .{ .sub_path = path, .data = content });
}

fn deleteFile(path: []const u8) void {
    std.Io.Dir.cwd().deleteFile(std.testing.io, path) catch {};
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  LSP result renderers + assert* functions                                  ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

// ── Hover ─────────────────────────────────────────────────────────────────────

pub fn assertHover(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.Hover,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- HOVER at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |hov| {
        try buf.print(gpa, "kind: {s}\n\n{s}\n", .{ hov.contents.kind, hov.contents.value });
    } else {
        try buf.appendSlice(gpa, "null\n");
    }

    try checkText(gpa, slug, buf.items);
}

// ── Definition ────────────────────────────────────────────────────────────────

pub fn assertDefinition(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.Location,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- DEFINITION at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |loc| {
        try buf.print(gpa, 
            "uri: {s}\nrange: ({d},{d}) → ({d},{d})\n",
            .{
                loc.uri,
                loc.range.start.line, loc.range.start.character,
                loc.range.end.line,   loc.range.end.character,
            },
        );
        try appendSourceWithUnderline(&buf, gpa, source, loc.range);
    } else {
        try buf.appendSlice(gpa, "null\n");
    }

    try checkText(gpa, slug, buf.items);
}

// ── Document Symbols ──────────────────────────────────────────────────────────

pub fn assertDocumentSymbols(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    symbols: []const proto.DocumentSymbol,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSource(&buf, gpa, source);
    try buf.appendSlice(gpa, "----- DOCUMENT SYMBOLS\n");
    for (symbols) |sym| {
        try buf.print(gpa, 
            "{s}  [{s}]  selection: ({d},{d})–({d},{d})\n",
            .{
                sym.name,
                symbolKindName(sym.kind),
                sym.selectionRange.start.line, sym.selectionRange.start.character,
                sym.selectionRange.end.line,   sym.selectionRange.end.character,
            },
        );
    }
    if (symbols.len == 0) try buf.appendSlice(gpa, "(empty)\n");

    try checkText(gpa, slug, buf.items);
}

// ── Completion ────────────────────────────────────────────────────────────────

pub fn assertCompletion(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    items: []const proto.CompletionItem,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- COMPLETION at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    for (items) |item| {
        const kind_str = if (item.kind) |k| completionKindName(k) else "?";
        const detail_str = item.detail orelse "";
        try buf.print(gpa, "{s}  [{s}]  detail: {s}\n", .{ item.label, kind_str, detail_str });
    }
    if (items.len == 0) try buf.appendSlice(gpa, "(empty)\n");

    try checkText(gpa, slug, buf.items);
}

// ── References ────────────────────────────────────────────────────────────────

pub fn assertReferences(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    locs: []const proto.Location,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- REFERENCES at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    for (locs) |loc| {
        try buf.print(gpa, 
            "  ({d},{d}) → ({d},{d})\n",
            .{
                loc.range.start.line, loc.range.start.character,
                loc.range.end.line,   loc.range.end.character,
            },
        );
    }
    if (locs.len == 0) try buf.appendSlice(gpa, "  (none)\n");

    try checkText(gpa, slug, buf.items);
}

// ── Rename ────────────────────────────────────────────────────────────────────

pub fn assertRename(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    new_name: []const u8,
    edits: []const proto.TextEdit,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa,
        "----- RENAME at (line {d}, char {d})  new name: \"{s}\"\n",
        .{ cursor.line, cursor.character, new_name },
    );
    for (edits, 1..) |edit, i| {
        try buf.print(gpa, 
            "  edit {d}: ({d},{d}) → ({d},{d})  \"{s}\"\n",
            .{
                i,
                edit.range.start.line, edit.range.start.character,
                edit.range.end.line,   edit.range.end.character,
                edit.newText,
            },
        );
    }
    if (edits.len == 0) try buf.appendSlice(gpa, "  (no edits)\n");

    try checkText(gpa, slug, buf.items);
}

// ── Signature Help ────────────────────────────────────────────────────────────

pub fn assertSignatureHelp(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.SignatureHelp,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- SIGNATURE HELP at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |sh| {
        const active_sig = sh.activeSignature orelse 0;
        const active_param = sh.activeParameter orelse 0;
        for (sh.signatures, 0..) |sig, si| {
            const marker: []const u8 = if (si == active_sig) "►" else " ";
            try buf.print(gpa, "{s} {s}\n", .{ marker, sig.label });
            if (sig.parameters) |params| {
                for (params, 0..) |param, pi| {
                    const active_marker: []const u8 = if (si == active_sig and pi == active_param) "▔" else " ";
                    try buf.print(gpa, "  param {d} [{s}]: {s}\n", .{ pi, active_marker, param.label });
                }
            }
        }
        try buf.print(gpa, "activeSignature: {d}  activeParameter: {d}\n", .{ active_sig, active_param });
    } else {
        try buf.appendSlice(gpa, "null\n");
    }

    try checkText(gpa, slug, buf.items);
}

// ── Inlay Hints ───────────────────────────────────────────────────────────────

pub fn assertInlayHints(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    hints: []const proto.InlayHint,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSource(&buf, gpa, source);
    try buf.appendSlice(gpa, "----- INLAY HINTS\n");
    for (hints) |hint| {
        try buf.print(gpa, "  ({d},{d})  {s}\n", .{ hint.position.line, hint.position.character, hint.label });
    }
    if (hints.len == 0) try buf.appendSlice(gpa, "  (none)\n");

    try checkText(gpa, slug, buf.items);
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Internal helpers                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

fn appendSource(buf: *std.ArrayList(u8), gpa: std.mem.Allocator, source: []const u8) !void {
    try appendSourceWithCursor(buf, gpa, source, null);
}

/// Renders the source inside a ```botopink code block.
/// When `cursor` is non-null, a line with `↑` is printed immediately after
/// the cursor's line, aligned to `cursor.character` — matching Gleam's style.
fn appendSourceWithCursor(
    buf: *std.ArrayList(u8),
    gpa: std.mem.Allocator,
    source: []const u8,
    cursor: ?proto.Position,
) !void {
    try buf.appendSlice(gpa, "----- SOURCE\n```botopink\n");

    var line_idx: u32 = 0;
    var it = std.mem.splitScalar(u8, source, '\n');
    while (it.next()) |line| {
        // Skip the empty trailing segment produced by a final '\n'.
        if (it.index == null and line.len == 0) break;

        try buf.appendSlice(gpa, line);
        try buf.append(gpa, '\n');

        if (cursor) |cur| {
            if (cur.line == line_idx) {
                // Pad spaces up to cursor column, then ↑.
                var col: u32 = 0;
                while (col < cur.character) : (col += 1)
                    try buf.append(gpa, ' ');
                try buf.appendSlice(gpa, "↑\n");
            }
        }

        line_idx += 1;
    }

    try buf.appendSlice(gpa, "```\n\n");
}

/// Appends the declaration line with a `^` underline under the selected range
/// (same visual style as Gleam's snapshots, adapted to ASCII).
fn appendSourceWithUnderline(
    buf: *std.ArrayList(u8),
    gpa: std.mem.Allocator,
    source: []const u8,
    range: proto.Range,
) !void {
    // use buf.print(gpa, ...) directly
    // Collect lines.
    var lines_buf: [256][]const u8 = undefined;
    var line_count: usize = 0;
    var it = std.mem.splitScalar(u8, source, '\n');
    while (it.next()) |line| {
        if (line_count < lines_buf.len) {
            lines_buf[line_count] = line;
            line_count += 1;
        }
    }
    const lines = lines_buf[0..line_count];
    if (range.start.line >= lines.len) return;

    const line_text = lines[range.start.line];
    try buf.print(gpa, "  {s}\n  ", .{line_text});

    const col_start = range.start.character;
    const col_end = if (range.end.line == range.start.line)
        range.end.character
    else
        @as(u32, @intCast(line_text.len));

    var col: u32 = 0;
    while (col < col_start) : (col += 1) try buf.append(gpa, ' ');
    while (col < col_end) : (col += 1) try buf.append(gpa, '^');
    try buf.append(gpa, '\n');
}

fn symbolKindName(kind: u32) []const u8 {
    return switch (kind) {
        proto.SymbolKind.Function  => "Function",
        proto.SymbolKind.Variable  => "Variable",
        proto.SymbolKind.Struct    => "Struct",
        proto.SymbolKind.Enum      => "Enum",
        proto.SymbolKind.Interface => "Interface",
        proto.SymbolKind.Constant  => "Constant",
        else => "?",
    };
}

fn completionKindName(kind: u32) []const u8 {
    return switch (kind) {
        proto.CompletionItemKind.Function  => "Function",
        proto.CompletionItemKind.Variable  => "Variable",
        proto.CompletionItemKind.Struct    => "Struct",
        proto.CompletionItemKind.Enum      => "Enum",
        proto.CompletionItemKind.Interface => "Interface",
        else => "?",
    };
}
