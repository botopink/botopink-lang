//! Decisions 780–783 — `comptime compiler.load(path)`: a file of the package
//! compiled at build as the entry of a package of its own, its refusals the
//! answer.
//!
//! - `parser/compiler_surface.zig` reads `compiler.load(p)` onto the builtin
//!   `surface.load_builtin`; the checker (`infer.zig` `inferLoadBuiltin`, beside
//!   `@embed`'s) reads the path by `@embed`'s rules and calls `compileFile`.
//! - `compileFile` gathers the file's own `mod` tree beside it through the
//!   package's reader (`Module.files`), adds the caller build's dependency
//!   modules (the caller's manifest), and runs `comptime.compile` on them for
//!   the build's target — captured: nothing is printed, and the caller's
//!   program never sees the modules. Each refused module is one `Diagnostic`,
//!   in the order `botopink build` prints them, with the text and the place it
//!   prints (decision 780 (2), 781).
//! - The answer is code (`rewrite`): `__bp_loaded([Bp_LoadDiagnostic(…), …])`, a
//!   call of the function `withLoadHelper` declares in the module that loads
//!   (`Ok` for `[]`, `Error(ds)` otherwise, decision 782), `Diagnostic` std's
//!   `compiler.Diagnostic` imported under a name no source writes.
//! - A nested compile re-enters nothing of std's one-time initialisation: it
//!   runs only once std's template is ready (`comptime.stdlibTemplateReady`),
//!   and a file that loads itself through a chain of loads is refused
//!   (`load-cycle`) instead of compiling forever.

const std = @import("std");
const ast = @import("../ast.zig");
const moduleMod = @import("../module.zig");
const Module = moduleMod.Module;
const PackageFiles = moduleMod.PackageFiles;
const surface = @import("../parser/compiler_surface.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const printErrors = @import("../print.zig");
const blockEval = @import("block_eval.zig");

/// The function `withLoadHelper` declares: `Ok` for no refusal, `Error(ds)`
/// otherwise.
pub const helper_fn = "__bp_loaded";
/// The local name of std's `compiler.Diagnostic` in a module that loads.
pub const diagnostic_alias = "Bp_LoadDiagnostic";

/// Where the helper's lines are parsed: past every line of the module and of
/// a typed meta read's helper (`typed_meta.helper_first_line`).
const helper_first_line: usize = 3_000_000;
/// Where each rewrite's line is: one line per call, from its location.
const rewrite_first_line: usize = 4_000_000;

/// The caller build's modules, for the dependencies a loaded file's package
/// shares with its caller (the caller's manifest): set by `comptime.compile`
/// around each compile, restored after it (a nested compile sets its own).
pub threadlocal var build_modules: []const Module = &.{};

/// The files being loaded on this thread, outermost first — a file loading
/// one of them is a cycle.
threadlocal var loading: std.ArrayListUnmanaged([]const u8) = .empty;

/// One refusal of a loaded file — std's `compiler.Diagnostic`.
pub const Diagnostic = struct {
    code: []const u8,
    message: []const u8,
    file: []const u8,
    line: usize,
    column: usize,
    label: ?[]const u8 = null,
};

// ── finding the reads ────────────────────────────────────────────────────────

fn isLoadCall(e: ast.Expr) bool {
    return e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, surface.load_builtin);
}

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

const Finder = struct {
    arena: std.mem.Allocator,
    found: bool = false,
    /// The string-literal paths of the reads, as written (`literalPaths`).
    paths: std.ArrayListUnmanaged([]const u8) = .empty,

    fn walk(self: *Finder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (isLoadCall(v)) {
            self.found = true;
            const args = v.call.kind.call.args;
            if (args.len == 1 and args[0].value.* == .literal and args[0].value.literal.kind == .stringLit) {
                if (try @import("template_eval.zig").lexemeBytes(self.arena, args[0].value.literal.kind.stringLit)) |p| try self.paths.append(self.arena, p);
            }
        };
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// The paths a program's `compiler.load` reads write as string literals,
/// as the program names them (package-root-relative): the files a package's
/// module tree leaves out (decision 780 (1) over 677 — the CLI's resolver).
pub fn literalPaths(arena: std.mem.Allocator, program: ast.Program) ![]const []const u8 {
    var f: Finder = .{ .arena = arena };
    for (program.decls) |d| try f.walk(ast.DeclKind, d);
    return f.paths.items;
}

/// `program` with what its `compiler.load` reads are rewritten to call — the
/// import of std's `compiler.Diagnostic` under `diagnostic_alias` and the
/// function `helper_fn`, inferred with the module so every backend lowers a
/// typed body —, or `program` itself when it reads none.
pub fn withLoadHelper(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var f: Finder = .{ .arena = arena };
    for (program.decls) |d| {
        try f.walk(ast.DeclKind, d);
        if (f.found) break;
    }
    if (!f.found) return program;
    for (program.decls) |d| switch (d) {
        .@"fn" => |fd| if (std.mem.eql(u8, fd.name, helper_fn)) return program,
        else => {},
    };
    const src = "import {compiler.Diagnostic as " ++ diagnostic_alias ++ "} from \"std\";\n" ++
        "fn " ++ helper_fn ++ "(ds: " ++ diagnostic_alias ++ "[]) -> Result<void, " ++ diagnostic_alias ++ "[]> { if (ds.length > 0) throw ds; return; }\n";
    const helper = try parseShifted(arena, src, helper_first_line, null);
    // Both first: an alias of an imported type names it in a signature only
    // of a function declared after the import and before its callers.
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + helper.decls.len);
    @memcpy(decls[0..helper.decls.len], helper.decls);
    @memcpy(decls[helper.decls.len..], program.decls);
    var out = program;
    out.decls = decls;
    return out;
}

/// `src` parsed with every token moved to line `first + its line - 1` (and,
/// when `col` is given, to that column): lines no module writes.
fn parseShifted(arena: std.mem.Allocator, src: []const u8, first: usize, col: ?usize) !ast.Program {
    var lx = Lexer.init(src);
    const tokens = try arena.dupe(@import("../lexer.zig").Token, try lx.scanAll(arena));
    for (tokens) |*t| {
        t.line += first - 1;
        if (col) |c| t.col += c;
    }
    var p = Parser.init(tokens);
    return p.parse(arena);
}

// ── the answer as code ───────────────────────────────────────────────────────

/// The call a read at `loc` is rewritten to: `__bp_loaded([…])`, one
/// `Bp_LoadDiagnostic(…)` per refusal, on a line of its own.
pub fn rewrite(arena: std.mem.Allocator, loc: ast.Loc, ds: []const Diagnostic) error{OutOfMemory}!*ast.Expr {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(arena, "fn __bp_load_rewrite() { " ++ helper_fn ++ "([");
    for (ds, 0..) |d, i| {
        if (i > 0) try text.appendSlice(arena, ", ");
        try text.print(arena, diagnostic_alias ++ "(code: \"{s}\", message: \"{s}\", file: \"{s}\", line: {d}, column: {d}, label: ", .{
            try blockEval.stringLexeme(arena, d.code),
            try blockEval.stringLexeme(arena, d.message),
            try blockEval.stringLexeme(arena, d.file),
            d.line,
            d.column,
        });
        if (d.label) |l| try text.print(arena, "\"{s}\")", .{try blockEval.stringLexeme(arena, l)}) else try text.appendSlice(arena, "null)");
    }
    try text.appendSlice(arena, "]); }");
    // A line per call: its line and column folded into one line number.
    const line = rewrite_first_line + loc.line * 4096 + @min(loc.col, 4095);
    // The text is the compiler's own, every string escaped: it parses.
    const program = parseShifted(arena, text.items, line, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("compiler.load: the answer's code does not parse"),
    };
    const body = program.decls[0].@"fn".body;
    const out = try arena.create(ast.Expr);
    out.* = body[0].expr;
    return out;
}

// ── the nested compile ───────────────────────────────────────────────────────

pub const Request = struct {
    /// The file, relative to the package's `botopink.json`; its path rules
    /// already checked (`embed.checkPath`).
    path: []const u8,
    files: PackageFiles,
    io: std.Io,
    build_root: ?[]const u8,
    target: ?[]const u8,
};

pub const Answer = union(enum) {
    /// The refusals, in order; empty when the file compiles.
    diagnostics: []const Diagnostic,
    /// The file is not one of the package.
    missing,
    /// The file is already being loaded on this thread.
    cycle,
    /// std's one-time initialisation is running: no compile may start.
    std_initialising,
};

/// Compile `req.path` as the entry of a package of its own and answer its
/// refusals, allocated with `arena`.
pub fn compileFile(arena: std.mem.Allocator, req: Request) !Answer {
    const comptimeMod = @import("../comptime.zig");
    if (!comptimeMod.stdlibTemplateReady()) return .std_initialising;
    for (loading.items) |p| if (std.mem.eql(u8, p, req.path)) return .cycle;

    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();

    var refusals: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const own = gatherTree(scratch, arena, req, &refusals) catch |err| switch (err) {
        error.FileNotFound => return .missing,
        else => |e| return e,
    };
    if (refusals.items.len > 0) return .{ .diagnostics = refusals.items };

    // The caller's manifest: its targets, its reader and its dependencies.
    const caller = build_modules;
    var targets: ?moduleMod.Targets = null;
    for (caller) |m| if (m.package.len == 0) {
        targets = m.targets;
        break;
    };
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    for (caller) |m| if (m.package.len > 0) try modules.append(scratch, m);
    for (own) |m| {
        var mm = m;
        mm.targets = targets;
        mm.files = req.files;
        try modules.append(scratch, mm);
    }

    try loading.append(std.heap.page_allocator, req.path);
    defer _ = loading.pop();
    const saved = build_modules;
    defer build_modules = saved;

    var session = try comptimeMod.compile(std.heap.page_allocator, modules.items, req.io, req.build_root, req.target);
    defer session.deinit(std.heap.page_allocator);
    for (session.outputs.items) |o| {
        // A dependency's refusal is no refusal of the loaded file: it is the
        // caller's, reported where the caller is built (781 (5)).
        const ownModule = for (own) |m| {
            if (std.mem.eql(u8, if (m.path.len > 0) m.path else "main", o.name)) break true;
        } else false;
        if (!ownModule) continue;
        if (try diagnosticOf(arena, o)) |d| try refusals.append(arena, d);
    }
    return .{ .diagnostics = refusals.items };
}

/// The loaded file and the `mod` tree beside it, children before their
/// parent (a module compiles after what it declares), each named by its
/// logical path as the CLI's resolver names a package's modules. A `mod`
/// naming no file, or two, is a refusal of the tree (`refusals`), as the
/// resolver's.
fn gatherTree(scratch: std.mem.Allocator, arena: std.mem.Allocator, req: Request, refusals: *std.ArrayListUnmanaged(Diagnostic)) ![]const Module {
    const Item = struct { logical: []const u8, file: []const u8, root: bool };
    var work: std.ArrayListUnmanaged(Item) = .empty;
    const base = std.fs.path.basename(req.path);
    const rootLogical = if (std.mem.endsWith(u8, base, ".bp")) base[0 .. base.len - 3] else base;
    try work.append(scratch, .{ .logical = rootLogical, .file = req.path, .root = true });
    var out: std.ArrayListUnmanaged(Module) = .empty;
    var i: usize = 0;
    while (i < work.items.len) : (i += 1) {
        const item = work.items[i];
        const source = req.files.readFile(arena, item.file) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => if (item.root) return error.FileNotFound else continue,
        };
        try out.append(scratch, .{ .path = item.logical, .source = source, .srcPath = item.file, .root = item.root });
        var lx = Lexer.init(source);
        const tokens = lx.scanAll(scratch) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(scratch) catch continue;
        const dir = std.fs.path.dirname(item.file) orelse "";
        for (program.decls) |d| {
            const m = switch (d) {
                .mod => |m| m,
                else => continue,
            };
            const name = ast.unquotedName(m.name);
            const sibling = try joinPath(scratch, dir, try std.mem.concat(scratch, u8, &.{ name, ".bp" }));
            const folder = try joinPath(scratch, dir, try std.mem.concat(scratch, u8, &.{ name, "/mod.bp" }));
            const hasSibling = exists(scratch, req.files, sibling);
            const hasFolder = exists(scratch, req.files, folder);
            if (hasSibling == hasFolder) {
                try refusals.append(arena, .{
                    .code = "",
                    .message = if (hasSibling) "ambiguous module: both a sibling file and a folder index exist" else "unresolved module declaration",
                    .file = "",
                    .line = 0,
                    .column = 0,
                });
                continue;
            }
            const logical = if (item.root) try scratch.dupe(u8, name) else try std.mem.concat(scratch, u8, &.{ item.logical, "/", name });
            try work.append(scratch, .{ .logical = logical, .file = if (hasSibling) sibling else folder, .root = false });
        }
    }
    std.mem.reverse(Module, out.items);
    return out.items;
}

fn joinPath(a: std.mem.Allocator, dir: []const u8, rel: []const u8) ![]const u8 {
    if (dir.len == 0) return a.dupe(u8, rel);
    return std.mem.concat(a, u8, &.{ dir, "/", rel });
}

fn exists(scratch: std.mem.Allocator, files: PackageFiles, rel: []const u8) bool {
    _ = files.readFile(scratch, rel) catch return false;
    return true;
}

// ── a refused module as a `Diagnostic` ───────────────────────────────────────

/// The refusal `o` carries, as `botopink build` prints it, or null when the
/// module compiled.
fn diagnosticOf(arena: std.mem.Allocator, o: anytype) !?Diagnostic {
    const file = if (o.srcPath.len > 0) o.srcPath else try std.fmt.allocPrint(arena, "{s}.bp", .{o.name});
    switch (o.outcome) {
        .ok => return null,
        .typeError => |te| {
            const message = try te.message(arena);
            var d: Diagnostic = .{ .code = codeOf(message), .message = message, .file = try arena.dupe(u8, file), .line = 0, .column = 0 };
            // A raise at build located in another file (decision 532).
            if (te.origin) |org| {
                d.file = try arena.dupe(u8, org.file);
                d.line = org.loc.line;
                d.column = org.loc.col;
            } else if (te.loc) |l| {
                d.line = l.line;
                d.column = l.col;
            }
            return d;
        },
        .validationError => |ce| return .{
            .code = "",
            .message = "comptime: expression cannot be evaluated at compile time",
            .file = try arena.dupe(u8, file),
            .line = ce.loc.line,
            .column = ce.loc.col,
        },
        .parseError => |se| switch (se) {
            .lex => |lf| {
                const start = if (lf.info) |le| le.start else lf.start;
                const name = if (lf.info) |le| @tagName(le.kind) else lf.name;
                const at = lineColOf(o.src, start);
                return .{ .code = "", .message = try humanize(arena, name), .file = try arena.dupe(u8, file), .line = at.line, .column = at.col };
            },
            .parse => |info| {
                const i = info orelse return .{ .code = "", .message = try std.fmt.allocPrint(arena, "parse error in {s}", .{file}), .file = "", .line = 0, .column = 0 };
                var aw: std.Io.Writer.Allocating = .init(arena);
                try printErrors.render(&aw.writer, i, o.src, file);
                return try fromRendered(arena, aw.written());
            },
        },
    }
}

/// A refusal's code as its message writes it first, `<code>: …` (a code is
/// lowercase words joined by `-`); `""` when the message names none.
pub fn codeOf(message: []const u8) []const u8 {
    const colon = std.mem.indexOf(u8, message, ": ") orelse return "";
    const head = message[0..colon];
    if (head.len == 0 or std.mem.indexOfScalar(u8, head, '-') == null) return "";
    for (head) |c| if (!(std.ascii.isLower(c) or std.ascii.isDigit(c) or c == '-')) return "";
    return head;
}

/// A refusal rendered as `print.zig` renders a parse error, read back: the
/// `error[<code>]: <message>` line, the `--> <file>:<line>:<col>` under it and
/// the label beside the caret.
fn fromRendered(arena: std.mem.Allocator, text: []const u8) !Diagnostic {
    var d: Diagnostic = .{ .code = "", .message = "", .file = "", .line = 0, .column = 0 };
    var lines = std.mem.splitScalar(u8, text, '\n');
    var at_read = false;
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (d.message.len == 0) {
            if (std.mem.startsWith(u8, line, "error[")) {
                const close = std.mem.indexOf(u8, line, "]: ") orelse continue;
                d.code = try arena.dupe(u8, line["error[".len..close]);
                d.message = try arena.dupe(u8, line[close + 3 ..]);
            } else if (std.mem.startsWith(u8, line, "error: ")) {
                d.message = try arena.dupe(u8, line["error: ".len..]);
                d.code = codeOf(d.message);
            }
            continue;
        }
        const t = std.mem.trimStart(u8, line, " ");
        if (!at_read) {
            if (std.mem.startsWith(u8, t, "--> ")) {
                at_read = true;
                const place = t["--> ".len..];
                const c2 = std.mem.lastIndexOfScalar(u8, place, ':') orelse continue;
                const c1 = std.mem.lastIndexOfScalar(u8, place[0..c2], ':') orelse continue;
                d.file = try arena.dupe(u8, place[0..c1]);
                d.line = std.fmt.parseInt(usize, place[c1 + 1 .. c2], 10) catch 0;
                d.column = std.fmt.parseInt(usize, place[c2 + 1 ..], 10) catch 0;
            }
            continue;
        }
        if (caretLabel(line)) |l| {
            if (l.len > 0) d.label = try arena.dupe(u8, l);
            break;
        }
    }
    return d;
}

/// The text beside the caret of a snippet line (`  |   ^^^ the label`): ""
/// when the carets stand alone, null when the line is no caret line — as
/// `botopink cell check` reads it (`cell.zig` `caretLabel`).
fn caretLabel(line: []const u8) ?[]const u8 {
    const bar = std.mem.indexOfScalar(u8, line, '|') orelse return null;
    if (std.mem.trim(u8, line[0..bar], " 0123456789").len != 0) return null;
    const after = std.mem.trimStart(u8, line[bar + 1 ..], " ");
    if (after.len == 0 or after[0] != '^') return null;
    const rest = std.mem.trimStart(u8, after, "^");
    return std.mem.trim(u8, rest, " ");
}

fn lineColOf(source: []const u8, offset: usize) struct { line: usize, col: usize } {
    const end = @min(offset, source.len);
    var line: usize = 1;
    var line_start: usize = 0;
    for (source[0..end], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{ .line = line, .col = end - line_start + 1 };
}

/// `UnterminatedString` → `unterminated string`, as the CLI prints a lex
/// error (`diagnostics.zig` `humanize`).
fn humanize(arena: std.mem.Allocator, name: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (name, 0..) |c, i| {
        if (std.ascii.isUpper(c)) {
            if (i > 0) try out.append(arena, ' ');
            try out.append(arena, std.ascii.toLower(c));
        } else try out.append(arena, c);
    }
    return out.items;
}

test "a refusal's code is the kebab word its message writes first" {
    try std.testing.expectEqualStrings("embed-file-missing", codeOf("embed-file-missing: `@embed(\"a\")` names no file"));
    try std.testing.expectEqualStrings("", codeOf("type mismatch: expected i32, got string"));
    try std.testing.expectEqualStrings("", codeOf("unbound variable 'x'"));
}

test "a rendered parse refusal reads back as its code, message, place and label" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const text =
        \\error[case-bare-name-arm]: a name alone is not a pattern
        \\ --> src/cases/a/main.bp:7:9
        \\  |
        \\7 |         n { "other" }
        \\  |         ^ use _ { n -> … } to bind the matched value
        \\  |
        \\  = hint: An arm names a type.
        \\
    ;
    const d = try fromRendered(arena_state.allocator(), text);
    try std.testing.expectEqualStrings("case-bare-name-arm", d.code);
    try std.testing.expectEqualStrings("a name alone is not a pattern", d.message);
    try std.testing.expectEqualStrings("src/cases/a/main.bp", d.file);
    try std.testing.expectEqual(@as(usize, 7), d.line);
    try std.testing.expectEqual(@as(usize, 9), d.column);
    try std.testing.expectEqualStrings("use _ { n -> … } to bind the matched value", d.label.?);
}
