/// Snapshot infrastructure for LSP engine tests.
///
/// Unified module: handles both file I/O (write/compare .snap.md files)
/// and LSP-specific result rendering.
///
/// Mirrors `compiler-core/src/comptime/snapshot.zig` but for LSP responses.
///
/// A missing snapshot **fails** the test (`error.SnapshotMissing`) and writes
/// the candidate baseline as `<snap>.new`; set `BOTOPINK_SNAP_CREATE=1` to
/// record it instead. Otherwise the saved file is compared against the new
/// output; a mismatch writes a `.new` file and returns `error.SnapshotMismatch`.
///
/// Snapshot files: `snapshots/lsp/{slug}.snap.md` (relative to test CWD,
/// which build.zig sets to `modules/language-server/`).
///
/// Snap format:
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
const engine = @import("../engine.zig");
const helpers = @import("helpers.zig");

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

/// `BOTOPINK_SNAP_CREATE=1` — opt in to recording a *missing* snapshot.
/// Mirrors `compiler-core/src/utils/snap.zig`: without the flag a missing
/// snapshot fails the test (spec 06 defect H4) and the candidate baseline is
/// written to `<snap>.new` for review.
const CREATE_ENV = "BOTOPINK_SNAP_CREATE";

fn createMissingEnabled() bool {
    return std.process.Environ.containsUnemptyConstant(std.testing.environ, CREATE_ENV);
}

fn compareOrCreate(allocator: std.mem.Allocator, snap_path: []const u8, got: []const u8) !void {
    const existing = readFile(allocator, snap_path) catch |err| switch (err) {
        error.FileNotFound => {
            if (createMissingEnabled()) {
                try writeFile(snap_path, got);
                std.debug.print("snap created: {s}\n", .{snap_path});
                return;
            }
            const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snap_path});
            defer allocator.free(new_path);
            try writeFile(new_path, got);
            std.debug.print(
                "\nsnap missing: {s}\ncandidate written to: {s}\n" ++
                    "review it, then re-run with " ++ CREATE_ENV ++ "=1 to record it\n",
                .{ snap_path, new_path },
            );
            return error.SnapshotMissing;
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

/// The source text of a module other than the one under the cursor, so a
/// cross-file definition result can be underlined in the file it actually
/// points at.
pub const TargetSource = struct { uri: []const u8, source: []const u8 };

pub fn assertDefinition(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.Location,
) !void {
    return assertDefinitionIn(gpa, slug, source, cursor, result, &.{});
}

/// Like `assertDefinition`, but `targets` carries the sources of the other
/// modules in the test so the underline is drawn on the file the result names.
pub fn assertDefinitionIn(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.Location,
    targets: []const TargetSource,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);
    // use buf.print(gpa, ...) directly

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- DEFINITION at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |loc| {
        try buf.print(
            gpa,
            "uri: {s}\nrange: ({d},{d}) → ({d},{d})\n",
            .{
                loc.uri,
                loc.range.start.line,
                loc.range.start.character,
                loc.range.end.line,
                loc.range.end.character,
            },
        );
        try appendTargetUnderline(&buf, gpa, source, loc, targets);
    } else {
        try buf.appendSlice(gpa, "null\n");
    }

    try checkText(gpa, slug, buf.items);
}

/// Underlines `loc.range` in the source the location's URI names: the document
/// under the cursor, one of `targets`, or — when the target's text is not
/// available to the test — nothing but a note. Underlining the caller's source
/// for a result in another file would show the wrong line entirely.
fn appendTargetUnderline(
    buf: *std.ArrayList(u8),
    gpa: std.mem.Allocator,
    source: []const u8,
    loc: proto.Location,
    targets: []const TargetSource,
) !void {
    if (std.mem.eql(u8, loc.uri, helpers.TEST_URI)) {
        try appendSourceWithUnderline(buf, gpa, source, loc.range);
        return;
    }
    for (targets) |t| {
        if (!std.mem.eql(u8, t.uri, loc.uri)) continue;
        try buf.print(gpa, "in {s}:\n", .{t.uri});
        try appendSourceWithUnderline(buf, gpa, t.source, loc.range);
        return;
    }
    try buf.print(gpa, "(target source not available to the test: {s})\n", .{loc.uri});
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
    try appendSymbols(&buf, gpa, symbols, 0);
    if (symbols.len == 0) try buf.appendSlice(gpa, "(empty)\n");

    try checkText(gpa, slug, buf.items);
}

/// Renders symbols with their full `range`, their `selectionRange` and their
/// children (indented). Both the range and the child list are part of what a
/// client shows in its outline, so both belong in the snapshot.
fn appendSymbols(
    buf: *std.ArrayList(u8),
    gpa: std.mem.Allocator,
    symbols: []const proto.DocumentSymbol,
    depth: usize,
) !void {
    for (symbols) |sym| {
        var d: usize = 0;
        while (d < depth) : (d += 1) try buf.appendSlice(gpa, "  ");
        try buf.print(
            gpa,
            "{s}  [{s}]  range: ({d},{d})–({d},{d})  selection: ({d},{d})–({d},{d})\n",
            .{
                sym.name,
                symbolKindName(sym.kind),
                sym.range.start.line,
                sym.range.start.character,
                sym.range.end.line,
                sym.range.end.character,
                sym.selectionRange.start.line,
                sym.selectionRange.start.character,
                sym.selectionRange.end.line,
                sym.selectionRange.end.character,
            },
        );
        if (sym.children) |kids| try appendSymbols(buf, gpa, kids, depth + 1);
    }
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
        try buf.print(
            gpa,
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
    try buf.print(
        gpa,
        "----- RENAME at (line {d}, char {d})  new name: \"{s}\"\n",
        .{ cursor.line, cursor.character, new_name },
    );
    for (edits, 1..) |edit, i| {
        try buf.print(
            gpa,
            "  edit {d}: ({d},{d}) → ({d},{d})  \"{s}\"\n",
            .{
                i,
                edit.range.start.line,
                edit.range.start.character,
                edit.range.end.line,
                edit.range.end.character,
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

// ── Semantic Tokens ───────────────────────────────────────────────────────────

pub fn assertSemanticTokens(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    tokens: []const engine.SemToken,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    try appendSource(&buf, gpa, source);
    try buf.appendSlice(gpa, "----- SEMANTIC TOKENS\n");
    for (tokens) |t| {
        const text = tokenText(source, t);
        try buf.print(gpa, "  ({d},{d}) +{d}  {s}", .{ t.line, t.start, t.len, semTokenTypeName(t.type_idx) });
        if (t.mods != 0) {
            try buf.appendSlice(gpa, " [");
            var first = true;
            inline for (.{
                .{ proto.SemanticTokenModifiers.declaration, "declaration" },
                .{ proto.SemanticTokenModifiers.readonly, "readonly" },
                .{ proto.SemanticTokenModifiers.defaultLibrary, "defaultLibrary" },
                .{ proto.SemanticTokenModifiers.@"async", "async" },
            }) |m| {
                if (t.mods & m[0] != 0) {
                    if (!first) try buf.appendSlice(gpa, ",");
                    try buf.appendSlice(gpa, m[1]);
                    first = false;
                }
            }
            try buf.appendSlice(gpa, "]");
        }
        try buf.print(gpa, "  \"{s}\"\n", .{text});
    }
    if (tokens.len == 0) try buf.appendSlice(gpa, "  (none)\n");

    // The wire format is the delta encoding, not the absolute tokens above —
    // pin it too, so a regression in `encodeSemanticTokens` is visible.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const data = try engine.encodeSemanticTokens(arena_state.allocator(), tokens);
    try buf.appendSlice(gpa, "----- ENCODED (deltaLine, deltaStart, len, type, mods)\n");
    if (data.len == 0) {
        try buf.appendSlice(gpa, "  (none)\n");
    } else {
        var idx: usize = 0;
        while (idx < data.len) : (idx += 5) {
            try buf.print(gpa, "  {d} {d} {d} {d} {d}\n", .{
                data[idx], data[idx + 1], data[idx + 2], data[idx + 3], data[idx + 4],
            });
        }
    }

    try checkText(gpa, slug, buf.items);
}

/// Extracts the source slice a semantic token covers (single-line tokens only).
fn tokenText(source: []const u8, t: engine.SemToken) []const u8 {
    var line: u32 = 0;
    var i: usize = 0;
    while (i < source.len and line < t.line) : (i += 1) {
        if (source[i] == '\n') line += 1;
    }
    const start = @min(i + t.start, source.len);
    const end = @min(start + t.len, source.len);
    return source[start..end];
}

fn semTokenTypeName(idx: u32) []const u8 {
    return switch (idx) {
        proto.SemanticTokenTypes.type_ => "type",
        proto.SemanticTokenTypes.interface => "interface",
        proto.SemanticTokenTypes.@"enum" => "enum",
        proto.SemanticTokenTypes.enumMember => "enumMember",
        proto.SemanticTokenTypes.function => "function",
        proto.SemanticTokenTypes.method => "method",
        proto.SemanticTokenTypes.parameter => "parameter",
        proto.SemanticTokenTypes.variable => "variable",
        proto.SemanticTokenTypes.property => "property",
        proto.SemanticTokenTypes.keyword => "keyword",
        proto.SemanticTokenTypes.comment => "comment",
        proto.SemanticTokenTypes.string => "string",
        proto.SemanticTokenTypes.number => "number",
        proto.SemanticTokenTypes.operator => "operator",
        else => "?",
    };
}

// ── Folding Ranges ───────────────────────────────────────────────────────────

pub fn assertFoldingRanges(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    ranges: []const proto.FoldingRange,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    try appendSource(&buf, gpa, source);
    try buf.appendSlice(gpa, "----- FOLDING RANGES\n");
    for (ranges) |r| {
        try buf.print(gpa, "  line {d}–{d}  kind: {s}\n", .{
            r.startLine, r.endLine, r.kind orelse "?",
        });
    }
    if (ranges.len == 0) try buf.appendSlice(gpa, "  (none)\n");

    try checkText(gpa, slug, buf.items);
}

// ── Prepare Rename ───────────────────────────────────────────────────────────

pub fn assertPrepareRename(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.PrepareRenameResult,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- PREPARE RENAME at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |r| {
        try buf.print(gpa, "placeholder: \"{s}\"\nrange: ({d},{d}) → ({d},{d})\n", .{
            r.placeholder,
            r.range.start.line,
            r.range.start.character,
            r.range.end.line,
            r.range.end.character,
        });
    } else {
        try buf.appendSlice(gpa, "null (not renameable)\n");
    }

    try checkText(gpa, slug, buf.items);
}

// ── Code Actions ─────────────────────────────────────────────────────────────

pub fn assertCodeActions(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    range: proto.Range,
    actions: []const proto.CodeAction,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    try appendSource(&buf, gpa, source);
    try buf.print(gpa, "----- CODE ACTIONS in range ({d},{d})–({d},{d})\n", .{
        range.start.line, range.start.character,
        range.end.line,   range.end.character,
    });
    for (actions) |a| {
        try buf.print(gpa, "  [{s}] {s}\n", .{ a.kind orelse "?", a.title });
        // The edits are the whole point of a code action — a title alone says
        // nothing about what applying it would do to the buffer.
        const edit = a.edit orelse {
            try buf.appendSlice(gpa, "    (no edit)\n");
            continue;
        };
        const changes = edit.documentChanges orelse {
            try buf.appendSlice(gpa, "    (no documentChanges)\n");
            continue;
        };
        for (changes) |dc| {
            try buf.print(gpa, "    in {s}\n", .{dc.textDocument.uri});
            for (dc.edits) |te| {
                try buf.print(gpa, "      ({d},{d})–({d},{d}) → \"{s}\"\n", .{
                    te.range.start.line,
                    te.range.start.character,
                    te.range.end.line,
                    te.range.end.character,
                    te.newText,
                });
            }
        }
    }
    if (actions.len == 0) try buf.appendSlice(gpa, "  (none)\n");

    try checkText(gpa, slug, buf.items);
}

// ── Type Definition ──────────────────────────────────────────────────────────

pub fn assertTypeDefinition(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
    cursor: proto.Position,
    result: ?proto.Location,
) !void {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(gpa);

    try appendSourceWithCursor(&buf, gpa, source, cursor);
    try buf.print(gpa, "----- TYPE DEFINITION at (line {d}, char {d})\n", .{ cursor.line, cursor.character });
    if (result) |loc| {
        try buf.print(gpa, "uri: {s}\nrange: ({d},{d}) → ({d},{d})\n", .{
            loc.uri,
            loc.range.start.line,
            loc.range.start.character,
            loc.range.end.line,
            loc.range.end.character,
        });
        try appendTargetUnderline(&buf, gpa, source, loc, &.{});
    } else {
        try buf.appendSlice(gpa, "null\n");
    }

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
/// the cursor's line, aligned to `cursor.character`.
///
/// Edge cases handled:
///   • Source ending with `\n` — the trailing empty segment is stripped.
///   • Cursor column beyond line length — spaces extend past visible content.
///   • Cursor on the last line (with or without trailing `\n`).
pub fn appendSourceWithCursor(
    buf: *std.ArrayList(u8),
    gpa: std.mem.Allocator,
    source: []const u8,
    cursor: ?proto.Position,
) !void {
    try buf.appendSlice(gpa, "----- SOURCE\n```botopink\n");

    // Collect all lines explicitly so we can strip the trailing empty segment
    // that `splitScalar` produces when source ends with '\n', without relying
    // on iterator-internal state (it.index) which can be version-sensitive.
    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(gpa);

    var it = std.mem.splitScalar(u8, source, '\n');
    while (it.next()) |line| try lines.append(gpa, line);

    // Drop a trailing empty segment produced by a final '\n'.
    if (lines.items.len > 0 and lines.items[lines.items.len - 1].len == 0)
        _ = lines.pop();

    for (lines.items, 0..) |line, i| {
        const line_idx: u32 = @intCast(i);
        try buf.appendSlice(gpa, line);
        try buf.append(gpa, '\n');

        if (cursor) |cur| {
            if (cur.line == line_idx) {
                var col: u32 = 0;
                while (col < cur.character) : (col += 1)
                    try buf.append(gpa, ' ');
                try buf.appendSlice(gpa, "↑\n");
            }
        }
    }

    try buf.appendSlice(gpa, "```\n\n");
}

/// Appends the declaration line with a `^` underline under the selected range
/// (adapted to ASCII).
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
        proto.SymbolKind.Method => "Method",
        proto.SymbolKind.Function => "Function",
        proto.SymbolKind.Variable => "Variable",
        proto.SymbolKind.Struct => "Struct",
        proto.SymbolKind.Enum => "Enum",
        proto.SymbolKind.Interface => "Interface",
        proto.SymbolKind.Constant => "Constant",
        proto.SymbolKind.EnumMember => "EnumMember",
        proto.SymbolKind.Field => "Field",
        proto.SymbolKind.Property => "Property",
        else => "?",
    };
}

fn completionKindName(kind: u32) []const u8 {
    return switch (kind) {
        proto.CompletionItemKind.Function => "Function",
        proto.CompletionItemKind.Method => "Method",
        proto.CompletionItemKind.Variable => "Variable",
        proto.CompletionItemKind.Struct => "Struct",
        proto.CompletionItemKind.Enum => "Enum",
        proto.CompletionItemKind.Interface => "Interface",
        proto.CompletionItemKind.Field => "Field",
        proto.CompletionItemKind.Property => "Property",
        proto.CompletionItemKind.EnumMember => "EnumMember",
        proto.CompletionItemKind.Module => "Module",
        else => "?",
    };
}
