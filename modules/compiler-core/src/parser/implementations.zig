//! Decision 575 (6) — a declaration's `#[external(…)]` sources, read into its
//! `implementations`.
//!
//! `external` is std's function `external(syntax decl: unknown, comptime
//! ..sources: Implementation[])` (`libs/std/src/external.bp`), whose body hands
//! each source to `compiler.implement`. Its sources are values of the enum
//! `Implementation`, written as its constructor — `.Erlang("lists:member($1,
//! $0)")`, `.Wasm(op: "f64.floor")`, `Implementation.JavaScript("…", result:
//! true)` —, so what the body implements is what the annotation writes: this
//! pass reads each source where the parser stands (one per parse, the prelude's
//! included, so every backend reads `implementations` alone) and the checker
//! checks each one as the constructor (`comptime/implementations.zig`), which
//! also adds what a library's own source annotation implemented.
//!
//! The reading is lenient: a source of another shape — a label the variant
//! does not declare, a value of another kind — gives what it can, and the
//! checker refuses it at the argument. A template's markers are translated to
//! the renderers' receiver convention here (`template_markers.rewrite`, decision
//! 5), and `$self`, `$stringify` and an out-of-range `$N` are refused.
const std = @import("std");
const ast = @import("../ast.zig");
const lexerMod = @import("../lexer.zig");
const token = @import("../lexer/token.zig");
const template_markers = @import("template_markers.zig");

const Token = token.Token;

/// The name std's source annotation is written with (`#[external(…)]`,
/// `#[@external(…)]` outside std).
pub const annotation_name = "external";

/// True when `a` is `#[external(…)]` / `#[@external(…)]`.
pub fn isSourceAnnotation(a: ast.Annotation) bool {
    return std.mem.eql(u8, a.name, annotation_name);
}

/// Each variant's fields in declaration order (`libs/std/src/external.bp`,
/// kept in step by the test below): a positional argument fills the next one.
pub const variant_fields = [_]struct { target: ast.Implementation.Target, fields: []const []const u8 }{
    .{ .target = .erlang, .fields = &.{ "template", "body", "inline", "result" } },
    .{ .target = .javascript, .fields = &.{ "template", "body", "result" } },
    .{ .target = .wasm, .fields = &.{ "template", "op", "std", "wasi", "body", "host", "needs", "result" } },
};

pub fn fieldsOf(target: ast.Implementation.Target) []const []const u8 {
    for (variant_fields) |v| if (v.target == target) return v.fields;
    unreachable;
}

/// One argument of a source, as written.
pub const Arg = struct {
    /// The field it fills: its label, or the declared field at its position
    /// (null past the last).
    field: ?[]const u8,
    /// Whether it was written with a label.
    labelled: bool,
    /// Its tokens.
    tokens: []const Token,
    /// Where it starts (the label's position when labelled).
    loc: ast.Loc,
};

/// A source as written: `.<Variant>(<args>)`.
pub const Source = struct {
    /// The variant's name as written (`Erlang`).
    variant: []const u8,
    target: ?ast.Implementation.Target,
    /// Where the variant's name is written.
    variantLoc: ast.Loc,
    args: []const Arg,
};

/// `text` (one argument of `#[external(…)]`, a slice of the source starting at
/// `at`) as a source, or null when it is no `.<Variant>(…)` call.
pub fn parseSource(alloc: std.mem.Allocator, text: []const u8, at: ast.Loc) !?Source {
    var lx = lexerMod.Lexer.init(text);
    const all = lx.scanAll(alloc) catch return null;
    var toks: std.ArrayListUnmanaged(Token) = .empty;
    for (all) |t| switch (t.kind) {
        .commentNormal, .commentDoc, .commentModule => {},
        .endOfFile => break,
        else => try toks.append(alloc, t),
    };
    const ts = toks.items;
    // `.<Variant>(`, `Implementation.<Variant>(`, `external.Implementation.<Variant>(`.
    var i: usize = 0;
    var name: ?Token = null;
    while (i < ts.len and ts[i].kind != .leftParenthesis) : (i += 1) {
        if (ts[i].kind == .identifier) name = ts[i] else if (ts[i].kind != .dot) return null;
    }
    const variant = name orelse return null;
    if (i >= ts.len) return null;
    i += 1; // `(`
    var args: std.ArrayListUnmanaged(Arg) = .empty;
    var position: usize = 0;
    const target = ast.Implementation.Target.ofVariant(variant.lexeme);
    while (i < ts.len and ts[i].kind != .rightParenthesis) {
        const start = i;
        var label: ?[]const u8 = null;
        if (i + 1 < ts.len and ts[i + 1].kind == .colon and (ts[i].kind == .identifier or isWord(ts[i].lexeme))) {
            label = ts[i].lexeme;
            i += 2;
        }
        const value_start = i;
        var depth: usize = 0;
        while (i < ts.len) : (i += 1) {
            const k = ts[i].kind;
            if (k == .leftParenthesis or k == .leftSquareBracket or k == .leftBrace) depth += 1;
            if (k == .rightParenthesis or k == .rightSquareBracket or k == .rightBrace) {
                if (depth == 0) break;
                depth -= 1;
            }
            if (k == .comma and depth == 0) break;
        }
        const field: ?[]const u8 = if (label) |l| l else blk: {
            const fields = if (target) |t| fieldsOf(t) else &[_][]const u8{};
            defer position += 1;
            break :blk if (position < fields.len) fields[position] else null;
        };
        try args.append(alloc, .{
            .field = field,
            .labelled = label != null,
            .tokens = ts[value_start..i],
            .loc = locIn(at, ts[start]),
        });
        if (i < ts.len and ts[i].kind == .comma) i += 1;
    }
    return .{
        .variant = variant.lexeme,
        .target = target,
        .variantLoc = locIn(at, variant),
        .args = args.items,
    };
}

/// A keyword written as a label (`body:` is no keyword; a reserved word before
/// `:` can only be a label).
fn isWord(lexeme: []const u8) bool {
    if (lexeme.len == 0) return false;
    for (lexeme) |c| if (!std.ascii.isAlphanumeric(c) and c != '_') return false;
    return std.ascii.isAlphabetic(lexeme[0]);
}

/// The location of `t`, a token of a text that starts at `at` in the file.
pub fn locIn(at: ast.Loc, t: Token) ast.Loc {
    if (t.line <= 1) return .{ .line = at.line, .col = at.col + t.col - 1, .expansion = at.expansion };
    return .{ .line = at.line + t.line - 1, .col = t.col, .expansion = at.expansion };
}

/// The one string literal of `toks`, raw (quotes included), or null.
pub fn stringOf(toks: []const Token) ?[]const u8 {
    if (toks.len != 1) return null;
    return switch (toks[0].kind) {
        .stringLiteral, .multilineStringLiteral => toks[0].lexeme,
        else => null,
    };
}

/// `.Name` → `Name`, or null.
pub fn enumValueOf(toks: []const Token) ?[]const u8 {
    if (toks.len != 2 or toks[0].kind != .dot or toks[1].kind != .identifier) return null;
    return toks[1].lexeme;
}

/// `true` / `false`, or null.
pub fn boolOf(toks: []const Token) ?bool {
    if (toks.len != 1) return null;
    if (std.mem.eql(u8, toks[0].lexeme, "true")) return true;
    if (std.mem.eql(u8, toks[0].lexeme, "false")) return false;
    return null;
}

/// A bare identifier, or null.
pub fn identOf(toks: []const Token) ?[]const u8 {
    if (toks.len != 1 or toks[0].kind != .identifier) return null;
    return toks[0].lexeme;
}

/// The `.Name` items of a `[.A, .B]` list, or null when it is no list of them.
pub fn enumListOf(alloc: std.mem.Allocator, toks: []const Token) !?[]const []const u8 {
    if (toks.len < 2 or toks[0].kind != .leftSquareBracket or toks[toks.len - 1].kind != .rightSquareBracket) return null;
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var i: usize = 1;
    while (i + 1 < toks.len) {
        if (toks[i].kind == .comma) {
            i += 1;
            continue;
        }
        if (toks[i].kind != .dot or i + 2 >= toks.len or toks[i + 1].kind != .identifier) return null;
        try out.append(alloc, toks[i + 1].lexeme);
        i += 2;
    }
    return out.items;
}

pub const Failure = template_markers.Failure;

pub const Declared = struct {
    params: []const ast.Param,
    /// A method of a type or a behavior: `$0` is the receiver.
    method: bool,
};

/// Reads every `#[external(…)]` source of `annotations` into implementations,
/// in the order written, its templates' markers translated for `decl`.
/// `tokens` are the file's (for a refused marker's location).
pub fn read(alloc: std.mem.Allocator, tokens: []const Token, annotations: []const ast.Annotation, decl: Declared) !union(enum) { ok: []ast.Implementation, refused: Failure } {
    var scratch = std.heap.ArenaAllocator.init(alloc);
    defer scratch.deinit();
    const sa = scratch.allocator();
    var out: std.ArrayListUnmanaged(ast.Implementation) = .empty;
    errdefer {
        for (out.items) |*x| x.deinit(alloc);
        out.deinit(alloc);
    }
    for (annotations) |a| {
        if (!isSourceAnnotation(a)) continue;
        for (a.args, 0..) |arg, i| {
            const at = a.argLoc(i) orelse a.loc orelse ast.Loc{ .line = 0, .col = 0 };
            const src = (try parseSource(sa, arg, at)) orelse continue;
            const target = src.target orelse continue;
            switch (try implementationOf(alloc, src, target, decl)) {
                .ok => |impl| {
                    var x = impl;
                    x.loc = a.loc;
                    x.sourceLoc = at;
                    try out.append(alloc, x);
                },
                .refused => |r| {
                    return .{ .refused = .{ .kind = r.kind, .tok = template_markers.tokenOf(tokens, r.lexeme) } };
                },
            }
        }
    }
    return .{ .ok = try out.toOwnedSlice(alloc) };
}

const MarkerRefusal = struct { kind: @FieldType(Failure, "kind"), lexeme: []const u8 };

/// `src`'s value as an implementation (what the checker has not refused is
/// read; the rest is left at its default).
pub fn implementationOf(alloc: std.mem.Allocator, src: Source, target: ast.Implementation.Target, decl: Declared) !union(enum) { ok: ast.Implementation, refused: MarkerRefusal } {
    var impl: ast.Implementation = .{ .target = target };
    errdefer impl.deinit(alloc);
    for (src.args) |arg| {
        const field = arg.field orelse continue;
        if (std.mem.eql(u8, field, "template")) {
            const raw = stringOf(arg.tokens) orelse continue;
            if (impl.template != null) continue;
            const has_self = decl.params.len > 0 and std.mem.eql(u8, decl.params[0].name, "self");
            const shift = has_self and decl.method;
            const marked: []const u8 = switch (try template_markers.rewrite(alloc, raw, decl.params.len, shift, shift)) {
                .unchanged => try alloc.dupe(u8, raw),
                .rewritten => |t| t,
                .self_marker => return .{ .refused = .{ .kind = .selfMarker, .lexeme = raw } },
                .stringify_marker => return .{ .refused = .{ .kind = .stringifyMarker, .lexeme = raw } },
                .out_of_range => return .{ .refused = .{ .kind = .indexOutOfRange, .lexeme = raw } },
            };
            defer alloc.free(marked);
            // The template is a string: a `${` of the host's own (a JS
            // template literal) is written `\${`, the one escape the value
            // resolves; every other byte is the host's as written.
            impl.template = try std.mem.replaceOwned(u8, alloc, ast.unquoteAnnotationArg(marked), "\\${", "${");
        } else if (std.mem.eql(u8, field, "body")) {
            if (impl.cell != null) continue;
            const name = identOf(arg.tokens) orelse continue;
            impl.cell = .{ .kind = .body, .value = try alloc.dupe(u8, name) };
        } else if (std.mem.eql(u8, field, "op") or std.mem.eql(u8, field, "std")) {
            if (impl.cell != null) continue;
            const raw = stringOf(arg.tokens) orelse continue;
            impl.cell = .{ .kind = if (field[0] == 'o') .op else .std_, .value = try alloc.dupe(u8, ast.unquoteAnnotationArg(raw)) };
        } else if (std.mem.eql(u8, field, "wasi")) {
            if (impl.cell != null) continue;
            const name = enumValueOf(arg.tokens) orelse continue;
            impl.cell = .{ .kind = .wasi, .value = try ast.snakeOf(alloc, name) };
        } else if (std.mem.eql(u8, field, "host")) {
            const name = enumValueOf(arg.tokens) orelse continue;
            if (std.mem.eql(u8, name, "Wasi")) impl.host = .wasi;
            if (std.mem.eql(u8, name, "Browser")) impl.host = .browser;
        } else if (std.mem.eql(u8, field, "needs")) {
            var scratch = std.heap.ArenaAllocator.init(alloc);
            defer scratch.deinit();
            const items = (try enumListOf(scratch.allocator(), arg.tokens)) orelse continue;
            for (items) |item| {
                if (std.mem.eql(u8, item, "Exceptions")) impl.addNeed(.exceptions);
                if (std.mem.eql(u8, item, "Http")) impl.addNeed(.http);
                if (std.mem.eql(u8, item, "Gc")) impl.addNeed(.gc);
            }
        } else if (std.mem.eql(u8, field, "inline")) {
            impl.inline_ = boolOf(arg.tokens) orelse false;
        } else if (std.mem.eql(u8, field, "result")) {
            impl.result = boolOf(arg.tokens) orelse false;
        }
    }
    impl.text = if (impl.cell) |c|
        try std.fmt.allocPrint(alloc, "{s}:{s}", .{ c.kind.prefix(), c.value })
    else
        try alloc.dupe(u8, impl.template orelse "");
    return .{ .ok = impl };
}

/// Reads the implementations of every declaration of `program` (a `fn`, a
/// type's and a behavior's members), replacing what each held.
pub fn fillProgram(alloc: std.mem.Allocator, tokens: []const Token, program: *ast.Program) !?Failure {
    for (program.decls) |*d| switch (d.*) {
        .@"fn" => |*f| if (try fill(alloc, tokens, f.annotations, &f.implementations, .{ .params = f.params, .method = false })) |x| return x,
        .type_ => |*t| for (t.methods) |*m| {
            if (try fill(alloc, tokens, m.annotations, &m.implementations, .{ .params = m.params, .method = true })) |x| return x;
        },
        .behavior => |*b| for (b.methods) |*m| {
            if (try fill(alloc, tokens, m.annotations, &m.implementations, .{ .params = m.params, .method = true })) |x| return x;
        },
        else => {},
    };
    return null;
}

fn fill(alloc: std.mem.Allocator, tokens: []const Token, annotations: []const ast.Annotation, into: *[]ast.Implementation, decl: Declared) !?Failure {
    var any = false;
    for (annotations) |a| if (isSourceAnnotation(a)) {
        any = true;
    };
    if (!any) return null;
    switch (try read(alloc, tokens, annotations, decl)) {
        .ok => |impls| {
            ast.freeImplementations(alloc, into.*);
            into.* = impls;
            return null;
        },
        .refused => |f| return f,
    }
}

test "variant_fields: external.bp's `Implementation`, field for field" {
    const prelude = @import("std_prelude");
    const Parser = @import("../parser.zig").Parser;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var lx = lexerMod.Lexer.init(prelude.external);
    var p = Parser.init(try lx.scanAll(a));
    const program = try p.parse(a);
    var seen: usize = 0;
    for (program.decls) |d| if (d == .type_ and std.mem.eql(u8, d.type_.name, "Implementation")) {
        const variants = d.type_.variants();
        try std.testing.expectEqual(variant_fields.len, variants.len);
        for (variants) |v| {
            const target = ast.Implementation.Target.ofVariant(v.name) orelse return error.UnknownVariant;
            const want = fieldsOf(target);
            const got = v.fields;
            try std.testing.expectEqual(want.len, got.len);
            for (want, got) |w, g| try std.testing.expectEqualStrings(w, g.name);
            seen += 1;
        }
    };
    try std.testing.expectEqual(variant_fields.len, seen);
}

test "a source reads its template, its cell and its flags" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const at: ast.Loc = .{ .line = 3, .col = 12 };
    const src = (try parseSource(a, ".Wasm(op: \"f64.floor\", host: .Wasi, needs: [.Exceptions])", at)).?;
    const r = try implementationOf(a, src, src.target.?, .{ .params = &.{}, .method = false });
    try std.testing.expectEqual(ast.Implementation.CellKind.op, r.ok.cell.?.kind);
    try std.testing.expectEqualStrings("op:f64.floor", r.ok.text);
    try std.testing.expectEqual(ast.WasmHost.wasi, r.ok.host.?);
    try std.testing.expect(r.ok.needs().contains(.exceptions));
    const e = (try parseSource(a, "Implementation.Erlang(\"lists:reverse\", inline: true)", at)).?;
    const r2 = try implementationOf(a, e, e.target.?, .{ .params = &.{}, .method = false });
    try std.testing.expectEqualStrings("lists:reverse", r2.ok.template.?);
    try std.testing.expect(r2.ok.inline_);
    try std.testing.expectEqual(@as(usize, 3), e.variantLoc.line);
    try std.testing.expectEqual(@as(usize, 27), e.variantLoc.col);
}
