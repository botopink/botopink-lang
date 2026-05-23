/// LSP feature implementations: diagnostics, formatting, hover, definition, symbols,
/// completion, references, and rename.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");
const compiler_mod = @import("./compiler.zig");
const index_mod = @import("./project_index.zig");

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
/// The `contents.kind` field of the returned Hover is owned by the caller.
pub fn hover(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Hover {
    const name = identAt(source, pos) orelse return null;

    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, name)) continue;

        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(gpa);

        try buf.appendSlice(gpa, "```botopink\n");

        switch (b.decl) {
            .@"fn" => |f| {
                if (f.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "fn ");
                try buf.appendSlice(gpa, b.name);
                try buf.append(gpa, '(');
                for (f.params, 0..) |p, pi| {
                    if (pi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, p.name);
                    try buf.appendSlice(gpa, ": ");
                    try appendTypeRef(gpa, &buf, p.typeRef);
                }
                try buf.append(gpa, ')');
                if (f.returnType) |rt| {
                    try buf.appendSlice(gpa, " -> ");
                    try appendTypeRef(gpa, &buf, rt);
                }
            },
            .val => {
                const type_str = try renderType(gpa, b.type_);
                defer gpa.free(type_str);
                try buf.appendSlice(gpa, "val ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " : ");
                try buf.appendSlice(gpa, type_str);
            },
            .record => |r| {
                if (r.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "record ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " { ");
                for (r.fields, 0..) |field, fi| {
                    if (fi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, field.name);
                    try buf.appendSlice(gpa, ": ");
                    try appendTypeRef(gpa, &buf, field.typeRef);
                }
                try buf.appendSlice(gpa, " }");
            },
            .@"struct" => |s| {
                if (s.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "struct ");
                try buf.appendSlice(gpa, b.name);
            },
            .@"enum" => |e| {
                if (e.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "enum ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " { ");
                for (e.variants, 0..) |v, vi| {
                    if (vi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, v.name);
                    if (v.fields.len > 0) try buf.appendSlice(gpa, "(...)");
                }
                try buf.appendSlice(gpa, " }");
            },
            .interface => {
                try buf.appendSlice(gpa, "interface ");
                try buf.appendSlice(gpa, b.name);
            },
            else => {
                const type_str = try renderType(gpa, b.type_);
                defer gpa.free(type_str);
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " : ");
                try buf.appendSlice(gpa, type_str);
            },
        }

        try buf.appendSlice(gpa, "\n```");

        // Append doc comment if available.
        const doc = getDeclDocComment(b.decl);
        if (doc) |d| {
            try buf.appendSlice(gpa, "\n\n---\n\n");
            try buf.appendSlice(gpa, d);
        }

        return .{ .contents = .{ .kind = proto.MarkupKind.Markdown, .value = try buf.toOwnedSlice(gpa) } };
    }
    return null;
}

fn getDeclDocComment(decl: ast.DeclKind) ?[]const u8 {
    return switch (decl) {
        .@"fn" => |f| f.docComment,
        .val => |v| v.docComment,
        .record => |r| r.docComment,
        .@"struct" => |s| s.docComment,
        .@"enum" => |e| e.docComment,
        .interface => |i| i.docComment,
        .delegate => |d| d.docComment,
        .implement => |i| i.docComment,
        else => null,
    };
}

fn appendTypeRef(gpa: std.mem.Allocator, buf: *std.ArrayList(u8), tr: ast.TypeRef) !void {
    switch (tr) {
        .named => |n| try buf.appendSlice(gpa, n),
        .array => |a| {
            try appendTypeRef(gpa, buf, a.*);
            try buf.appendSlice(gpa, "[]");
        },
        .optional => |o| {
            try buf.append(gpa, '?');
            try appendTypeRef(gpa, buf, o.*);
        },
        .function => |f| {
            try buf.appendSlice(gpa, "fn(");
            for (f.params, 0..) |p, pi| {
                if (pi > 0) try buf.appendSlice(gpa, ", ");
                try appendTypeRef(gpa, buf, p);
            }
            try buf.appendSlice(gpa, ") -> ");
            try appendTypeRef(gpa, buf, f.returnType.*);
        },
        .tuple_ => |t| {
            try buf.appendSlice(gpa, "#(");
            for (t, 0..) |elem, ei| {
                if (ei > 0) try buf.appendSlice(gpa, ", ");
                try appendTypeRef(gpa, buf, elem);
            }
            try buf.append(gpa, ')');
        },
        .errorUnion => |eu| {
            try appendTypeRef(gpa, buf, eu.errorType.*);
            try buf.append(gpa, '!');
            try appendTypeRef(gpa, buf, eu.payload.*);
        },
    }
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
    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl_kw = false;
        for (decl_values) |k| {
            if (tok.kind == k) {
                is_decl_kw = true;
                break;
            }
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

/// Returns all top-level symbol declarations in the document, with children
/// for struct/record members and enum variants.
/// The caller owns the returned slice and must free each `name` field.
pub fn documentSymbols(
    gpa: std.mem.Allocator,
    tokens: []const Token,
) ![]proto.DocumentSymbol {
    var syms: std.ArrayList(proto.DocumentSymbol) = .empty;
    errdefer {
        for (syms.items) |s| freeSymbol(gpa, s);
        syms.deinit(gpa);
    }

    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var sym_kind: ?u32 = null;
        var decl_kind: ?TokenKind = null;
        for (decl_values) |k| {
            if (tok.kind == k) {
                sym_kind = tokenToSymbolKind(k);
                decl_kind = k;
                break;
            }
        }
        if (sym_kind == null) continue;

        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;

        const sel_start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const sel_end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);

        // Find the full range of the declaration (up to matching `}`).
        var range_end = sel_end;
        const block_end_idx = findBlockEnd(tokens, j + 1);
        if (block_end_idx) |end_idx| {
            range_end = lsp_types.locToPosition(tokens[end_idx].line, tokens[end_idx].col + 1);
        }

        // Collect children for types with bodies.
        var children: ?[]proto.DocumentSymbol = null;
        if (block_end_idx) |end_idx| {
            children = try collectChildren(gpa, tokens, j + 1, end_idx, decl_kind.?);
        }

        try syms.append(gpa, .{
            .name = try gpa.dupe(u8, name_tok.lexeme),
            .kind = sym_kind.?,
            .range = .{ .start = sel_start, .end = range_end },
            .selectionRange = .{ .start = sel_start, .end = sel_end },
            .children = children,
        });

        if (block_end_idx) |end_idx| {
            i = end_idx;
        } else {
            i = j;
        }
    }

    return syms.toOwnedSlice(gpa);
}

pub fn freeSymbol(gpa: std.mem.Allocator, sym: proto.DocumentSymbol) void {
    if (sym.children) |kids| {
        for (kids) |k| freeSymbol(gpa, k);
        gpa.free(kids);
    }
    gpa.free(sym.name);
}

fn findBlockEnd(tokens: []const Token, start: usize) ?usize {
    var k = start;
    while (k < tokens.len and tokens[k].kind != .leftBrace) : (k += 1) {
        if (tokens[k].kind == .semicolon or tokens[k].kind == .endOfFile) return null;
    }
    if (k >= tokens.len or tokens[k].kind != .leftBrace) return null;
    var depth: u32 = 1;
    k += 1;
    while (k < tokens.len and depth > 0) : (k += 1) {
        if (tokens[k].kind == .leftBrace) depth += 1;
        if (tokens[k].kind == .rightBrace) depth -= 1;
    }
    return if (depth == 0) k - 1 else null;
}

fn collectChildren(
    gpa: std.mem.Allocator,
    tokens: []const Token,
    start: usize,
    end: usize,
    parent_kind: TokenKind,
) !?[]proto.DocumentSymbol {
    var kids: std.ArrayList(proto.DocumentSymbol) = .empty;
    errdefer {
        for (kids.items) |k| freeSymbol(gpa, k);
        kids.deinit(gpa);
    }

    // Find the opening brace.
    var i = start;
    while (i < end and tokens[i].kind != .leftBrace) : (i += 1) {}
    if (i >= end) return null;
    i += 1; // skip past `{`

    while (i < end) : (i += 1) {
        const tok = tokens[i];

        switch (parent_kind) {
            .@"enum" => {
                // Enum variants are PascalCase identifiers at depth 0.
                if (tok.kind == .identifier and tok.lexeme.len > 0 and tok.lexeme[0] >= 'A' and tok.lexeme[0] <= 'Z') {
                    const s = lsp_types.locToPosition(tok.line, tok.col);
                    const e = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
                    try kids.append(gpa, .{
                        .name = try gpa.dupe(u8, tok.lexeme),
                        .kind = proto.SymbolKind.EnumMember,
                        .range = .{ .start = s, .end = e },
                        .selectionRange = .{ .start = s, .end = e },
                    });
                }
                // Methods inside enum.
                if (tok.kind == .@"fn") {
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = proto.SymbolKind.Function,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            .@"struct", .record => {
                // Fields: identifier followed by `:` (but not `self`).
                if (tok.kind == .identifier and i + 1 < end and tokens[i + 1].kind == .colon) {
                    if (!std.mem.eql(u8, tok.lexeme, "self")) {
                        const s = lsp_types.locToPosition(tok.line, tok.col);
                        const e = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, tok.lexeme),
                            .kind = proto.SymbolKind.Variable,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                    }
                }
                // Methods/getters/setters.
                if (tok.kind == .@"fn" or tok.kind == .get or tok.kind == .set) {
                    const child_kind: u32 = if (tok.kind == .@"fn") proto.SymbolKind.Function else proto.SymbolKind.Variable;
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = child_kind,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            .interface => {
                // Interface methods.
                if (tok.kind == .@"fn") {
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = proto.SymbolKind.Function,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            else => {},
        }

        // Skip nested brace blocks to avoid picking up inner members.
        if (tok.kind == .leftBrace) {
            var depth: u32 = 1;
            i += 1;
            while (i < end and depth > 0) : (i += 1) {
                if (tokens[i].kind == .leftBrace) depth += 1;
                if (tokens[i].kind == .rightBrace) depth -= 1;
            }
        }
    }

    if (kids.items.len == 0) {
        kids.deinit(gpa);
        return null;
    }
    const slice = try kids.toOwnedSlice(gpa);
    return slice;
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Returns the identifier name at the given cursor position by scanning the source.
fn identAt(source: []const u8, pos: proto.Position) ?[]const u8 {
    const offset = lsp_types.positionToOffset(source, pos);
    var i: usize = 0;
    while (i < source.len) {
        if (!isIdentStart(source[i])) {
            i += 1;
            continue;
        }
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

// ── Type Definition ──────────────────────────────────────────────────────────

pub fn typeDefinition(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Location {
    const name = identAt(source, pos) orelse return null;

    // Find the type name for this binding.
    const type_name: []const u8 = blk: {
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, name)) continue;
            const t = b.type_.deref();
            switch (t.*) {
                .named => |n| break :blk n.name,
                .func => |f| {
                    const ret = f.ret.deref();
                    if (ret.* == .named) break :blk ret.named.name;
                },
                else => {},
            }
            break;
        }
        return null;
    };

    const decl_kws = [_]TokenKind{ .record, .@"struct", .@"enum", .interface, .type };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_type_kw = false;
        for (decl_kws) |k| {
            if (tok.kind == k) {
                is_type_kw = true;
                break;
            }
        }
        if (!is_type_kw) continue;

        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, type_name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }

    // Fallback: if the name was declared with `val Name = struct/record/enum`,
    // look for `val` followed by the type name.
    var k: usize = 0;
    while (k < tokens.len) : (k += 1) {
        if (tokens[k].kind != .val) continue;
        var j = k + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;
        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, type_name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }
    return null;
}

// ── Folding Ranges ───────────────────────────────────────────────────────────

pub fn foldingRanges(
    gpa: std.mem.Allocator,
    source: []const u8,
    tokens: []const Token,
) ![]proto.FoldingRange {
    var ranges: std.ArrayList(proto.FoldingRange) = .empty;
    errdefer ranges.deinit(gpa);

    // Track brace-delimited blocks for fn/struct/record/enum/interface/implement.
    const block_kws = [_]TokenKind{
        .@"fn", .@"struct", .record, .@"enum", .interface, .implement,
    };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_block_kw = false;
        for (block_kws) |k| {
            if (tok.kind == k) {
                is_block_kw = true;
                break;
            }
        }
        if (!is_block_kw) continue;

        // Find the opening `{` for this declaration.
        var j = i + 1;
        while (j < tokens.len) : (j += 1) {
            if (tokens[j].kind == .leftBrace) break;
            if (tokens[j].kind == .semicolon or tokens[j].kind == .endOfFile) break;
        }
        if (j >= tokens.len or tokens[j].kind != .leftBrace) continue;

        const open_line = tokens[j].line;

        // Find the matching `}`.
        var depth: u32 = 1;
        var end_j = j + 1;
        while (end_j < tokens.len and depth > 0) : (end_j += 1) {
            if (tokens[end_j].kind == .leftBrace) depth += 1;
            if (tokens[end_j].kind == .rightBrace) depth -= 1;
        }
        if (depth != 0) continue;
        const close_line = tokens[end_j - 1].line;

        if (close_line > open_line) {
            try ranges.append(gpa, .{
                .startLine = @intCast(open_line -| 1),
                .endLine = @intCast(close_line -| 1),
                .kind = proto.FoldingRangeKind.Region,
            });
        }
    }

    // Track consecutive `use` imports as a foldable region.
    _ = source;
    i = 0;
    var import_start: ?usize = null;
    var import_end_line: u32 = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind == .use) {
            if (import_start == null) {
                import_start = @intCast(tokens[i].line -| 1);
            }
            // Scan to the end of this `use` statement (semicolon).
            while (i < tokens.len and tokens[i].kind != .semicolon) : (i += 1) {}
            if (i < tokens.len) {
                import_end_line = @intCast(tokens[i].line -| 1);
            }
        } else if (import_start != null) {
            // Non-use token: close the import block if it spans multiple lines.
            const start_line: u32 = @intCast(import_start.?);
            if (import_end_line > start_line) {
                try ranges.append(gpa, .{
                    .startLine = start_line,
                    .endLine = import_end_line,
                    .kind = proto.FoldingRangeKind.Imports,
                });
            }
            import_start = null;
        }
    }
    // Close trailing import block.
    if (import_start) |start| {
        const start_line: u32 = @intCast(start);
        if (import_end_line > start_line) {
            try ranges.append(gpa, .{
                .startLine = start_line,
                .endLine = import_end_line,
                .kind = proto.FoldingRangeKind.Imports,
            });
        }
    }

    return ranges.toOwnedSlice(gpa);
}

// ── Prepare Rename ───────────────────────────────────────────────────────────

pub fn prepareRename(
    source: []const u8,
    pos: proto.Position,
) ?proto.PrepareRenameResult {
    const name = identAt(source, pos) orelse return null;
    if (name.len == 0) return null;

    // Reject keywords and reserved words.
    if (isKeyword(name)) return null;

    const offset = lsp_types.positionToOffset(source, pos);
    var start = offset;
    while (start > 0 and isIdentCont(source[start - 1])) start -= 1;

    const start_pos = lsp_types.offsetToPosition(source, start);
    const end_pos = lsp_types.offsetToPosition(source, start + name.len);

    return .{
        .range = .{ .start = start_pos, .end = end_pos },
        .placeholder = name,
    };
}

fn isKeyword(name: []const u8) bool {
    const keywords = [_][]const u8{
        "as",       "assert",   "auto",      "break",    "case",
        "catch",    "comptime", "const",     "continue", "declare",
        "default",  "delegate", "derive",    "echo",     "else",
        "enum",     "extends",  "fn",        "for",      "from",
        "get",      "if",       "implement", "import",   "interface",
        "loop",     "macro",    "new",       "null",     "opaque",
        "private",  "pub",      "record",    "return",   "self",
        "set",      "struct",   "syntax",    "test",     "throw",
        "todo",     "true",     "false",     "try",      "type",
        "typeinfo", "use",      "val",       "var",      "yield",
        "Self",
    };
    for (keywords) |kw| {
        if (std.mem.eql(u8, name, kw)) return true;
    }
    return false;
}

// ── Code Actions ─────────────────────────────────────────────────────────────

pub fn codeActions(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    project_index: ?*index_mod.ProjectIndex,
) ![]proto.CodeAction {
    var actions: std.ArrayList(proto.CodeAction) = .empty;
    errdefer actions.deinit(gpa);

    try addTypeAnnotationActions(gpa, &actions, uri, source, range, tokens, bindings);
    try addRemoveUnusedImportActions(gpa, &actions, uri, source, range, tokens);
    try addMissingCasePatternsActions(gpa, &actions, uri, source, range, tokens, bindings);
    if (project_index) |idx| {
        try addMissingImportActions(gpa, &actions, uri, range, tokens, bindings, idx);
    }

    return actions.toOwnedSlice(gpa);
}

fn addTypeAnnotationActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !void {
    const decl_kws = [_]TokenKind{ .val, .@"var" };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl = false;
        for (decl_kws) |k| {
            if (tok.kind == k) {
                is_decl = true;
                break;
            }
        }
        if (!is_decl) continue;

        const tok_line: u32 = @intCast(tok.line -| 1);
        if (tok_line < range.start.line or tok_line > range.end.line) continue;

        // Next token should be the identifier name.
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .identifier) continue;

        const name_tok = tokens[j];

        // Check if there's already a type annotation (`:` after the name).
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind == .endOfFile) : (k += 1) {}
        if (k < tokens.len and tokens[k].kind == .colon) continue; // already annotated

        // Find the binding and get its inferred type.
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, name_tok.lexeme)) continue;
            const t = b.type_.deref();
            if (t.isUnbound()) break;
            const type_str = renderType(gpa, b.type_) catch break;
            defer gpa.free(type_str);

            const annotation = std.fmt.allocPrint(gpa, ": {s}", .{type_str}) catch break;
            defer gpa.free(annotation);

            // Insert position: right after the name token.
            const insert_pos = lsp_types.locToPosition(
                name_tok.line,
                name_tok.col + name_tok.lexeme.len,
            );

            _ = source;
            const title = std.fmt.allocPrint(gpa, "Add type annotation: {s}", .{type_str}) catch break;

            const edit_slice = gpa.alloc(proto.TextEdit, 1) catch break;
            edit_slice[0] = .{
                .range = .{ .start = insert_pos, .end = insert_pos },
                .newText = std.fmt.allocPrint(gpa, ": {s}", .{type_str}) catch break,
            };

            const doc_edit_slice = gpa.alloc(proto.TextDocumentEdit, 1) catch break;
            doc_edit_slice[0] = .{
                .textDocument = .{ .uri = uri, .version = null },
                .edits = edit_slice,
            };

            try actions.append(gpa, .{
                .title = title,
                .kind = proto.CodeActionKind.QuickFix,
                .edit = .{ .documentChanges = doc_edit_slice },
            });
            break;
        }
    }
}

fn addRemoveUnusedImportActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
) !void {
    // Scan for `use { name1, name2 } from "module";` patterns.
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .use) continue;

        const use_tok = tokens[i];
        const use_line: u32 = @intCast(use_tok.line -| 1);
        if (use_line < range.start.line or use_line > range.end.line) continue;

        // Collect imported names between `{` and `}`.
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind != .leftBrace) : (j += 1) {
            if (tokens[j].kind == .semicolon or tokens[j].kind == .endOfFile) break;
        }
        if (j >= tokens.len or tokens[j].kind != .leftBrace) continue;
        j += 1; // skip `{`

        var imported_names: std.ArrayList([]const u8) = .empty;
        defer imported_names.deinit(gpa);

        while (j < tokens.len and tokens[j].kind != .rightBrace) : (j += 1) {
            if (tokens[j].kind == .identifier) {
                try imported_names.append(gpa, tokens[j].lexeme);
            }
        }
        if (j >= tokens.len) continue;

        // Find the semicolon to get the full statement range.
        var stmt_end = j + 1;
        while (stmt_end < tokens.len and tokens[stmt_end].kind != .semicolon) : (stmt_end += 1) {}
        if (stmt_end >= tokens.len) continue;

        // Check each imported name: is it referenced elsewhere?
        for (imported_names.items) |name| {
            var used = false;
            for (tokens, 0..) |tok, ti| {
                if (ti >= i and ti <= stmt_end) continue; // skip the use statement itself
                if (tok.kind == .identifier and std.mem.eql(u8, tok.lexeme, name)) {
                    used = true;
                    break;
                }
            }
            if (used) continue;

            // This import is unused — offer removal.
            // For simplicity, if there's only one import in the statement, remove the whole line.
            // If multiple, just flag it (full multi-name editing is complex).
            if (imported_names.items.len == 1) {
                const line_start = lsp_types.locToPosition(use_tok.line, 1);
                const line_end_line = tokens[stmt_end].line;
                // Include the newline after the semicolon.
                const del_end = lsp_types.locToPosition(line_end_line + 1, 1);

                _ = source;
                const title = try std.fmt.allocPrint(gpa, "Remove unused import '{s}'", .{name});

                const edit_slice = try gpa.alloc(proto.TextEdit, 1);
                edit_slice[0] = .{
                    .range = .{ .start = line_start, .end = del_end },
                    .newText = try gpa.dupe(u8, ""),
                };

                const doc_edit_slice = try gpa.alloc(proto.TextDocumentEdit, 1);
                doc_edit_slice[0] = .{
                    .textDocument = .{ .uri = uri, .version = null },
                    .edits = edit_slice,
                };

                try actions.append(gpa, .{
                    .title = title,
                    .kind = proto.CodeActionKind.QuickFix,
                    .edit = .{ .documentChanges = doc_edit_slice },
                });
            }
        }
    }
}

fn addMissingCasePatternsActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !void {
    _ = source;
    // Scan for `case <ident> {` patterns.
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .case) continue;

        const case_line: u32 = @intCast(tokens[i].line -| 1);
        if (case_line < range.start.line or case_line > range.end.line) continue;

        // Next token should be an identifier (the subject).
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .identifier) continue;

        const subject_name = tokens[j].lexeme;

        // Find the subject's type via bindings.
        var enum_decl: ?ast.EnumDecl = null;
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, subject_name)) continue;
            const t = b.type_.deref();
            if (t.* != .named) break;
            // Look up the enum declaration by type name.
            for (bindings) |tb| {
                if (tb.decl != .@"enum") continue;
                if (std.mem.eql(u8, tb.name, t.named.name)) {
                    enum_decl = tb.decl.@"enum";
                    break;
                }
            }
            break;
        }
        const ed = enum_decl orelse continue;

        // Find the opening `{` of the case block.
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind != .leftBrace) : (k += 1) {
            if (tokens[k].kind == .semicolon or tokens[k].kind == .endOfFile) break;
        }
        if (k >= tokens.len or tokens[k].kind != .leftBrace) continue;

        // Find the matching `}`.
        var depth: u32 = 1;
        var case_end = k + 1;
        while (case_end < tokens.len and depth > 0) : (case_end += 1) {
            if (tokens[case_end].kind == .leftBrace) depth += 1;
            if (tokens[case_end].kind == .rightBrace) depth -= 1;
        }
        if (depth != 0) continue;
        const close_idx = case_end - 1;

        // Collect covered patterns (identifiers inside the case block at depth 0).
        var covered: std.ArrayList([]const u8) = .empty;
        defer covered.deinit(gpa);
        var ci = k + 1;
        var cdepth: u32 = 0;
        while (ci < close_idx) : (ci += 1) {
            if (tokens[ci].kind == .leftBrace) cdepth += 1;
            if (tokens[ci].kind == .rightBrace) cdepth -= 1;
            if (cdepth == 0 and tokens[ci].kind == .identifier) {
                try covered.append(gpa, tokens[ci].lexeme);
            }
        }

        // Find missing variants.
        var missing: std.ArrayList([]const u8) = .empty;
        defer missing.deinit(gpa);
        for (ed.variants) |v| {
            var found = false;
            for (covered.items) |c| {
                if (std.mem.eql(u8, c, v.name)) {
                    found = true;
                    break;
                }
            }
            if (!found) try missing.append(gpa, v.name);
        }

        if (missing.items.len == 0) continue;

        // Build the insertion text for missing patterns.
        var insert_buf: std.ArrayList(u8) = .empty;
        defer insert_buf.deinit(gpa);
        for (missing.items) |m| {
            try insert_buf.appendSlice(gpa, "    ");
            try insert_buf.appendSlice(gpa, m);
            try insert_buf.appendSlice(gpa, " -> todo;\n");
        }

        // Insert position: just before the closing `}`.
        const insert_pos = lsp_types.locToPosition(tokens[close_idx].line, tokens[close_idx].col);

        const title = try std.fmt.allocPrint(gpa, "Add {d} missing case pattern(s)", .{missing.items.len});

        const edit_slice = try gpa.alloc(proto.TextEdit, 1);
        edit_slice[0] = .{
            .range = .{ .start = insert_pos, .end = insert_pos },
            .newText = try insert_buf.toOwnedSlice(gpa),
        };

        const doc_edit_slice = try gpa.alloc(proto.TextDocumentEdit, 1);
        doc_edit_slice[0] = .{
            .textDocument = .{ .uri = uri, .version = null },
            .edits = edit_slice,
        };

        try actions.append(gpa, .{
            .title = title,
            .kind = proto.CodeActionKind.QuickFix,
            .edit = .{ .documentChanges = doc_edit_slice },
        });

        i = close_idx;
    }
}

fn addMissingImportActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    idx: *index_mod.ProjectIndex,
) !void {
    // Find identifiers on the selected line(s) that are not in bindings.
    const decl_kws = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface, .@"var" };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        if (tok.kind != .identifier) continue;

        const tok_line: u32 = @intCast(tok.line -| 1);
        if (tok_line < range.start.line or tok_line > range.end.line) continue;

        // Skip if it's a declaration name (preceded by val/fn/etc).
        if (i > 0) {
            var is_decl_name = false;
            for (decl_kws) |k| {
                if (tokens[i - 1].kind == k) {
                    is_decl_name = true;
                    break;
                }
            }
            if (is_decl_name) continue;
        }

        // Skip if it's in bindings.
        var in_bindings = false;
        for (bindings) |b| {
            if (std.mem.eql(u8, b.name, tok.lexeme)) {
                in_bindings = true;
                break;
            }
        }
        if (in_bindings) continue;

        // Skip common keywords/builtins that aren't real identifiers.
        if (isKeyword(tok.lexeme)) continue;
        if (std.mem.eql(u8, tok.lexeme, "self")) continue;
        if (std.mem.eql(u8, tok.lexeme, "print")) continue;
        if (std.mem.eql(u8, tok.lexeme, "console")) continue;

        // Check if the project index has this symbol.
        const sym = idx.findSymbol(tok.lexeme) orelse continue;

        // Don't suggest importing from the current file.
        if (std.mem.eql(u8, sym.uri, uri)) continue;

        const title = std.fmt.allocPrint(gpa, "Import '{s}' from \"{s}\"", .{ tok.lexeme, sym.module_name }) catch continue;

        // Build the import statement: `use { name } from "module";\n`
        const import_text = std.fmt.allocPrint(gpa, "use {{ {s} }} from \"{s}\";\n", .{ tok.lexeme, sym.module_name }) catch continue;

        // Insert at the top of the file (line 0, char 0).
        const edit_slice = gpa.alloc(proto.TextEdit, 1) catch continue;
        edit_slice[0] = .{
            .range = .{ .start = .{ .line = 0, .character = 0 }, .end = .{ .line = 0, .character = 0 } },
            .newText = import_text,
        };

        const doc_edit_slice = gpa.alloc(proto.TextDocumentEdit, 1) catch continue;
        doc_edit_slice[0] = .{
            .textDocument = .{ .uri = uri, .version = null },
            .edits = edit_slice,
        };

        try actions.append(gpa, .{
            .title = title,
            .kind = proto.CodeActionKind.QuickFix,
            .edit = .{ .documentChanges = doc_edit_slice },
        });
    }
}

// ── Module completion ────────────────────────────────────────────────────────

pub fn moduleCompletion(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    idx: *index_mod.ProjectIndex,
) !?[]proto.CompletionItem {
    const offset = lsp_types.positionToOffset(source, pos);

    // Check if cursor is inside `use ... from "..."` by looking for `from` + `"` before cursor.
    if (!cursorInFromString(source, offset)) return null;

    const module_names = idx.getModuleNames();
    if (module_names.len == 0) return null;

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| gpa.free(it.label);
        items.deinit(gpa);
    }

    for (module_names) |name| {
        try items.append(gpa, .{
            .label = try gpa.dupe(u8, name),
            .kind = proto.CompletionItemKind.Module,
            .detail = null,
        });
    }

    const slice = try items.toOwnedSlice(gpa);
    return slice;
}

fn cursorInFromString(source: []const u8, offset: usize) bool {
    // Walk backward from cursor to find opening `"` then `from`.
    var i = offset;
    if (i > 0 and source[i - 1] == '"') i -= 1; // skip quote at cursor
    while (i > 0 and i < source.len and source[i] != '"') {
        if (source[i] == '\n') return false;
        i -= 1;
    }
    if (i == 0 or source[i] != '"') return false;
    // Now walk backward past whitespace to find `from`.
    var j = i;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j < 4) return false;
    return std.mem.eql(u8, source[j - 4 .. j], "from");
}

// ── Cross-module references ──────────────────────────────────────────────────

pub fn crossModuleReferences(
    gpa: std.mem.Allocator,
    io: std.Io,
    source: []const u8,
    pos: proto.Position,
    current_uri: []const u8,
    current_tokens: []const Token,
    include_declaration: bool,
    idx: *index_mod.ProjectIndex,
) ![]proto.Location {
    const name = identAt(source, pos) orelse return &.{};

    var locs: std.ArrayList(proto.Location) = .empty;
    errdefer {
        for (locs.items) |l| gpa.free(l.uri);
        locs.deinit(gpa);
    }

    // First add references from the current file.
    const local_refs = try references(gpa, current_uri, source, pos, current_tokens, include_declaration);
    defer gpa.free(local_refs);
    for (local_refs) |loc| {
        try locs.append(gpa, loc);
    }

    // Collect unique URIs of files that have matching symbols.
    var seen_uris: std.StringHashMap(void) = .init(gpa);
    defer seen_uris.deinit();
    try seen_uris.put(current_uri, {});

    const all_syms = idx.getAllSymbols();
    for (all_syms) |sym| {
        if (seen_uris.contains(sym.uri)) continue;
        if (!std.mem.eql(u8, sym.name, name)) continue;
        try seen_uris.put(sym.uri, {});
    }

    // Re-lex each external file and find exact positions of every identifier match.
    var it = seen_uris.keyIterator();
    while (it.next()) |key_ptr| {
        const ext_uri = key_ptr.*;
        if (std.mem.eql(u8, ext_uri, current_uri)) continue;

        const ext_path = lsp_types.uriToPath(ext_uri);
        const cwd = std.Io.Dir.cwd();
        const ext_source = cwd.readFileAlloc(io, ext_path, gpa, .limited(10 * 1024 * 1024)) catch continue;
        defer gpa.free(ext_source);

        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();

        var lexer = Lexer.init(ext_source);
        const ext_tokens = lexer.scanAll(arena.allocator()) catch continue;

        for (ext_tokens) |tok| {
            if (tok.kind != .identifier) continue;
            if (!std.mem.eql(u8, tok.lexeme, name)) continue;

            const start = lsp_types.locToPosition(tok.line, tok.col);
            const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
            try locs.append(gpa, .{
                .uri = try gpa.dupe(u8, ext_uri),
                .range = .{ .start = start, .end = end },
            });
        }
    }

    return locs.toOwnedSlice(gpa);
}

/// Cross-module rename: applies rename in current file + all external files
/// that reference the symbol. Returns a list of (uri, edits) pairs encoded
/// as a JSON body for the WorkspaceEdit response.
pub fn crossModuleRename(
    gpa: std.mem.Allocator,
    io: std.Io,
    source: []const u8,
    pos: proto.Position,
    new_name: []const u8,
    current_uri: []const u8,
    current_tokens: []const Token,
    idx: *index_mod.ProjectIndex,
) !CrossModuleRenameResult {
    const name = identAt(source, pos) orelse return .{ .entries = &.{} };

    var entries: std.ArrayList(RenameFileEntry) = .empty;
    errdefer {
        for (entries.items) |e| {
            gpa.free(e.uri);
            gpa.free(e.edits);
        }
        entries.deinit(gpa);
    }

    // Current file edits.
    const cur_edits = try rename(gpa, source, pos, new_name, current_tokens);
    if (cur_edits.len > 0) {
        try entries.append(gpa, .{
            .uri = try gpa.dupe(u8, current_uri),
            .edits = cur_edits,
        });
    }

    // External files.
    var seen_uris: std.StringHashMap(void) = .init(gpa);
    defer seen_uris.deinit();
    try seen_uris.put(current_uri, {});

    const all_syms = idx.getAllSymbols();
    for (all_syms) |sym| {
        if (seen_uris.contains(sym.uri)) continue;
        if (!std.mem.eql(u8, sym.name, name)) continue;
        try seen_uris.put(sym.uri, {});
    }

    var it = seen_uris.keyIterator();
    while (it.next()) |key_ptr| {
        const ext_uri = key_ptr.*;
        if (std.mem.eql(u8, ext_uri, current_uri)) continue;

        const ext_path = lsp_types.uriToPath(ext_uri);
        const cwd = std.Io.Dir.cwd();
        const ext_source = cwd.readFileAlloc(io, ext_path, gpa, .limited(10 * 1024 * 1024)) catch continue;
        defer gpa.free(ext_source);

        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();

        var lexer = Lexer.init(ext_source);
        const ext_tokens = lexer.scanAll(arena.allocator()) catch continue;

        var file_edits: std.ArrayList(proto.TextEdit) = .empty;
        for (ext_tokens) |tok| {
            if (tok.kind != .identifier) continue;
            if (!std.mem.eql(u8, tok.lexeme, name)) continue;

            const start = lsp_types.locToPosition(tok.line, tok.col);
            const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
            file_edits.append(gpa, .{
                .range = .{ .start = start, .end = end },
                .newText = new_name,
            }) catch continue;
        }

        if (file_edits.items.len > 0) {
            try entries.append(gpa, .{
                .uri = try gpa.dupe(u8, ext_uri),
                .edits = try file_edits.toOwnedSlice(gpa),
            });
        } else {
            file_edits.deinit(gpa);
        }
    }

    return .{ .entries = try entries.toOwnedSlice(gpa) };
}

pub const RenameFileEntry = struct {
    uri: []const u8,
    edits: []const proto.TextEdit,
};

pub const CrossModuleRenameResult = struct {
    entries: []const RenameFileEntry,
};

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
                if (depth == 0) {
                    paren_idx = i;
                    break;
                }
                depth -= 1;
            },
            ',' => if (depth == 0) {
                active_param += 1;
            },
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

    const decl_values = [_]TokenKind{ .val, .@"fn" };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl = false;
        for (decl_values) |k| {
            if (tok.kind == k) {
                is_decl = true;
                break;
            }
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

        if (!posInRange(hint_pos, range)) {
            i = j;
            continue;
        }

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
///
/// Returns an empty slice when the cursor is inside a string literal or when
/// the cursor is positioned on / immediately before a numeric literal.
pub fn completion(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    const offset = lsp_types.positionToOffset(source, pos);

    // ── guard: cursor inside a string literal ─────────────────────────────────
    if (cursorInString(source, offset))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── guard: cursor inside a comment ────────────────────────────────────────
    if (cursorInComment(source, pos))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── guard: cursor on a numeric literal ────────────────────────────────────
    // Case A: prefix itself starts with a digit (cursor is inside/after a number).
    // Case B: prefix is empty but the character at the cursor is a digit
    //         (cursor is just before a number literal, e.g. `{ |42 }`).
    const prefix = prefixAt(source, pos);
    if (prefix.len > 0 and isDigit(prefix[0]))
        return gpa.alloc(proto.CompletionItem, 0);
    if (prefix.len == 0 and offset < source.len and isDigit(source[offset]))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── dot-completion: `expr.` triggers member completion ───────────────────
    const dot_ctx = dotContext(source, offset);
    if (dot_ctx) |ctx| {
        return dotCompletion(gpa, ctx.receiver, bindings);
    }

    // ── labeled argument completion: inside `fn_name(|)` suggest param labels
    if (prefix.len == 0 or (prefix.len > 0 and !isDigit(prefix[0]))) {
        const label_items = try labeledArgCompletion(gpa, source, offset, prefix, bindings);
        if (label_items.len > 0) return label_items;
    }

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
            .sortText = bindingSortText(b),
        });
    }

    return items.toOwnedSlice(gpa);
}

// ── Dot-completion helpers ───────────────────────────────────────────────────

const DotCompletionContext = struct {
    receiver: []const u8,
};

fn labeledArgCompletion(
    gpa: std.mem.Allocator,
    source: []const u8,
    offset: usize,
    prefix: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    // Walk backwards to find the opening `(` at depth 0.
    var depth: u32 = 0;
    var paren_idx: ?usize = null;
    var i: usize = offset;
    while (i > 0) {
        i -= 1;
        switch (source[i]) {
            ')', ']' => depth += 1,
            '[' => {
                if (depth == 0) break;
                depth -= 1;
            },
            '(' => {
                if (depth == 0) {
                    paren_idx = i;
                    break;
                }
                depth -= 1;
            },
            else => {},
        }
    }

    const paren = paren_idx orelse return gpa.alloc(proto.CompletionItem, 0);

    // Find the function name before `(`.
    var j = paren;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j == 0 or !isIdentCont(source[j - 1])) return gpa.alloc(proto.CompletionItem, 0);
    const name_end = j;
    while (j > 0 and isIdentCont(source[j - 1])) j -= 1;
    const fn_name = source[j..name_end];

    // Find the binding for this function.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, fn_name)) continue;
        switch (b.decl) {
            .@"fn" => |f| {
                var items: std.ArrayList(proto.CompletionItem) = .empty;
                errdefer {
                    for (items.items) |it| {
                        gpa.free(it.label);
                        if (it.detail) |d| gpa.free(d);
                    }
                    items.deinit(gpa);
                }
                for (f.params) |p| {
                    if (std.mem.eql(u8, p.name, "self")) continue;
                    if (prefix.len > 0 and !std.mem.startsWith(u8, p.name, prefix)) continue;
                    const label = try std.fmt.allocPrint(gpa, "{s}:", .{p.name});
                    try items.append(gpa, .{
                        .label = label,
                        .kind = proto.CompletionItemKind.Field,
                        .detail = null,
                        .insertText = try std.fmt.allocPrint(gpa, "{s}: ", .{p.name}),
                    });
                }
                return items.toOwnedSlice(gpa);
            },
            else => {},
        }
        break;
    }

    return gpa.alloc(proto.CompletionItem, 0);
}

fn dotContext(source: []const u8, offset: usize) ?DotCompletionContext {
    if (offset == 0) return null;
    if (source[offset - 1] != '.') {
        // Check if there's a prefix after the dot: `foo.ba|`
        const end = offset;
        var start = offset;
        while (start > 0 and isIdentCont(source[start - 1])) start -= 1;
        if (start == end) return null; // no prefix
        if (start == 0 or source[start - 1] != '.') return null;
        // Found `receiver.prefix` — we want `receiver` for member lookup
        const dot_pos = start - 1;
        if (dot_pos == 0) return null;
        const recv_end = dot_pos;
        var recv_start = recv_end;
        while (recv_start > 0 and isIdentCont(source[recv_start - 1])) recv_start -= 1;
        if (recv_start == recv_end) return null;
        return .{ .receiver = source[recv_start..recv_end] };
    }
    // Cursor is right after the dot: `foo.|`
    const dot_pos = offset - 1;
    if (dot_pos == 0) return null;
    const recv_end = dot_pos;
    var recv_start = recv_end;
    while (recv_start > 0 and isIdentCont(source[recv_start - 1])) recv_start -= 1;
    if (recv_start == recv_end) return null;
    return .{ .receiver = source[recv_start..recv_end] };
}

fn dotCompletion(
    gpa: std.mem.Allocator,
    receiver_name: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }

    // Find the type of the receiver.
    var receiver_type_name: ?[]const u8 = null;
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, receiver_name)) continue;
        const t = b.type_.deref();
        if (t.* == .named) {
            receiver_type_name = t.named.name;
        }
        break;
    }

    const type_name = receiver_type_name orelse {
        // Receiver might be a type name itself (e.g., `Status.Active`).
        // Check if any binding has that name as a type declaration.
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, receiver_name)) continue;
            switch (b.decl) {
                .@"enum" => |e| {
                    for (e.variants) |v| {
                        try items.append(gpa, .{
                            .label = try gpa.dupe(u8, v.name),
                            .kind = proto.CompletionItemKind.EnumMember,
                            .detail = null,
                        });
                    }
                },
                else => {},
            }
            break;
        }
        return items.toOwnedSlice(gpa);
    };

    // Find the type declaration and list its members.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, type_name)) continue;
        switch (b.decl) {
            .record => |r| {
                for (r.fields) |field| {
                    try items.append(gpa, .{
                        .label = try gpa.dupe(u8, field.name),
                        .kind = proto.CompletionItemKind.Field,
                        .detail = null,
                    });
                }
                for (r.methods) |method| {
                    try items.append(gpa, .{
                        .label = try gpa.dupe(u8, method.name),
                        .kind = proto.CompletionItemKind.Method,
                        .detail = null,
                    });
                }
            },
            .@"struct" => |s| {
                for (s.members) |member| {
                    switch (member) {
                        .field => |field| try items.append(gpa, .{
                            .label = try gpa.dupe(u8, field.name),
                            .kind = proto.CompletionItemKind.Field,
                            .detail = null,
                        }),
                        .method => |method| try items.append(gpa, .{
                            .label = try gpa.dupe(u8, method.name),
                            .kind = proto.CompletionItemKind.Method,
                            .detail = null,
                        }),
                        .getter => |getter| try items.append(gpa, .{
                            .label = try gpa.dupe(u8, getter.name),
                            .kind = proto.CompletionItemKind.Property,
                            .detail = null,
                        }),
                        .setter => |setter| try items.append(gpa, .{
                            .label = try gpa.dupe(u8, setter.name),
                            .kind = proto.CompletionItemKind.Property,
                            .detail = null,
                        }),
                    }
                }
            },
            .@"enum" => |e| {
                for (e.variants) |v| {
                    try items.append(gpa, .{
                        .label = try gpa.dupe(u8, v.name),
                        .kind = proto.CompletionItemKind.EnumMember,
                        .detail = null,
                    });
                }
                for (e.methods) |method| {
                    try items.append(gpa, .{
                        .label = try gpa.dupe(u8, method.name),
                        .kind = proto.CompletionItemKind.Method,
                        .detail = null,
                    });
                }
            },
            else => {},
        }
        break;
    }

    return items.toOwnedSlice(gpa);
}

/// Returns true if `offset` (byte index into `source`) falls inside a
/// double-quoted string literal.  Handles `\"` escapes; strings cannot span
/// newlines so a bare `\n` also closes an open string.
fn cursorInString(source: []const u8, offset: usize) bool {
    var in_string = false;
    var i: usize = 0;
    while (i < offset) {
        const c = source[i];
        if (in_string) {
            if (c == '\\' and i + 1 < source.len) {
                i += 2; // skip escape sequence
                continue;
            }
            if (c == '"' or c == '\n') in_string = false;
        } else {
            if (c == '"') in_string = true;
        }
        i += 1;
    }
    return in_string;
}

/// Returns true if the cursor at `pos` is inside a line comment (`//`).
/// Locates the start of the cursor's line and scans forward until the cursor
/// position to check if `//` appears before it (outside of a string).
fn cursorInComment(source: []const u8, pos: proto.Position) bool {
    const offset = lsp_types.positionToOffset(source, pos);

    // Find the start of the current line
    var line_start: usize = offset;
    while (line_start > 0 and source[line_start - 1] != '\n') {
        line_start -= 1;
    }

    // Scan from line start to cursor position
    var in_string = false;
    var i: usize = line_start;
    while (i < offset) {
        const c = source[i];

        // Track string state (but don't care about closing strings here)
        if (in_string) {
            if (c == '\\' and i + 1 < offset) {
                i += 2; // skip escape sequence
                continue;
            }
            if (c == '"') in_string = false;
        } else {
            if (c == '"') {
                in_string = true;
            } else if (c == '/' and i + 1 < offset and source[i + 1] == '/') {
                // Found `//` before cursor position (and not inside a string)
                return true;
            }
        }
        i += 1;
    }

    return false;
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
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

fn bindingSortText(b: comptime_pipeline.TypedBinding) []const u8 {
    return switch (b.decl) {
        .@"fn" => "0",
        .val => "1",
        .record, .@"struct" => "2",
        .@"enum" => "2",
        .interface => "3",
        else => "4",
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

    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    for (tokens, 0..) |tok, i| {
        if (tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, tok.lexeme, name)) continue;

        // Check if this token is a declaration name (previous token is a keyword).
        const is_decl = blk: {
            if (i == 0) break :blk false;
            const prev = tokens[i - 1];
            for (decl_values) |k| {
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
