/// The `.bpp` unfold (front 116 step 2; decisions 198, 199, 212, 213, 221,
/// 275, 289, 338): a `.bpp` file is another spelling of a `.bp` module, and
/// this is the one place that spells it out. The toolchain knows only the
/// declarations std's `bpp` annotations mark in the package `"bpp"` names
/// (`bpp.zig` finds them, `Spec` carries them here); it knows no library, no
/// tag and no type name.
///
/// The file (212, 338): the header runs from the first line to the first
/// separator line — `---` (the markup follows, to the end of the file) or
/// `--- style ---` (the style section follows, closed by a `---` line, then the
/// markup). No separator line: markup only.
///
/// The module (199, 289): the header's declarations at module level, as
/// written; then the anonymous `pub default fn (props: Props) -> R` (`()` when
/// the header declares no `Props`), whose body is the header's statements in
/// order, `use <style> """<the section>""";` when there is a style section,
/// and `return <html> """<the markup>""";`. `R` is the `R` of the marked
/// function's `@ExprCustom<R>` (275). A decorator on the header's last line
/// annotates the function (221); nothing else does.
///
/// Positions. The unfolded text keeps every line of the file at its line: a
/// header item stays where it is written, the function's head is written at
/// the end of the line before the first statement, each separator line holds
/// the generated `use … ` / `return …`, and the closing `""";` and `}`, the
/// generated imports and a declaration written after a statement go after the
/// end of the file. Only columns move, on the few lines that get a prefix —
/// `columnShifts` lists them, and the diagnostics map back through it — so a
/// type error in the header and a `failAt` in a literal report at the `.bpp`
/// line and column, and a literal's text is the file's bytes after its
/// separator line, unchanged.
const std = @import("std");
const bp = @import("botopink");
const manifest = @import("manifest");

const Token = bp.Token;
const TokenKind = bp.TokenKind;

/// One function a section unfolds onto: `import {<path>.<name> as <alias>} from
/// "<package>"` (`import {<name> as <alias>}` for the package's entry module).
pub const Target = struct {
    package: []const u8,
    /// The module inside the package, dotted (`elements.html`); `""` for the
    /// package's entry module.
    path: []const u8,
    name: []const u8,
};

pub const Spec = struct {
    html: Target,
    style: ?Target = null,
    /// `R` as the unfolded module spells it (each name the package declares
    /// imported under `ret_imports`'s aliases).
    ret: []const u8,
    /// The imports `ret`'s names need, each line ending in `\n`.
    ret_imports: []const u8 = "",
};

/// The names the unfold binds in the module. A header cannot reach them by
/// accident: no botopink name a person writes starts with `__bpp`.
pub const HTML_ALIAS = "__bppHtml";
pub const STYLE_ALIAS = "__bppStyle";

/// A column a generated prefix moved: on 1-based `line`, every column from
/// `from` on (in the unfolded text) is `by` columns right of the file's.
pub const Shift = struct { line: usize, from: usize, by: usize };

/// Text the unfold moved: `len` bytes at (`line`, `col`) of the unfolded text
/// are the file's from (`file_line`, `file_col`) — the header's last-line
/// decorator written before the function's head, a declaration written after
/// a statement placed after the function.
pub const Moved = struct { line: usize, col: usize, len: usize, file_line: usize, file_col: usize };

pub const Unfolded = struct {
    source: []const u8,
    shifts: []const Shift,
    moved: []const Moved = &.{},
};

/// A refusal of the file, at its 1-based line and column.
pub const Refusal = struct { line: usize, col: usize, message: []const u8 };

pub const Result = union(enum) {
    ok: Unfolded,
    refused: Refusal,
};

pub const FIRST_LINE_SEPARATOR = "the header starts on the first line; a .bpp has no opening ---";
pub const STYLE_AFTER_MARKUP = "a style section comes before the markup — this `--- style ---` line is after the markup's `---`";
pub const SECOND_STYLE = "a .bpp has one style section — this `--- style ---` line opens a second one";
pub const STYLE_UNCLOSED = "the style section opened here is not closed — a `---` line ends it, and the markup follows";
pub const LITERAL_QUOTES = "a .bpp section is one literal, and `\"\"\"` would end it — this line holds `\"\"\"`";

// ── The file's sections ───────────────────────────────────────────────────────

const Line = struct {
    /// 1-based.
    number: usize,
    start: usize,
    /// The end of the line's text (its newline excluded).
    end: usize,
    /// The start of the next line (`end` + 1, or the source's length).
    next: usize,
};

fn lineText(source: []const u8, l: Line) []const u8 {
    return std.mem.trimEnd(u8, source[l.start..l.end], " \t\r");
}

const LineIter = struct {
    source: []const u8,
    at: usize = 0,
    n: usize = 0,

    fn next(self: *LineIter) ?Line {
        if (self.at > self.source.len or (self.at == self.source.len and self.n > 0)) return null;
        if (self.at == self.source.len and self.source.len == 0) return null;
        const start = self.at;
        const end = std.mem.indexOfScalarPos(u8, self.source, start, '\n') orelse self.source.len;
        self.n += 1;
        self.at = if (end < self.source.len) end + 1 else self.source.len + 1;
        return .{ .number = self.n, .start = start, .end = end, .next = @min(end + 1, self.source.len) };
    }
};

pub const Sections = struct {
    /// `source[0..header_end]` is the header (empty for a markup-only file).
    header_end: usize,
    /// The `--- style ---` line and the `---` line closing it.
    style_open: ?Line = null,
    style_close: ?Line = null,
    /// The separator line before the markup (null for a markup-only file).
    markup_sep: ?Line = null,
    /// The markup: `source[markup_start..]`.
    markup_start: usize,
};

const STYLE_SEP = "--- style ---";
const MARKUP_SEP = "---";

pub fn sections(source: []const u8) union(enum) { ok: Sections, refused: Refusal } {
    var it: LineIter = .{ .source = source };
    var out: Sections = .{ .header_end = 0, .markup_start = 0 };
    // The header: up to the first separator line.
    const first = while (it.next()) |l| {
        const t = lineText(source, l);
        if (std.mem.eql(u8, t, MARKUP_SEP) or std.mem.eql(u8, t, STYLE_SEP)) break l;
    } else return .{ .ok = out }; // no separator: markup only
    if (std.mem.eql(u8, lineText(source, first), MARKUP_SEP) and first.number == 1)
        return .{ .refused = .{ .line = 1, .col = 1, .message = FIRST_LINE_SEPARATOR } };
    out.header_end = first.start;
    var sep = first;
    if (std.mem.eql(u8, lineText(source, first), STYLE_SEP)) {
        out.style_open = first;
        const close = while (it.next()) |l| {
            const t = lineText(source, l);
            if (std.mem.eql(u8, t, STYLE_SEP)) return .{ .refused = .{ .line = l.number, .col = 1, .message = SECOND_STYLE } };
            if (std.mem.eql(u8, t, MARKUP_SEP)) break l;
        } else return .{ .refused = .{ .line = first.number, .col = 1, .message = STYLE_UNCLOSED } };
        out.style_close = close;
        sep = close;
    }
    out.markup_sep = sep;
    out.markup_start = sep.next;
    while (it.next()) |l| {
        if (std.mem.eql(u8, lineText(source, l), STYLE_SEP)) return .{ .refused = .{ .line = l.number, .col = 1, .message = STYLE_AFTER_MARKUP } };
    }
    return .{ .ok = out };
}

/// The 1-based line of `--- style ---`, when the file has a style section.
pub fn styleLine(source: []const u8) ?usize {
    return switch (sections(source)) {
        .ok => |s| if (s.style_open) |l| l.number else null,
        .refused => null,
    };
}

// ── The header's items ────────────────────────────────────────────────────────

pub const ItemKind = enum {
    /// Stays at module level (`import`, `type`, `pub …`, a private `fn`, a
    /// `test`, a decorated declaration, …).
    declaration,
    /// Goes into the function's body, in order (`val`, `var`, `use`, `if`, an
    /// expression statement, …).
    statement,
    /// Annotations with no declaration after them — the header's last item:
    /// they annotate the unfolded function (221).
    annotations,
};

pub const Item = struct {
    kind: ItemKind,
    start: usize,
    end: usize,
    /// The token after `type` / `pub type` when the item declares a type.
    type_name: ?[]const u8 = null,
};

fn isOpen(k: TokenKind) bool {
    return k == .leftParenthesis or k == .leftSquareBracket or k == .leftBrace;
}

fn isClose(k: TokenKind) bool {
    return k == .rightParenthesis or k == .rightSquareBracket or k == .rightBrace;
}

fn isComment(k: TokenKind) bool {
    return k == .commentNormal or k == .commentDoc or k == .commentModule or k == .newLine;
}

/// A token an item can end on (an expression's or a declaration's last token).
fn canEnd(k: TokenKind) bool {
    return switch (k) {
        .identifier, .numberLiteral, .stringLiteral, .multilineStringLiteral, .linesStringLiteral, .charLiteral, .rightParenthesis, .rightSquareBracket, .rightBrace, .greaterThan, .null, .selfType, .unknown, .underscore, .builtinIdent, .bang, .questionMark => true,
        else => false,
    };
}

/// A token on a new line that continues the item before it.
fn continues(k: TokenKind) bool {
    return switch (k) {
        .dot, .questionDot, .questionQuestion, .plus, .minus, .star, .slash, .percent, .lessThan, .greaterThan, .lessThanEqual, .greaterThanEqual, .equalEqual, .notEqual, .verticalBar, .verticalBarVerticalBar, .amperAmper, .ampersand, .caret, .lessThanLessThan, .greaterThanGreaterThan, .pipe, .rightArrow, .dotDot, .colon, .comma, .equal, .plusEqual, .@"else", .@"catch", .as, .is, .leftBrace, .leftParenthesis, .leftSquareBracket, .rightParenthesis, .rightSquareBracket, .rightBrace, .from, .extends => true,
        else => false,
    };
}

fn lastLine(t: Token) usize {
    return t.line + std.mem.count(u8, t.lexeme, "\n");
}

/// Annotations at `i` (`#[…]`, `@[…]`, several in a row): the index after them,
/// or `i` when there are none.
fn skipAnnotations(toks: []const Token, i: usize) usize {
    var j = i;
    while (j + 1 < toks.len and (toks[j].kind == .hash or toks[j].kind == .at) and toks[j + 1].kind == .leftSquareBracket) {
        var depth: usize = 0;
        var k = j + 1;
        while (k < toks.len) : (k += 1) {
            if (isOpen(toks[k].kind)) depth += 1;
            if (isClose(toks[k].kind)) {
                depth -|= 1;
                if (depth == 0) break;
            }
        }
        j = @min(k + 1, toks.len);
    }
    return j;
}

fn isDeclarationStart(toks: []const Token, i: usize) bool {
    return switch (toks[i].kind) {
        .import, .type, .@"pub", .@"fn", .@"test", .mod, .behavior, .interface, .implement, .extend, .declare, .@"enum", .record => true,
        // A decorated `val` is a module binding (356), not a statement.
        else => false,
    };
}

/// Split the header (`toks`, comments dropped) into its items. Null when the
/// tokens do not split (an unbalanced bracket): the unfold then keeps the
/// header whole at module level and the compiler reports where it fails.
pub fn items(arena: std.mem.Allocator, header: []const u8, toks: []const Token) !?[]const Item {
    var out: std.ArrayListUnmanaged(Item) = .empty;
    var i: usize = 0;
    while (i < toks.len) {
        const start = i;
        const after_anns = skipAnnotations(toks, i);
        const annotated = after_anns > i;
        if (annotated and after_anns >= toks.len) {
            try out.append(arena, .{ .kind = .annotations, .start = toks[start].offset, .end = endOf(toks[toks.len - 1]) });
            break;
        }
        const head = after_anns;
        const kind: ItemKind = if (isDeclarationStart(toks, head) or (annotated and (toks[head].kind == .val or toks[head].kind == .@"var"))) .declaration else .statement;
        var depth: isize = 0;
        var j = head;
        while (j < toks.len) {
            const t = toks[j];
            if (isOpen(t.kind)) depth += 1;
            if (isClose(t.kind)) depth -= 1;
            if (depth < 0) return null;
            j += 1;
            if (depth != 0) continue;
            if (t.kind == .semicolon) break;
            if (j >= toks.len) break;
            const n = toks[j];
            if (n.line > lastLine(t) and canEnd(t.kind) and !continues(n.kind)) break;
        }
        if (depth != 0) return null;
        var type_name: ?[]const u8 = null;
        var h = head;
        if (h < toks.len and toks[h].kind == .@"pub") h += 1;
        if (h + 1 < toks.len and toks[h].kind == .type and toks[h + 1].kind == .identifier) type_name = toks[h + 1].lexeme;
        try out.append(arena, .{ .kind = kind, .start = toks[start].offset, .end = endOf(toks[j - 1]), .type_name = type_name });
        i = j;
    }
    _ = header;
    return out.items;
}

fn endOf(t: Token) usize {
    return t.offset + t.lexeme.len;
}

// ── The unfold ────────────────────────────────────────────────────────────────

const Builder = struct {
    arena: std.mem.Allocator,
    out: std.ArrayListUnmanaged(u8) = .empty,
    shifts: std.ArrayListUnmanaged(Shift) = .empty,
    moved: std.ArrayListUnmanaged(Moved) = .empty,
    /// The 1-based line `out` is on, and the column its next byte takes.
    line: usize = 1,
    col: usize = 1,

    fn write(self: *Builder, bytes: []const u8) !void {
        try self.out.appendSlice(self.arena, bytes);
        for (bytes) |c| {
            if (c == '\n') {
                self.line += 1;
                self.col = 1;
            } else self.col += 1;
        }
    }

    /// Generated text that moves the rest of this line right.
    fn prefix(self: *Builder, bytes: []const u8) !void {
        std.debug.assert(std.mem.indexOfScalar(u8, bytes, '\n') == null);
        try self.shifts.append(self.arena, .{ .line = self.line, .from = self.col, .by = bytes.len });
        try self.write(bytes);
    }

    /// `source[start..end]` written here, away from its place, one line of it
    /// after another joined by `join`, each piece recorded as `Moved`.
    fn moveHere(self: *Builder, source: []const u8, start: usize, end: usize, join: []const u8) !void {
        var at = start;
        while (at < end) {
            const nl = std.mem.indexOfScalarPos(u8, source[0..end], at, '\n') orelse end;
            const piece = std.mem.trimEnd(u8, source[at..nl], "\r");
            const lc = lineColOf(source, at);
            if (piece.len > 0) try self.moved.append(self.arena, .{ .line = self.line, .col = self.col, .len = piece.len, .file_line = lc.line, .file_col = lc.col });
            try self.write(piece);
            if (nl < end) try self.write(join);
            at = nl + 1;
        }
    }

    /// `bytes` with every byte but a newline turned into a space: the text
    /// moves away, its lines stay.
    fn blank(self: *Builder, bytes: []const u8) !void {
        for (bytes) |c| try self.write(if (c == '\n') "\n" else " ");
    }
};

fn importLine(arena: std.mem.Allocator, t: Target, alias: []const u8) ![]const u8 {
    if (t.path.len == 0) return std.fmt.allocPrint(arena, "import {{{s} as {s}}} from \"{s}\";\n", .{ t.name, alias, t.package });
    return std.fmt.allocPrint(arena, "import {{{s}.{s} as {s}}} from \"{s}\";\n", .{ t.path, t.name, alias, t.package });
}

fn quoteFree(source: []const u8, from: usize, to: usize) ?usize {
    const at = std.mem.indexOfPos(u8, source[0..to], from, "\"\"\"") orelse return null;
    return at;
}

fn lineColOf(source: []const u8, offset: usize) struct { line: usize, col: usize } {
    var line: usize = 1;
    var start: usize = 0;
    for (source[0..@min(offset, source.len)], 0..) |c, i| if (c == '\n') {
        line += 1;
        start = i + 1;
    };
    return .{ .line = line, .col = offset - start + 1 };
}

/// Unfold the `.bpp` text `source` onto `spec`.
pub fn unfold(arena: std.mem.Allocator, source: []const u8, spec: Spec) !Result {
    const secs = switch (sections(source)) {
        .ok => |s| s,
        .refused => |r| return .{ .refused = r },
    };
    if (secs.style_open != null and spec.style == null) return error.NoStyleTarget; // `bpp.checkStyleSections` refuses it first
    // A literal holds no `"""`.
    const style_body: ?[2]usize = if (secs.style_open) |o| .{ o.next, secs.style_close.?.start } else null;
    if (style_body) |b| if (quoteFree(source, b[0], b[1])) |at| {
        const lc = lineColOf(source, at);
        return .{ .refused = .{ .line = lc.line, .col = lc.col, .message = LITERAL_QUOTES } };
    };
    if (quoteFree(source, secs.markup_start, source.len)) |at| {
        const lc = lineColOf(source, at);
        return .{ .refused = .{ .line = lc.line, .col = lc.col, .message = LITERAL_QUOTES } };
    }

    const header = source[0..secs.header_end];
    var toks: std.ArrayListUnmanaged(Token) = .empty;
    var whole_header = false;
    {
        var lx = bp.Lexer.init(header);
        if (lx.scanAll(arena)) |all| {
            for (all) |t| {
                if (t.kind == .endOfFile) break;
                if (!isComment(t.kind)) try toks.append(arena, t);
            }
        } else |_| whole_header = true;
    }
    const its: []const Item = if (whole_header) &.{} else (try items(arena, header, toks.items)) orelse blk: {
        whole_header = true;
        break :blk &.{};
    };

    var has_props = false;
    var first_stmt: ?usize = null;
    var trailing: ?Item = null;
    for (its, 0..) |it, k| {
        if (it.kind == .declaration) if (it.type_name) |n| {
            if (std.mem.eql(u8, n, "Props")) has_props = true;
        };
        if (it.kind == .statement and first_stmt == null) first_stmt = k;
        if (it.kind == .annotations) trailing = it;
    }

    const head = try std.fmt.allocPrint(arena, "pub default fn ({s}) -> {s} {{", .{ if (has_props) "props: Props" else "", spec.ret });
    // With a statement, the header's last-line decorator moves before the
    // function's head, on one line (221 (1)); without one it stays where it is
    // written, right before the head.
    const moved_decorator: ?Item = if (first_stmt != null) trailing else null;

    var b: Builder = .{ .arena = arena };
    var late: std.ArrayListUnmanaged(Item) = .empty;
    var cursor: usize = 0;
    var opened = false;
    if (!whole_header) {
        for (its, 0..) |it, k| {
            const gap = source[cursor..it.start];
            if (first_stmt != null and k == first_stmt.?) {
                // The head goes at the end of the line before the statement
                // when that line ends in code, else just before it.
                const nl = std.mem.indexOfScalar(u8, gap, '\n');
                if (nl != null and std.mem.indexOf(u8, gap[0..nl.?], "//") == null and cursor > 0) {
                    try b.write(gap[0..nl.?]);
                    try b.write(" ");
                    try writeHead(&b, source, moved_decorator, head, false);
                    try b.write(gap[nl.?..]);
                } else {
                    try b.write(gap);
                    try writeHead(&b, source, moved_decorator, head, true);
                    try b.prefix(" ");
                }
                opened = true;
            } else try b.write(gap);
            const text = source[it.start..it.end];
            switch (it.kind) {
                .declaration => if (opened) {
                    // A declaration after a statement: at module level, after the function.
                    try b.blank(text);
                    try late.append(arena, it);
                } else try b.write(text),
                .statement => try b.write(text),
                .annotations => if (opened) try b.blank(text) else try b.write(text),
            }
            cursor = it.end;
        }
    }
    try b.write(source[cursor..secs.header_end]);

    // The separator lines and the literals.
    if (secs.markup_sep == null) {
        // Markup only: the whole file is the literal.
        try b.prefix(head);
        try b.prefix(" return " ++ HTML_ALIAS ++ " \"\"\"");
    } else {
        if (secs.style_open) |o| {
            if (!opened) {
                try b.write(head);
                try b.write(" ");
            }
            opened = true;
            try b.write("use " ++ STYLE_ALIAS);
            try b.write(source[o.end..o.next]);
            try b.prefix("\"\"\"");
            try b.write(source[o.next..secs.style_close.?.start]);
            try b.write("\"\"\"; ");
        } else if (!opened) {
            try b.write(head);
            try b.write(" ");
        }
        const sep = secs.markup_sep.?;
        try b.write("return " ++ HTML_ALIAS);
        try b.write(source[sep.end..sep.next]);
        if (sep.next == sep.end) try b.write("\n"); // the separator is the file's last line
        try b.prefix("\"\"\"");
    }
    try b.write(source[secs.markup_start..]);
    try b.write("\"\"\";\n}\n");
    try b.write(try importLine(arena, spec.html, HTML_ALIAS));
    if (secs.style_open != null) try b.write(try importLine(arena, spec.style.?, STYLE_ALIAS));
    try b.write(spec.ret_imports);
    if (whole_header) {
        // The header did not split: the compiler reports it where it fails.
    }
    for (late.items) |it| {
        try b.moveHere(source, it.start, it.end, "\n");
        try b.write("\n");
    }
    return .{ .ok = .{ .source = b.out.items, .shifts = b.shifts.items, .moved = b.moved.items } };
}

/// The function's head, after the decorator moved before it (when there is
/// one): a `prefix` moves the rest of the line right.
fn writeHead(b: *Builder, source: []const u8, decorator: ?Item, head: []const u8, prefix: bool) !void {
    const from = b.col;
    const line = b.line;
    if (decorator) |d| {
        try b.moveHere(source, d.start, d.end, " ");
        try b.write(" ");
    }
    try b.write(head);
    if (prefix) try b.shifts.append(b.arena, .{ .line = line, .from = from, .by = b.col - from });
}

// ── The files unfolded in this process ────────────────────────────────────────

/// What a diagnostic needs to speak of a `.bpp` file rather than of its
/// unfolded module: the file's own text (the excerpt under a location) and
/// the columns the unfold moved.
pub const Origin = struct {
    text: []const u8,
    shifts: []const Shift,
    moved: []const Moved = &.{},

    /// The file's (line, column) for unfolded (`line`, `col`).
    pub fn position(self: Origin, line: usize, col: usize) struct { line: usize, col: usize } {
        for (self.moved) |m| {
            if (m.line == line and col >= m.col and col < m.col + m.len) return .{ .line = m.file_line, .col = m.file_col + (col - m.col) };
        }
        return .{ .line = line, .col = fileColumn(self.shifts, line, col) };
    }
};

var origins: std.StringHashMapUnmanaged(Origin) = .empty;

/// Keep `file`'s text and shifts for `origin` (process-lifetime memory: a
/// command unfolds each file once; a file unfolded again replaces its entry).
pub fn remember(file: []const u8, text: []const u8, shifts: []const Shift, moved: []const Moved) void {
    const a = std.heap.page_allocator;
    const key = a.dupe(u8, file) catch return;
    const entry: Origin = .{
        .text = a.dupe(u8, text) catch return,
        .shifts = a.dupe(Shift, shifts) catch return,
        .moved = a.dupe(Moved, moved) catch return,
    };
    origins.put(a, key, entry) catch return;
}

/// The `.bpp` text and shifts behind `file`, when `file` was unfolded here.
pub fn origin(file: []const u8) ?Origin {
    if (!manifest.isBppFile(file)) return null;
    return origins.get(file);
}

/// Unfold `file`'s text `source` onto `spec`: the module's source in `gpa`,
/// its origin remembered, or the file's refusal (`scratch`).
pub fn unfoldFile(gpa: std.mem.Allocator, scratch: std.mem.Allocator, file: []const u8, source: []const u8, spec: Spec) !union(enum) { ok: []u8, refused: Refusal } {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const result = unfold(arena_inst.allocator(), source, spec) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.NoStyleTarget => return .{ .refused = .{ .line = (styleLine(source) orelse 1), .col = 1, .message = "a style section needs a #[bpp.style] function, and the package \"bpp\" names marks none" } },
    };
    switch (result) {
        .refused => |r| {
            _ = origins.remove(file);
            return .{ .refused = .{ .line = r.line, .col = r.col, .message = try scratch.dupe(u8, r.message) } };
        },
        .ok => |u| {
            remember(file, source, u.shifts, u.moved);
            return .{ .ok = try gpa.dupe(u8, u.source) };
        },
    }
}

/// The file's column for unfolded (`line`, `col`).
pub fn fileColumn(shifts: []const Shift, line: usize, col: usize) usize {
    var c = col;
    var k = shifts.len;
    while (k > 0) {
        k -= 1;
        const s = shifts[k];
        if (s.line != line) continue;
        if (c >= s.from + s.by) {
            c -= s.by;
        } else if (c >= s.from) c = s.from;
    }
    return c;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const test_spec: Spec = .{ .html = .{ .package = "markup", .path = "markup", .name = "markup" }, .ret = "i32" };

fn unfoldOk(a: std.mem.Allocator, source: []const u8, spec: Spec) !Unfolded {
    return switch (try unfold(a, source, spec)) {
        .ok => |u| u,
        .refused => |r| {
            std.debug.print("refused {d}:{d} {s}\n", .{ r.line, r.col, r.message });
            return error.TestUnexpectedResult;
        },
    };
}

fn lineOf(text: []const u8, n: usize) []const u8 {
    var it = std.mem.splitScalar(u8, text, '\n');
    var k: usize = 1;
    while (it.next()) |l| : (k += 1) if (k == n) return l;
    return "";
}

test "bpp unfold: Props' header, statements in the body, every line where it is written" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const src =
        \\import {lib.db.Post};
        \\type Props(title: string)
        \\
        \\val n = props.title.length();
        \\---
        \\<h1>{props.title}</h1>
        \\
    ;
    const u = try unfoldOk(a, src, test_spec);
    try std.testing.expectEqualStrings(
        \\import {lib.db.Post};
        \\type Props(title: string) pub default fn (props: Props) -> i32 {
        \\
        \\val n = props.title.length();
        \\return __bppHtml
        \\"""<h1>{props.title}</h1>
        \\""";
        \\}
        \\import {markup.markup as __bppHtml} from "markup";
        \\
    , u.source);
    try std.testing.expectEqual(@as(usize, 1), u.shifts.len);
    try std.testing.expectEqual(@as(usize, 6), u.shifts[0].line);
    try std.testing.expectEqual(@as(usize, 5), fileColumn(u.shifts, 6, 8));
}

test "bpp unfold: no Props, no header, markup only" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const none = try unfoldOk(a, "import {x.y};\n---\n<p/>\n", test_spec);
    try std.testing.expectEqualStrings("import {x.y};\npub default fn () -> i32 { return __bppHtml\n\"\"\"<p/>\n\"\"\";\n}\nimport {markup.markup as __bppHtml} from \"markup\";\n", none.source);
    const only = try unfoldOk(a, "<article></article>\n", test_spec);
    try std.testing.expect(std.mem.startsWith(u8, only.source, "pub default fn () -> i32 { return __bppHtml \"\"\"<article></article>\n\"\"\";"));
    // The markup's first column is the file's.
    const col = std.mem.indexOf(u8, only.source, "<article>").? + 1;
    try std.testing.expectEqual(@as(usize, 1), fileColumn(only.shifts, 1, col));
}

test "bpp unfold: the style section is a `use` before the return; the import is the style target's" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var spec = test_spec;
    spec.style = .{ .package = "markup", .path = "", .name = "css" };
    const u = try unfoldOk(a, "type Props(title: string)\n--- style ---\n.title { font-size: 2rem; }\n---\n<h1 class=\"title\">{props.title}</h1>\n", spec);
    try std.testing.expectEqualStrings(
        \\type Props(title: string)
        \\pub default fn (props: Props) -> i32 { use __bppStyle
        \\""".title { font-size: 2rem; }
        \\"""; return __bppHtml
        \\"""<h1 class="title">{props.title}</h1>
        \\""";
        \\}
        \\import {markup.markup as __bppHtml} from "markup";
        \\import {css as __bppStyle} from "markup";
        \\
    , u.source);
}

test "bpp unfold: a decorator on the last header line annotates the function; a declaration after a statement moves past it" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const u = try unfoldOk(a, "import {page} from \"web\";\nval x = 1;\nfn helper() -> i32 { return 2; }\n#[page(\"/\")]\n---\n<p/>\n", test_spec);
    try std.testing.expectEqualStrings("import {page} from \"web\"; #[page(\"/\")] pub default fn () -> i32 {", lineOf(u.source, 1));
    try std.testing.expectEqualStrings("val x = 1;", lineOf(u.source, 2));
    try std.testing.expectEqualStrings("", std.mem.trim(u8, lineOf(u.source, 3), " "));
    try std.testing.expectEqualStrings("", std.mem.trim(u8, lineOf(u.source, 4), " "));
    try std.testing.expect(std.mem.endsWith(u8, u.source, "fn helper() -> i32 { return 2; }\n"));
    // Without a statement the decorator stays where it is written, before the head.
    const d = try unfoldOk(a, "#[page(\"/\")]\n---\n<p/>\n", test_spec);
    try std.testing.expectEqualStrings("#[page(\"/\")]", lineOf(d.source, 1));
    try std.testing.expectEqualStrings("pub default fn () -> i32 { return __bppHtml", lineOf(d.source, 2));
}

test "bpp unfold: if, use and expression statements are statements; test, private fn and decorated val declarations" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const header =
        \\import {a.b};
        \\type Props(
        \\    title: string,
        \\)
        \\pub fn staticPaths() -> i32 {
        \\    return 1;
        \\}
        \\fn helper() -> i32 { return 2; }
        \\test "t" { assert true; }
        \\#[mark]
        \\val tagged = 1;
        \\val k = if (props.title == "") { "a" } else { "b" };
        \\if (k == "a") { notFound(); }
        \\use styled """x""";
        \\notFound()
        \\    .then(1);
    ;
    var lx = bp.Lexer.init(header);
    const all = try lx.scanAll(a);
    var toks: std.ArrayListUnmanaged(Token) = .empty;
    for (all) |t| if (t.kind != .endOfFile and !isComment(t.kind)) try toks.append(a, t);
    const got = (try items(a, header, toks.items)).?;
    const want = [_]ItemKind{ .declaration, .declaration, .declaration, .declaration, .declaration, .declaration, .statement, .statement, .statement, .statement };
    try std.testing.expectEqual(want.len, got.len);
    for (want, got) |w, g| try std.testing.expectEqual(w, g.kind);
    try std.testing.expectEqualStrings("Props", got[1].type_name.?);
    try std.testing.expectEqualStrings("notFound()\n    .then(1);", header[got[9].start..got[9].end]);
}

test "bpp unfold: the sections' refusals, each at its line" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var spec = test_spec;
    spec.style = .{ .package = "markup", .path = "", .name = "css" };
    const cases = [_]struct { src: []const u8, line: usize, msg: []const u8 }{
        .{ .src = "---\n<p/>\n", .line = 1, .msg = FIRST_LINE_SEPARATOR },
        .{ .src = "val x = 1;\n---\n<p/>\n--- style ---\n.a {}\n", .line = 4, .msg = STYLE_AFTER_MARKUP },
        .{ .src = "val x = 1;\n--- style ---\n.a {}\n--- style ---\n.b {}\n---\n<p/>\n", .line = 4, .msg = SECOND_STYLE },
        .{ .src = "val x = 1;\n--- style ---\n.a {}\n", .line = 2, .msg = STYLE_UNCLOSED },
        .{ .src = "val x = 1;\n---\n<p>\"\"\"</p>\n", .line = 3, .msg = LITERAL_QUOTES },
    };
    for (cases) |c| switch (try unfold(a, c.src, spec)) {
        .ok => return error.TestUnexpectedResult,
        .refused => |r| {
            try std.testing.expectEqual(c.line, r.line);
            try std.testing.expectEqualStrings(c.msg, r.message);
        },
    };
}
