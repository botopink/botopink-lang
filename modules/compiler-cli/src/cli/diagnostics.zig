/// Compile diagnostics shared by `build`, `check` and `test`.
///
/// Every failed module carries a located diagnostic in its comptime outcome:
/// a lex or parse error (`SyntaxError`, rendered by `printSyntaxError`), a type
/// error or a comptime validation error. A module that fails to lex or parse no
/// longer aborts the session, so the others still compile and get diagnosed.
/// `check` renders the comptime outcomes (`renderOutcome`); `build` and `test`
/// read the same diagnostic from `codegen.generateWith`'s result, where every
/// backend returns a failed module with it (`failedOutputs`), so no command
/// re-runs the pipeline to explain a failure.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");

const Module = bp.Module;

/// The name the compiler gives a module's output (`comptime.compile`).
pub fn moduleName(m: Module) []const u8 {
    return if (m.path.len > 0) m.path else "main";
}

/// Best-effort source file label for a module: `src/<name>.bp` or
/// `src/<name>/mod.bp` when that file exists under cwd, else `<name>.bp`
/// (dependency modules live under their library's own directory).
pub fn fileLabel(arena: std.mem.Allocator, io: std.Io, name: []const u8) []const u8 {
    const candidates = [_][]const u8{ "src/{s}.bp", "src/{s}/mod.bp", "test/{s}.bp" };
    inline for (candidates) |fmt| {
        if (std.fmt.allocPrint(arena, fmt, .{name})) |p| {
            if (std.Io.Dir.cwd().access(io, p, .{})) |_| return p else |_| {}
        } else |_| {}
    }
    return std.fmt.allocPrint(arena, "{s}.bp", .{name}) catch name;
}

// ── Rendering ─────────────────────────────────────────────────────────────────

/// Render one located diagnostic in the shape `print.zig` uses for parse errors:
///
///   error: <message>
///    --> <file>:<line>:<col>
///     |
///   N | <source line>
///     | ^^^
///
pub fn renderLocated(
    w: *std.Io.Writer,
    message: []const u8,
    file: []const u8,
    source: []const u8,
    line: usize,
    col: usize,
    span: usize,
) !void {
    return renderLocatedAs(w, "error", message, file, source, line, col, span);
}

/// `renderLocated` under another severity word — `warning` for the checker's
/// warning channel (decision 57), which renders exactly like an error.
pub fn renderLocatedAs(
    w: *std.Io.Writer,
    severity: []const u8,
    message: []const u8,
    file: []const u8,
    source: []const u8,
    line: usize,
    col: usize,
    span: usize,
) !void {
    const line_w = digitWidth(line);
    try w.print("{s}: {s}\n", .{ severity, message });
    try w.splatByteAll(' ', line_w);
    try w.print("--> {s}:{d}:{d}\n", .{ file, line, col });
    try w.splatByteAll(' ', line_w + 1);
    try w.writeAll("|\n");
    try w.print("{d} | {s}\n", .{ line, lineText(source, line) });
    try w.splatByteAll(' ', line_w + 1);
    try w.writeAll("| ");
    try w.splatByteAll(' ', if (col > 0) col - 1 else 0);
    try w.splatByteAll('^', @max(span, 1));
    try w.writeAll("\n\n");
}

fn printLocated(gpa: std.mem.Allocator, message: []const u8, file: []const u8, source: []const u8, line: usize, col: usize, span: usize) void {
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    renderLocated(&aw.writer, message, file, source, line, col, span) catch return;
    std.debug.print("{s}", .{aw.written()});
}

fn digitWidth(n: usize) usize {
    var w: usize = 1;
    var v = n;
    while (v >= 10) : (v /= 10) w += 1;
    return w;
}

/// The text of 1-based `line` in `source`, without its newline.
fn lineText(source: []const u8, line: usize) []const u8 {
    var it = std.mem.splitScalar(u8, source, '\n');
    var n: usize = 1;
    while (it.next()) |l| : (n += 1) {
        if (n == line) return std.mem.trimEnd(u8, l, "\r");
    }
    return "";
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

/// `UnterminatedString` → `unterminated string`.
fn humanize(buf: []u8, name: []const u8) []const u8 {
    var n: usize = 0;
    for (name, 0..) |c, i| {
        if (n + 2 > buf.len) break;
        if (std.ascii.isUpper(c)) {
            if (i > 0) {
                buf[n] = ' ';
                n += 1;
            }
            buf[n] = std.ascii.toLower(c);
        } else buf[n] = c;
        n += 1;
    }
    return buf[0..n];
}

// ── Lex and parse errors ──────────────────────────────────────────────────────

/// The located lex / parse error a module's comptime outcome carries
/// (`ComptimeOutput.Outcome.parseError`).
pub const SyntaxError = bp.comptime_pipeline.SyntaxError;

/// Render the lex or parse error a comptime outcome carries.
pub fn printSyntaxError(gpa: std.mem.Allocator, se: SyntaxError, source: []const u8, file: []const u8) void {
    switch (se) {
        .lex => |lf| printLexFailure(gpa, lf, source, file),
        .parse => |info| if (info) |i| {
            printParseInfo(gpa, i, source, file);
        } else {
            var buf: [256]u8 = undefined;
            reporter.errMsg(std.fmt.bufPrint(&buf, "parse error in {s}", .{file}) catch "parse error");
        },
    }
}

/// Render a lex failure, located at the structured error when the lexer
/// recorded one, else at the token it was scanning.
fn printLexFailure(gpa: std.mem.Allocator, lf: SyntaxError.LexFailure, source: []const u8, file: []const u8) void {
    var buf: [128]u8 = undefined;
    if (lf.info) |le| {
        const at = lineColOf(source, le.start);
        const span = if (le.end > le.start) le.end - le.start else 1;
        printLocated(gpa, humanize(&buf, @tagName(le.kind)), file, source, at.line, at.col, span);
    } else {
        const at = lineColOf(source, lf.start);
        const rest_of_line = lineText(source, at.line).len -| (at.col - 1);
        const span = @max(@min(lf.end -| lf.start, rest_of_line), 1);
        printLocated(gpa, humanize(&buf, lf.name), file, source, at.line, at.col, span);
    }
}

/// Render the error `lexer.scanAll` just failed with (`format`).
pub fn printLexError(gpa: std.mem.Allocator, lexer: *const bp.Lexer, err: anyerror, source: []const u8, file: []const u8) void {
    printLexFailure(gpa, .{
        .name = @errorName(err),
        .info = lexer.lexError,
        .start = lexer.start,
        .end = lexer.current,
    }, source, file);
}

fn printParseInfo(gpa: std.mem.Allocator, info: bp.print_errors.ParseErrorInfo, source: []const u8, file: []const u8) void {
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    bp.print_errors.render(&aw.writer, info, source, file) catch {};
    std.debug.print("{s}", .{aw.written()});
}

/// Render the error `parser.parse` just failed with.
pub fn printParseError(gpa: std.mem.Allocator, parser: *const bp.Parser, err: anyerror, source: []const u8, file: []const u8) void {
    if (parser.parseError) |info| {
        printParseInfo(gpa, info, source, file);
    } else if (parser.tokens.len > 0) {
        // No structured error recorded: locate the token the parser stopped at.
        const tok = parser.tokens[@min(parser.current, parser.tokens.len - 1)];
        var buf: [256]u8 = undefined;
        const msg = if (tok.kind == .endOfFile)
            std.fmt.bufPrint(&buf, "unexpected end of file", .{}) catch "unexpected end of file"
        else
            std.fmt.bufPrint(&buf, "unexpected token '{s}'", .{tok.lexeme}) catch "unexpected token";
        const at = lineColOf(source, tok.offset);
        printLocated(gpa, msg, file, source, at.line, at.col, @max(tok.lexeme.len, 1));
    } else {
        var buf: [128]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "parse error in {s}: {s}", .{ file, @errorName(err) }) catch "parse error";
        reporter.errMsg(msg);
    }
}

// ── Named module-set guard ────────────────────────────────────────────────────

/// Render the diagnostic of every module `codegen.generateWith` returned
/// without an artifact, and answer the names of the failed non-declaration
/// modules. Every module comes back from `generateWith`: a lex/parse/type
/// failure carries `result.diagnostic`, a comptime validation failure
/// `result.comptime_err`. A non-declaration module with no entry at all is
/// named too (no diagnostic to render). Nothing is printed when no
/// non-declaration module failed — a broken declaration file alone does not
/// fail the command.
pub fn failedOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    modules: []const Module,
    outputs: []const bp.codegen.ModuleOutput,
) ![]const []const u8 {
    var declarations = std.StringHashMap(void).init(arena);
    var returned = std.StringHashMap(void).init(arena);
    for (modules) |m| {
        if (m.declaration) try declarations.put(moduleName(m), {});
    }
    var failed: std.ArrayListUnmanaged([]const u8) = .empty;
    for (outputs) |o| {
        try returned.put(o.name, {});
        if (o.result.failed() and !declarations.contains(o.name)) try failed.append(arena, o.name);
    }
    for (modules) |m| {
        if (m.declaration) continue;
        const name = moduleName(m);
        if (!returned.contains(name)) try failed.append(arena, name);
    }
    if (failed.items.len > 0) {
        for (outputs) |o| _ = renderResult(gpa, io, arena, o);
    }
    return failed.items;
}

/// Render the diagnostic a `generateWith` entry carries. Returns true when the
/// entry is a failure.
pub fn renderResult(gpa: std.mem.Allocator, io: std.Io, arena: std.mem.Allocator, o: bp.codegen.ModuleOutput) bool {
    if (o.result.comptime_err) |ce| {
        renderValidationError(gpa, ce, o.src);
        return true;
    }
    const d = o.result.diagnostic orelse return false;
    const file = fileLabel(arena, io, o.name);
    switch (d) {
        .syntax => |se| printSyntaxError(gpa, se, o.src, file),
        .type => |t| printTypeError(gpa, t.message, t.loc, o.src, file),
    }
    return true;
}

fn renderValidationError(gpa: std.mem.Allocator, ce: anytype, source: []const u8) void {
    const rendered = ce.renderAlloc(gpa, source) catch return;
    defer gpa.free(rendered);
    std.debug.print("{s}", .{rendered});
}

fn printTypeError(gpa: std.mem.Allocator, msg: []const u8, loc: anytype, source: []const u8, file: []const u8) void {
    if (loc) |l| {
        printLocated(gpa, msg, file, source, l.line, l.col, 1);
    } else {
        std.debug.print("error: {s}\n --> {s}\n\n", .{ msg, file });
    }
}

// ── Type diagnostics ──────────────────────────────────────────────────────────

/// Render the diagnostic a comptime outcome carries. Returns true when the
/// outcome is a failure.
pub fn renderOutcome(gpa: std.mem.Allocator, io: std.Io, arena: std.mem.Allocator, o: bp.codegen.ComptimeOutput) bool {
    switch (o.outcome) {
        .ok => |ok| {
            // Decision 57 — a warning renders like an error and fails nothing.
            for (ok.warnings) |w| {
                const msg = w.message(gpa) catch continue;
                defer gpa.free(msg);
                const file = fileLabel(arena, io, o.name);
                if (w.loc) |l| {
                    var aw: std.Io.Writer.Allocating = .init(gpa);
                    defer aw.deinit();
                    renderLocatedAs(&aw.writer, "warning", msg, file, o.src, l.line, l.col, 1) catch continue;
                    std.debug.print("{s}", .{aw.written()});
                } else std.debug.print("warning: {s}\n --> {s}\n\n", .{ msg, file });
            }
            return false;
        },
        .parseError => |se| {
            printSyntaxError(gpa, se, o.src, fileLabel(arena, io, o.name));
            return true;
        },
        .validationError => |ce| {
            renderValidationError(gpa, ce, o.src);
            return true;
        },
        .typeError => |te| {
            const msg = te.message(gpa) catch return true;
            defer gpa.free(msg);
            printTypeError(gpa, msg, te.loc, o.src, fileLabel(arena, io, o.name));
            return true;
        },
    }
}

/// The target vocabulary the comptime pipeline takes (`codegen.generate` threads
/// the same names in).
pub fn comptimeTargetName(t: anytype) []const u8 {
    return switch (t) {
        .commonJS => "node",
        .erlang, .beam => "erlang",
        .wasm => "wasm",
    };
}

/// `error: N module(s) failed to compile: a, b, c`.
pub fn reportFailedModules(arena: std.mem.Allocator, names: []const []const u8) void {
    if (names.len == 0) return;
    var list: std.ArrayListUnmanaged(u8) = .empty;
    list.print(arena, "{d} module(s) failed to compile: ", .{names.len}) catch return;
    for (names, 0..) |n, i| {
        if (i > 0) list.appendSlice(arena, ", ") catch return;
        list.appendSlice(arena, n) catch return;
    }
    reporter.errMsg(list.items);
}

/// Warn once, with a count, about `.bp` files no `mod` path reaches.
pub fn reportOrphans(arena: std.mem.Allocator, count: usize) void {
    if (count == 0) return;
    const msg = std.fmt.allocPrint(arena, "{d} module(s) not reached by any `mod` path were not compiled", .{count}) catch return;
    reporter.warnMsg(msg);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

test "renderLocated prints file, line, column, excerpt and caret" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try renderLocated(&aw.writer, "unbound variable 'nope'", "src/broken.bp", "pub fn f() {\n  nope()\n}\n", 2, 3, 4);
    try std.testing.expectEqualStrings(
        \\error: unbound variable 'nope'
        \\ --> src/broken.bp:2:3
        \\  |
        \\2 |   nope()
        \\  |   ^^^^
        \\
        \\
    , aw.written());
}

test "a lex or parse error is a located outcome, not a session failure" {
    const gpa = std.testing.allocator;
    var session = try bp.comptime_pipeline.compileTypesOnly(gpa, &.{
        .{ .path = "lexbad", .source = "pub fn g() {\n    print(\"abc);\n}\n" },
        .{ .path = "parsebad", .source = "pub fn h() {\n    print((1);\n}\n" },
        .{ .path = "ok", .source = "pub fn f() -> i32 {\n    return 1;\n}\n" },
    }, null);
    defer session.deinit(gpa);

    const outs = session.outputs.items;
    try std.testing.expectEqual(@as(usize, 3), outs.len);

    // `print("abc);` — an unterminated string, located at its opening quote.
    const lf = outs[0].outcome.parseError.lex;
    try std.testing.expectEqualStrings("UnterminatedString", lf.name);
    const lex_at = lineColOf(outs[0].src, lf.start);
    try std.testing.expectEqual(@as(usize, 2), lex_at.line);
    try std.testing.expectEqual(@as(usize, 11), lex_at.col);

    // `print((1);` — the parser records the `;` it stopped on.
    const info = outs[1].outcome.parseError.parse orelse return error.TestExpectedParseErrorInfo;
    try std.testing.expectEqual(@as(usize, 2), info.line);
    try std.testing.expectEqual(@as(usize, 14), info.col);
    try std.testing.expectEqualStrings(";", info.lexeme);

    try std.testing.expect(outs[2].outcome == .ok);
}

test "lineColOf and humanize" {
    const at = lineColOf("ab\ncd\"x", 5);
    try std.testing.expectEqual(@as(usize, 2), at.line);
    try std.testing.expectEqual(@as(usize, 3), at.col);
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("unterminated string", humanize(&buf, "UnterminatedString"));
}

test "failedOutputs names diagnosed and absent modules, never a declaration file or a std output" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const modules = [_]Module{
        .{ .path = "main", .source = "" },
        .{ .path = "broken", .source = "" },
        .{ .path = "gone", .source = "" },
        .{ .path = "decls", .source = "", .declaration = true },
    };
    var js_a = "a".*;
    var js_b = "b".*;
    var js_c = "".*;
    const outputs = [_]bp.codegen.ModuleOutput{
        .{ .name = "std/list", .src = "", .result = .{ .js = &js_a, .comptime_script = null } },
        .{ .name = "main", .src = "", .result = .{ .js = &js_b, .comptime_script = null } },
        .{ .name = "broken", .src = "val x = ;", .result = .{ .js = &js_c, .comptime_script = null, .diagnostic = .{ .syntax = .{ .parse = null } } } },
    };
    const failed = try failedOutputs(std.testing.allocator, std.testing.io, arena, &modules, &outputs);
    try std.testing.expectEqual(@as(usize, 2), failed.len);
    try std.testing.expectEqualStrings("broken", failed[0]);
    try std.testing.expectEqualStrings("gone", failed[1]);
}
