/// LSP feature implementations: diagnostics, formatting, hover, definition, symbols,
/// completion, references, and rename.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");
const compiler_mod = @import("./compiler.zig");

const Lexer = bp.Lexer;
const Parser = bp.Parser;
const Token = bp.Token;
const TokenKind = bp.TokenKind;
const ast = bp.ast;
const format_fn = bp.format.format;
const comptime_pipeline = bp.comptime_pipeline;

// ── Diagnostics ───────────────────────────────────────────────────────────────

pub const DiagnosticsResult = struct {
    uri: []const u8,
    diagnostics: []proto.Diagnostic,

    pub fn deinit(self: *DiagnosticsResult, gpa: std.mem.Allocator) void {
        for (self.diagnostics) |d| gpa.free(d.message);
        gpa.free(self.diagnostics);
    }
};

pub fn diagnose(
    gpa: std.mem.Allocator,
    io: std.Io,
    uri: []const u8,
    source: []const u8,
) !DiagnosticsResult {
    _ = io;
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa);
    const entries = [_]compiler_mod.ModuleEntry{.{ .uri = uri, .source = source }};

    var result = try lsp_compiler.compile(&entries);
    defer result.deinit(gpa);

    var diags: std.ArrayList(proto.Diagnostic) = .empty;
    errdefer {
        for (diags.items) |d| gpa.free(d.message);
        diags.deinit(gpa);
    }

    // Comptime validation errors
    const compile_diags = try result.diagnosticsFor(gpa, uri);
    defer {
        for (compile_diags) |d| gpa.free(d.message);
        gpa.free(compile_diags);
    }
    for (compile_diags) |d| {
        try diags.append(gpa, .{
            .range = d.range,
            .severity = d.severity,
            .message = try gpa.dupe(u8, d.message),
            .source = d.source,
        });
    }

    // Parse errors
    {
        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();
        const alloc = arena.allocator();
        var lexer = Lexer.init(source);
        if (lexer.scanAll(alloc)) |tokens| {
            var parser = Parser.init(tokens);
            _ = parser.parse(alloc) catch |err| switch (err) {
                error.UnexpectedToken => {
                    if (parser.parseError) |pe| {
                        const msgs = bp.print_errors.errorMessages(pe);
                        try diags.append(gpa, .{
                            .range = lsp_types.spanToRange(source, pe.start, pe.end),
                            .severity = proto.DiagnosticSeverity.Error,
                            .message = try gpa.dupe(u8, msgs.message),
                            .source = "botopink",
                        });
                    }
                },
                else => {},
            };
        } else |_| {}
    }

    return .{ .uri = uri, .diagnostics = try diags.toOwnedSlice(gpa) };
}

// ── Formatting ────────────────────────────────────────────────────────────────

pub fn formatting(arena: std.mem.Allocator, source: []const u8) !?proto.TextEdit {
    var lexer = Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch return null;
    var parser = Parser.init(tokens);
    const program = parser.parse(arena) catch return null;
    const formatted = try format_fn(arena, program);
    if (std.mem.eql(u8, source, formatted)) return null;
    return .{ .range = lsp_types.fullRange(source), .newText = formatted };
}

// ── Hover ─────────────────────────────────────────────────────────────────────

/// Returns hover info (inferred type) for the symbol under the cursor.
/// The `contents.value` field of the returned Hover is owned by the caller.
pub fn hover(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Hover {
    const name = identAt(source, pos) orelse return null;

    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, name)) continue;
        const type_str = try renderType(gpa, b.type_);
        const label = try std.fmt.allocPrint(gpa, "```botopink\n{s} : {s}\n```", .{ b.name, type_str });
        gpa.free(type_str);
        return .{ .contents = .{ .kind = proto.MarkupKind.Markdown, .value = label } };
    }
    return null;
}

// ── Go to Definition ──────────────────────────────────────────────────────────

/// Returns the location of the declaration for the symbol under the cursor.
/// The returned `uri` is owned by the caller.
pub fn definition(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
) !?proto.Location {
    const name = identAt(source, pos) orelse return null;

    // Find the identifier token that is the name in a declaration:
    // look for a keyword (val/fn/record/struct/enum/interface) followed by an identifier with the given name.
    const decl_kinds = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl_kw = false;
        for (decl_kinds) |k| {
            if (tok.kind == k) { is_decl_kw = true; break; }
        }
        if (!is_decl_kw) continue;

        // Next non-trivial token should be the name identifier
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }
    return null;
}

// ── Document Symbols ──────────────────────────────────────────────────────────

/// Returns all top-level symbol declarations in the document.
/// The caller owns the returned slice and must free each `name` field.
pub fn documentSymbols(
    gpa: std.mem.Allocator,
    tokens: []const Token,
) ![]proto.DocumentSymbol {
    var syms: std.ArrayList(proto.DocumentSymbol) = .empty;
    errdefer {
        for (syms.items) |s| gpa.free(s.name);
        syms.deinit(gpa);
    }

    const decl_kinds = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var sym_kind: ?u32 = null;
        for (decl_kinds) |k| {
            if (tok.kind == k) {
                sym_kind = tokenToSymbolKind(k);
                break;
            }
        }
        if (sym_kind == null) continue;

        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);

        try syms.append(gpa, .{
            .name = try gpa.dupe(u8, name_tok.lexeme),
            .kind = sym_kind.?,
            .range = .{ .start = start, .end = end },
            .selectionRange = .{ .start = start, .end = end },
        });

        i = j; // skip past the name token
    }

    return syms.toOwnedSlice(gpa);
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Returns the identifier name at the given cursor position by scanning the source.
fn identAt(source: []const u8, pos: proto.Position) ?[]const u8 {
    const offset = lsp_types.positionToOffset(source, pos);
    var i: usize = 0;
    while (i < source.len) {
        if (!isIdentStart(source[i])) { i += 1; continue; }
        const start = i;
        while (i < source.len and isIdentCont(source[i])) i += 1;
        if (offset >= start and offset < i) return source[start..i];
    }
    return null;
}

fn isIdentStart(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}
fn isIdentCont(c: u8) bool {
    return isIdentStart(c) or (c >= '0' and c <= '9');
}

fn tokenToSymbolKind(kind: TokenKind) u32 {
    return switch (kind) {
        .@"fn" => proto.SymbolKind.Function,
        .val => proto.SymbolKind.Variable,
        .record => proto.SymbolKind.Struct,
        .@"struct" => proto.SymbolKind.Struct,
        .@"enum" => proto.SymbolKind.Enum,
        .interface => proto.SymbolKind.Interface,
        else => proto.SymbolKind.Variable,
    };
}

/// Renders a Type as a human-readable string. The caller owns the result.
pub fn renderType(gpa: std.mem.Allocator, ty: *comptime_pipeline.Type) ![]u8 {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| blk: {
            if (n.args.len == 0) break :blk gpa.dupe(u8, n.name);
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, n.name);
            try buf.append(gpa, '<');
            for (n.args, 0..) |arg, idx| {
                if (idx > 0) try buf.appendSlice(gpa, ", ");
                const s = try renderType(gpa, arg);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            try buf.append(gpa, '>');
            break :blk buf.toOwnedSlice(gpa);
        },
        .func => |f| blk: {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, "fn(");
            for (f.params, 0..) |param, idx| {
                if (idx > 0) try buf.appendSlice(gpa, ", ");
                const s = try renderType(gpa, param);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            try buf.appendSlice(gpa, ") -> ");
            const rs = try renderType(gpa, f.ret);
            defer gpa.free(rs);
            try buf.appendSlice(gpa, rs);
            break :blk buf.toOwnedSlice(gpa);
        },
        .typeVar => |cell| switch (cell.state) {
            .unbound => gpa.dupe(u8, "_"),
            .generic => |id| std.fmt.allocPrint(gpa, "T{d}", .{id}),
            .link => |linked| renderType(gpa, linked),
        },
        .union_ => |arms| blk: {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            for (arms, 0..) |arm, idx| {
                if (idx > 0) try buf.appendSlice(gpa, " | ");
                const s = try renderType(gpa, arm);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            break :blk buf.toOwnedSlice(gpa);
        },
    };
}

// ── Signature Help ────────────────────────────────────────────────────────────

/// Returns signature help for the function call under the cursor, or null if
/// the cursor is not inside a call. All strings in the result are allocated in
/// `arena` — caller deinits the arena when done.
pub fn signatureHelp(
    arena: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.SignatureHelp {
    const offset = lsp_types.positionToOffset(source, pos);

    // Walk backwards to find the opening `(` of the current call at depth 0.
    var depth: u32 = 0;
    var active_param: u32 = 0;
    var paren_idx: ?usize = null;

    var i: usize = offset;
    while (i > 0) {
        i -= 1;
        switch (source[i]) {
            ')', ']' => depth += 1,
            '[' => {
                if (depth == 0) break; // index access, not a call
                depth -= 1;
            },
            '(' => {
                if (depth == 0) { paren_idx = i; break; }
                depth -= 1;
            },
            ',' => if (depth == 0) { active_param += 1; },
            else => {},
        }
    }

    const paren = paren_idx orelse return null;

    // Find the identifier immediately before `(` (skip whitespace).
    var j = paren;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j == 0 or !isIdentCont(source[j - 1])) return null;
    const name_end = j;
    while (j > 0 and isIdentCont(source[j - 1])) j -= 1;
    const fn_name = source[j..name_end];

    // Find the binding whose name matches and has a function type.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, fn_name)) continue;
        const t = b.type_.deref();
        if (t.* != .func) continue;
        const func = t.*.func;

        // Build "name(T1, T2) -> R" label.
        var lbl: std.ArrayList(u8) = .empty;
        try lbl.appendSlice(arena, fn_name);
        try lbl.append(arena, '(');
        for (func.params, 0..) |param_ty, pi| {
            if (pi > 0) try lbl.appendSlice(arena, ", ");
            const ps = try renderType(arena, param_ty);
            try lbl.appendSlice(arena, ps);
        }
        try lbl.appendSlice(arena, ") -> ");
        try lbl.appendSlice(arena, try renderType(arena, func.ret));

        // Build ParameterInformation slice.
        const params = try arena.alloc(proto.ParameterInformation, func.params.len);
        for (func.params, 0..) |param_ty, pi| {
            params[pi] = .{ .label = try renderType(arena, param_ty) };
        }

        const sigs = try arena.alloc(proto.SignatureInformation, 1);
        sigs[0] = .{
            .label = try lbl.toOwnedSlice(arena),
            .parameters = if (params.len > 0) params else null,
        };

        const active = if (func.params.len > 0)
            @min(active_param, @as(u32, @intCast(func.params.len - 1)))
        else
            0;

        return proto.SignatureHelp{
            .signatures = sigs,
            .activeSignature = 0,
            .activeParameter = active,
        };
    }

    return null;
}

// ── Inlay Hints ───────────────────────────────────────────────────────────────

/// Returns inlay hints (inferred types) for all `val`/`fn` declarations within
/// `range`. All strings in the result are allocated in `arena`.
pub fn inlayHints(
    arena: std.mem.Allocator,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    range: proto.Range,
) ![]proto.InlayHint {
    var hints: std.ArrayList(proto.InlayHint) = .empty;

    const decl_kinds = [_]TokenKind{ .val, .@"fn" };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl = false;
        for (decl_kinds) |k| {
            if (tok.kind == k) { is_decl = true; break; }
        }
        if (!is_decl) continue;

        // Next non-trivial token is the declaration name.
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .identifier) continue;

        const name_tok = tokens[j];

        // Hint position: immediately after the name token.
        const hint_pos = lsp_types.locToPosition(
            name_tok.line,
            name_tok.col + name_tok.lexeme.len,
        );

        if (!posInRange(hint_pos, range)) { i = j; continue; }

        // Find the binding and render its type.
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, name_tok.lexeme)) continue;
            const t = b.type_.deref();
            if (t.isUnbound()) break; // skip unknown types
            const type_str = try renderType(arena, b.type_);
            const label = try std.fmt.allocPrint(arena, ": {s}", .{type_str});
            try hints.append(arena, .{
                .position = hint_pos,
                .label = label,
                .kind = proto.InlayHintKind.Type,
                .paddingLeft = true,
            });
            break;
        }

        i = j;
    }

    return hints.toOwnedSlice(arena);
}

fn posInRange(pos: proto.Position, range: proto.Range) bool {
    if (pos.line < range.start.line or pos.line > range.end.line) return false;
    if (pos.line == range.start.line and pos.character < range.start.character) return false;
    if (pos.line == range.end.line and pos.character > range.end.character) return false;
    return true;
}

// ── Completion ────────────────────────────────────────────────────────────────

/// Returns completion items for all bindings in scope at the cursor position.
/// The prefix typed so far (the partial identifier before the cursor) is used
/// to filter candidates. Caller owns the returned slice and all `label`/`detail`
/// strings inside each item.
pub fn completion(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    // Extract the partial word before the cursor as a filter prefix.
    const prefix = prefixAt(source, pos);

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }

    for (bindings) |b| {
        if (b.name.len == 0) continue;
        if (!std.mem.startsWith(u8, b.name, prefix)) continue;

        const kind = bindingCompletionKind(b);
        const detail = try renderType(gpa, b.type_);
        errdefer gpa.free(detail);

        try items.append(gpa, .{
            .label = try gpa.dupe(u8, b.name),
            .kind = kind,
            .detail = detail,
        });
    }

    return items.toOwnedSlice(gpa);
}

fn bindingCompletionKind(b: comptime_pipeline.TypedBinding) u32 {
    return switch (b.decl) {
        .@"fn" => proto.CompletionItemKind.Function,
        .record, .@"struct" => proto.CompletionItemKind.Struct,
        .@"enum" => proto.CompletionItemKind.Enum,
        .interface => proto.CompletionItemKind.Interface,
        else => proto.CompletionItemKind.Variable,
    };
}

/// Returns the partial identifier immediately before (and including) `pos`.
fn prefixAt(source: []const u8, pos: proto.Position) []const u8 {
    const offset = lsp_types.positionToOffset(source, pos);
    if (offset == 0) return "";
    const end = offset;
    // Walk back to find start of current identifier word
    var start = end;
    while (start > 0 and isIdentCont(source[start - 1])) start -= 1;
    return source[start..end];
}

// ── Find References ───────────────────────────────────────────────────────────

/// Returns all locations in `source` where the identifier at `pos` is used.
/// Caller owns the returned slice and each `uri` string inside each Location.
pub fn references(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
    include_declaration: bool,
) ![]proto.Location {
    const name = identAt(source, pos) orelse return &.{};

    var locs: std.ArrayList(proto.Location) = .empty;
    errdefer {
        for (locs.items) |l| gpa.free(l.uri);
        locs.deinit(gpa);
    }

    const decl_kinds = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    for (tokens, 0..) |tok, i| {
        if (tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, tok.lexeme, name)) continue;

        // Check if this token is a declaration name (previous token is a keyword).
        const is_decl = blk: {
            if (i == 0) break :blk false;
            const prev = tokens[i - 1];
            for (decl_kinds) |k| {
                if (prev.kind == k) break :blk true;
            }
            break :blk false;
        };

        if (is_decl and !include_declaration) continue;

        const start = lsp_types.locToPosition(tok.line, tok.col);
        const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
        try locs.append(gpa, .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        });
    }

    return locs.toOwnedSlice(gpa);
}

// ── Rename ────────────────────────────────────────────────────────────────────

/// Computes all edits needed to rename the symbol at `pos` to `new_name`.
/// Returns a slice of TextEdits for the current file. Caller owns it.
pub fn rename(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    new_name: []const u8,
    tokens: []const Token,
) ![]proto.TextEdit {
    const name = identAt(source, pos) orelse return &.{};

    var edits: std.ArrayList(proto.TextEdit) = .empty;
    errdefer edits.deinit(gpa);

    for (tokens) |tok| {
        if (tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, tok.lexeme, name)) continue;

        const start = lsp_types.locToPosition(tok.line, tok.col);
        const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
        try edits.append(gpa, .{
            .range = .{ .start = start, .end = end },
            .newText = new_name,
        });
    }

    return edits.toOwnedSlice(gpa);
}
