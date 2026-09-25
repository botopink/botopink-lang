/// `botopink migrate effects` — the codemod of front 24 (1.0.10-beta,
/// decisions 118–128): rewrite the effect surface of today's language — the
/// six `#[@<effect>]` annotations, `@Future<T, E>`, `@Generator<T>`,
/// `@ResultGenerator<T, E>`, `@FutureGenerator<T, E>`, the annotated
/// `#[@X] loop`, `YieldStep<T, E>` — and the pre-121 spellings still found in
/// old code (`#[@context]`, `@Context<B, R>`, `@Use<C, T>`, `@Component<T>`,
/// `#[@iterator]`, `@Iterator<T, E>`, `#[@asyncGenerator]`, `@AsyncIterator`,
/// `IteratorStep`, `loop (xs) { x -> }`, `loop (cond)`, `loop await`) into the
/// language of `guide.md`: the wrapper in the return decides the effect
/// (`@Task`, `@Component<C, T>`, `@Iterator`, `@Stream`), only `@Result` fails,
/// and a prefixed loop (`iter` / `stream`) replaces the annotated one.
///
/// **Three stages per file**, each a list of byte-range edits over the text
/// the stage reads, so everything the codemod does not name — comments,
/// blank lines, layout — is kept byte for byte:
///
/// 1. *normalise* (`stage1`) — the pre-121 spellings become today's
///    (`#[@context]` → `#[@use]`, `@Context<B, R>` → `@Component<B, R>`,
///    `loop (xs) { x -> }` → `for`, …), so the file type-checks with today's
///    compiler. `@Component<T>` and a function that `use`s a hook behind a
///    plain `-> T` read the base `C` off `type T … implement @Context<C>` in
///    the loaded sources (the project and its dependencies).
/// 2. *type-check* — every project module, normalised, goes through
///    `compileTypesOnly` with the checker's `ExprTypeLog` installed: the type
///    of every expression at its location. The `await x` → `try await x`
///    rewrite and the `for` / `.next()` review items need it — whether the
///    awaited `@Future<U, E>` could fail is a type, not a spelling.
/// 3. *rewrite* (`stage2`) — annotations removed, wrappers renamed, loops
///    prefixed, `try` inserted where the old `await` / `for` propagated and the
///    new return still has a `@Result` to propagate into, and a
///    `// TODO(migrate-effects): <why>` line above every site the codemod
///    cannot decide (the README's review list, and open point 5: a
///    `@Future<T>` body that throws or tries).
///
/// **Idempotent.** A file stage 1 and the syntactic half of stage 2 leave
/// unchanged is not analysed at all (the migrated language does not
/// type-check with today's compiler, and has nothing left to migrate); a
/// review marker is not inserted twice (the block of markers above a line is
/// read first). **`--dry-run`** reports every file and marker and writes
/// nothing. There is no flag that weakens a rule: a site the codemod cannot
/// classify — the module does not type-check, the base of a component is not
/// declared anywhere it can see — is marked, never guessed (decision 67).
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const scanner = @import("./scanner.zig");
const libs = @import("./libs.zig");
const build_cmd = @import("./build.zig");
const diagnostics = @import("./diagnostics.zig");

const ast = bp.ast;
const Token = bp.Token;
const TokenKind = bp.TokenKind;
const Type = bp.types.Type;
const Allocator = std.mem.Allocator;
const Module = bp.Module;

pub const Options = struct {
    dry_run: bool = false,
};

/// The prefix of every review marker the codemod writes.
pub const MARK = "// TODO(migrate-effects): ";

// ── public result ───────────────────────────────────────────────────────────

/// One file handed to `migrate`.
pub const Input = struct {
    /// Package-relative path, forward slashes (`src/main.bp`) — also the
    /// `Module.srcPath` the checker records types under.
    file: []const u8,
    /// Module path in the compilation (`main`, `shapes/circle`), or null for
    /// a file the project does not compile (a `.d.bp`, an orphan): such a
    /// file is rewritten without types.
    module: ?[]const u8,
    source: []const u8,
    /// A `.d.bp` the project compiles as declaration-only (`Module.declaration`).
    declaration: bool = false,
};

pub const FileResult = struct {
    file: []const u8,
    output: []const u8,
    changed: bool,
    /// `line: text` of every review marker in `output` (1-based lines).
    markers: []const MarkerLine,
    /// The module did not type-check after normalisation — its
    /// type-dependent sites were marked instead of decided.
    untyped: bool = false,
};

pub const MarkerLine = struct { line: usize, text: []const u8 };

pub const Outcome = struct {
    files: []FileResult,
    /// Rendered diagnostics of the modules that did not type-check.
    unchecked: []const []const u8,
};

// ── the codemod over a set of files ─────────────────────────────────────────

/// Run the three stages over `inputs`. `deps` are the dependency modules the
/// project compiles against (read for context bases and types, never
/// rewritten). Everything returned lives in `arena`.
/// `render` prints the located diagnostic of every rewritten module that does
/// not type-check (the command does; the tests read `Outcome.unchecked`).
pub fn migrate(gpa: Allocator, arena: Allocator, io: std.Io, inputs: []const Input, deps: []const Module, render: bool) !Outcome {
    // The migration-only mode (decisions-pending 24-d): the parser reads the
    // pre-front-24 annotations and wrappers instead of refusing them, and the
    // checker types the files that still spell them with their old meaning
    // (the list is filled in below). Nothing outside this call ever sets it.
    bp.comptime_pipeline.setEffectMigration(&.{});
    defer bp.comptime_pipeline.setEffectMigration(null);
    // Context bases: `type T … implement @Context<C>` over every source seen.
    var bases: Bases = .empty;
    for (inputs) |in| try collectBases(arena, in.source, &bases);
    for (deps) |d| try collectBases(arena, d.source, &bases);

    const s1 = try arena.alloc([]const u8, inputs.len);
    const gated = try arena.alloc(bool, inputs.len);
    var any_gated = false;
    for (inputs, 0..) |in, i| {
        s1[i] = try stage1(arena, in.source, &bases);
        const syntactic = try stage2(arena, s1[i], null);
        gated[i] = !std.mem.eql(u8, syntactic, in.source);
        any_gated = any_gated or gated[i];
    }

    var results: std.ArrayListUnmanaged(FileResult) = .empty;
    var unchecked: std.ArrayListUnmanaged([]const u8) = .empty;
    if (!any_gated) {
        for (inputs) |in| try results.append(arena, .{ .file = in.file, .output = in.source, .changed = false, .markers = try markerLines(arena, in.source) });
        return .{ .files = results.items, .unchecked = &.{} };
    }

    // The files the checker types with the old meaning: every input the
    // codemod rewrites, and every dependency that still spells the old
    // surface (a migrated one, std included, is typed as it is written).
    var legacy: std.ArrayListUnmanaged([]const u8) = .empty;
    for (inputs, 0..) |in, i| if (gated[i]) try legacy.append(arena, in.file);
    for (deps) |d| {
        if (d.declaration) continue;
        const d_s1 = try stage1(arena, d.source, &bases);
        if (std.mem.eql(u8, try stage2(arena, d_s1, null), d.source)) continue;
        // The checker's `env.srcPath` (`comptime.displaySrcPath`).
        try legacy.append(arena, if (d.srcPath.len > 0) d.srcPath else try std.fmt.allocPrint(arena, "{s}.bp", .{if (d.path.len > 0) d.path else "main"}));
    }
    bp.comptime_pipeline.setEffectMigration(legacy.items);

    // Type-check the normalised project, recording every expression's type.
    var mods: std.ArrayListUnmanaged(Module) = .empty;
    for (deps) |d| if (!d.declaration) try mods.append(arena, d);
    for (inputs, 0..) |in, i| {
        const name = in.module orelse continue;
        try mods.append(arena, .{ .path = name, .source = s1[i], .srcPath = in.file, .declaration = in.declaration });
    }
    var log: bp.comptime_pipeline.ExprTypeLog = .{ .gpa = gpa };
    defer log.deinit();
    bp.comptime_pipeline.setExprTypeLog(&log);
    var session_opt: ?bp.comptime_pipeline.ComptimeSession = bp.comptime_pipeline.compileTypesOnly(gpa, mods.items, .{
        .io = io,
        .build_root = ".botopinkbuild",
    }) catch null;
    bp.comptime_pipeline.setExprTypeLog(null);
    defer if (session_opt) |*s| s.deinit(gpa);

    for (inputs, 0..) |in, i| {
        if (!gated[i]) {
            try results.append(arena, .{ .file = in.file, .output = in.source, .changed = false, .markers = try markerLines(arena, in.source) });
            continue;
        }
        var typed = false;
        if (in.module) |name| if (session_opt) |*s| {
            for (s.outputs.items) |o| {
                if (!std.mem.eql(u8, o.name, name)) continue;
                if (o.outcome == .ok) {
                    typed = true;
                } else {
                    try unchecked.append(arena, try outcomeSummary(arena, in.file, o));
                    if (render) _ = diagnostics.renderOutcome(gpa, io, arena, o);
                }
                break;
            }
        };
        const facts = try analyse(arena, s1[i], if (typed) &log else null, in.file);
        const out = try stage2(arena, s1[i], &facts);
        try results.append(arena, .{
            .file = in.file,
            .output = out,
            .changed = !std.mem.eql(u8, out, in.source),
            .markers = try markerLines(arena, out),
            .untyped = !typed,
        });
    }
    return .{ .files = results.items, .unchecked = unchecked.items };
}

fn outcomeSummary(arena: Allocator, file: []const u8, o: bp.codegen.ComptimeOutput) ![]const u8 {
    return switch (o.outcome) {
        .ok => file,
        .parseError => std.fmt.allocPrint(arena, "{s}: does not parse", .{file}),
        .validationError => std.fmt.allocPrint(arena, "{s}: does not validate", .{file}),
        .typeError => |te| if (te.loc) |l|
            std.fmt.allocPrint(arena, "{s}:{d}:{d}: {s}", .{ file, l.line, l.col, @tagName(te.kind) })
        else
            std.fmt.allocPrint(arena, "{s}: {s}", .{ file, @tagName(te.kind) }),
    };
}

fn markerLines(arena: Allocator, text: []const u8) ![]const MarkerLine {
    var out: std.ArrayListUnmanaged(MarkerLine) = .empty;
    var it = std.mem.splitScalar(u8, text, '\n');
    var line: usize = 1;
    while (it.next()) |raw| : (line += 1) {
        const t = std.mem.trim(u8, raw, " \t\r");
        if (std.mem.startsWith(u8, t, MARK)) try out.append(arena, .{ .line = line, .text = t[MARK.len..] });
    }
    return out.items;
}

// ── tokens ──────────────────────────────────────────────────────────────────

/// The source's tokens with the trivia (newlines, comments) filtered out of
/// `sig`; `all` keeps them, so a rewrite can see a comment it would drop.
const Toks = struct {
    src: []const u8,
    all: []const Token,
    sig: []const u32,

    fn tok(self: Toks, i: usize) Token {
        return self.all[self.sig[i]];
    }
    fn kind(self: Toks, i: usize) TokenKind {
        if (i >= self.sig.len) return .endOfFile;
        return self.all[self.sig[i]].kind;
    }
    fn start(self: Toks, i: usize) usize {
        return self.tok(i).offset;
    }
    fn end(self: Toks, i: usize) usize {
        const t = self.tok(i);
        return t.offset + t.lexeme.len;
    }
    fn lexeme(self: Toks, i: usize) []const u8 {
        return self.tok(i).lexeme;
    }
    fn is(self: Toks, i: usize, k: TokenKind) bool {
        return self.kind(i) == k;
    }
    fn isIdent(self: Toks, i: usize, name: []const u8) bool {
        return self.kind(i) == .identifier and std.mem.eql(u8, self.lexeme(i), name);
    }

    /// The matching `)` / `]` / `}` of the opener at `i`.
    fn matchClose(self: Toks, i: usize) ?usize {
        var depth: usize = 0;
        var j = i;
        while (j < self.sig.len) : (j += 1) {
            switch (self.kind(j)) {
                .leftParenthesis, .leftSquareBracket, .leftBrace => depth += 1,
                .rightParenthesis, .rightSquareBracket, .rightBrace => {
                    if (depth == 0) return null;
                    depth -= 1;
                    if (depth == 0) return j;
                },
                .endOfFile => return null,
                else => {},
            }
        }
        return null;
    }

    /// The type-argument list opened by the `<` at `i`: the sig index of the
    /// token that closes it and the byte offset just past the closing `>` (a
    /// `>>` that also closes an outer list ends after its first byte).
    fn matchAngle(self: Toks, i: usize) ?struct { close: usize, end: usize } {
        var depth: isize = 0;
        var j = i;
        while (j < self.sig.len) : (j += 1) {
            switch (self.kind(j)) {
                .lessThan => depth += 1,
                .lessThanLessThan => depth += 2,
                .greaterThan => depth -= 1,
                .greaterThanGreaterThan => {
                    depth -= 2;
                    if (depth == -1) return .{ .close = j, .end = self.start(j) + 1 };
                },
                .leftParenthesis, .leftSquareBracket => {
                    j = self.matchClose(j) orelse return null;
                    continue;
                },
                .semicolon, .leftBrace, .rightBrace, .endOfFile => return null,
                else => {},
            }
            if (depth == 0) return .{ .close = j, .end = self.end(j) };
            if (depth < 0) return null;
        }
        return null;
    }

    /// The first sig index whose token starts at or after `off`.
    fn sigAt(self: Toks, off: usize) usize {
        var lo: usize = 0;
        var hi: usize = self.sig.len;
        while (lo < hi) {
            const mid = (lo + hi) / 2;
            if (self.start(mid) < off) lo = mid + 1 else hi = mid;
        }
        return lo;
    }
};

fn lex(arena: Allocator, src: []const u8) !?Toks {
    var lexer = bp.Lexer.init(src);
    const all = lexer.scanAll(arena) catch return null;
    var sig: std.ArrayListUnmanaged(u32) = .empty;
    for (all, 0..) |t, i| switch (t.kind) {
        .newLine, .commentNormal, .commentDoc, .commentModule => {},
        else => try sig.append(arena, @intCast(i)),
    };
    return .{ .src = src, .all = all, .sig = sig.items };
}

// ── edits ───────────────────────────────────────────────────────────────────

const Edit = struct { start: usize, end: usize, text: []const u8, seq: usize = 0 };

const Editor = struct {
    arena: Allocator,
    src: []const u8,
    edits: std.ArrayListUnmanaged(Edit) = .empty,
    /// (line start, text) of every marker queued, so one line never gets the
    /// same marker twice in one run.
    queued: std.ArrayListUnmanaged(struct { at: usize, text: []const u8 }) = .empty,

    fn replace(self: *Editor, s: usize, e: usize, text: []const u8) !void {
        try self.edits.append(self.arena, .{ .start = s, .end = e, .text = text, .seq = self.edits.items.len });
    }

    fn insert(self: *Editor, at: usize, text: []const u8) !void {
        try self.replace(at, at, text);
    }

    /// Queue `MARK ++ text` on its own line above the line holding `off`,
    /// unless the block of markers already above that line carries it.
    fn mark(self: *Editor, off: usize, text: []const u8) !void {
        const ls = lineStart(self.src, off);
        for (self.queued.items) |q| {
            if (q.at == ls and std.mem.eql(u8, q.text, text)) return;
        }
        // Walk the marker block directly above.
        var cur = ls;
        while (cur > 0) {
            const prev_start = lineStart(self.src, cur - 1);
            const line = std.mem.trim(u8, self.src[prev_start .. cur - 1], " \t\r");
            if (!std.mem.startsWith(u8, line, MARK)) break;
            if (std.mem.eql(u8, line[MARK.len..], text)) return;
            cur = prev_start;
        }
        try self.queued.append(self.arena, .{ .at = ls, .text = text });
        const indent = leadingSpace(self.src[ls..]);
        try self.insert(ls, try std.mem.concat(self.arena, u8, &.{ indent, MARK, text, "\n" }));
    }

    fn apply(self: *Editor) ![]const u8 {
        const items = self.edits.items;
        std.mem.sort(Edit, items, {}, struct {
            fn lt(_: void, a: Edit, b: Edit) bool {
                if (a.start != b.start) return a.start < b.start;
                const az = a.start == a.end;
                const bz = b.start == b.end;
                if (az != bz) return az; // an insertion goes before a replacement at the same offset
                return a.seq < b.seq;
            }
        }.lt);
        var out: std.ArrayListUnmanaged(u8) = .empty;
        var at: usize = 0;
        for (items) |e| {
            if (e.start < at) return error.OverlappingEdits;
            try out.appendSlice(self.arena, self.src[at..e.start]);
            try out.appendSlice(self.arena, e.text);
            at = e.end;
        }
        try out.appendSlice(self.arena, self.src[at..]);
        return out.items;
    }
};

fn lineStart(src: []const u8, off: usize) usize {
    var i = @min(off, src.len);
    while (i > 0 and src[i - 1] != '\n') i -= 1;
    return i;
}

fn lineEnd(src: []const u8, off: usize) usize {
    var i = off;
    while (i < src.len and src[i] != '\n') i += 1;
    return i;
}

fn leadingSpace(s: []const u8) []const u8 {
    var i: usize = 0;
    while (i < s.len and (s[i] == ' ' or s[i] == '\t')) i += 1;
    return s[0..i];
}

fn isBlank(s: []const u8) bool {
    return std.mem.trim(u8, s, " \t\r\n").len == 0;
}

// ── context bases ───────────────────────────────────────────────────────────

const Bases = std.StringHashMapUnmanaged([]const u8);

/// Record `T → C` for every `type T … implement … @Context<C>` in `src`.
fn collectBases(arena: Allocator, src: []const u8, bases: *Bases) !void {
    const tk = (try lex(arena, src)) orelse return;
    var i: usize = 0;
    while (i + 1 < tk.sig.len) : (i += 1) {
        if (!tk.is(i, .type) or !tk.is(i + 1, .identifier)) continue;
        const name = tk.lexeme(i + 1);
        var j = i + 2;
        while (j < tk.sig.len) : (j += 1) {
            switch (tk.kind(j)) {
                .leftParenthesis, .leftSquareBracket => j = tk.matchClose(j) orelse break,
                .semicolon, .leftBrace, .endOfFile, .type, .@"fn", .@"pub" => break,
                .builtinIdent => if (std.mem.eql(u8, tk.lexeme(j), "@Context") and tk.is(j + 1, .lessThan) and tk.is(j + 2, .identifier) and tk.is(j + 3, .greaterThan)) {
                    try bases.put(arena, name, tk.lexeme(j + 2));
                    break;
                },
                else => {},
            }
        }
    }
}

// ── type text ───────────────────────────────────────────────────────────────

const Stage = enum { one, two };

const TypeCtx = struct {
    arena: Allocator,
    stage: Stage,
    bases: ?*const Bases,
    /// Review notes raised while rewriting, attached to the type's line.
    notes: std.ArrayListUnmanaged([]const u8) = .empty,
};

fn isIdentStart(c: u8) bool {
    return std.ascii.isAlphabetic(c) or c == '_';
}
fn isIdentChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
}

/// The index of the `>` closing the `<` at `open` in `text`, skipping `->`.
fn closeAngle(text: []const u8, open: usize) ?usize {
    var depth: usize = 0;
    var i = open;
    while (i < text.len) : (i += 1) {
        const c = text[i];
        if (c == '-' and i + 1 < text.len and text[i + 1] == '>') {
            i += 1;
            continue;
        }
        switch (c) {
            '<', '(', '[', '{' => depth += 1,
            '>', ')', ']', '}' => {
                if (depth == 0) return null;
                depth -= 1;
                if (depth == 0) return if (c == '>') i else null;
            },
            else => {},
        }
    }
    return null;
}

/// Split a type-argument list at its top-level commas; each part trimmed.
fn splitArgs(arena: Allocator, text: []const u8) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var depth: usize = 0;
    var from: usize = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const c = text[i];
        if (c == '-' and i + 1 < text.len and text[i + 1] == '>') {
            i += 1;
            continue;
        }
        switch (c) {
            '<', '(', '[', '{' => depth += 1,
            '>', ')', ']', '}' => depth -|= 1,
            ',' => if (depth == 0) {
                try out.append(arena, std.mem.trim(u8, text[from..i], " \t\r\n"));
                from = i + 1;
            },
            else => {},
        }
    }
    const last = std.mem.trim(u8, text[from..], " \t\r\n");
    if (last.len > 0 or out.items.len > 0) try out.append(arena, last);
    return out.items;
}

/// The head name of a type (`Element` in `Element<T>`, `a.B` kept whole).
fn typeHead(t: []const u8) []const u8 {
    var i: usize = 0;
    while (i < t.len and (isIdentChar(t[i]) or t[i] == '.' or t[i] == '@')) i += 1;
    return t[0..i];
}

fn join(arena: Allocator, parts: []const []const u8) ![]const u8 {
    return std.mem.concat(arena, u8, parts);
}

/// Rewrite every wrapper this stage names inside the type text `text`.
fn rewriteType(ctx: *TypeCtx, text: []const u8) error{OutOfMemory}![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < text.len) {
        const c = text[i];
        const boundary = i == 0 or !(isIdentChar(text[i - 1]) or text[i - 1] == '.' or text[i - 1] == '@');
        if (!boundary or !(c == '@' or isIdentStart(c))) {
            try out.append(ctx.arena, c);
            i += 1;
            continue;
        }
        var j = i + 1;
        while (j < text.len and isIdentChar(text[j])) j += 1;
        const name = text[i..j];
        var k = j;
        while (k < text.len and (text[k] == ' ' or text[k] == '\t')) k += 1;
        if (k >= text.len or text[k] != '<') {
            if (ctx.stage == .one and std.mem.eql(u8, name, "Iterable")) try ctx.notes.append(ctx.arena, note_iterable);
            try out.appendSlice(ctx.arena, name);
            i = j;
            continue;
        }
        const close = closeAngle(text, k) orelse {
            try out.appendSlice(ctx.arena, name);
            i = j;
            continue;
        };
        const raw_args = try splitArgs(ctx.arena, text[k + 1 .. close]);
        const args = try ctx.arena.alloc([]const u8, raw_args.len);
        var inner_changed = false;
        for (raw_args, 0..) |a, n| {
            args[n] = try rewriteType(ctx, a);
            inner_changed = inner_changed or !std.mem.eql(u8, args[n], a);
        }
        const whole = text[i .. close + 1];
        const replaced = try rewriteApplication(ctx, name, args);
        if (replaced) |r| {
            try out.appendSlice(ctx.arena, r);
        } else if (inner_changed) {
            try out.appendSlice(ctx.arena, name);
            try out.append(ctx.arena, '<');
            for (args, 0..) |a, n| {
                if (n > 0) try out.appendSlice(ctx.arena, ", ");
                try out.appendSlice(ctx.arena, a);
            }
            try out.append(ctx.arena, '>');
        } else {
            try out.appendSlice(ctx.arena, whole);
        }
        i = close + 1;
    }
    return out.items;
}

/// The rewrite of `name<args…>` at this stage, or null to keep it.
fn rewriteApplication(ctx: *TypeCtx, name: []const u8, args: []const []const u8) !?[]const u8 {
    const a = ctx.arena;
    const eql = std.mem.eql;
    const n = args.len;
    switch (ctx.stage) {
        .one => {
            if (eql(u8, name, "@Context") and n == 2) return try join(a, &.{ "@Component<", args[0], ", ", args[1], ">" });
            if (eql(u8, name, "@Use")) {
                if (n == 2) return try join(a, &.{ "@Component<", args[0], ", ", args[1], ">" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "@Component") and n == 1) {
                const head = typeHead(args[0]);
                if (ctx.bases) |b| if (b.get(head)) |base| return try join(a, &.{ "@Component<", base, ", ", args[0], ">" });
                try ctx.notes.append(a, try std.fmt.allocPrint(a, "`@Component<{s}>` needs its context base: no `type {s} … implement @Context<C>` was found — write `@Component<C, {s}>`", .{ args[0], head, args[0] }));
                return null;
            }
            if (eql(u8, name, "@Iterator")) {
                if (n == 2) return try join(a, &.{ "@ResultGenerator<", args[0], ", ", args[1], ">" });
                if (n > 2) try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "@AsyncIterator")) {
                if (n == 1) return try join(a, &.{ "@FutureGenerator<", args[0], ">" });
                if (n == 2) return try join(a, &.{ "@FutureGenerator<", args[0], ", ", args[1], ">" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "IteratorStep")) {
                var parts: std.ArrayListUnmanaged(u8) = .empty;
                try parts.appendSlice(a, "YieldStep<");
                for (args, 0..) |arg, idx| {
                    if (idx > 0) try parts.appendSlice(a, ", ");
                    try parts.appendSlice(a, arg);
                }
                try parts.append(a, '>');
                return parts.items;
            }
            if (eql(u8, name, "Yield") and n == 2) {
                try ctx.notes.append(a, note_yield_completion);
                return try join(a, &.{ "YieldStep<", args[0], ">" });
            }
            return null;
        },
        .two => {
            if (eql(u8, name, "@Future")) {
                if (n == 1) return try join(a, &.{ "@Task<", args[0], ">" });
                if (n == 2) return try join(a, &.{ "@Task<@Result<", args[0], ", ", args[1], ">>" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "@Generator")) {
                if (n == 1) return try join(a, &.{ "@Iterator<", args[0], ">" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "@ResultGenerator")) {
                if (n == 1) return try join(a, &.{ "@Iterator<", args[0], ">" });
                if (n == 2) return try join(a, &.{ "@Iterator<@Result<", args[0], ", ", args[1], ">>" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "@FutureGenerator")) {
                if (n == 1) return try join(a, &.{ "@Stream<", args[0], ">" });
                if (n == 2) return try join(a, &.{ "@Stream<@Result<", args[0], ", ", args[1], ">>" });
                try ctx.notes.append(a, try arityNote(a, name, n));
                return null;
            }
            if (eql(u8, name, "YieldStep") and n == 2) return try join(a, &.{ "YieldStep<", args[0], ">" });
            return null;
        },
    }
}

fn arityNote(a: Allocator, name: []const u8, n: usize) ![]const u8 {
    return std.fmt.allocPrint(a, "`{s}` with {d} type argument(s) has no automatic rewrite — write the wrapper of guide.md (`@Task`, `@Component<C, T>`, `@Iterator`, `@Stream`) by hand", .{ name, n });
}

/// The names a stage's type scan stops at (as written in the source).
fn isTypeTarget(stage: Stage, tk: Toks, i: usize) bool {
    const lx = tk.lexeme(i);
    const eql = std.mem.eql;
    switch (tk.kind(i)) {
        .builtinIdent => return switch (stage) {
            .one => eql(u8, lx, "@Context") or eql(u8, lx, "@Use") or eql(u8, lx, "@Component") or
                eql(u8, lx, "@Iterator") or eql(u8, lx, "@AsyncIterator"),
            .two => eql(u8, lx, "@Future") or eql(u8, lx, "@Generator") or eql(u8, lx, "@ResultGenerator") or
                eql(u8, lx, "@FutureGenerator"),
        },
        .identifier => {
            // A declaration of the name is not a use of it.
            if (i > 0 and (tk.is(i - 1, .type) or tk.is(i - 1, .behavior) or tk.is(i - 1, .dot))) return false;
            return switch (stage) {
                .one => eql(u8, lx, "IteratorStep") or eql(u8, lx, "Yield") or eql(u8, lx, "Iterable"),
                .two => eql(u8, lx, "YieldStep"),
            };
        },
        else => return false,
    }
}

/// Scan the source for this stage's wrapper applications and queue their
/// rewrites (and the notes they raise, as markers).
fn rewriteTypesIn(ed: *Editor, tk: Toks, stage: Stage, bases: ?*const Bases) !void {
    var i: usize = 0;
    while (i < tk.sig.len) : (i += 1) {
        if (!isTypeTarget(stage, tk, i)) continue;
        var ctx: TypeCtx = .{ .arena = ed.arena, .stage = stage, .bases = bases };
        if (!tk.is(i + 1, .lessThan)) {
            if (stage == .one and std.mem.eql(u8, tk.lexeme(i), "Iterable")) try ed.mark(tk.start(i), note_iterable);
            continue;
        }
        const m = tk.matchAngle(i + 1) orelse continue;
        const text = tk.src[tk.start(i)..m.end];
        const new = try rewriteType(&ctx, text);
        if (!std.mem.eql(u8, new, text)) try ed.replace(tk.start(i), m.end, new);
        for (ctx.notes.items) |n| try ed.mark(tk.start(i), n);
        i = m.close;
    }
}

// ── attributes and functions ────────────────────────────────────────────────

const AttrItem = struct { first: usize, last: usize };
const AttrGroup = struct { hash: usize, open: usize, close: usize, items: []const AttrItem };

fn attrGroups(arena: Allocator, tk: Toks) ![]const AttrGroup {
    var out: std.ArrayListUnmanaged(AttrGroup) = .empty;
    var i: usize = 0;
    while (i + 1 < tk.sig.len) : (i += 1) {
        if (!tk.is(i, .hash) or !tk.is(i + 1, .leftSquareBracket)) continue;
        const close = tk.matchClose(i + 1) orelse continue;
        var items: std.ArrayListUnmanaged(AttrItem) = .empty;
        var first = i + 2;
        var j = i + 2;
        while (j < close) : (j += 1) {
            switch (tk.kind(j)) {
                .leftParenthesis, .leftSquareBracket, .leftBrace => j = tk.matchClose(j) orelse close,
                .comma => {
                    if (j > first) try items.append(arena, .{ .first = first, .last = j - 1 });
                    first = j + 1;
                },
                else => {},
            }
        }
        if (close > first) try items.append(arena, .{ .first = first, .last = close - 1 });
        try out.append(arena, .{ .hash = i, .open = i + 1, .close = close, .items = items.items });
        i = close;
    }
    return out.items;
}

/// The effect a single-token attribute item names, or null.
fn effectOf(tk: Toks, item: AttrItem) ?[]const u8 {
    if (item.first != item.last or !tk.is(item.first, .builtinIdent)) return null;
    const lx = tk.lexeme(item.first);
    for (effect_names) |e| if (std.mem.eql(u8, lx, e)) return e;
    return null;
}

const effect_names = [_][]const u8{ "@result", "@future", "@use", "@generator", "@resultGenerator", "@futureGenerator" };

const FnInfo = struct {
    fn_tok: usize,
    name: []const u8,
    is_pub: bool,
    is_declare: bool = false,
    /// Offset of the first attribute (or modifier) of the declaration.
    decl_start: usize,
    /// Offset of the first modifier / `fn` after the attributes.
    head_start: usize,
    groups: []const usize,
    effect: ?struct { group: usize, item: usize, name: []const u8 } = null,
    ret: ?struct { start: usize, end: usize, first: usize } = null,
    body: ?struct { open: usize, close: usize } = null,
};

fn functions(arena: Allocator, tk: Toks, groups: []const AttrGroup) ![]const FnInfo {
    var by_close: std.AutoHashMapUnmanaged(usize, usize) = .empty;
    for (groups, 0..) |g, gi| try by_close.put(arena, g.close, gi);

    var out: std.ArrayListUnmanaged(FnInfo) = .empty;
    var i: usize = 0;
    while (i + 1 < tk.sig.len) : (i += 1) {
        if (!tk.is(i, .@"fn") or !tk.is(i + 1, .identifier)) continue;
        var info: FnInfo = .{ .fn_tok = i, .name = tk.lexeme(i + 1), .is_pub = false, .decl_start = tk.start(i), .head_start = tk.start(i), .groups = &.{} };
        // Modifiers and attribute groups before `fn`.
        var j: isize = @as(isize, @intCast(i)) - 1;
        var head = i;
        var gs: std.ArrayListUnmanaged(usize) = .empty;
        while (j >= 0) {
            const ju: usize = @intCast(j);
            switch (tk.kind(ju)) {
                .@"pub", .declare, .default, .private => {
                    if (tk.is(ju, .@"pub")) info.is_pub = true;
                    if (tk.is(ju, .declare)) info.is_declare = true;
                    head = ju;
                    j -= 1;
                },
                .rightSquareBracket => {
                    const gi = by_close.get(ju) orelse break;
                    try gs.append(arena, gi);
                    j = @as(isize, @intCast(groups[gi].hash)) - 1;
                },
                else => break,
            }
        }
        info.head_start = tk.start(head);
        info.decl_start = if (gs.items.len > 0) tk.start(groups[gs.items[gs.items.len - 1]].hash) else info.head_start;
        std.mem.reverse(usize, gs.items);
        info.groups = gs.items;
        for (gs.items) |gi| for (groups[gi].items, 0..) |item, ii| {
            if (effectOf(tk, item)) |e| info.effect = .{ .group = gi, .item = ii, .name = e };
        };
        // Signature.
        var k = i + 2;
        if (tk.is(k, .lessThan)) k = (tk.matchAngle(k) orelse continue).close + 1;
        if (!tk.is(k, .leftParenthesis)) continue;
        k = (tk.matchClose(k) orelse continue) + 1;
        if (tk.is(k, .rightArrow)) {
            const first = k + 1;
            var depth: isize = 0;
            var e = first;
            while (e < tk.sig.len) : (e += 1) {
                switch (tk.kind(e)) {
                    .lessThan, .lessThanLessThan => depth += if (tk.is(e, .lessThan)) 1 else 2,
                    .greaterThan => depth -= 1,
                    .greaterThanGreaterThan => depth -= 2,
                    .leftParenthesis, .leftSquareBracket => {
                        e = tk.matchClose(e) orelse break;
                        continue;
                    },
                    .leftBrace, .semicolon, .colon, .rightBrace, .endOfFile => if (depth <= 0) break,
                    else => {},
                }
            }
            if (e > first) info.ret = .{ .start = tk.start(first), .end = tk.end(e - 1), .first = first };
            k = e;
            if (tk.is(k, .colon) and tk.is(k + 1, .identifier)) k += 2;
        }
        if (tk.is(k, .leftBrace)) {
            if (tk.matchClose(k)) |c| info.body = .{ .open = k, .close = c };
        }
        try out.append(arena, info);
    }
    return out.items;
}

/// The innermost named function whose body holds `off`.
fn enclosing(fns: []const FnInfo, tk: Toks, off: usize) ?usize {
    var best: ?usize = null;
    for (fns, 0..) |f, fi| {
        const b = f.body orelse continue;
        if (off <= tk.start(b.open) or off >= tk.end(b.close)) continue;
        if (best) |bi| {
            if (tk.start(fns[bi].body.?.open) < tk.start(b.open)) best = fi;
        } else best = fi;
    }
    return best;
}

/// Remove one attribute item — its line when the group is alone on it.
fn removeAttrItem(ed: *Editor, tk: Toks, g: AttrGroup, item_idx: usize) !void {
    const src = tk.src;
    if (g.items.len == 1) {
        const s = tk.start(g.hash);
        const e = tk.end(g.close);
        const ls = lineStart(src, s);
        const le = lineEnd(src, e);
        if (isBlank(src[ls..s]) and isBlank(src[e..le])) {
            try ed.replace(ls, @min(le + 1, src.len), "");
        } else {
            var after = e;
            while (after < src.len and (src[after] == ' ' or src[after] == '\t')) after += 1;
            try ed.replace(s, after, "");
        }
        return;
    }
    const item = g.items[item_idx];
    if (item_idx + 1 < g.items.len) {
        try ed.replace(tk.start(item.first), tk.start(g.items[item_idx + 1].first), "");
    } else {
        try ed.replace(tk.end(g.items[item_idx - 1].last), tk.end(item.last), "");
    }
}

// ── stage 1: normalise the pre-121 spellings to today's ─────────────────────

fn stage1(arena: Allocator, src: []const u8, bases: *const Bases) ![]const u8 {
    const tk = (try lex(arena, src)) orelse return src;
    var ed: Editor = .{ .arena = arena, .src = src };
    const groups = try attrGroups(arena, tk);

    // Attribute names of the pre-121 effects.
    for (groups) |g| for (g.items) |item| {
        if (item.first != item.last or !tk.is(item.first, .builtinIdent)) continue;
        const lx = tk.lexeme(item.first);
        const to: ?[]const u8 = if (std.mem.eql(u8, lx, "@context"))
            "@use"
        else if (std.mem.eql(u8, lx, "@iterator"))
            "@resultGenerator"
        else if (std.mem.eql(u8, lx, "@asyncGenerator"))
            "@futureGenerator"
        else
            null;
        if (to) |t| try ed.replace(tk.start(item.first), tk.end(item.first), t);
    };

    // `loop (xs) { x -> }` → `for`, `loop (cond)` → `while`, `loop await` → `for await`.
    var i: usize = 0;
    while (i + 1 < tk.sig.len) : (i += 1) {
        if (!tk.is(i, .loop)) continue;
        if (tk.is(i + 1, .await)) {
            try ed.replace(tk.start(i), tk.end(i), "for");
            continue;
        }
        if (!tk.is(i + 1, .leftParenthesis)) continue;
        const close = tk.matchClose(i + 1) orelse continue;
        var b = close + 1;
        if (tk.is(b, .colon) and tk.is(b + 1, .identifier)) b += 2;
        const binds = tk.is(b, .leftBrace) and bindsItem(tk, b + 1);
        try ed.replace(tk.start(i), tk.end(i), if (binds) "for" else "while");
    }

    try rewriteTypesIn(&ed, tk, .one, bases);

    // A function that `use`s a hook behind a plain `-> T`.
    const fns = try functions(arena, tk, groups);
    for (fns) |f| {
        const body = f.body orelse continue;
        if (!bodyUsesHook(tk, fns, f)) continue;
        if (f.effect) |e| if (!std.mem.eql(u8, e.name, "@use") and !std.mem.eql(u8, tk.lexeme(groups[e.group].items[e.item].first), "@context")) continue;
        const ret = f.ret orelse {
            try ed.mark(f.decl_start, note_hook_plain_return);
            continue;
        };
        const t = std.mem.trim(u8, tk.src[ret.start..ret.end], " \t\r\n");
        if (t.len > 0 and t[0] == '@') continue;
        const base = bases.get(typeHead(t)) orelse {
            try ed.mark(f.decl_start, note_hook_plain_return);
            continue;
        };
        _ = body;
        try ed.replace(ret.start, ret.end, try join(arena, &.{ "@Component<", base, ", ", t, ">" }));
        if (f.effect == null) try ed.insert(f.head_start, "#[@use] ");
    }

    return ed.apply();
}

/// `{ x ->` / `{ _ ->` / `{ (a, b) ->` — the body of a loop binds its item.
fn bindsItem(tk: Toks, j: usize) bool {
    if (tk.is(j, .identifier) or tk.is(j, .underscore)) return tk.is(j + 1, .rightArrow);
    if (tk.is(j, .leftParenthesis)) {
        const c = tk.matchClose(j) orelse return false;
        return tk.is(c + 1, .rightArrow);
    }
    return false;
}

/// A `use` in `f`'s own body (not in a named function nested in it).
fn bodyUsesHook(tk: Toks, fns: []const FnInfo, f: FnInfo) bool {
    const b = f.body orelse return false;
    var j = b.open + 1;
    while (j < b.close) : (j += 1) {
        if (!tk.is(j, .use)) continue;
        if (enclosing(fns, tk, tk.start(j))) |fi| {
            if (fns[fi].fn_tok == f.fn_tok) return true;
        }
    }
    return false;
}

// ── semantic facts (the checker's types over the normalised text) ───────────

const SiteKind = enum { await_, throw_, try_, for_, case_error, next_call, ident };

const Site = struct {
    kind: SiteKind,
    off: usize,
    closure: u32,
    /// await: the operand; for: the iterated expression; case: the subject;
    /// next: the receiver.
    operand: ?ast.Loc = null,
    /// for: the one name the loop binds; ident: the name.
    name: []const u8 = "",
    /// for: `for await`.
    await_loop: bool = false,
    /// case: an arm names `Yield` or `Done` too (a step, whatever its type).
    step_arms: bool = false,
};

const Facts = struct {
    /// The normalised text parsed.
    parsed: bool,
    log: ?*const bp.comptime_pipeline.ExprTypeLog,
    file: []const u8,
    sites: []const Site,
    line_starts: []const usize,

    fn typeAt(self: *const Facts, loc: ?ast.Loc) ?*Type {
        const l = self.log orelse return null;
        const at = loc orelse return null;
        return l.typeAt(self.file, at);
    }
};

fn analyse(arena: Allocator, s1: []const u8, log: ?*const bp.comptime_pipeline.ExprTypeLog, file: []const u8) !Facts {
    var starts: std.ArrayListUnmanaged(usize) = .empty;
    try starts.append(arena, 0);
    for (s1, 0..) |c, i| if (c == '\n') try starts.append(arena, i + 1);
    var facts: Facts = .{ .parsed = false, .log = log, .file = file, .sites = &.{}, .line_starts = starts.items };

    var lexer = bp.Lexer.init(s1);
    const tokens = lexer.scanAll(arena) catch return facts;
    var parser = bp.Parser.init(tokens);
    const program = parser.parse(arena) catch return facts;
    var w: Walker = .{ .arena = arena, .line_starts = starts.items };
    for (program.decls) |*d| try w.walk(ast.DeclKind, d);
    facts.parsed = true;
    facts.sites = w.sites.items;
    return facts;
}

const Walker = struct {
    arena: Allocator,
    line_starts: []const usize,
    closure: u32 = 0,
    sites: std.ArrayListUnmanaged(Site) = .empty,

    const Error = error{OutOfMemory};

    fn offOf(self: *const Walker, loc: ast.Loc) usize {
        if (loc.line == 0 or loc.line > self.line_starts.len) return 0;
        return self.line_starts[loc.line - 1] + loc.col - 1;
    }

    fn add(self: *Walker, site: Site) Error!void {
        try self.sites.append(self.arena, site);
    }

    fn walk(self: *Walker, comptime T: type, v: *const T) Error!void {
        if (T == ast.Expr) return self.visitExpr(v);
        if (T == ast.TrailingLambdaOf(.untyped)) {
            self.closure += 1;
            defer self.closure -= 1;
            return self.walkFields(T, v);
        }
        return self.walkFields(T, v);
    }

    fn walkFields(self: *Walker, comptime T: type, v: *const T) Error!void {
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (comptime walkable(f.type)) try self.walk(f.type, &@field(v.*, f.name));
            },
            .@"union" => |u| {
                if (u.tag_type == null) return;
                switch (v.*) {
                    inline else => |*p| {
                        const P = @TypeOf(p.*);
                        if (comptime walkable(P)) try self.walk(P, p);
                    },
                }
            },
            .pointer => |p| switch (p.size) {
                .one => if (comptime walkable(p.child)) try self.walk(p.child, v.*),
                .slice => if (comptime walkable(p.child)) {
                    for (v.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            .optional => |o| if (v.*) |*inner| {
                if (comptime walkable(o.child)) try self.walk(o.child, inner);
            },
            else => {},
        }
    }

    fn walkable(comptime T: type) bool {
        return switch (@typeInfo(T)) {
            .@"struct", .@"union" => true,
            .pointer => |p| (p.size == .one or p.size == .slice) and p.child != u8 and walkable(p.child),
            .optional => |o| walkable(o.child),
            else => false,
        };
    }

    fn visitExpr(self: *Walker, e: *const ast.Expr) Error!void {
        switch (e.*) {
            .jump => |j| switch (j.kind) {
                .await_ => |op| try self.add(.{ .kind = .await_, .off = self.offOf(j.loc), .closure = self.closure, .operand = op.getLoc() }),
                .throw_ => try self.add(.{ .kind = .throw_, .off = self.offOf(j.loc), .closure = self.closure }),
                .try_ => try self.add(.{ .kind = .try_, .off = self.offOf(j.loc), .closure = self.closure }),
                else => {},
            },
            .loop => |lp| if (lp.keyword == .for_) {
                try self.add(.{
                    .kind = .for_,
                    .off = self.offOf(lp.loc),
                    .closure = self.closure,
                    .operand = lp.iter.getLoc(),
                    .name = if (lp.params.len == 1) lp.params[0] else "",
                    .await_loop = lp.awaitLoop,
                });
            },
            .collection => |c| switch (c.kind) {
                .case => |cs| {
                    var err_arm = false;
                    var step_arm = false;
                    for (cs.arms) |arm| {
                        const n = variantName(arm.pattern) orelse continue;
                        if (std.mem.eql(u8, n, "Error")) err_arm = true;
                        if (std.mem.eql(u8, n, "Yield") or std.mem.eql(u8, n, "Done")) step_arm = true;
                    }
                    if (err_arm and cs.subjects.len > 0) try self.add(.{
                        .kind = .case_error,
                        .off = self.offOf(c.loc),
                        .closure = self.closure,
                        .operand = cs.subjects[0].getLoc(),
                        .step_arms = step_arm,
                    });
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cl| if (std.mem.eql(u8, cl.callee, "next") and cl.args.len == 0) {
                    if (cl.receiver) |r| try self.add(.{ .kind = .next_call, .off = self.offOf(c.loc), .closure = self.closure, .operand = r.getLoc() });
                },
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |name| try self.add(.{ .kind = .ident, .off = self.offOf(id.loc), .closure = self.closure, .name = name }),
                else => {},
            },
            .function => |f| {
                self.closure += 1;
                defer self.closure -= 1;
                for (f.kind.body) |*s| try self.walk(ast.Stmt, s);
                return;
            },
            else => {},
        }
        switch (e.*) {
            inline else => |*p| try self.walkFields(@TypeOf(p.*), p),
        }
    }
};

/// The variant a case pattern names, without its qualifier (`.Error(e)`,
/// `YieldStep.Error(e)` → `Error`).
fn variantName(p: ast.Pattern) ?[]const u8 {
    const raw = switch (p) {
        .variant => |v| v.name,
        .ident => |n| n,
        else => return null,
    };
    const dot = std.mem.lastIndexOfScalar(u8, raw, '.') orelse return raw;
    return raw[dot + 1 ..];
}

/// The error type of a fallible wrapper value: `name<@Result<T, E>>` with `E`
/// not `any`. The migration parse (24-d) reads the old wrappers in their new
/// spelling, so the checker's types name `Task` (`@Future<T, E>`), `Iterator`
/// (`@ResultGenerator<T, E>`) and `Stream` (`@FutureGenerator<T, E>`), with
/// the error in a `@Result` layer; `@Future<T>` (`E = any`) reads as
/// `@Task<T>` and is not fallible.
fn fallibleError(t: ?*Type, names: []const []const u8) ?*Type {
    const ty = (t orelse return null).deref();
    switch (ty.*) {
        .named => |n| {
            var hit = false;
            for (names) |want| {
                if (std.mem.eql(u8, n.name, want) or (n.name.len > 0 and n.name[0] == '@' and std.mem.eql(u8, n.name[1..], want))) hit = true;
            }
            if (!hit or n.args.len != 1) return null;
            const inner = n.args[0].deref();
            if (inner.* != .named or !std.mem.eql(u8, inner.named.name, "Result") or inner.named.args.len < 2) return null;
            const e = inner.named.args[1].deref();
            if (e.isNamed("any")) return null;
            return e;
        },
        else => return null,
    }
}

fn typeIsNamed(t: ?*Type, want: []const u8) bool {
    const ty = (t orelse return false).deref();
    return switch (ty.*) {
        .named => |n| std.mem.eql(u8, n.name, want) or (n.name.len > 0 and n.name[0] == '@' and std.mem.eql(u8, n.name[1..], want)),
        else => false,
    };
}

// ── stage 2: today's language → guide.md ────────────────────────────────────

/// Whether the (rewritten) return type carries a `@Result` in some layer —
/// the fallible channel `throw` / `try` read (decision 121).
fn hasResultLayer(arena: Allocator, ret: []const u8) !bool {
    var t = std.mem.trim(u8, ret, " \t\r\n");
    while (true) {
        const head = typeHead(t);
        if (std.mem.eql(u8, head, "@Result")) return true;
        const open = std.mem.indexOfScalar(u8, t, '<') orelse return false;
        if (open != head.len) return false;
        const close = closeAngle(t, open) orelse return false;
        const args = try splitArgs(arena, t[open + 1 .. close]);
        if (std.mem.eql(u8, head, "@Task") or std.mem.eql(u8, head, "@Iterator") or std.mem.eql(u8, head, "@Stream")) {
            if (args.len != 1) return false;
            t = args[0];
        } else if (std.mem.eql(u8, head, "@Component")) {
            if (args.len != 2) return false;
            t = args[1];
        } else return false;
    }
}

fn stage2(arena: Allocator, s1: []const u8, facts: ?*const Facts) ![]const u8 {
    const tk = (try lex(arena, s1)) orelse return s1;
    var ed: Editor = .{ .arena = arena, .src = s1 };
    const groups = try attrGroups(arena, tk);
    const fns = try functions(arena, tk, groups);

    // Annotated loops → `iter` / `stream`.
    for (groups) |g| {
        const after = g.close + 1;
        if (!(tk.is(after, .loop) or tk.is(after, .@"while") or tk.is(after, .@"for"))) continue;
        if (g.items.len != 1) continue;
        const eff = effectOf(tk, g.items[0]) orelse continue;
        const prefix: []const u8 = if (std.mem.eql(u8, eff, "@generator") or std.mem.eql(u8, eff, "@resultGenerator"))
            "iter"
        else if (std.mem.eql(u8, eff, "@futureGenerator"))
            "stream"
        else {
            try ed.mark(tk.start(g.hash), try std.fmt.allocPrint(arena, "`#[{s}]` on a loop names no generator: an `iter` / `stream` loop, or a plain loop — decide which", .{eff}));
            continue;
        };
        if (try collapseLoop(&ed, tk, g, prefix)) continue;
        try ed.replace(tk.start(g.hash), tk.start(after), try join(arena, &.{ prefix, " " }));
    }

    // Effect annotations on functions.
    for (fns) |f| {
        const e = f.effect orelse continue;
        const g = groups[e.group];
        const after = g.close + 1;
        if (tk.is(after, .loop) or tk.is(after, .@"while") or tk.is(after, .@"for")) continue;
        try removeAttrItem(&ed, tk, g, e.item);
    }

    try rewriteTypesIn(&ed, tk, .two, null);
    try markReturnTypeNames(&ed, tk);

    if (facts) |fa| try semantic(&ed, tk, groups, fns, fa);

    return ed.apply();
}

/// The head a renamed wrapper answers in the comptime reflection: `@Decl`'s
/// `returnType` is the head of the written return with no type argument
/// (`"Future"` for `-> @Future<Element>`), so a decorator that compares it
/// against an old wrapper's name refuses every function the migration
/// rewrote.
const renamed_heads = [_]struct { old: []const u8, new: []const u8 }{
    .{ .old = "Future", .new = "Task" },
    .{ .old = "Generator", .new = "Iterator" },
    .{ .old = "ResultGenerator", .new = "Iterator" },
    .{ .old = "FutureGenerator", .new = "Stream" },
    .{ .old = "AsyncIterator", .new = "Stream" },
    .{ .old = "Use", .new = "Component" },
};

/// `….returnType == "Future"` (either side, `==` or `!=`): marked, not
/// rewritten — the literal is a decorator's rule, and whether the rule still
/// holds under the new wrapper (a page that must be a `@Task`, a layout that
/// must not be one) is the library's call, as is every message beside it
/// that names the old annotation (decision 67).
fn markReturnTypeNames(ed: *Editor, tk: Toks) !void {
    var i: usize = 0;
    while (i < tk.sig.len) : (i += 1) {
        if (!tk.is(i, .stringLiteral)) continue;
        const lx = tk.lexeme(i);
        if (lx.len < 2) continue;
        const name = lx[1 .. lx.len - 1];
        const new = for (renamed_heads) |h| {
            if (std.mem.eql(u8, h.old, name)) break h.new;
        } else continue;
        const left = i >= 3 and (tk.is(i - 1, .equalEqual) or tk.is(i - 1, .notEqual)) and
            tk.isIdent(i - 2, "returnType") and tk.is(i - 3, .dot);
        var right = false;
        if (tk.is(i + 1, .equalEqual) or tk.is(i + 1, .notEqual)) {
            var j = i + 2;
            while (tk.is(j, .identifier) or tk.is(j, .dot)) : (j += 1) {
                if (tk.isIdent(j, "returnType") and j > 0 and tk.is(j - 1, .dot) and !tk.is(j + 1, .dot)) right = true;
            }
        }
        if (!left and !right) continue;
        try ed.mark(tk.start(i), try std.fmt.allocPrint(ed.arena, "`.returnType` answers the head of the written return, and the migration renamed it: `@{s}<…>` is `@{s}<…>` now, so this compares against \"{s}\" — update the comparison, and every message beside it that names the old wrapper or annotation", .{ name, new, new }));
    }
}

/// `#[@X] loop { for (xs) { … }; break; }` → `iter for (xs) { … }` when the
/// `for` is the only statement before the `break` and nothing else (no
/// comment) sits around it.
fn collapseLoop(ed: *Editor, tk: Toks, g: AttrGroup, prefix: []const u8) !bool {
    const l = g.close + 1;
    if (!tk.is(l, .loop) or !tk.is(l + 1, .leftBrace)) return false;
    const open = l + 1;
    const close = tk.matchClose(open) orelse return false;
    const f = open + 1;
    if (!tk.is(f, .@"for")) return false;
    var k = f + 1;
    if (tk.is(k, .await)) k += 1;
    if (!tk.is(k, .leftParenthesis)) return false;
    k = (tk.matchClose(k) orelse return false) + 1;
    if (!tk.is(k, .leftBrace)) return false;
    const fb = tk.matchClose(k) orelse return false;
    var r = fb + 1;
    if (tk.is(r, .semicolon)) r += 1;
    if (!tk.is(r, .@"break")) return false;
    r += 1;
    if (tk.is(r, .semicolon)) r += 1;
    if (r != close) return false;
    if (!isBlank(tk.src[tk.end(open)..tk.start(f)])) return false;
    // Only `;`, `break` and whitespace between the `for`'s body and the loop's end.
    const tail = tk.src[tk.end(fb)..tk.start(close)];
    var rest: std.ArrayListUnmanaged(u8) = .empty;
    for (tail) |c| if (c != ';' and c != ' ' and c != '\t' and c != '\n' and c != '\r') try rest.append(ed.arena, c);
    if (!std.mem.eql(u8, rest.items, "break")) return false;
    try ed.replace(tk.start(g.hash), tk.start(f), try join(ed.arena, &.{ prefix, " " }));
    try ed.replace(tk.end(fb), tk.end(close), "");
    return true;
}

fn semantic(ed: *Editor, tk: Toks, groups: []const AttrGroup, fns: []const FnInfo, fa: *const Facts) !void {
    const a = ed.arena;
    // Per function: the old return, the new one, and whether it can fail.
    const new_ret = try a.alloc(?[]const u8, fns.len);
    const result_layer = try a.alloc(bool, fns.len);
    for (fns, 0..) |f, fi| {
        new_ret[fi] = null;
        result_layer[fi] = false;
        const r = f.ret orelse continue;
        var ctx: TypeCtx = .{ .arena = a, .stage = .two, .bases = null };
        const nr = try rewriteType(&ctx, tk.src[r.start..r.end]);
        new_ret[fi] = nr;
        result_layer[fi] = try hasResultLayer(a, nr);
    }

    for (fns) |f| {
        // A host binding declared `@Future<T>` failed by rejecting (`E = any`);
        // declared `@Task<T>` a rejection is a fatal host failure (decision 126).
        if (f.is_declare and f.body == null) if (f.ret) |r| {
            const old = std.mem.trim(u8, tk.src[r.start..r.end], " \t\r\n");
            if (std.mem.startsWith(u8, old, "@Future<") and (try oneTypeArg(a, old))) try ed.mark(f.decl_start, note_declare_future);
        };
        if (f.effect == null) continue;
        if (!fa.parsed) {
            try ed.mark(f.decl_start, note_not_parsed);
            continue;
        }
        const r = f.ret orelse continue;
        const old = std.mem.trim(u8, tk.src[r.start..r.end], " \t\r\n");
        if (old.len == 0 or old[0] != '@') try ed.mark(f.decl_start, note_alias);
    }
    if (!fa.parsed) return;
    _ = groups;

    for (fa.sites) |site| {
        const fi = enclosing(fns, tk, site.off) orelse continue;
        const f = fns[fi];
        switch (site.kind) {
            .await_ => {
                if (f.effect == null) continue;
                const i = tk.sigAt(site.off);
                if (i > 0 and tk.is(i - 1, .@"try")) continue;
                if (fa.log == null) {
                    try ed.mark(site.off, note_await_untyped);
                    continue;
                }
                const err = fallibleError(fa.typeAt(site.operand), &.{"Task"}) orelse continue;
                _ = err;
                if (result_layer[fi] and site.closure == 0) {
                    try ed.insert(site.off, "try ");
                } else {
                    try ed.mark(site.off, note_await_no_channel);
                }
            },
            .throw_, .try_ => {
                if (site.closure > 0 or f.effect == null) continue;
                if (result_layer[fi]) continue;
                try ed.mark(site.off, try throwNote(a, tk, f));
            },
            .for_ => {
                if (fa.log == null) {
                    // Untyped: a `for await` walks a stream, which may be a
                    // fallible one — mark it; a plain `for` is left alone.
                    if (site.await_loop) try ed.mark(site.off, note_for_await_untyped);
                    continue;
                }
                const t = fa.typeAt(site.operand);
                _ = fallibleError(t, &.{ "Iterator", "Stream" }) orelse continue;
                if (try wrapLoopItem(ed, tk, fa, site, result_layer[fi])) continue;
                try ed.mark(site.off, if (site.await_loop) note_for_await_fallible else note_for_fallible);
            },
            .case_error => {
                const t = fa.typeAt(site.operand);
                const is_step = if (fa.log != null) typeIsNamed(t, "YieldStep") else site.step_arms;
                if (is_step) try ed.mark(site.off, note_case_yieldstep);
            },
            .next_call => {
                if (fa.log == null) continue;
                _ = fallibleError(fa.typeAt(site.operand), &.{ "Iterator", "Stream" }) orelse continue;
                try ed.mark(site.off, note_next);
            },
            .ident => {},
        }
    }

    // JS consumers of a `pub` function whose failure used to reject. Read
    // off the signature — a declared `E` is the contract JS callers relied
    // on — not off the body: a body that fails by passing another fallible
    // future through (`return load(n);`) has no `throw` / `try` to see, and
    // its Promise stops rejecting all the same.
    for (fns, 0..) |f, fi| {
        if (!f.is_pub or f.effect == null) continue;
        const r = f.ret orelse continue;
        const old = std.mem.trim(u8, tk.src[r.start..r.end], " \t\r\n");
        if (!std.mem.startsWith(u8, old, "@Future<")) continue;
        if (!try declaresError(a, old)) continue;
        const nr = new_ret[fi] orelse continue;
        if (!std.mem.startsWith(u8, nr, "@Task<@Result<")) continue;
        try ed.mark(f.decl_start, note_js_reject);
    }
}

/// `Name<T, E>` with an error argument other than `any` — a declared failure.
fn declaresError(a: Allocator, t: []const u8) !bool {
    const open = std.mem.indexOfScalar(u8, t, '<') orelse return false;
    const close = closeAngle(t, open) orelse return false;
    const args = try splitArgs(a, t[open + 1 .. close]);
    return args.len == 2 and !std.mem.eql(u8, std.mem.trim(u8, args[1], " \t\r\n"), "any");
}

/// `Name<X>` with exactly one type argument.
fn oneTypeArg(a: Allocator, t: []const u8) !bool {
    const open = std.mem.indexOfScalar(u8, t, '<') orelse return false;
    const close = closeAngle(t, open) orelse return false;
    return (try splitArgs(a, t[open + 1 .. close])).len == 1;
}

fn throwNote(a: Allocator, tk: Toks, f: FnInfo) ![]const u8 {
    const r = f.ret orelse return note_throw_no_channel;
    const old = std.mem.trim(u8, tk.src[r.start..r.end], " \t\r\n");
    const head = typeHead(old);
    const one_arg = try oneTypeArg(a, old);
    if (one_arg and std.mem.eql(u8, head, "@Future")) return note_future_any;
    if (one_arg and (std.mem.eql(u8, head, "@ResultGenerator") or std.mem.eql(u8, head, "@FutureGenerator"))) return note_generator_any;
    return note_throw_no_channel;
}

/// `for` over what was a fallible generator: the loop used to `try` each
/// item. With a `@Result` in the new return and the item used exactly once
/// in the loop's own body, that use becomes `(try x)`; otherwise false.
fn wrapLoopItem(ed: *Editor, tk: Toks, fa: *const Facts, site: Site, result_layer: bool) !bool {
    if (!result_layer or site.name.len == 0 or site.closure > 0) return false;
    // The loop's body braces.
    var i = tk.sigAt(site.off);
    if (!tk.is(i, .@"for")) return false;
    i += 1;
    if (tk.is(i, .await)) i += 1;
    if (tk.is(i, .colon)) i += 2;
    if (!tk.is(i, .leftParenthesis)) return false;
    i = (tk.matchClose(i) orelse return false) + 1;
    if (!tk.is(i, .leftBrace)) return false;
    const close = tk.matchClose(i) orelse return false;
    const lo = tk.end(i);
    const hi = tk.start(close);
    var use: ?Site = null;
    var count: usize = 0;
    for (fa.sites) |s| {
        if (s.kind != .ident or s.off < lo or s.off >= hi) continue;
        if (!std.mem.eql(u8, s.name, site.name)) continue;
        count += 1;
        use = s;
    }
    if (count != 1) return false;
    const u = use.?;
    if (u.closure != site.closure) return false;
    try ed.replace(u.off, u.off + site.name.len, try join(ed.arena, &.{ "(try ", site.name, ")" }));
    return true;
}

// ── review notes ────────────────────────────────────────────────────────────

const note_await_no_channel = "`await` now hands over the `@Result` (the awaited `@Future` could fail) and this function's return has no `@Result` to propagate it into: handle it here (`try await … catch …`, `case`, `notFound()`) or put `@Result` in the return";
const note_await_untyped = "this module was not type-checked (it does not type-check after normalisation, or the project does not compile it), so this `await` was not classified: write `try await` if the awaited value can fail and its error should propagate";
const note_throw_no_channel = "`throw` / `try` needs a `@Result` in the return now (a hook or component no longer propagates): return a `@Result`, or handle the error here with `catch` / `case`";
const note_future_any = "`@Future<T>` could fail (`E = any`) and this body throws or tries, but `@Task<T>` cannot fail: return `@Task<@Result<T, E>>`, or handle the error here";
const note_generator_any = "the generator could fail (`E = any`) and this body throws or tries, but its item is not a `@Result`: make the item `@Result<T, E>`, or handle the error here";
const note_for_fallible = "`for` no longer does an implicit `try`: each item of this iterator is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it";
const note_for_await_fallible = "`for await` no longer does an implicit `try`: each item of this stream is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it";
const note_for_await_untyped = "this module was not type-checked, so this `for await` was not classified: if the stream can fail, its items are `@Result`s now and the implicit `try` is gone — write `try <item>` where it is used, or `case` over it";
const note_declare_future = "a host binding declared `@Future<T>` failed by rejecting (`E = any`); declared `@Task<T>`, a rejection is a fatal host failure — declare `@Task<@Result<T, E>>` if the host can fail";
const note_case_yieldstep = "`YieldStep<T>` has no `Error` arm any more: the error travels in the item (`@Iterator<@Result<T, E>>`) — rewrite this `case`";
const note_next = "`.next()` on a fallible generator: the step has no `Error` any more, the item is a `@Result` — review how this code handles the error";
const note_alias = "the effect is read from the written return: an alias does not activate it — write the wrapper (`@Result`, `@Task`, `@Component<C, T>`, `@Iterator`, `@Stream`) in the return";
const note_js_reject = "JavaScript callers: a failure of this function now resolves the Promise with `Error(…)` instead of rejecting it";
const note_hook_plain_return = "`use` in a function that does not return `@Component<C, T>`: a hook or component returns `@Component<C, T>` — write it with the context base `C`";
const note_iterable = "`Iterable` is gone: expose a method that returns an `@Iterator<T>` (`fn iter(self: Self) -> @Iterator<T>`)";
const note_yield_completion = "`Yield<T, R>` → `YieldStep<T>`: the completion value `R` has no place in the step — end with `break v` (it emits `v` as the last item) or return it separately";
const note_not_parsed = "the module did not parse after normalisation, so `await`, `throw`, `try` and `for` in this function were not analysed — review them against guide.md";

// ── the command ─────────────────────────────────────────────────────────────

pub fn run(gpa: Allocator, io: std.Io, opts: Options, env_map: libs.EnvMap) !u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // The loaders parse every module to order the module tree and read its
    // exports: they parse the old surface too (the migration parse, 24-d);
    // `migrate` adds the checker's half for the files it rewrites.
    bp.comptime_pipeline.setEffectMigration(&.{});
    defer bp.comptime_pipeline.setEffectMigration(null);

    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — run `botopink migrate effects` in a botopink project"),
            error.ConfigInvalid => {},
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    var loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer loaded.free(gpa);
    var test_scan = try scanner.scanSourcesWithFiles(gpa, io, "test");
    defer test_scan.free(gpa);
    const dep_modules = libs.loadDependencies(gpa, io, proj, env_map) catch |err| {
        build_cmd.reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Every `.bp` / `.d.bp` under src/ and test/; the compiled ones carry
    // their module path so the checker types them.
    var files: std.ArrayListUnmanaged([]const u8) = .empty;
    for ([_][]const u8{ "src", "test" }) |dir| try collectFiles(arena, io, dir, &files);
    std.mem.sort([]const u8, files.items, {}, struct {
        fn lt(_: void, x: []const u8, y: []const u8) bool {
            return std.mem.lessThan(u8, x, y);
        }
    }.lt);
    if (files.items.len == 0) {
        reporter.errMsg("no .bp sources under src/ or test/");
        return 1;
    }

    // The compiled files go first, in the order the loaders hand them over:
    // `sources.load` orders the module tree so an imported module is checked
    // before its importer (the order `check` compiles in). Handing the checker
    // the files sorted by path instead left `config.bp` ahead of the
    // `runtime.bp` it imports — `unbound variable` in a module `check` passes,
    // and every `await` of it marked instead of decided.
    const inputs = try planInputs(arena, files.items, &.{ loaded.modules, test_scan.modules });
    for (inputs) |*in| {
        in.source = std.Io.Dir.cwd().readFileAlloc(io, in.file, arena, .unlimited) catch |err| {
            reporter.errMsg(try std.fmt.allocPrint(arena, "cannot read {s}: {s}", .{ in.file, @errorName(err) }));
            return 1;
        };
    }

    const outcome = try migrate(gpa, arena, io, inputs, dep_modules, true);
    std.mem.sort(FileResult, outcome.files, {}, struct {
        fn lt(_: void, x: FileResult, y: FileResult) bool {
            return std.mem.lessThan(u8, x.file, y.file);
        }
    }.lt);
    return report(arena, io, std.Io.Dir.cwd(), outcome, opts);
}

/// The files the codemod reads, in the order the checker must see them: the
/// compiled ones first, in the order the loaders handed them over (each
/// list in `compiled` is already ordered so an imported module comes before
/// its importer), then the files no loader compiles (`module = null`). The
/// sources are left empty for the caller to read.
fn planInputs(arena: Allocator, files: []const []const u8, compiled: []const []const bp.Module) ![]Input {
    var inputs: std.ArrayListUnmanaged(Input) = .empty;
    var listed: std.StringHashMapUnmanaged(void) = .empty;
    for (files) |f| try listed.put(arena, f, {});
    var taken: std.StringHashMapUnmanaged(void) = .empty;
    for (compiled) |mods| for (mods) |m| {
        if (m.srcPath.len == 0 or !listed.contains(m.srcPath) or taken.contains(m.srcPath)) continue;
        try taken.put(arena, m.srcPath, {});
        try inputs.append(arena, .{ .file = m.srcPath, .module = m.path, .source = "", .declaration = m.declaration });
    };
    for (files) |f| {
        if (taken.contains(f)) continue;
        try inputs.append(arena, .{ .file = f, .module = null, .source = "" });
    }
    return inputs.items;
}

/// Print what the codemod did (or would do) and, unless `dry_run`, write it.
pub fn report(arena: Allocator, io: std.Io, dir: std.Io.Dir, outcome: Outcome, opts: Options) !u8 {
    for (outcome.unchecked) |u| reporter.warnDetail("does not type-check; its type-dependent sites are marked:", u);
    var changed: usize = 0;
    var markers: usize = 0;
    for (outcome.files) |f| {
        if (!f.changed) continue;
        changed += 1;
        markers += f.markers.len;
        const line = try std.fmt.allocPrint(arena, "{s} ({d} marked for review)", .{ f.file, f.markers.len });
        if (opts.dry_run) {
            reporter.warnDetail("  would rewrite", line);
        } else {
            try dir.writeFile(io, .{ .sub_path = f.file, .data = f.output });
            reporter.warnDetail("  rewrote", line);
        }
        for (f.markers) |m| {
            const at = try std.fmt.allocPrint(arena, "{s}:{d}: {s}", .{ f.file, m.line, m.text });
            reporter.hintMsg(at);
        }
    }
    if (changed == 0) {
        reporter.warnMsg("nothing to migrate — no pre-118 effect syntax found");
    } else if (opts.dry_run) {
        reporter.hintMsg("dry run — re-run without --dry-run to write these files");
    } else if (markers > 0) {
        reporter.hintMsg("every `// TODO(migrate-effects)` line names a site the codemod could not decide");
    }
    return 0;
}

fn collectFiles(arena: Allocator, io: std.Io, root: []const u8, out: *std.ArrayListUnmanaged([]const u8)) !void {
    var d = std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true, .access_sub_paths = true }) catch return;
    defer d.close(io);
    var walker = try d.walk(arena);
    defer walker.deinit();
    while (walker.next(io) catch null) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.basename, ".bp")) continue;
        const full = try std.fs.path.join(arena, &.{ root, entry.path });
        for (full) |*c| if (c.* == '\\') {
            c.* = '/';
        };
        try out.append(arena, full);
    }
}

// ── tests ───────────────────────────────────────────────────────────────────

const testing = std.testing;

fn migrateOne(arena: Allocator, source: []const u8) !FileResult {
    const out = try migrate(testing.allocator, arena, testing.io, &.{.{ .file = "src/main.bp", .module = "main", .source = source }}, &.{}, false);
    return out.files[0];
}

fn snapText(arena: Allocator, title: []const u8, inputs: []const Input, results: []const FileResult) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "# {s}\n\n`botopink migrate effects` over {d} file(s).\n", .{ title, inputs.len }));
    for (inputs, results) |in, r| {
        try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "\n## `{s}` — input\n\n```botopink\n", .{in.file}));
        try buf.appendSlice(arena, in.source);
        try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "```\n\n## `{s}` — output (type-checked: {s})\n\n```botopink\n", .{ in.file, if (r.untyped) "no" else "yes" }));
        try buf.appendSlice(arena, r.output);
        try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "```\n\n## `{s}` — marked for review\n\n", .{in.file}));
        if (r.markers.len == 0) try buf.appendSlice(arena, "(none)\n");
        for (r.markers) |m| try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "- line {d}: {s}\n", .{ m.line, m.text }));
    }
    return buf.items;
}

/// Every automatic row of the README's § Codemod and of guide.md § 9.
const all_patterns =
    \\pub type ParseError { Empty, Bad(text: string) }
    \\pub type ElementBase(id: i32)
    \\pub type Element(tag: string) implement @Context<ElementBase>
    \\pub type State(value: i32)
    \\
    \\// #[@result] — the annotation goes, the return stays.
    \\#[@result]
    \\fn parsePort(s: string) -> @Result<i32, ParseError> {
    \\    if (s == "") { throw ParseError.Empty; };
    \\    return 80;
    \\}
    \\
    \\// #[@future] + @Future<T, E> → @Task<@Result<T, E>>, and its awaits of a
    \\// fallible future become `try await`.
    \\#[@future]
    \\fn fetchCount(n: i32) -> @Future<i32, string> {
    \\    if (n < 0) { throw "negative"; };
    \\    return n;
    \\}
    \\
    \\// @Future<T> → @Task<T>.
    \\#[@future]
    \\fn delayed(n: i32) -> @Future<i32> {
    \\    return n;
    \\}
    \\
    \\#[@future]
    \\fn total(a: i32) -> @Future<i32, string> {
    \\    val x = await fetchCount(a);
    \\    val y = await delayed(a);
    \\    return x + y;
    \\}
    \\
    \\// #[@use] + @Component<C, T> → @Component<C, T>.
    \\#[@use]
    \\fn state(initial: i32) -> @Component<ElementBase, State> {
    \\    return State(value: initial);
    \\}
    \\
    \\// #[@context] + @Context<B, R> (pre-121) → @Component<B, R>.
    \\#[@context]
    \\fn counter(start: i32) -> @Context<ElementBase, i32> {
    \\    val s = use state(start);
    \\    return s.value;
    \\}
    \\
    \\// @Use<C, T> (front 21's spelling) → @Component<C, T>.
    \\#[@use]
    \\fn theme() -> @Use<ElementBase, string> {
    \\    return "dark";
    \\}
    \\
    \\// @Component<T> → @Component<B, T>, B read from `T implement @Context<B>`.
    \\#[@use]
    \\fn Card() -> @Component<Element> {
    \\    val n = use counter(0);
    \\    return Element(tag: "div");
    \\}
    \\
    \\// `-> Element` on a component that uses a hook → @Component<ElementBase, Element>.
    \\fn Badge() -> Element {
    \\    val t = use theme();
    \\    return Element(tag: t);
    \\}
    \\
    \\// #[@generator] + @Generator<T> → @Iterator<T>.
    \\#[@generator]
    \\fn upto(n: i32) -> @Generator<i32> {
    \\    var i = 0;
    \\    while (i < n) { yield i; i = i + 1; };
    \\}
    \\
    \\// #[@resultGenerator] + @ResultGenerator<T, E> → @Iterator<@Result<T, E>>.
    \\#[@resultGenerator]
    \\fn ports(n: i32) -> @ResultGenerator<i32, ParseError> {
    \\    var i = 0;
    \\    while (i < n) { val p = try parsePort("x"); yield p; i = i + 1; };
    \\}
    \\
    \\// #[@iterator] + @Iterator<T, E> (pre-121) → @Iterator<@Result<T, E>>.
    \\#[@iterator]
    \\fn ports2(n: i32) -> @Iterator<i32, ParseError> {
    \\    var i = 0;
    \\    while (i < n) { val p = try parsePort("y"); yield p; i = i + 1; };
    \\}
    \\
    \\// #[@futureGenerator] + @FutureGenerator<T, E> → @Stream<@Result<T, E>>.
    \\#[@futureGenerator]
    \\fn pages(n: i32) -> @FutureGenerator<i32, string> {
    \\    var i = 0;
    \\    while (i < n) { val c = await fetchCount(i); yield c; i = i + 1; };
    \\}
    \\
    \\// #[@asyncGenerator] + @AsyncIterator<T, E> (pre-121) → @Stream<@Result<T, E>>.
    \\#[@asyncGenerator]
    \\fn pages2(n: i32) -> @AsyncIterator<i32, string> {
    \\    var i = 0;
    \\    while (i < n) { val c = await fetchCount(i); yield c; i = i + 1; };
    \\}
    \\
    \\// `for` over a fallible generator: the implicit `try` becomes explicit
    \\// at the one use of the item (the return has a @Result).
    \\#[@result]
    \\fn sum(n: i32) -> @Result<i32, ParseError> {
    \\    var t = 0;
    \\    for (ports(n)) { r -> t = t + r; };
    \\    return t;
    \\}
    \\
    \\// `for await` over a fallible stream, likewise.
    \\#[@future]
    \\fn countPages() -> @Future<i32, string> {
    \\    var t = 0;
    \\    for await (pages(3)) { p -> t = t + p; };
    \\    return t;
    \\}
    \\
    \\// `loop await (g) { x -> }` (pre-105) → `for await`.
    \\#[@future]
    \\fn countPages2() -> @Future<i32, string> {
    \\    var t = 0;
    \\    loop await (pages2(3)) { p -> t = t + p; };
    \\    return t;
    \\}
    \\
    \\// Annotated loops → `iter` / `stream` loops; `loop (xs) { x -> }` → `for`,
    \\// `loop (cond)` → `while` (pre-105).
    \\fn loops(xs: i32[]) -> i32 {
    \\    val squares = #[@generator] loop {
    \\        for (xs) { x -> yield x * x; };
    \\        break;
    \\    };
    \\    val evens = #[@resultGenerator] loop {
    \\        yield 2;
    \\        break;
    \\    };
    \\    val ticks = #[@futureGenerator] loop { yield 1; break; };
    \\    val odds = #[@iterator] loop { yield 3; break; };
    \\    val beats = #[@asyncGenerator] loop { yield 4; break; };
    \\    var n = 0;
    \\    loop (xs) { x -> n = n + x; };
    \\    loop (n > 100) { n = n - 1; };
    \\    return n;
    \\}
    \\
    \\// YieldStep<T, E> → YieldStep<T>; IteratorStep<T, E> (pre-103) → YieldStep<T>.
    \\fn stepValue(s: YieldStep<i32, string>) -> i32 {
    \\    return 0;
    \\}
    \\fn stepValue2(s: IteratorStep<i32, string>) -> i32 {
    \\    return 0;
    \\}
    \\
    \\pub fn main() { @print(1); }
    \\
;

/// Every item of the README's "needs review" list, plus open point 5.
const review_patterns =
    \\pub type ElementBase(id: i32)
    \\pub type Element(tag: string) implement @Context<ElementBase>
    \\
    \\#[@future]
    \\pub fn fetchCount(n: i32) -> @Future<i32, string> {
    \\    if (n < 0) { throw "negative"; };
    \\    return n;
    \\}
    \\
    \\// A pub fallible future that fails only by passing another one through:
    \\// no throw / try in its body, yet its Promise stops rejecting too.
    \\#[@future]
    \\pub fn relay(n: i32) -> @Future<i32, string> {
    \\    return fetchCount(n);
    \\}
    \\
    \\// await in a component whose T is not a @Result: the error has nowhere to go.
    \\#[@use]
    \\fn Page() -> @Component<ElementBase, Element> {
    \\    val n = await fetchCount(1);
    \\    return Element(tag: "p");
    \\}
    \\
    \\#[@result]
    \\fn check(n: i32) -> @Result<i32, string> {
    \\    if (n < 0) { throw "negative"; };
    \\    return n;
    \\}
    \\
    \\// try (the throw of a hook) in a hook whose T is not a @Result.
    \\#[@use]
    \\fn guard(n: i32) -> @Component<ElementBase, i32> {
    \\    val v = try check(n);
    \\    return v;
    \\}
    \\
    \\// open point 5: @Future<T> could throw (E = any); @Task<T> cannot.
    \\#[@future]
    \\fn risky(n: i32) -> @Future<i32> {
    \\    if (n < 0) { throw "negative"; };
    \\    return n;
    \\}
    \\
    \\#[@resultGenerator]
    \\fn nums(n: i32) -> @ResultGenerator<i32, string> {
    \\    if (n < 0) { throw "negative"; };
    \\    yield n;
    \\}
    \\
    \\#[@futureGenerator]
    \\fn stream(n: i32) -> @FutureGenerator<i32, string> {
    \\    val c = await fetchCount(n);
    \\    yield c;
    \\}
    \\
    \\// for over a fallible generator, the item used twice: no automatic try.
    \\#[@result]
    \\fn twice(n: i32) -> @Result<i32, string> {
    \\    var t = 0;
    \\    for (nums(n)) { r -> t = t + r + r; };
    \\    return t;
    \\}
    \\
    \\// for await over a fallible stream, in a function with no @Result.
    \\#[@future]
    \\fn drain() -> @Future<i32> {
    \\    var t = 0;
    \\    for await (stream(1)) { v -> t = t + v; };
    \\    return t;
    \\}
    \\
    \\// case over YieldStep with an Error arm.
    \\fn stepOf(s: YieldStep<i32, string>) -> i32 {
    \\    case (s) {
    \\        .Yield(v) -> return v;
    \\        .Done -> return 0;
    \\        .Error(e) -> return -1;
    \\    }
    \\}
    \\
    \\// A host binding declared @Future<T>: a rejection was its error.
    \\#[@future]
    \\#[@External.Node("""Promise.reject(new Error($0))""")]
    \\pub declare fn failing(message: string) -> @Future<i32>;
    \\
    \\// .next() by hand on a fallible generator.
    \\fn first(n: i32) -> i32 {
    \\    val g = nums(n);
    \\    val s = g.next();
    \\    return stepOf(s);
    \\}
    \\
    \\pub fn main() { @print(1); }
    \\
;

/// What today's compiler refuses — an effect behind a named return (the
/// alias `type Job<T> = @Future<T, E>` of guide.md), the pre-103 names with
/// no (or a lossy) automatic rewrite — so this file is rewritten without
/// types: its `await` cannot be classified and is marked.
const review_legacy =
    \\// A wrapper alias as the return of an effect function.
    \\#[@future]
    \\fn job() -> Job<i32> {
    \\    val n = await fetchCount(1);
    \\    return n;
    \\}
    \\
    \\// for await in a module that was not type-checked.
    \\#[@future]
    \\fn drainAll() -> @Future<i32, string> {
    \\    var t = 0;
    \\    for await (stream(1)) { v -> t = t + v; };
    \\    return t;
    \\}
    \\
    \\fn legacy(xs: Iterable) -> Yield<i32, string> {
    \\    return 0;
    \\}
    \\
    \\// A decorator comparing the reflected return head against a renamed wrapper.
    \\pub fn page(comptime decl: @Decl) {
    \\    if (decl.returnType != "Future") decl.fail("#[page] must return @Future<Element>");
    \\    if ("Generator" == decl.returnType) decl.fail("#[page] is not a generator");
    \\    if (decl.returnType == "Element") decl.fail("unchanged: not a renamed wrapper");
    \\}
    \\
;

test "migrate effects: every automatic pattern (snapshot), idempotent" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const r = try migrateOne(arena, all_patterns);
    try testing.expect(r.changed);
    try testing.expect(!r.untyped);
    const inputs = [_]Input{.{ .file = "src/main.bp", .module = "main", .source = all_patterns }};
    try bp.snap.checkText(testing.allocator, "cli/migrate_effects_all_patterns", try snapText(arena, "migrate effects — every automatic pattern", &inputs, &.{r}));
    const again = try migrateOne(arena, r.output);
    try testing.expect(!again.changed);
    try testing.expectEqualStrings(r.output, again.output);
}

test "migrate effects: every review pattern carries a marker (snapshot), idempotent" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const inputs = [_]Input{
        .{ .file = "src/main.bp", .module = "main", .source = review_patterns },
        .{ .file = "src/legacy.bp", .module = null, .source = review_legacy },
    };
    const out = try migrate(testing.allocator, arena, testing.io, &inputs, &.{}, false);
    try testing.expect(out.files[0].changed and !out.files[0].untyped);
    try testing.expect(out.files[1].changed);
    try bp.snap.checkText(testing.allocator, "cli/migrate_effects_review_patterns", try snapText(arena, "migrate effects — the review patterns", &inputs, out.files));
    const again = try migrate(testing.allocator, arena, testing.io, &.{
        .{ .file = "src/main.bp", .module = "main", .source = out.files[0].output },
        .{ .file = "src/legacy.bp", .module = null, .source = out.files[1].output },
    }, &.{}, false);
    try testing.expect(!again.files[0].changed);
    try testing.expect(!again.files[1].changed);
}

test "planInputs: compiled files in the loaders' order, declarations kept, the rest after" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    // Sorted by path, `config.bp` comes before the `runtime.bp` it imports;
    // the checker must see them in the module tree's order instead (rakun's
    // `config.bp` was refused with `unbound variable 'rkSetProp'`).
    const files = [_][]const u8{ "src/config.bp", "src/orphan.bp", "src/rakun.d.bp", "src/root.bp", "src/runtime.bp", "test/config_test.bp" };
    const src_mods = [_]bp.Module{
        .{ .path = "runtime", .source = "", .srcPath = "src/runtime.bp" },
        .{ .path = "config", .source = "", .srcPath = "src/config.bp" },
        .{ .path = "rakun", .source = "", .srcPath = "src/rakun.d.bp", .declaration = true },
        .{ .path = "root", .source = "", .srcPath = "src/root.bp" },
    };
    const test_mods = [_]bp.Module{.{ .path = "config_test", .source = "", .srcPath = "test/config_test.bp" }};
    const got = try planInputs(arena, &files, &.{ &src_mods, &test_mods });
    const want = [_]struct { file: []const u8, module: ?[]const u8, decl: bool }{
        .{ .file = "src/runtime.bp", .module = "runtime", .decl = false },
        .{ .file = "src/config.bp", .module = "config", .decl = false },
        .{ .file = "src/rakun.d.bp", .module = "rakun", .decl = true },
        .{ .file = "src/root.bp", .module = "root", .decl = false },
        .{ .file = "test/config_test.bp", .module = "config_test", .decl = false },
        .{ .file = "src/orphan.bp", .module = null, .decl = false },
    };
    try testing.expectEqual(want.len, got.len);
    for (want, got) |w, g| {
        try testing.expectEqualStrings(w.file, g.file);
        if (w.module) |m| try testing.expectEqualStrings(m, g.module.?) else try testing.expect(g.module == null);
        try testing.expectEqual(w.decl, g.declaration);
    }
}

test "migrate effects: the checker sees an imported module before its importer" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const runtime =
        \\pub fn load() -> i32 { return 1; }
        \\
    ;
    const app =
        \\import {load} from "runtime";
        \\
        \\#[@future]
        \\pub fn boot() -> @Future<i32> {
        \\    val n = await start();
        \\    return n + load();
        \\}
        \\
        \\#[@future]
        \\fn start() -> @Future<i32> { return 1; }
        \\
    ;
    const out = try migrate(testing.allocator, arena, testing.io, &.{
        .{ .file = "src/runtime.bp", .module = "runtime", .source = runtime },
        .{ .file = "src/app.bp", .module = "app", .source = app },
    }, &.{}, false);
    try testing.expectEqual(@as(usize, 0), out.unchecked.len);
    try testing.expect(!out.files[1].untyped);
    try testing.expectEqual(@as(usize, 0), out.files[1].markers.len);
}

test "migrate effects: the migration mode ends with the command (decision 67)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const old =
        \\#[@future]
        \\fn f() -> @Future<i32, string> { return 1; }
        \\
    ;
    const r = try migrateOne(arena, old);
    try testing.expect(r.changed and !r.untyped);
    // After `migrate`, the old surface is refused again, by the parser and
    // by the full pipeline.
    var lexer = bp.Lexer.init(old);
    var parser = bp.Parser.init(try lexer.scanAll(arena));
    try testing.expectError(error.UnexpectedToken, parser.parse(arena));
    var session = try bp.comptime_pipeline.compileTypesOnly(testing.allocator, &.{.{ .path = "main", .source = old }}, null);
    defer session.deinit(testing.allocator);
    try testing.expect(session.outputs.items[0].outcome == .parseError);
}

test "migrate effects: a file with no old syntax is left alone" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const src =
        \\fn f(xs: i32[]) -> i32 {
        \\    var n = 0;
        \\    for (xs) { x -> n = n + x; };
        \\    return n;
        \\}
        \\
    ;
    const r = try migrateOne(arena, src);
    try testing.expect(!r.changed);
    try testing.expectEqualStrings(src, r.output);
}

test "migrate effects: --dry-run reports without writing; a second run changes nothing" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const src =
        \\#[@future]
        \\fn f() -> @Future<i32> {
        \\    return 1;
        \\}
        \\
    ;
    try tmp.dir.createDirPath(io, "src");
    try tmp.dir.writeFile(io, .{ .sub_path = "src/main.bp", .data = src });
    const inputs = [_]Input{.{ .file = "src/main.bp", .module = "main", .source = src }};

    const first = try migrate(testing.allocator, arena, io, &inputs, &.{}, false);
    try testing.expect(first.files[0].changed);
    try testing.expectEqual(@as(u8, 0), try report(arena, io, tmp.dir, first, .{ .dry_run = true }));
    const after_dry = try tmp.dir.readFileAlloc(io, "src/main.bp", arena, .unlimited);
    try testing.expectEqualStrings(src, after_dry);

    try testing.expectEqual(@as(u8, 0), try report(arena, io, tmp.dir, first, .{}));
    const written = try tmp.dir.readFileAlloc(io, "src/main.bp", arena, .unlimited);
    try testing.expectEqualStrings(
        \\fn f() -> @Task<i32> {
        \\    return 1;
        \\}
        \\
    , written);

    const second = try migrate(testing.allocator, arena, io, &.{.{ .file = "src/main.bp", .module = "main", .source = written }}, &.{}, false);
    try testing.expect(!second.files[0].changed);
}

test "stage2: an effect item inside a multi-item attribute leaves the others" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\#[deprecated]
        \\fn f() -> @Task<i32> {
        \\    return 1;
        \\}
        \\#[deprecated] fn g() -> @Result<i32, string> { return 1; }
        \\#[deprecated] pub fn h() -> @Iterator<i32> { yield 1; }
        \\
    , try stage2(arena,
        \\#[@future, deprecated]
        \\fn f() -> @Future<i32> {
        \\    return 1;
        \\}
        \\#[deprecated, @result] fn g() -> @Result<i32, string> { return 1; }
        \\#[deprecated] #[@generator] pub fn h() -> @Generator<i32> { yield 1; }
        \\
    , null));
}

test "rewriteType: nested wrappers, >> and arity" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var ctx: TypeCtx = .{ .arena = arena, .stage = .two, .bases = null };
    try testing.expectEqualStrings("@Task<@Result<Array<@Iterator<i32>>, string>>", try rewriteType(&ctx, "@Future<Array<@Generator<i32>>, string>"));
    try testing.expectEqualStrings("Array<@Task<i32>>", try rewriteType(&ctx, "Array<@Future<i32>>"));
    try testing.expectEqualStrings("fn(x: i32) -> @Stream<@Result<i32, E>>", try rewriteType(&ctx, "fn(x: i32) -> @FutureGenerator<i32, E>"));
    try testing.expectEqualStrings("@Future<A, B, C>", try rewriteType(&ctx, "@Future<A, B, C>"));
    try testing.expectEqual(@as(usize, 1), ctx.notes.items.len);
    try testing.expect(try hasResultLayer(arena, "@Task<@Result<i32, string>>"));
    try testing.expect(try hasResultLayer(arena, "@Component<ElementBase, @Result<i32, E>>"));
    try testing.expect(!try hasResultLayer(arena, "@Component<ElementBase, Element>"));
    try testing.expect(!try hasResultLayer(arena, "@Task<i32>"));
}
