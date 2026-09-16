/// Compile diagnostics shared by `build`, `check` and `test`.
///
/// The compiler core reports a failed module in three lossy ways today: a lex
/// error aborts the whole session as a bare Zig error tag, a parse error is an
/// outcome with no location, and a type error makes `codegen.generate` drop the
/// module without a trace (the backends `continue` past it). This file closes
/// that gap from the driver side so every command answers the same question the
/// same way — "which modules did not compile, and where":
///
///   * `preflight` lexes and parses every module before compilation and renders
///     a located lex or parse error (file, line, excerpt) for each one that
///     fails; the caller compiles only the modules that passed.
///   * `missingOutputs` compares the *named* set of modules handed to
///     `codegen.generate` with the named set it returned — never counts, which
///     `from "std"` expansion inflates.
///   * `explainFailures` re-runs the comptime pipeline over the same modules
///     (only on the failure path) and renders the located diagnostic of every
///     module that did not type-check.
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
    const line_w = digitWidth(line);
    try w.print("error: {s}\n", .{message});
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

// ── Preflight: lex + parse ────────────────────────────────────────────────────

pub const Preflight = struct {
    /// Modules that lexed and parsed (declaration modules pass through), in
    /// input order.
    ok: []Module,
    /// Names of the modules that did not lex or parse, each already rendered.
    failed: []const []const u8,
};

/// Lex and parse every non-declaration module, render a located diagnostic for
/// each failure, and split the input into the modules that can be compiled and
/// the names of those that cannot.
pub fn preflight(arena: std.mem.Allocator, gpa: std.mem.Allocator, io: std.Io, modules: []const Module) !Preflight {
    var ok: std.ArrayListUnmanaged(Module) = .empty;
    var failed: std.ArrayListUnmanaged([]const u8) = .empty;
    for (modules) |m| {
        if (m.declaration or lexParse(arena, gpa, io, m)) {
            try ok.append(arena, m);
        } else {
            try failed.append(arena, moduleName(m));
        }
    }
    return .{ .ok = ok.items, .failed = failed.items };
}

/// True when `m` lexes and parses; otherwise renders the located error.
fn lexParse(arena: std.mem.Allocator, gpa: std.mem.Allocator, io: std.Io, m: Module) bool {
    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();
    const sa = scratch.allocator();
    const file = fileLabel(arena, io, moduleName(m));

    var lexer = bp.Lexer.init(m.source);
    const tokens = lexer.scanAll(sa) catch |err| {
        printLexError(gpa, &lexer, err, m.source, file);
        return false;
    };

    var parser = bp.Parser.init(tokens);
    _ = parser.parse(sa) catch |err| {
        printParseError(gpa, &parser, err, m.source, file);
        return false;
    };
    return true;
}

/// Render the error `lexer.scanAll` just failed with, located at the token the
/// lexer was scanning.
pub fn printLexError(gpa: std.mem.Allocator, lexer: *const bp.Lexer, err: anyerror, source: []const u8, file: []const u8) void {
    var buf: [128]u8 = undefined;
    if (lexer.lexError) |le| {
        const at = lineColOf(source, le.start);
        const span = if (le.end > le.start) le.end - le.start else 1;
        printLocated(gpa, humanize(&buf, @tagName(le.kind)), file, source, at.line, at.col, span);
    } else {
        const at = lineColOf(source, lexer.start);
        const rest_of_line = lineText(source, at.line).len -| (at.col - 1);
        const span = @max(@min(lexer.current -| lexer.start, rest_of_line), 1);
        printLocated(gpa, humanize(&buf, @errorName(err)), file, source, at.line, at.col, span);
    }
}

/// Render the error `parser.parse` just failed with.
pub fn printParseError(gpa: std.mem.Allocator, parser: *const bp.Parser, err: anyerror, source: []const u8, file: []const u8) void {
    if (parser.parseError) |info| {
        var aw: std.Io.Writer.Allocating = .init(gpa);
        defer aw.deinit();
        bp.print_errors.render(&aw.writer, info, source, file) catch {};
        std.debug.print("{s}", .{aw.written()});
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

/// Names of the non-declaration `modules` for which `outputs` holds no entry
/// (or only a validation-error entry). Compares named sets, never counts:
/// `codegen.generate` adds one output per `from "std"` module it pulls in.
pub fn missingOutputs(
    arena: std.mem.Allocator,
    modules: []const Module,
    outputs: []const bp.codegen.ModuleOutput,
) ![]const []const u8 {
    var produced = std.StringHashMap(void).init(arena);
    for (outputs) |o| {
        if (o.result.comptime_err == null) try produced.put(o.name, {});
    }
    var missing: std.ArrayListUnmanaged([]const u8) = .empty;
    for (modules) |m| {
        if (m.declaration) continue;
        const name = moduleName(m);
        if (!produced.contains(name)) try missing.append(arena, name);
    }
    return missing.items;
}

// ── Type diagnostics ──────────────────────────────────────────────────────────

/// Render the diagnostic a comptime outcome carries. Returns true when the
/// outcome is a failure.
pub fn renderOutcome(gpa: std.mem.Allocator, io: std.Io, arena: std.mem.Allocator, o: bp.codegen.ComptimeOutput) bool {
    switch (o.outcome) {
        .ok => return false,
        .parseError => {
            // Normally caught by `preflight`; re-lex/parse to locate it.
            _ = lexParse(arena, gpa, io, .{ .path = o.name, .source = o.src });
            return true;
        },
        .validationError => |ce| {
            const rendered = ce.renderAlloc(gpa, o.src) catch return true;
            defer gpa.free(rendered);
            std.debug.print("{s}", .{rendered});
            return true;
        },
        .typeError => |te| {
            const msg = te.message(gpa) catch return true;
            defer gpa.free(msg);
            const file = fileLabel(arena, io, o.name);
            if (te.loc) |loc| {
                printLocated(gpa, msg, file, o.src, loc.line, loc.col, 1);
            } else {
                std.debug.print("error: {s}\n --> {s}\n\n", .{ msg, file });
            }
            return true;
        },
    }
}

/// Re-run the comptime pipeline over `modules` and render the diagnostic of
/// every module that failed. Called only on the failure path of `build`/`test`,
/// after `codegen.generate` dropped a module without saying why.
pub fn explainFailures(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    modules: []const Module,
    target_name: []const u8,
) void {
    var session = bp.comptime_pipeline.compile(gpa, modules, io, ".botopinkbuild", target_name) catch |err| {
        var buf: [128]u8 = undefined;
        reporter.errMsg(std.fmt.bufPrint(&buf, "type-check failed: {s}", .{@errorName(err)}) catch "type-check failed");
        return;
    };
    defer session.deinit(gpa);
    for (session.outputs.items) |o| _ = renderOutcome(gpa, io, arena, o);
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
        \\2 | nope()
        \\  |   ^^^^
        \\
        \\
    , aw.written());
}

test "lineColOf and humanize" {
    const at = lineColOf("ab\ncd\"x", 5);
    try std.testing.expectEqual(@as(usize, 2), at.line);
    try std.testing.expectEqual(@as(usize, 3), at.col);
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("unterminated string", humanize(&buf, "UnterminatedString"));
}

test "missingOutputs compares named sets, not counts" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const modules = [_]Module{
        .{ .path = "main", .source = "" },
        .{ .path = "broken", .source = "" },
        .{ .path = "decls", .source = "", .declaration = true },
    };
    // One `from "std"` output masks the missing `broken` under a count guard.
    var js_a = "a".*;
    var js_b = "b".*;
    const outputs = [_]bp.codegen.ModuleOutput{
        .{ .name = "std/list", .src = "", .result = .{ .js = &js_a, .comptime_script = null } },
        .{ .name = "main", .src = "", .result = .{ .js = &js_b, .comptime_script = null } },
    };
    const missing = try missingOutputs(arena, &modules, &outputs);
    try std.testing.expectEqual(@as(usize, 1), missing.len);
    try std.testing.expectEqualStrings("broken", missing[0]);
}
