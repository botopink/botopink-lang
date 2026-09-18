/// Code formatter for botopink.
///
/// implements a Wadler-Lindig pretty-printer:
///   - Build a `Doc` IR from the AST via `Formatter`.
///   - Render to a string at a target line width via `render`.
///
/// Public entry point:
///   const out = try format.format(allocator, program);
///   defer allocator.free(out);
const std = @import("std");
const ast = @import("ast.zig");

pub const LINE_WIDTH: usize = 80;
pub const INDENT: usize = 4;

// ── Document IR ───────────────────────────────────────────────────────────────

/// Intermediate pretty-printer document.
/// Nodes are arena-allocated; build them through `Formatter` helpers.
pub const Doc = union(enum) {
    /// Empty document ---- produces no output.
    nil,
    /// Literal string slice (not owned).
    text: []const u8,
    /// Soft break: single space in flat mode, newline+indent in break mode.
    line,
    /// Zero-width break: nothing in flat mode, newline+indent in break mode.
    softline,
    /// Hard break: always newline+indent, regardless of mode.
    hardline,
    /// Two documents concatenated left-to-right.
    concat: struct { left: *const Doc, right: *const Doc },
    /// Increase the current indentation for the inner document.
    nest: struct { amount: usize, doc: *const Doc },
    /// Try to fit the inner document on one line (flat); fall back if it overflows.
    group: *const Doc,
    /// Force break mode for the inner document regardless of enclosing group.
    forceBreak: *const Doc,
};

// ── global singletons (zero-cost leaves) ──────────────────────────────────────

const DOC_NIL: Doc = .nil;
const DOC_LINE: Doc = .line;
const DOC_SOFTLINE: Doc = .softline;
const DOC_HARDLINE: Doc = .hardline;

// ── Formatter ─────────────────────────────────────────────────────────────────

/// Walks the AST and produces a `Doc` tree.
/// All `Doc` nodes are allocated in the provided arena; free the arena when done.
pub const Formatter = struct {
    arena: std.mem.Allocator,

    pub fn init(arena: std.mem.Allocator) Formatter {
        return .{ .arena = arena };
    }

    // ── low-level Doc constructors ─────────────────────────────────────────────

    fn alloc(this: *Formatter, doc: Doc) !*const Doc {
        const p = try this.arena.create(Doc);
        p.* = doc;
        return p;
    }

    pub fn nil(_: *Formatter) *const Doc {
        return &DOC_NIL;
    }

    pub fn text(this: *Formatter, s: []const u8) !*const Doc {
        return this.alloc(.{ .text = s });
    }

    pub fn line(_: *Formatter) *const Doc {
        return &DOC_LINE;
    }

    pub fn softline(_: *Formatter) *const Doc {
        return &DOC_SOFTLINE;
    }

    pub fn hardline(_: *Formatter) *const Doc {
        return &DOC_HARDLINE;
    }

    pub fn concat(this: *Formatter, left: *const Doc, right: *const Doc) !*const Doc {
        return this.alloc(.{ .concat = .{ .left = left, .right = right } });
    }

    pub fn nest(this: *Formatter, amount: usize, doc: *const Doc) !*const Doc {
        return this.alloc(.{ .nest = .{ .amount = amount, .doc = doc } });
    }

    pub fn group(this: *Formatter, doc: *const Doc) !*const Doc {
        return this.alloc(.{ .group = doc });
    }

    pub fn forceBreak(this: *Formatter, doc: *const Doc) !*const Doc {
        return this.alloc(.{ .forceBreak = doc });
    }

    // ── higher-level combinators ───────────────────────────────────────────────

    /// Concatenate a slice of documents left-to-right.
    fn concatAll(this: *Formatter, docs: []const *const Doc) !*const Doc {
        if (docs.len == 0) return this.nil();
        var acc = docs[docs.len - 1];
        var i = docs.len - 1;
        while (i > 0) {
            i -= 1;
            acc = try this.concat(docs[i], acc);
        }
        return acc;
    }

    /// Join documents with a separator in between.
    fn join(this: *Formatter, items: []const *const Doc, sep: *const Doc) !*const Doc {
        if (items.len == 0) return this.nil();
        var acc = items[0];
        for (items[1..]) |item| {
            acc = try this.concat(acc, try this.concat(sep, item));
        }
        return acc;
    }

    /// Like `join` but the separator is placed BETWEEN items (no trailing).
    fn joinWith(this: *Formatter, items: []const *const Doc, sep: *const Doc) !*const Doc {
        return this.join(items, sep);
    }

    /// `open inner close` with no breaks (for single-line formatting).
    fn surroundFlat(this: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return try this.concatAll(&.{
            try this.text(open),
            try this.text(" "),
            inner,
            try this.text(" "),
            try this.text(close),
        });
    }

    /// `open` + nest(INDENT, line + inner) + line + `close`, grouped.
    /// In flat mode: `open inner close`; in break mode: multi-line block.
    fn surround(this: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return this.group(try this.concatAll(&.{
            try this.text(open),
            try this.nest(INDENT, try this.concat(this.line(), inner)),
            this.line(),
            try this.text(close),
        }));
    }

    /// Like `surround` but always breaks (for bodies that are multi-statement).
    fn surroundBreak(this: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return this.forceBreak(try this.concatAll(&.{
            try this.text(open),
            try this.nest(INDENT, try this.concat(this.hardline(), inner)),
            this.hardline(),
            try this.text(close),
        }));
    }

    /// Comma-separated list grouped in `open`/`close` delimiters.
    /// In flat mode: `(a, b, c)` ---- no extra spaces inside.
    /// In break mode: each item on its own indented line.
    fn commaList(this: *Formatter, open: []const u8, items: []const *const Doc, close: []const u8) !*const Doc {
        if (items.len == 0) {
            return this.text(try std.fmt.allocPrint(this.arena, "{s}{s}", .{ open, close }));
        }
        // `line` after comma: space in flat, newline+indent in break.
        const commaLine = try this.concat(try this.text(","), this.line());
        const inner = try this.join(items, commaLine);
        // `softline` at boundaries: empty in flat, newline+indent in break.
        return this.group(try this.concatAll(&.{
            try this.text(open),
            try this.nest(INDENT, try this.concat(this.softline(), inner)),
            this.softline(),
            try this.text(close),
        }));
    }

    // ── parameter formatting ───────────────────────────────────────────────────

    fn fmtGenericParams(this: *Formatter, gps: []ast.GenericParam) !*const Doc {
        if (gps.len == 0) return this.nil();
        var items = try this.arena.alloc(*const Doc, gps.len);
        for (gps, 0..) |gp, i| {
            if (gp.default) |d| {
                const def = try this.fmtTypeRef(d);
                items[i] = try this.concatAll(&.{
                    try this.text(gp.name),
                    try this.text(" = "),
                    def,
                });
            } else {
                items[i] = try this.text(gp.name);
            }
        }
        return this.commaList("<", items, ">");
    }

    fn fmtImplementClause(this: *Formatter, impls: []const ast.TypeRef) anyerror!*const Doc {
        if (impls.len == 0) return this.nil();
        var parts = try this.arena.alloc(*const Doc, impls.len);
        for (impls, 0..) |im, i| parts[i] = try this.fmtTypeRef(im);
        const list = try this.joinWith(parts, try this.text(", "));
        return this.concatAll(&.{ try this.text("implement "), list, try this.text(" ") });
    }

    fn fmtFnType(this: *Formatter, ft: ast.FnType) !*const Doc {
        var items = try this.arena.alloc(*const Doc, ft.params.len);
        for (ft.params, 0..) |p, i| {
            items[i] = try this.text(try std.fmt.allocPrint(
                this.arena,
                "{s}: {s}",
                .{ p.name, p.typeName },
            ));
        }
        const paramsDoc = try this.commaList("(", items, ")");
        if (ft.returnType) |ret| {
            return this.concatAll(&.{
                try this.text("fn"),
                paramsDoc,
                try this.text(try std.fmt.allocPrint(this.arena, " -> {s}", .{ret})),
            });
        }
        return this.concat(try this.text("fn"), paramsDoc);
    }

    fn fmtParam(this: *Formatter, p: ast.Param) !*const Doc {
        // Destructuring param
        if (p.destruct) |d| {
            const patternDoc = switch (d) {
                .names => |*n| blk: {
                    var nameDocs = try this.arena.alloc(*const Doc, n.fields.len);
                    for (n.fields, 0..) |f, i| {
                        if (std.mem.eql(u8, f.field_name, f.bind_name)) {
                            nameDocs[i] = try this.text(f.bind_name);
                        } else {
                            nameDocs[i] = try this.concatAll(&.{
                                try this.text(f.field_name),
                                try this.text(": "),
                                try this.text(f.bind_name),
                            });
                        }
                    }
                    const namesList = try this.join(nameDocs, try this.text(", "));
                    const spreadPart: *const Doc = if (n.hasSpread)
                        try this.text(", ..")
                    else
                        this.nil();
                    break :blk try this.concatAll(&.{
                        try this.text("{ "),
                        namesList,
                        spreadPart,
                        try this.text(" }"),
                    });
                },
                .tuple_ => |t| blk: {
                    var nameDocs = try this.arena.alloc(*const Doc, t.len);
                    for (t, 0..) |nm, i| nameDocs[i] = try this.text(nm);
                    const namesList = try this.join(nameDocs, try this.text(", "));
                    break :blk try this.concatAll(&.{
                        try this.text("#("),
                        namesList,
                        try this.text(")"),
                    });
                },
                .list => |pat| try this.fmtPattern(pat),
                .ctor => |pat| try this.fmtPattern(pat),
            };
            return this.concatAll(&.{
                patternDoc,
                try this.text(": "),
                try this.fmtTypeRef(p.typeRef),
            });
        }
        const typeDoc: *const Doc = if (p.modifier == .syntax) blk: {
            if (p.fnType) |ft| break :blk try this.fmtFnType(ft);
            break :blk try this.fmtTypeRef(p.typeRef);
        } else try this.fmtTypeRef(p.typeRef);
        const defaultDoc: *const Doc = if (p.default) |d|
            try this.concat(try this.text(" = "), try this.fmtExpr(d))
        else
            this.nil();
        return switch (p.modifier) {
            .none => this.concatAll(&.{
                try this.text(p.name),
                try this.text(": "),
                typeDoc,
                defaultDoc,
            }),
            .@"comptime" => this.concatAll(&.{
                try this.text("comptime "),
                try this.text(p.name),
                try this.text(": "),
                typeDoc,
                defaultDoc,
            }),
            .syntax => this.concatAll(&.{
                try this.text(p.name),
                try this.text(" comptime: syntax "),
                typeDoc,
            }),
        };
    }

    fn fmtParams(this: *Formatter, params: []const ast.Param) !*const Doc {
        var items = try this.arena.alloc(*const Doc, params.len);
        for (params, 0..) |p, i| items[i] = try this.fmtParam(p);
        return this.commaList("(", items, ")");
    }

    fn fmtReturnType(this: *Formatter, ret: ?[]const u8) !*const Doc {
        if (ret) |r| return this.text(try std.fmt.allocPrint(this.arena, " -> {s}", .{r}));
        return this.nil();
    }

    fn fmtReturnTypeRef(this: *Formatter, ret: ?ast.TypeRef, typeGuardParam: ?[]const u8) !*const Doc {
        if (ret) |r| {
            if (typeGuardParam) |param| {
                return this.concatAll(&.{
                    try this.text(" -> "),
                    try this.text(param),
                    try this.text(" is "),
                    try this.fmtTypeRef(r),
                });
            }
            return this.concat(try this.text(" -> "), try this.fmtTypeRef(r));
        }
        return this.nil();
    }

    // ── body / statements ──────────────────────────────────────────────────────

    fn fmtBody(this: *Formatter, stmts: []ast.Stmt) !*const Doc {
        if (stmts.len == 0) return this.text("{}");
        return this.surroundBreak("{", try this.fmtStmtSeq(stmts), "}");
    }

    /// The statements of a block body — a `fn`, a lambda, a `loop` — one per
    /// line, each ended by `;` (a comment takes none); a blank source line is
    /// kept, and a comment written on the previous statement's line stays there.
    fn fmtStmtSeq(this: *Formatter, stmts: []ast.Stmt) !*const Doc {
        var items: std.ArrayList(*const Doc) = .empty;
        defer items.deinit(this.arena);

        for (stmts, 0..) |s, i| {
            if (i > 0 and s.expr == .literal and s.expr.literal.kind == .comment and s.expr.literal.kind.comment.trailing) {
                // A trailing comment stays at the end of the previous line.
                try items.append(this.arena, try this.text(" "));
                try items.append(this.arena, try this.fmtExpr(s.expr));
                continue;
            }
            if (i > 0 and s.emptyLinesBefore > 0) {
                // Emit plain "\n" (no indent) to create blank lines without trailing spaces
                for (0..s.emptyLinesBefore) |_| {
                    try items.append(this.arena, try this.text("\n"));
                }
            }
            if (i > 0) {
                // Add hardline before each statement after the first
                try items.append(this.arena, this.hardline());
            }
            const exprDoc = try this.fmtExpr(s.expr);
            const stmtDoc = switch (s.expr) {
                .literal => |lit| if (lit.kind == .comment) exprDoc else try this.concat(exprDoc, try this.text(";")),
                else => try this.concat(exprDoc, try this.text(";")),
            };
            try items.append(this.arena, stmtDoc);
        }
        return this.concatAll(items.items);
    }

    fn fmtOptionalBody(this: *Formatter, body: ?[]ast.Stmt) !*const Doc {
        if (body) |stmts| return this.fmtBody(stmts);
        return this.nil();
    }

    // ── expressions ───────────────────────────────────────────────────────────

    pub fn fmtExpr(this: *Formatter, expr: ast.Expr) anyerror!*const Doc {
        return switch (expr) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => |s| blk: {
                    // Check if string should be formatted as multiline (contains newlines)
                    if (needsTripleQuotes(s)) {
                        // Format as multiline string with triple quotes
                        // The content already includes the newlines from the source
                        break :blk this.text(try std.fmt.allocPrint(this.arena, "\"\"\"{s}\"\"\"", .{s}));
                    } else {
                        break :blk this.text(try std.fmt.allocPrint(this.arena, "\"{s}\"", .{s}));
                    }
                },
                .stringTemplate => |t| blk: {
                    const quote: []const u8 = if (t.multiline) "\"\"\"" else "\"";
                    var doc = try this.text(quote);
                    for (t.parts) |p| switch (p) {
                        .text => |txt| {
                            doc = try this.concat(doc, try this.text(txt));
                        },
                        .expr => |e| {
                            doc = try this.concat(doc, try this.text("${"));
                            doc = try this.concat(doc, try this.fmtExpr(e.*));
                            doc = try this.concat(doc, try this.text("}"));
                        },
                    };
                    break :blk this.concat(doc, try this.text(quote));
                },
                .numberLit => |n| this.text(n),
                .null_ => this.text("null"),
                .comment => |c| blk: {
                    const prefix = switch (c.kind) {
                        .normal => "//",
                        .doc => "///",
                        .module => "////",
                    };
                    break :blk this.text(try std.fmt.allocPrint(this.arena, "{s} {s}", .{ prefix, c.text }));
                },
            },
            .identifier => |id| switch (id.kind) {
                .ident => |name| this.text(name),
                .dotIdent => |name| this.text(
                    try std.fmt.allocPrint(this.arena, ".{s}", .{name}),
                ),
                .identAccess => |ia| this.concatAll(&.{
                    try this.fmtExpr(ia.receiver.*),
                    try this.text(if (ia.optional) "?." else "."),
                    try this.text(ia.member),
                }),
            },
            .binaryOp => |bin| this.fmtBinop(
                bin.lhs.*,
                switch (bin.op) {
                    .add => " + ",
                    .sub => " - ",
                    .mul => " * ",
                    .div => " / ",
                    .mod => " % ",
                    .lt => " < ",
                    .gt => " > ",
                    .lte => " <= ",
                    .gte => " >= ",
                    .eq => " == ",
                    .ne => " != ",
                    .@"and" => " && ",
                    .@"or" => " || ",
                },
                bin.rhs.*,
            ),
            .unaryOp => |un| switch (un.op) {
                .not => this.concat(try this.text("!"), try this.fmtExpr(un.expr.*)),
                .neg => this.concat(try this.text("-"), try this.fmtExpr(un.expr.*)),
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |e| if (e) |ep| this.concat(try this.text("return "), try this.fmtExpr(ep.*)) else this.text("return"),
                .throw_ => |e| if (e) |ep| this.concat(try this.text("throw "), try this.fmtExpr(ep.*)) else this.text("throw"),
                .try_ => |e| if (e) |ep| this.concat(try this.text("try "), try this.fmtExpr(ep.*)) else this.text("try"),
                .await_ => |e| this.concat(try this.text("await "), try this.fmtExpr(e.*)),
                .@"break" => |b| blk: {
                    const kw = if (b.label) |lbl|
                        try this.text(try std.fmt.allocPrint(this.arena, "break :{s}", .{lbl}))
                    else
                        try this.text("break");
                    if (b.value) |ep| {
                        const head = try this.concat(kw, try this.text(" "));
                        break :blk this.concat(head, try this.fmtExpr(ep.*));
                    }
                    break :blk kw;
                },
                .yield => |y| blk: {
                    const kw = if (y.label) |lbl|
                        try this.text(try std.fmt.allocPrint(this.arena, "yield :{s}", .{lbl}))
                    else
                        try this.text("yield");
                    if (y.value) |ep| {
                        const head = try this.concat(kw, try this.text(" "));
                        break :blk this.concat(head, try this.fmtExpr(ep.*));
                    }
                    break :blk kw;
                },
                .@"continue" => this.text("continue"),
            },
            .branch => |br| switch (br.kind) {
                .tryCatch => |tc| this.concatAll(&.{
                    try this.text("try "),
                    try this.fmtExpr(tc.expr.*),
                    try this.text(" catch "),
                    try this.fmtExpr(tc.handler.*),
                }),
                .if_ => |i| blk: {
                    const condDoc = try this.fmtExpr(i.cond.*);
                    // Build then block: with or without binding
                    const thenDoc = if (i.binding) |b| blk2: {
                        const body = try this.fmtBranchStmts(i.then_);
                        const inner = try this.concatAll(&.{
                            try this.text(b),
                            try this.text(" ->"),
                            this.hardline(),
                            body,
                        });
                        break :blk2 try this.surroundBreak("{", inner, "}");
                    } else blk2: {
                        // Single expression body — format without braces, unless it
                        // is itself an `if` and an `else` follows (the `else` would
                        // bind to the inner `if`).
                        const nestedIf = i.then_.len == 1 and i.then_[0].expr == .branch and i.then_[0].expr.branch.kind == .if_;
                        if (i.then_.len == 1 and !(nestedIf and i.else_ != null)) {
                            break :blk2 try this.fmtExpr(i.then_[0].expr);
                        }
                        // Multi-statement block: one statement per line, as written.
                        const inner = try this.fmtBranchStmts(i.then_);
                        break :blk2 try this.surroundBreak("{", inner, "}");
                    };
                    if (i.else_) |els| {
                        const elseDoc = if (els.len == 1)
                            try this.fmtExpr(els[0].expr)
                        else blk2: {
                            const inner = try this.fmtBranchStmts(els);
                            break :blk2 try this.surroundBreak("{", inner, "}");
                        };
                        break :blk this.concatAll(&.{
                            try this.text("if ("),
                            condDoc,
                            try this.text(") "),
                            thenDoc,
                            try this.text(" else "),
                            elseDoc,
                        });
                    }
                    break :blk this.concatAll(&.{
                        try this.text("if ("),
                        condDoc,
                        try this.text(") "),
                        thenDoc,
                    });
                },
            },
            .loop => |lp| blk: {
                // `loop [await] [:label] (...)`
                var head: []const u8 = "loop ";
                if (lp.awaitLoop) head = "loop await ";
                var doc: *const Doc = try this.text(head);
                if (lp.label) |lbl| {
                    doc = try this.concat(doc, try this.text(try std.fmt.allocPrint(this.arena, ":{s} ", .{lbl})));
                }
                doc = try this.concat(doc, try this.text("("));
                doc = try this.concat(doc, try this.fmtExpr(lp.iter.*));
                if (lp.indexRange) |ir| {
                    doc = try this.concat(doc, try this.text(", "));
                    doc = try this.concat(doc, try this.fmtExpr(ir.*));
                }
                doc = try this.concat(doc, try this.text(") {"));
                for (lp.params, 0..) |p, i| {
                    doc = try this.concat(doc, if (i == 0) try this.text(" ") else try this.text(", "));
                    doc = try this.concat(doc, try this.text(p));
                }
                // A condition loop (decision 8 §10) binds nothing: no `->`.
                if (lp.params.len > 0) doc = try this.concat(doc, try this.text(" ->"));
                // Each body statement keeps its `;` — printing them bare made a
                // loop of two statements unparseable.
                if (lp.body.len == 0) {
                    doc = try this.concat(doc, try this.text(" }"));
                    break :blk doc;
                }
                break :blk this.forceBreak(try this.concatAll(&.{
                    doc,
                    try this.nest(INDENT, try this.concat(this.hardline(), try this.fmtStmtSeq(lp.body))),
                    this.hardline(),
                    try this.text("}"),
                }));
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| if (lb.typeAnnotation) |ann| this.concatAll(&.{
                    try this.text(if (lb.mutable) "var " else "val "),
                    try this.text(lb.name),
                    try this.text(": "),
                    try this.fmtTypeRef(ann),
                    try this.text(" = "),
                    try this.fmtExpr(lb.value.*),
                }) else this.concatAll(&.{
                    try this.text(if (lb.mutable) "var " else "val "),
                    try this.text(lb.name),
                    try this.text(" = "),
                    try this.fmtExpr(lb.value.*),
                }),
                .assign => |a| blk: {
                    const targetDoc: *const Doc = switch (a.target) {
                        .name => |name| try this.text(name),
                        .fieldAccess => |fa| try this.concatAll(&.{
                            try this.fmtExpr(fa.receiver.*),
                            try this.text("."),
                            try this.text(fa.field),
                        }),
                    };
                    break :blk this.concatAll(&.{
                        targetDoc,
                        try this.text(if (a.op == .plusAssign) " += " else " = "),
                        try this.fmtExpr(a.value.*),
                    });
                },
                .localBindDestruct => |lb| blk: {
                    var doc: *const Doc = try this.text(if (lb.mutable) "var " else "val ");
                    doc = try this.concat(doc, try this.fmtParamDestruct(lb.pattern));
                    doc = try this.concat(doc, try this.text(" = "));
                    doc = try this.concat(doc, try this.fmtExpr(lb.value.*));
                    break :blk doc;
                },
            },
            .useHook => |uh| this.concat(try this.text("use "), try this.fmtExpr(uh.kind.inner.*)),
            .function => |func| switch (func.kind.syntax) {
                .lambda => try this.fmtLambdaAt(func.loc.line, func.kind.params, func.kind.body, true),
                .fnExpr => try this.fmtFnExpr(func.kind.params, func.kind.body),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| try this.fmtCall(cc),
                .pipeline => |op| blk: {
                    // Flatten left-associative pipeline chain: ((a |> b) |> c) |> d → [a, b, c, d]
                    // Also collect per-step comments (comment[i] is before |> items[i], i >= 1).
                    var items: std.ArrayList(ast.Expr) = .empty;
                    defer items.deinit(this.arena);
                    var stepComments: std.ArrayList(?[]const u8) = .empty;
                    defer stepComments.deinit(this.arena);
                    try items.append(this.arena, op.rhs.*);
                    try stepComments.append(this.arena, op.comment);
                    var lhs = op.lhs.*;
                    while (true) {
                        if (lhs != .call or lhs.call.kind != .pipeline) {
                            try items.append(this.arena, lhs);
                            try stepComments.append(this.arena, null); // first item has no preceding comment
                            break;
                        }
                        const inner = lhs.call.kind.pipeline;
                        try items.append(this.arena, inner.rhs.*);
                        try stepComments.append(this.arena, inner.comment);
                        lhs = inner.lhs.*;
                    }
                    std.mem.reverse(ast.Expr, items.items);
                    std.mem.reverse(?[]const u8, stepComments.items);

                    const hasAnyComment = for (stepComments.items) |sc| {
                        if (sc != null) break true;
                    } else false;

                    // Single-step pipeline (a |> b) with no comment: use group so short ones stay inline
                    // Multi-step or with comments: always multiline
                    var docs: std.ArrayList(*const Doc) = .empty;
                    defer docs.deinit(this.arena);
                    try docs.append(this.arena, try this.fmtExpr(items.items[0]));
                    if (items.items.len == 2 and !hasAnyComment) {
                        // Single step, no comment: use line() so group can choose flat mode
                        try docs.append(this.arena, try this.concat(this.line(), try this.text("|> ")));
                        try docs.append(this.arena, try this.fmtExpr(items.items[1]));
                        break :blk this.group(try this.concatAll(docs.items));
                    } else {
                        // Multi-step or with comments: always force multiline
                        var i: usize = 1;
                        while (i < items.items.len) : (i += 1) {
                            if (stepComments.items[i]) |cmt| {
                                try docs.append(this.arena, try this.concat(
                                    this.hardline(),
                                    try this.text(try std.fmt.allocPrint(this.arena, "// {s}", .{cmt})),
                                ));
                            }
                            try docs.append(this.arena, try this.concat(this.hardline(), try this.text("|> ")));
                            try docs.append(this.arena, try this.fmtExpr(items.items[i]));
                        }
                        break :blk this.forceBreak(try this.concatAll(docs.items));
                    }
                },
            },
            .collection => |coll| switch (coll.kind) {
                .grouped => |e| try this.concatAll(&.{
                    try this.text("("),
                    try this.fmtExpr(e.*),
                    try this.text(")"),
                }),
                // `record { name: value, … }` — anonymous record literal.
                .behaviorLit => |il| blk: {
                    var doc: *const Doc = try this.text("@");
                    doc = try this.concat(doc, try this.text(il.name));
                    doc = try this.concat(doc, try this.text("("));
                    for (il.fields, 0..) |f, i| {
                        if (i > 0) doc = try this.concat(doc, try this.text(", "));
                        doc = try this.concat(doc, try this.text(f.name));
                        doc = try this.concat(doc, try this.text(": "));
                        doc = try this.concat(doc, try this.fmtExpr(f.value.*));
                    }
                    break :blk try this.concat(doc, try this.text(")"));
                },
                .case => |c| try this.fmtCase(c.subjects, c.arms, c.trailingComments),
                .arrayLit => |al| blk: {
                    // Build items interleaving elements and comments.
                    // Elements on the same source line as the previous element (and with no preceding
                    // comments) are grouped on the same doc row (separated by a space, not a hardline).
                    var docs: std.ArrayList(*const Doc) = .empty;
                    defer docs.deinit(this.arena);

                    var commentIdx: usize = 0;
                    const hasComments = al.comments.len > 0;
                    const hasCounts = al.commentsPerElem.len > 0;

                    for (al.elems, 0..) |e, i| {
                        // Emit comments that appear before this element
                        const numCommentsBefore: usize = if (hasCounts and i < al.commentsPerElem.len)
                            al.commentsPerElem[i]
                        else
                            0;
                        for (0..numCommentsBefore) |_| {
                            if (commentIdx < al.comments.len) {
                                const cText = al.comments[commentIdx];
                                commentIdx += 1;
                                try docs.append(this.arena, try this.text(
                                    try std.fmt.allocPrint(this.arena, "// {s}", .{cText}),
                                ));
                            }
                        }
                        const elemDoc = try this.fmtExpr(e);
                        // In multi-line mode (trailingComma/comments), always add comma
                        const hasMore = (i < al.elems.len - 1) or (al.spread != null) or (al.spreadExpr != null);
                        const shouldAddComma = hasMore or al.trailingComma or hasComments;
                        const elemWithComma = if (shouldAddComma)
                            try this.concat(elemDoc, try this.text(","))
                        else
                            elemDoc;
                        // Group this element with the previous one if they share the same source line
                        // and this element has no preceding comments.
                        const sameLineAsPrev = i > 0 and numCommentsBefore == 0 and
                            e.getLoc().line == al.elems[i - 1].getLoc().line;
                        if (sameLineAsPrev and docs.items.len > 0) {
                            const prev = docs.items[docs.items.len - 1];
                            docs.items[docs.items.len - 1] = try this.concat(prev, try this.concat(try this.text(" "), elemWithComma));
                        } else {
                            try docs.append(this.arena, elemWithComma);
                        }
                    }
                    // Emit spread comments (commentsPerElem[elems.len])
                    const spreadCommentCount: usize = if (hasCounts and al.commentsPerElem.len > al.elems.len)
                        al.commentsPerElem[al.elems.len]
                    else
                        0;
                    for (0..spreadCommentCount) |_| {
                        if (commentIdx < al.comments.len) {
                            const cText = al.comments[commentIdx];
                            commentIdx += 1;
                            try docs.append(this.arena, try this.text(
                                try std.fmt.allocPrint(this.arena, "// {s}", .{cText}),
                            ));
                        }
                    }
                    // Emit trailing comments (commentsPerElem[elems.len + 1] or remaining)
                    const trailingCommentStart = commentIdx;
                    _ = trailingCommentStart;
                    const trailingCount: usize = if (hasCounts and al.commentsPerElem.len > al.elems.len + 1)
                        al.commentsPerElem[al.elems.len + 1]
                    else
                        al.comments.len - commentIdx;
                    for (0..trailingCount) |_| {
                        if (commentIdx < al.comments.len) {
                            const cText = al.comments[commentIdx];
                            commentIdx += 1;
                            try docs.append(this.arena, try this.text(
                                try std.fmt.allocPrint(this.arena, "// {s}", .{cText}),
                            ));
                        }
                    }

                    const hasSpread = al.spread != null or al.spreadExpr != null;
                    const spreadDoc: *const Doc = if (al.spreadExpr) |se| blk2: {
                        break :blk2 try this.concat(
                            try this.text(".."),
                            try this.fmtExpr(se.*),
                        );
                    } else if (al.spread) |name| blk2: {
                        break :blk2 try this.text(
                            try std.fmt.allocPrint(this.arena, "..{s}", .{name}),
                        );
                    } else this.nil();

                    if (al.elems.len == 0 and !hasSpread and !hasComments) {
                        break :blk try this.text("[]");
                    }

                    // If trailingComma or comments are set, force multi-line format
                    if (al.trailingComma or hasComments) {
                        // Add spread into docs so it gets proper indentation inside nest
                        if (hasSpread) {
                            try docs.append(this.arena, try this.concat(spreadDoc, try this.text(",")));
                        }
                        const inner = try this.join(docs.items, this.hardline());
                        break :blk try this.forceBreak(try this.concatAll(&.{
                            try this.text("["),
                            try this.nest(INDENT, try this.concat(this.hardline(), inner)),
                            this.hardline(),
                            try this.text("]"),
                        }));
                    }

                    // Otherwise, use group for flexible inline/multi-line
                    const inner = try this.join(docs.items, this.line());
                    break :blk this.group(try this.concatAll(&.{
                        try this.text("["),
                        try this.nest(INDENT, try this.concat(this.softline(), inner)),
                        if (spreadDoc != this.nil()) try this.concatAll(&.{ this.line(), spreadDoc }) else this.nil(),
                        this.softline(),
                        try this.text("]"),
                    }));
                },

                .tupleLit => |tl| blk: {
                    // Build items interleaving elements and comments
                    var items: std.ArrayList(*const Doc) = .empty;
                    defer items.deinit(this.arena);
                    var isComment: std.ArrayList(bool) = .empty;
                    defer isComment.deinit(this.arena);

                    const tlHasComments = tl.comments.len > 0;
                    const tlHasCounts = tl.commentsPerElem.len > 0;

                    var commentIdx: usize = 0;
                    for (tl.elems, 0..) |e, i| {
                        // Emit per-element comments using commentsPerElem if available
                        const numCommentsBefore: usize = if (tlHasCounts and i < tl.commentsPerElem.len)
                            tl.commentsPerElem[i]
                        else
                            0;
                        for (0..numCommentsBefore) |_| {
                            if (commentIdx < tl.comments.len) {
                                const cText = tl.comments[commentIdx];
                                commentIdx += 1;
                                try items.append(this.arena, try this.text(
                                    try std.fmt.allocPrint(this.arena, "// {s}", .{cText}),
                                ));
                                try isComment.append(this.arena, true);
                            }
                        }
                        const isLast = i == tl.elems.len - 1;
                        const elemDoc = try this.fmtExpr(e);
                        // In comment mode: attach comma to element doc (all args get trailing comma)
                        // In non-comment mode: no comma attached (separator handles it)
                        try items.append(this.arena, if (tlHasComments)
                            try this.concat(elemDoc, try this.text(","))
                        else
                            elemDoc);
                        _ = isLast;
                        try isComment.append(this.arena, false);
                    }
                    // Emit trailing comments
                    const trailingCount2: usize = if (tlHasCounts and tl.commentsPerElem.len > tl.elems.len)
                        tl.commentsPerElem[tl.elems.len]
                    else
                        tl.comments.len - commentIdx;
                    for (0..trailingCount2) |_| {
                        if (commentIdx < tl.comments.len) {
                            const cText = tl.comments[commentIdx];
                            commentIdx += 1;
                            try items.append(this.arena, try this.text(
                                try std.fmt.allocPrint(this.arena, "// {s}", .{cText}),
                            ));
                            try isComment.append(this.arena, true);
                        }
                    }

                    if (tl.elems.len == 0 and !tlHasComments) {
                        break :blk try this.text("#()");
                    }

                    if (tlHasComments) {
                        // In comment mode: all items separated by hardlines
                        var parts: std.ArrayList(*const Doc) = .empty;
                        defer parts.deinit(this.arena);
                        for (items.items, 0..) |item, i| {
                            if (i > 0) try parts.append(this.arena, this.hardline());
                            try parts.append(this.arena, item);
                        }
                        const inner = try this.concatAll(parts.items);
                        break :blk try this.forceBreak(try this.concatAll(&.{
                            try this.text("#("),
                            try this.nest(INDENT, try this.concat(this.hardline(), inner)),
                            this.hardline(),
                            try this.text(")"),
                        }));
                    }

                    // No comments: comma-separated
                    var parts: std.ArrayList(*const Doc) = .empty;
                    defer parts.deinit(this.arena);
                    for (items.items, 0..) |item, i| {
                        if (i > 0) {
                            try parts.append(this.arena, try this.concat(try this.text(","), this.line()));
                        }
                        try parts.append(this.arena, item);
                    }
                    const inner = try this.concatAll(parts.items);
                    break :blk this.group(try this.concatAll(&.{
                        try this.text("#("),
                        try this.nest(INDENT, try this.concat(this.softline(), inner)),
                        this.softline(),
                        try this.text(")"),
                    }));
                },

                .range => |r| if (r.end) |end|
                    this.concat(try this.fmtExpr(r.start.*), try this.concat(try this.text(".."), try this.fmtExpr(end.*)))
                else
                    this.concat(try this.fmtExpr(r.start.*), try this.text("..")),
            },
            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |e| this.concat(try this.text("comptime "), try this.fmtExpr(e.*)),

                .comptimeBlock => |cb| blk: {
                    var items = try this.arena.alloc(*const Doc, cb.body.len);
                    for (cb.body, 0..) |s, i| {
                        const exprDoc = try this.fmtExpr(s.expr);
                        items[i] = try this.concat(exprDoc, try this.text(";"));
                    }
                    const inner = try this.join(items, this.hardline());
                    break :blk this.concat(
                        try this.text("comptime "),
                        try this.surroundBreak("{", inner, "}"),
                    );
                },

                .assert => |a| blk: {
                    var doc: *const Doc = try this.text("assert ");
                    doc = try this.concat(doc, try this.fmtExpr(a.condition.*));
                    if (a.message) |msg| {
                        doc = try this.concat(doc, try this.text(", "));
                        doc = try this.concat(doc, try this.fmtExpr(msg.*));
                    }
                    break :blk doc;
                },
                .assertPattern => |ap| blk: {
                    // Pattern assertions are used as: val assert Pattern = expr catch handler
                    var doc: *const Doc = try this.text("val assert ");
                    doc = try this.concat(doc, try this.fmtPattern(ap.pattern));
                    doc = try this.concat(doc, try this.text(" = "));
                    doc = try this.concat(doc, try this.fmtExpr(ap.expr.*));
                    doc = try this.concat(doc, try this.text(" catch "));
                    doc = try this.concat(doc, try this.fmtExpr(ap.handler.*));
                    break :blk doc;
                },
            },
        };
    }

    fn fmtBinop(this: *Formatter, lhs: ast.Expr, op: []const u8, rhs: ast.Expr) !*const Doc {
        return this.concatAll(&.{
            try this.fmtExpr(lhs),
            try this.text(op),
            try this.fmtExpr(rhs),
        });
    }

    fn fmtCall(this: *Formatter, c: anytype) anyerror!*const Doc {
        // Tagged-call sugar round-trip: `callee "..."` (single string arg, no parens)
        const is_tagged = if (@hasField(@TypeOf(c), "is_tagged")) c.is_tagged else false;
        if (is_tagged and c.args.len == 1 and c.args[0].label == null) {
            const head: *const Doc = if (c.receiver) |recv|
                try this.concatAll(&.{
                    try this.fmtExpr(recv.*),
                    try this.text("."),
                    try this.text(c.callee),
                })
            else
                try this.text(c.callee);
            return this.concatAll(&.{
                head,
                try this.text(" "),
                try this.fmtExpr(c.args[0].value.*),
            });
        }
        // Build arg docs interleaving comments
        var items: std.ArrayList(*const Doc) = .empty;
        defer items.deinit(this.arena);
        var isComment: std.ArrayList(bool) = .empty;
        defer isComment.deinit(this.arena);

        for (c.args, 0..) |a, i| {
            _ = i;
            // Emit comments before this argument
            for (a.comments) |cmt| {
                try items.append(this.arena, try this.text(
                    try std.fmt.allocPrint(this.arena, "// {s}", .{cmt}),
                ));
                try isComment.append(this.arena, true);
            }
            const argDoc: *const Doc = if (a.label) |lbl|
                try this.concatAll(&.{
                    try this.text(lbl),
                    try this.text(": "),
                    try this.fmtExpr(a.value.*),
                })
            else
                try this.fmtExpr(a.value.*);
            try items.append(this.arena, argDoc);
            try isComment.append(this.arena, false);
        }

        const is_builtin = if (@hasField(@TypeOf(c), "is_builtin")) c.is_builtin else false;
        const is_optional = if (@hasField(@TypeOf(c), "optional")) c.optional else false;
        const callee: *const Doc = if (c.receiver) |recv|
            try this.concatAll(&.{
                try this.fmtExpr(recv.*),
                try this.text(if (is_optional) "?." else "."),
                try this.text(c.callee),
            })
        else
            try this.text(if (is_builtin) try std.fmt.allocPrint(this.arena, "@{s}", .{c.callee}) else c.callee);

        // Check if there are any comments to force multiline formatting
        const hasComments = hasCommentsLoop: {
            for (isComment.items) |isCmt| {
                if (isCmt) break :hasCommentsLoop true;
            }
            break :hasCommentsLoop false;
        };

        // Check if any argument contains a multiline string (contains newlines)
        const hasMultilineStringArg = hasMultilineLoop: {
            for (c.args) |a| {
                if (a.value.* == .literal and a.value.literal.kind == .stringLit) {
                    const s = a.value.literal.kind.stringLit;
                    if (std.mem.indexOfScalar(u8, s, '\n') != null) {
                        break :hasMultilineLoop true;
                    }
                }
            }
            break :hasMultilineLoop false;
        };

        // Build comma-separated arg list with proper grouping
        var argParts: std.ArrayList(*const Doc) = .empty;
        defer argParts.deinit(this.arena);
        for (items.items, 0..) |item, i| {
            if (hasComments or hasMultilineStringArg) {
                // Comment mode: hardline separator, comma attached to arg docs
                if (i > 0) try argParts.append(this.arena, this.hardline());
                if (!isComment.items[i]) {
                    // Regular arg: always add trailing comma in multiline/comment mode
                    try argParts.append(this.arena, try this.concat(item, try this.text(",")));
                } else {
                    try argParts.append(this.arena, item);
                }
            } else {
                // No-comment mode: comma-before-next-arg style
                if (i > 0) {
                    try argParts.append(this.arena, try this.concat(try this.text(","), this.line()));
                }
                try argParts.append(this.arena, item);
            }
        }

        const argsDoc = if (argParts.items.len == 0)
            try this.text("()")
        else blk: {
            const inner = try this.concatAll(argParts.items);

            if (hasComments or hasMultilineStringArg) {
                break :blk try this.forceBreak(try this.concatAll(&.{
                    try this.text("("),
                    try this.nest(INDENT, try this.concat(this.hardline(), inner)),
                    this.hardline(),
                    try this.text(")"),
                }));
            } else {
                break :blk try this.group(try this.concatAll(&.{
                    try this.text("("),
                    try this.nest(INDENT, try this.concat(this.softline(), inner)),
                    this.softline(),
                    try this.text(")"),
                }));
            }
        };

        // No trailing lambdas → simple call
        if (c.trailing.len == 0) {
            return this.concat(callee, argsDoc);
        }

        // Build trailing lambdas
        var parts: std.ArrayList(*const Doc) = .empty;
        try parts.append(this.arena, callee);
        // Only emit () if there are actual args when trailing lambdas present
        if (c.args.len > 0) try parts.append(this.arena, argsDoc);
        // Add space before trailing lambda:
        // - Always add space if lambda has params (e.g. "fn { a -> ... }")
        // - For parameterless lambdas: only add space for non-builtin calls
        //   (e.g., "executar { ... }" has space, but "@block{ ... }" does not)
        const needs_space = if (c.trailing.len > 0) blk: {
            if (c.trailing[0].params.len > 0) break :blk true;
            // Parameterless lambda: no space only for builtins
            break :blk !is_builtin;
        } else false;
        if (needs_space) {
            try parts.append(this.arena, try this.text(" "));
        }

        for (c.trailing, 0..) |tl, ti| {
            if (ti > 0) try parts.append(this.arena, try this.text(" "));
            if (tl.label) |lbl| {
                try parts.append(this.arena, try this.text(lbl));
                try parts.append(this.arena, try this.text(": "));
            }
            try parts.append(this.arena, try this.fmtLambda(tl.params, tl.body, false));
        }

        return this.concatAll(parts.items);
    }

    /// The statements of a multi-statement `if` branch, one per line, each
    /// ended by `;` (a comment takes none) — the block re-parses as written.
    /// (The branch printer used to prefix each with `break`, which does not
    /// parse for a `val` and changes the value of every other statement.)
    fn fmtBranchStmts(this: *Formatter, stmts: []ast.Stmt) !*const Doc {
        var items = try this.arena.alloc(*const Doc, stmts.len);
        for (stmts, 0..) |st, idx| {
            const exprDoc = try this.fmtExpr(st.expr);
            items[idx] = switch (st.expr) {
                .literal => |lit| if (lit.kind == .comment) exprDoc else try this.concat(exprDoc, try this.text(";")),
                else => try this.concat(exprDoc, try this.text(";")),
            };
        }
        return this.join(items, this.hardline());
    }

    /// `arrow_when_empty`: a parameterless lambda in expression position keeps
    /// its `{ -> … }` arrow — without it the braces re-parse as a block. A
    /// trailing lambda (`f { … }`) needs none.
    /// A lambda written on one line with a single value expression
    /// (`{ n -> n * 2 }`) stays on one line; everything else is `fmtLambda`.
    fn fmtLambdaAt(this: *Formatter, lambdaLine: usize, params: []const []const u8, body: []ast.Stmt, arrow_when_empty: bool) !*const Doc {
        if (params.len > 0 and body.len == 1 and body[0].expr.getLoc().line == lambdaLine) {
            const inlineValue = switch (body[0].expr) {
                .binding, .jump => false,
                .literal => |lit| lit.kind != .comment,
                else => true,
            };
            if (inlineValue) {
                // The value is rendered flat, as one text: letting its groups
                // break by width split it over lines, and the next pass (the
                // value no longer on the lambda's line) printed the lambda
                // open — `format` was not idempotent. A value that needs a
                // line break of its own prints the open form.
                const flat = try render(this.arena, try this.fmtExpr(body[0].expr), std.math.maxInt(u32));
                if (std.mem.indexOfScalar(u8, flat, '\n') == null) {
                    var paramDocs = try this.arena.alloc(*const Doc, params.len);
                    for (params, 0..) |p, i| paramDocs[i] = try this.text(p);
                    return this.concatAll(&.{
                        try this.text("{ "),
                        try this.join(paramDocs, try this.text(", ")),
                        try this.text(" -> "),
                        try this.text(flat),
                        try this.text(" }"),
                    });
                }
            }
        }
        return this.fmtLambda(params, body, arrow_when_empty);
    }

    fn fmtLambda(this: *Formatter, params: []const []const u8, body: []ast.Stmt, arrow_when_empty: bool) !*const Doc {
        const inner = try this.fmtStmtSeq(body);

        if (params.len == 0 and !arrow_when_empty) {
            return this.surroundBreak("{", inner, "}");
        }
        if (params.len == 0) {
            return this.forceBreak(try this.concatAll(&.{
                try this.text("{ ->"),
                try this.nest(INDENT, try this.concat(this.hardline(), inner)),
                this.hardline(),
                try this.text("}"),
            }));
        }

        // `{ a, b -> ... }`
        var paramDocs = try this.arena.alloc(*const Doc, params.len);
        for (params, 0..) |p, i| paramDocs[i] = try this.text(p);
        const paramList = try this.join(paramDocs, try this.text(", "));

        // `{ a, b ->\n    body\n}`
        return this.forceBreak(try this.concatAll(&.{
            try this.text("{ "),
            paramList,
            try this.text(" ->"),
            try this.nest(INDENT, try this.concat(this.hardline(), inner)),
            this.hardline(),
            try this.text("}"),
        }));
    }

    fn fmtFnExpr(this: *Formatter, params: []const []const u8, body: []ast.Stmt) !*const Doc {
        var items: std.ArrayList(*const Doc) = .empty;
        defer items.deinit(this.arena);
        for (body, 0..) |s, i| {
            if (i > 0 and s.emptyLinesBefore > 0) {
                for (0..s.emptyLinesBefore) |_| {
                    try items.append(this.arena, try this.text("\n"));
                }
            }
            if (i > 0) try items.append(this.arena, this.hardline());
            const exprDoc = try this.fmtExpr(s.expr);
            const stmtDoc = switch (s.expr) {
                .literal => |lit| if (lit.kind == .comment) exprDoc else try this.concat(exprDoc, try this.text(";")),
                else => try this.concat(exprDoc, try this.text(";")),
            };
            try items.append(this.arena, stmtDoc);
        }
        const inner = try this.concatAll(items.items);

        if (params.len == 0) {
            return this.concatAll(&.{
                try this.text("fn() "),
                try this.surroundBreak("{", inner, "}"),
            });
        }

        // `fn(a, b) { ... }`
        var paramDocs = try this.arena.alloc(*const Doc, params.len);
        for (params, 0..) |p, i| paramDocs[i] = try this.text(p);
        const paramList = try this.join(paramDocs, try this.text(", "));

        return this.forceBreak(try this.concatAll(&.{
            try this.text("fn("),
            paramList,
            try this.text(") "),
            try this.surroundBreak("{", inner, "}"),
        }));
    }

    fn fmtCase(this: *Formatter, subjects: []ast.Expr, arms: []ast.CaseArm, trailingComments: []const []const u8) !*const Doc {
        var armParts: std.ArrayList(*const Doc) = .empty;
        defer armParts.deinit(this.arena);
        for (arms, 0..) |arm, i| {
            if (i > 0) {
                // Add plain "\n" (no indent) for extra blank lines between arms
                if (arm.emptyLinesBefore > 0) {
                    for (0..arm.emptyLinesBefore) |_| {
                        try armParts.append(this.arena, try this.text("\n"));
                    }
                }
                // Regular separator
                try armParts.append(this.arena, this.hardline());
            }
            // An arm whose body is a lambda is decision 8 §5.1's
            // `Pattern [when (…)] { body }`: no arrow, no `;`, and the body's
            // parameter (`{ n -> … }`) binds the whole matched value. Any other
            // body is the pre-decision-8 `pattern [if …] -> value;`.
            const isBlockArm = arm.body == .function and arm.body.function.kind.syntax == .lambda;
            const guardDoc: *const Doc = if (arm.guard) |g| try this.concatAll(&.{
                try this.text(if (isBlockArm) " when (" else " if "),
                try this.fmtExpr(g),
                try this.text(if (isBlockArm) ")" else ""),
            }) else this.nil();
            try armParts.append(this.arena, try this.concatAll(&.{
                try this.fmtPattern(arm.pattern),
                guardDoc,
                if (isBlockArm) try this.text(" ") else try this.text(" -> "),
                if (isBlockArm)
                    try this.fmtLambda(arm.body.function.kind.params, arm.body.function.kind.body, false)
                else
                    try this.fmtExpr(arm.body),
                if (isBlockArm) this.nil() else try this.text(";"),
            }));
        }
        // Add trailing comments after the last arm
        for (trailingComments) |cmt| {
            try armParts.append(this.arena, this.hardline());
            try armParts.append(this.arena, try this.text(
                try std.fmt.allocPrint(this.arena, "// {s}", .{cmt}),
            ));
        }
        const armsDoc = try this.concatAll(armParts.items);
        var subjectDocs: std.ArrayList(*const Doc) = .empty;
        defer subjectDocs.deinit(this.arena);
        for (subjects, 0..) |s, i| {
            if (i > 0) try subjectDocs.append(this.arena, try this.text(", "));
            try subjectDocs.append(this.arena, try this.fmtExpr(s));
        }
        const subjectsDoc = try this.concatAll(subjectDocs.items);
        return this.concatAll(&.{
            try this.text("case "),
            subjectsDoc,
            try this.text(" "),
            try this.surroundBreak("{", armsDoc, "}"),
        });
    }

    // ── patterns ──────────────────────────────────────────────────────────────

    fn fmtParamDestruct(this: *Formatter, pd: ast.ParamDestruct) anyerror!*const Doc {
        return switch (pd) {
            .names => |n| blk: {
                var items: std.ArrayList(*const Doc) = .empty;
                defer items.deinit(this.arena);
                for (n.fields) |f| {
                    const fieldDoc = if (!std.mem.eql(u8, f.field_name, f.bind_name))
                        try this.concatAll(&.{
                            try this.text(f.field_name),
                            try this.text(": "),
                            try this.text(f.bind_name),
                        })
                    else
                        try this.text(f.field_name);
                    try items.append(this.arena, fieldDoc);
                }
                if (n.hasSpread) try items.append(this.arena, try this.text(".."));
                break :blk try this.commaList("{ ", items.items, " }");
            },
            .tuple_ => |names| blk: {
                var items = try this.arena.alloc(*const Doc, names.len);
                for (names, 0..) |name, i| items[i] = try this.text(name);
                break :blk try this.commaList("#(", items, ")");
            },
            .list => |pat| this.fmtPattern(pat),
            .ctor => |pat| this.fmtPattern(pat),
        };
    }

    /// The `label: ` a payload element was written with (decision 8 §5.1 P4),
    /// or the element alone when it carried none.
    fn withPatternLabel(this: *Formatter, labels: []const []const u8, i: usize, doc: *const Doc) !*const Doc {
        if (i >= labels.len or labels[i].len == 0) return doc;
        return this.concat(
            try this.text(try std.fmt.allocPrint(this.arena, "{s}: ", .{labels[i]})),
            doc,
        );
    }

    fn fmtPattern(this: *Formatter, pat: ast.Pattern) !*const Doc {
        return switch (pat) {
            .wildcard => this.text("_"),
            .ident => |id| this.text(id),
            .numberLit => |n| this.text(n),
            .stringLit => |s| blk: {
                // Check if string should be formatted as multiline (contains newlines)
                if (needsTripleQuotes(s)) {
                    // Format as multiline string with triple quotes
                    // The content already includes the newlines from the source
                    break :blk this.text(try std.fmt.allocPrint(this.arena, "\"\"\"{s}\"\"\"", .{s}));
                } else {
                    break :blk this.text(try std.fmt.allocPrint(this.arena, "\"{s}\"", .{s}));
                }
            },

            // `Ok ok`, `Rgb(r, g, b)`, `Rect(width: w, ..)`, `#(0, s)` and the
            // inclusive range `1...9` — decision 8 §5's shapes ride on this node
            // (see `ast.PatternShape`), so the label, the trailing `..` and the
            // tuple's `#` are written back from `labels`, `rest` and `shape`.
            .variant => |v| {
                if (v.shape == .range) {
                    const bounds = v.payload.literals;
                    return this.concatAll(&.{
                        try this.fmtPattern(bounds[0]),
                        try this.text("..."),
                        try this.fmtPattern(bounds[1]),
                    });
                }
                if (v.payload == .binding) {
                    return this.concat(
                        try this.text(v.name),
                        try this.concat(try this.text(" "), try this.text(v.payload.binding)),
                    );
                }
                var items: std.ArrayList(*const Doc) = .empty;
                defer items.deinit(this.arena);
                switch (v.payload) {
                    .fields => |fields| for (fields, 0..) |b, i| {
                        try items.append(this.arena, try this.withPatternLabel(v.labels, i, try this.text(b)));
                    },
                    .literals => |args| for (args, 0..) |arg, i| {
                        try items.append(this.arena, try this.withPatternLabel(v.labels, i, try this.fmtPattern(arg)));
                    },
                    .binding => unreachable,
                }
                if (v.rest) try items.append(this.arena, try this.text(".."));
                return this.concat(
                    try this.text(v.name),
                    try this.commaList(if (v.shape == .tuple) "#(" else "(", items.items, ")"),
                );
            },

            .list => |l| {
                var items: std.ArrayList(*const Doc) = .empty;
                for (l.elems) |elem| {
                    const d: *const Doc = switch (elem) {
                        .wildcard => try this.text("_"),
                        .bind => |b| try this.text(b),
                        .numberLit => |n| try this.text(n),
                    };
                    try items.append(this.arena, d);
                }
                if (l.spread) |sp| {
                    const spreadDoc = if (sp.len == 0)
                        try this.text("..")
                    else
                        try this.text(try std.fmt.allocPrint(this.arena, "..{s}", .{sp}));
                    try items.append(this.arena, spreadDoc);
                }
                return this.commaList("[", items.items, "]");
            },

            .@"or" => |pats| {
                var docs = try this.arena.alloc(*const Doc, pats.len);
                for (pats, 0..) |p, i| docs[i] = try this.fmtPattern(p);
                return this.join(docs, try this.text(" | "));
            },

            .multi => |pats| {
                var docs = try this.arena.alloc(*const Doc, pats.len);
                for (pats, 0..) |p, i| docs[i] = try this.fmtPattern(p);
                return this.join(docs, try this.text(", "));
            },
        };
    }

    // ── declarations ──────────────────────────────────────────────────────────

    fn fmtDocPrefix(this: *Formatter, doc: ?[]const u8) !*const Doc {
        if (doc) |d| {
            var lines: std.ArrayList(*const Doc) = .empty;
            defer lines.deinit(this.arena);
            var it = std.mem.splitSequence(u8, d, "\n");
            while (it.next()) |ln| {
                const lineDoc = try this.text(
                    try std.fmt.allocPrint(this.arena, "/// {s}", .{ln}),
                );
                try lines.append(this.arena, lineDoc);
            }
            const joined = try this.join(lines.items, this.hardline());
            return this.concat(joined, this.hardline());
        }
        return this.nil();
    }

    pub fn fmtProgram(this: *Formatter, program: ast.Program) !*const Doc {
        if (program.decls.len == 0) return this.nil();
        var docs = try this.arena.alloc(*const Doc, program.decls.len);
        for (program.decls, 0..) |d, i| {
            const declDoc = try this.fmtDecl(d);
            // Extract docComment from each declaration type
            const docComment: ?[]const u8 = switch (d) {
                .use => |v| v.docComment,
                .behavior => |v| v.docComment,
                .delegate => |v| v.docComment,
                .type_ => |v| v.docComment,
                .implement => |v| v.docComment,
                .extend => |v| v.docComment,
                .@"fn" => |v| v.docComment,
                .val => |v| v.docComment,
                .@"test" => |v| v.docComment,
                .mod => |v| v.docComment,
                .comment => null,
            };
            const prefix = try this.fmtDocPrefix(docComment);
            // Add semicolon after declarations that don't have a body
            const needsSemi = switch (d) {
                .@"fn" => false,
                .@"test" => false,
                .val => true,
                // 1.0.3 declarations end with `)` or `}` and take no `;`.
                .type_ => false,
                .behavior => false,
                .use, .delegate, .implement, .extend => true,
                .mod => true,
                .comment => false,
            };
            const declWithSemi = if (needsSemi)
                try this.concat(declDoc, try this.text(";"))
            else
                declDoc;
            docs[i] = if (docComment != null)
                try this.concat(prefix, declWithSemi)
            else
                declWithSemi;
        }
        // Build output with smart separators:
        // consecutive use/val delegates get single newline,
        // everything else gets a blank line.
        var parts: std.ArrayList(*const Doc) = .empty;
        defer parts.deinit(this.arena);
        try parts.append(this.arena, docs[0]);
        for (1..docs.len) |i| {
            const prev = program.decls[i - 1];
            const curr = program.decls[i];
            // `mod` declarations group with imports — both are tight module-graph
            // statements, so adjacent ones get a single newline, not a blank line.
            const prevIsUse = prev == .use or prev == .mod;
            const currIsUse = curr == .use or curr == .mod;
            const prevIsComment = prev == .comment;
            const prevIsModuleComment = prevIsComment and prev.comment.is_module;
            const currIsComment = curr == .comment;
            // Single newline when adjacent to a non-module comment or use declarations.
            // A blank source line between two declarations is kept.
            const sourceBlank = program.blankLineBefore.len == program.decls.len and program.blankLineBefore[i];
            const sep: *const Doc = if (curr == .comment and curr.comment.trailing)
                try this.text(" ")
            else if (sourceBlank)
                try this.concat(this.hardline(), this.hardline())
            else if (prevIsUse and currIsUse)
                this.hardline()
            else if ((prevIsComment and !prevIsModuleComment) or currIsComment)
                this.hardline()
            else
                try this.concat(this.hardline(), this.hardline());
            try parts.append(this.arena, sep);
            try parts.append(this.arena, docs[i]);
        }
        return this.concatAll(parts.items);
    }

    fn fmtDecl(this: *Formatter, decl: ast.DeclKind) !*const Doc {
        return switch (decl) {
            .use => |u| this.fmtUse(u),
            .behavior => |iface| this.fmtBehavior(iface),
            .delegate => |d| this.fmtDelegate(d),
            .type_ => |t| this.fmtType(t),
            .implement => |impl| this.fmtImplement(impl),
            .extend => |ext| this.fmtExtend(ext),
            .@"fn" => |f| this.fmtFnDecl(f),
            .val => |v| this.fmtValDecl(v),
            .@"test" => |t| this.fmtTestDecl(t),
            .mod => |m| this.text(try std.fmt.allocPrint(
                this.arena,
                "{s}mod {s}",
                .{ if (m.isPub) "pub " else "", m.name },
            )),
            .comment => |c| blk: {
                const prefix = if (c.is_module) "////" else if (c.is_doc) "///" else "//";
                if (c.text.len == 0) break :blk this.text(prefix);
                break :blk this.text(try std.fmt.allocPrint(this.arena, "{s} {s}", .{ prefix, c.text }));
            },
        };
    }

    /// One import item: `a.b.C` + optional `*` + optional ` as Q`.
    fn fmtImportItem(this: *Formatter, imp: ast.ImportPath) !*const Doc {
        var seg_docs = try this.arena.alloc(*const Doc, imp.segments.len * 2 - 1);
        for (imp.segments, 0..) |seg, j| {
            if (j > 0) seg_docs[j * 2 - 1] = try this.text(".");
            seg_docs[j * 2] = try this.text(seg);
        }
        var doc = try this.concatAll(seg_docs);
        if (imp.activate) doc = try this.concat(doc, try this.text("*"));
        if (imp.alias) |a| doc = try this.concat(doc, try this.text(
            try std.fmt.allocPrint(this.arena, " as {s}", .{a}),
        ));
        return doc;
    }

    fn fmtUse(this: *Formatter, u: ast.ImportDecl) !*const Doc {
        // Fallback activation statement `X*;` — a single activated item, no braces.
        if (u.activationOnly) return this.fmtImportItem(u.imports[0]);

        var items = try this.arena.alloc(*const Doc, u.imports.len);
        for (u.imports, 0..) |imp, i| {
            items[i] = try this.fmtImportItem(imp);
        }
        // Package-namespace form: `import pkg [, { … }]` binds `pkg`.
        const head = if (u.package) |pkg| blk: {
            if (u.imports.len == 0) break :blk try this.text(try std.fmt.allocPrint(this.arena, "import {s}", .{pkg}));
            break :blk try this.concatAll(&.{
                try this.text(try std.fmt.allocPrint(this.arena, "import {s}, ", .{pkg})),
                try this.commaList("{", items, "}"),
            });
        } else try this.concatAll(&.{ try this.text("import "), try this.commaList("{", items, "}") });
        return switch (u.source) {
            .root => head,
            .module => |name| this.concatAll(&.{
                head,
                try this.text(try std.fmt.allocPrint(this.arena, " from \"{s}\"", .{name})),
            }),
        };
    }

    fn fmtDelegate(this: *Formatter, d: ast.DelegateDecl) !*const Doc {
        const prefix: *const Doc = if (d.isPub)
            try this.text("pub declare fn ")
        else
            try this.text("declare fn ");
        return this.concatAll(&.{
            prefix,
            try this.text(d.name),
            try this.fmtParams(d.params),
            try this.fmtReturnType(d.returnType),
        });
    }

    fn fmtAnnotations(this: *Formatter, annotations: []const ast.Annotation) !*const Doc {
        if (annotations.len == 0) return this.nil();
        var docs: std.ArrayList(*const Doc) = .empty;
        defer docs.deinit(this.arena);
        for (annotations) |ann| {
            const prefix: []const u8 = if (ann.is_builtin) "@" else "";
            if (ann.writtenArgs().len == 0) {
                try docs.append(this.arena, try this.text(
                    try std.fmt.allocPrint(this.arena, "#[{s}{s}]", .{ prefix, ann.name }),
                ));
            } else {
                const argsStr = try std.mem.join(this.arena, ", ", ann.writtenArgs());
                try docs.append(this.arena, try this.text(
                    try std.fmt.allocPrint(this.arena, "#[{s}{s}({s})]", .{ prefix, ann.name, argsStr }),
                ));
            }
        }
        const sep = try this.concat(this.hardline(), try this.text(""));
        const annsDoc = try this.join(docs.items, sep);
        return this.concat(annsDoc, this.hardline());
    }

    /// `#[…] [pub] behavior Name<G> extends A, B { members }` — the 1.0.3
    /// surface. Bodyless members end with `;`, members with a body with `}`;
    /// a blank line separates `val` fields, signatures and default methods.
    fn fmtBehavior(this: *Formatter, iface: ast.BehaviorDecl) !*const Doc {
        var members: std.ArrayList(*const Doc) = .empty;
        var groups: std.ArrayList(u8) = .empty;
        var blanks: std.ArrayList(bool) = .empty;
        for (iface.fields) |f| {
            const c = try this.withMemberComments(f.comments, try this.text(
                try std.fmt.allocPrint(this.arena, "val {s}: {s};", .{ f.name, f.typeName }),
            ));
            try members.append(this.arena, c.doc);
            try blanks.append(this.arena, c.blank);
            try groups.append(this.arena, 0);
        }
        for (iface.methods) |m| {
            const c = try this.withMemberComments(m.comments, try this.concat(
                try this.fmtAnnotations(m.annotations),
                try this.fmtInterfaceMethod(m),
            ));
            try members.append(this.arena, c.doc);
            try blanks.append(this.arena, c.blank);
            try groups.append(this.arena, if (m.body == null) 1 else 2);
        }
        const body = try this.fmtMemberBlock(members.items, groups.items, blanks.items, iface.bodyComments);

        var parts: std.ArrayList(*const Doc) = .empty;
        try parts.append(this.arena, try this.fmtAnnotations(iface.annotations));
        if (iface.isPub) try parts.append(this.arena, try this.text("pub "));
        try parts.append(this.arena, try this.text("behavior "));
        try parts.append(this.arena, try this.text(iface.name));
        try parts.append(this.arena, try this.fmtGenericParams(iface.genericParams));
        if (iface.extends.len > 0) {
            try parts.append(this.arena, try this.text(" extends "));
            try parts.append(this.arena, try this.text(try std.mem.join(this.arena, ", ", iface.extends)));
        }
        try parts.append(this.arena, try this.text(" "));
        try parts.append(this.arena, body);
        return this.concatAll(parts.items);
    }

    /// `{ member … }` — one member per line, a blank line wherever the group
    /// changes or the source had one; the body's trailing comments last; `{}`
    /// when empty.
    fn fmtMemberBlock(this: *Formatter, members: []const *const Doc, groups: []const u8, blanks: []const bool, bodyComments: []const []const u8) !*const Doc {
        const trailing = try this.commentLines(bodyComments);
        if (members.len == 0 and trailing.items.len == 0) return this.text("{}");
        var parts: std.ArrayList(*const Doc) = .empty;
        for (members, 0..) |m, i| {
            if (i > 0) {
                // A plain "\n" (no indent) makes the blank line between groups.
                if (groups[i] != groups[i - 1] or blanks[i]) try parts.append(this.arena, try this.text("\n"));
                try parts.append(this.arena, this.hardline());
            }
            try parts.append(this.arena, m);
        }
        try this.appendCommentLines(&parts, trailing, parts.items.len > 0);
        return this.surroundBreak("{", try this.concatAll(parts.items), "}");
    }

    const CommentLines = struct { items: []const *const Doc, blanks: []const bool };

    /// Comment lexemes as docs, with a blank-before flag per line ("" entries
    /// fold into the next line's flag; a trailing "" is dropped).
    fn commentLines(this: *Formatter, comments: []const []const u8) !CommentLines {
        var items: std.ArrayList(*const Doc) = .empty;
        var blanks: std.ArrayList(bool) = .empty;
        var pending = false;
        for (comments) |c| {
            if (c.len == 0) {
                pending = true;
                continue;
            }
            try items.append(this.arena, try this.text(std.mem.trimEnd(u8, c, " \t\r")));
            try blanks.append(this.arena, pending);
            pending = false;
        }
        return .{ .items = items.items, .blanks = blanks.items };
    }

    fn appendCommentLines(this: *Formatter, parts: *std.ArrayList(*const Doc), lines: CommentLines, afterContent: bool) !void {
        for (lines.items, lines.blanks, 0..) |lineDoc, blank, i| {
            if (afterContent or i > 0) {
                if (blank) try parts.append(this.arena, try this.text("\n"));
                try parts.append(this.arena, this.hardline());
            }
            try parts.append(this.arena, lineDoc);
        }
    }

    /// A body member preceded by its comment lines. `blank` is whether a blank
    /// source line comes before the member (or before its first comment).
    fn withMemberComments(this: *Formatter, comments: []const []const u8, member: *const Doc) !struct { doc: *const Doc, blank: bool } {
        const lines = try this.commentLines(comments);
        const leadingBlank = comments.len > 0 and comments[0].len == 0;
        if (lines.items.len == 0) return .{ .doc = member, .blank = leadingBlank or (comments.len > 0) };
        var parts: std.ArrayList(*const Doc) = .empty;
        try this.appendCommentLines(&parts, lines, false);
        // A blank between the last comment and the member.
        if (comments[comments.len - 1].len == 0) try parts.append(this.arena, try this.text("\n"));
        try parts.append(this.arena, this.hardline());
        try parts.append(this.arena, member);
        return .{ .doc = try this.concatAll(parts.items), .blank = lines.blanks[0] };
    }

    fn fmtInterfaceMethod(this: *Formatter, m: ast.BehaviorMethod) !*const Doc {
        const pub_prefix: *const Doc = if (m.isPub) try this.text("pub ") else try this.text("");
        const fn_kw = if (m.is_default)
            try this.text("default fn ")
        else if (m.is_declare)
            try this.text("declare fn ")
        else
            try this.text("fn ");
        const sig = try this.concatAll(&.{
            pub_prefix,
            fn_kw,
            try this.text(m.name),
            try this.fmtGenericParams(m.genericParams),
            try this.fmtParams(m.params),
            try this.fmtReturnTypeRef(m.returnType, null),
        });
        if (m.body) |stmts| {
            return this.concatAll(&.{
                sig,
                try this.text(" "),
                try this.fmtBody(stmts),
            });
        }
        // Abstract method - add semicolon
        return this.concat(sig, try this.text(";"));
    }

    /// One field of a field list: `#[ann] name: Type = default`, preceded by
    /// its `//` comments (each on its own line).
    fn fmtField(this: *Formatter, f: ast.Field) !*const Doc {
        var parts: std.ArrayList(*const Doc) = .empty;
        for (f.comments) |c| {
            try parts.append(this.arena, try this.text(try std.fmt.allocPrint(this.arena, "// {s}", .{c})));
            try parts.append(this.arena, this.hardline());
        }
        for (f.annotations) |ann| {
            const prefix: []const u8 = if (ann.is_builtin) "@" else "";
            const annText = if (ann.writtenArgs().len == 0)
                try std.fmt.allocPrint(this.arena, "#[{s}{s}] ", .{ prefix, ann.name })
            else
                try std.fmt.allocPrint(this.arena, "#[{s}{s}({s})] ", .{ prefix, ann.name, try std.mem.join(this.arena, ", ", ann.writtenArgs()) });
            try parts.append(this.arena, try this.text(annText));
        }
        try parts.append(this.arena, try this.text(f.name));
        try parts.append(this.arena, try this.text(": "));
        try parts.append(this.arena, try this.fmtTypeRef(f.typeRef));
        if (f.default) |d| {
            try parts.append(this.arena, try this.text(" = "));
            try parts.append(this.arena, try this.fmtExpr(d));
        }
        return this.concatAll(parts.items);
    }

    /// `(a: T, b: U)` — the field list of a record or a variant payload.
    /// Compact on one line without a trailing comma (whatever the width);
    /// open, one field per line with the trailing comma, when the source had
    /// one or a field carries a comment.
    fn fmtFieldList(this: *Formatter, fields: []const ast.Field, trailingComma: bool) !*const Doc {
        var open = trailingComma;
        for (fields) |f| {
            if (f.comments.len > 0) open = true;
        }
        const items = try this.arena.alloc(*const Doc, fields.len);
        for (fields, 0..) |f, i| items[i] = try this.fmtField(f);
        if (!open) {
            return this.concatAll(&.{
                try this.text("("),
                try this.join(items, try this.text(", ")),
                try this.text(")"),
            });
        }
        const withCommas = try this.arena.alloc(*const Doc, items.len);
        for (items, 0..) |item, i| withCommas[i] = try this.concat(item, try this.text(","));
        return this.surroundBreak("(", try this.join(withCommas, this.hardline()), ")");
    }

    /// `#[…] [pub] type Name<G>(fields) implement A { methods }` (record shape)
    /// or `#[…] [pub] type Name<G> implement A { Variant, …, methods }` (enum
    /// shape) — the 1.0.3 surface. A record with no methods prints no body;
    /// variants stay compact on one line unless the source had a trailing
    /// comma, the body holds a section or a method.
    fn fmtType(this: *Formatter, t: ast.TypeDecl) !*const Doc {
        var parts: std.ArrayList(*const Doc) = .empty;
        try parts.append(this.arena, try this.fmtAnnotations(t.annotations));
        if (t.isPub) try parts.append(this.arena, try this.text("pub "));
        try parts.append(this.arena, try this.text("type "));
        try parts.append(this.arena, try this.text(t.name));
        try parts.append(this.arena, try this.fmtGenericParams(t.genericParams));

        const methodDocs = try this.arena.alloc(*const Doc, t.methods.len);
        const methodBlanks = try this.arena.alloc(bool, t.methods.len);
        const noGroups = try this.arena.alloc(u8, t.methods.len);
        for (t.methods, 0..) |m, i| {
            const c = try this.withMemberComments(m.comments, try this.concat(
                try this.fmtAnnotations(m.annotations),
                try this.fmtInterfaceMethod(m),
            ));
            methodDocs[i] = c.doc;
            methodBlanks[i] = c.blank;
            noGroups[i] = 0;
        }

        if (t.isRecord()) {
            if (t.recordFields().len > 0) try parts.append(this.arena, try this.fmtFieldList(t.recordFields(), t.trailingComma));
            try this.appendImplement(&parts, t.implement);
            if (methodDocs.len > 0 or t.bodyComments.len > 0) {
                try parts.append(this.arena, try this.text(" "));
                try parts.append(this.arena, try this.fmtMemberBlock(methodDocs, noGroups, methodBlanks, t.bodyComments));
            }
            return this.concatAll(parts.items);
        }

        try this.appendImplement(&parts, t.implement);
        try parts.append(this.arena, try this.text(" "));
        const variants = t.variants();
        const sections = t.sections();
        const itemCount = variants.len + sections.len;
        if (itemCount + methodDocs.len == 0) {
            try parts.append(this.arena, try this.text("{}"));
            return this.concatAll(parts.items);
        }
        const open = t.trailingComma or sections.len > 0 or methodDocs.len > 0;
        if (!open) {
            const vdocs = try this.arena.alloc(*const Doc, variants.len);
            for (variants, 0..) |v, i| vdocs[i] = try this.fmtEnumVariant(v);
            try parts.append(this.arena, try this.surroundFlat("{", try this.join(vdocs, try this.text(", ")), "}"));
            return this.concatAll(parts.items);
        }
        var lines: std.ArrayList(*const Doc) = .empty;
        for (variants) |v| try lines.append(this.arena, try this.concat(try this.fmtEnumVariant(v), try this.text(",")));
        for (sections) |sec| try lines.append(this.arena, try this.fmtEnumSection(sec));
        var inner = try this.join(lines.items, this.hardline());
        if (methodDocs.len > 0) {
            var mparts: std.ArrayList(*const Doc) = .empty;
            for (methodDocs, 0..) |m, i| {
                if (i > 0) {
                    if (methodBlanks[i]) try mparts.append(this.arena, try this.text("\n"));
                    try mparts.append(this.arena, this.hardline());
                }
                try mparts.append(this.arena, m);
            }
            const methods = try this.concatAll(mparts.items);
            inner = if (itemCount > 0)
                try this.concatAll(&.{ inner, try this.text("\n"), this.hardline(), methods })
            else
                methods;
        }
        try parts.append(this.arena, try this.surroundBreak("{", inner, "}"));
        return this.concatAll(parts.items);
    }

    fn appendImplement(this: *Formatter, parts: *std.ArrayList(*const Doc), impls: []const ast.TypeRef) !void {
        if (impls.len == 0) return;
        const docs = try this.arena.alloc(*const Doc, impls.len);
        for (impls, 0..) |im, i| docs[i] = try this.fmtTypeRef(im);
        try parts.append(this.arena, try this.text(" implement "));
        try parts.append(this.arena, try this.join(docs, try this.text(", ")));
    }

    /// One enum variant: a unit name (`Red`), a numeric section leaf (`500`,
    /// whose name is the digit string verbatim) or a payload variant
    /// (`Rgb(r: i32, g: i32)`).
    fn fmtEnumVariant(this: *Formatter, v: ast.EnumVariant) !*const Doc {
        if (v.fields.len == 0) return this.text(v.name);
        return this.concat(try this.text(v.name), try this.fmtFieldList(v.fields, false));
    }

    /// An enum section: `Color { Red, Blue }`, holding bare variants and
    /// nested sections (arbitrarily deep). Always rendered broken, and never
    /// followed by a comma — the closing brace ends the item.
    fn fmtEnumSection(this: *Formatter, s: ast.EnumSection) !*const Doc {
        const items = try this.arena.alloc(*const Doc, s.variants.len + s.sections.len);
        for (s.variants, 0..) |v, i|
            items[i] = try this.concat(try this.fmtEnumVariant(v), try this.text(","));
        for (s.sections, 0..) |sub, i|
            items[s.variants.len + i] = try this.fmtEnumSection(sub);

        const body = if (items.len == 0)
            try this.text("{}")
        else blk: {
            const inner = try this.join(items, this.hardline());
            break :blk try this.surroundBreak("{", inner, "}");
        };
        return this.concatAll(&.{ try this.text(s.name), try this.text(" "), body });
    }

    fn fmtImplement(this: *Formatter, impl: ast.ImplementDecl) !*const Doc {
        // `implement Interface1, Interface2 for Type`
        var ifaceDocs = try this.arena.alloc(*const Doc, impl.interfaces.len);
        for (impl.interfaces, 0..) |iface, i| ifaceDocs[i] = try this.fmtTypeRef(iface);
        const ifacesDoc = try this.join(ifaceDocs, try this.text(", "));

        var methodDocs = try this.arena.alloc(*const Doc, impl.methods.len);
        for (impl.methods, 0..) |m, i| methodDocs[i] = try this.fmtImplementMethod(m);

        const body = if (methodDocs.len == 0)
            try this.text("{}")
        else blk: {
            const inner = try this.join(methodDocs, this.hardline());
            break :blk try this.surroundBreak("{", inner, "}");
        };

        const pubPrefix = if (impl.isPub) try this.text("pub ") else try this.text("");
        // shorthand: `Name implement … for T { … }`
        // explicit:  `val Name = implement … for T { … }`
        const keyword = if (impl.shorthand)
            try this.text(" implement ")
        else
            try this.text(" = implement ");
        const namePrefix = if (impl.shorthand) try this.text("") else try this.text("val ");

        return this.concatAll(&.{
            pubPrefix,
            namePrefix,
            try this.text(impl.name),
            try this.fmtGenericParams(impl.genericParams),
            keyword,
            ifacesDoc,
            try this.text(" for "),
            try this.text(impl.target),
            try this.text(" "),
            body,
        });
    }

    fn fmtExtend(this: *Formatter, ext: ast.ExtendDecl) !*const Doc {
        var methodDocs = try this.arena.alloc(*const Doc, ext.methods.len);
        for (ext.methods, 0..) |m, i| methodDocs[i] = try this.fmtImplementMethod(m);

        const body = if (methodDocs.len == 0)
            try this.text("{}")
        else blk: {
            const inner = try this.join(methodDocs, this.hardline());
            break :blk try this.surroundBreak("{", inner, "}");
        };

        const pubPrefix = if (ext.isPub) try this.text("pub ") else try this.text("");
        // shorthand: `Name extend T { … }`
        // explicit:  `val Name = extend T { … }`
        const keyword = if (ext.shorthand)
            try this.text(" extend ")
        else
            try this.text(" = extend ");
        const namePrefix = if (ext.shorthand) try this.text("") else try this.text("val ");

        return this.concatAll(&.{
            pubPrefix,
            namePrefix,
            try this.text(ext.name),
            try this.fmtGenericParams(ext.genericParams),
            keyword,
            try this.text(ext.target),
            try this.text(" "),
            body,
        });
    }

    fn fmtImplementMethod(this: *Formatter, m: ast.ImplementMethod) !*const Doc {
        const nameDoc: *const Doc = if (m.qualifier) |q|
            try this.text(try std.fmt.allocPrint(this.arena, "{s}.{s}", .{ q, m.name }))
        else
            try this.text(m.name);

        return this.concatAll(&.{
            try this.text("fn "),
            nameDoc,
            try this.fmtParams(m.params),
            try this.text(" "),
            try this.fmtBody(m.body),
        });
    }

    fn fmtFnDecl(this: *Formatter, f: ast.FnDecl) !*const Doc {
        // `[pub] fn ` — the effect is carried by a `#[@<effect>]` annotation
        // (emitted by `fmtAnnotations`). The deprecated `*fn` prefix was removed
        // in v0.beta.19, so there is no longer a star-derived effect to print.
        // An FFI declaration (`#[@External.…] pub declare fn f(…) -> T;`) is a
        // `declare fn` with NO body: it must keep the `declare` keyword and
        // end in `;`. Printing it as `pub fn f(…) -> T {}` (what this did
        // before) silently turned every host-backed declaration into an empty
        // implementation.
        const pubKw: []const u8 = if (f.isPub) "pub " else "";
        const declareKw: []const u8 = if (f.isDeclare) "declare " else "";
        const prefix = try this.text(try std.fmt.allocPrint(this.arena, "{s}{s}fn ", .{ pubKw, declareKw }));
        if (f.isDeclare and f.body.len == 0) {
            return this.concatAll(&.{
                try this.fmtAnnotations(f.annotations),
                prefix,
                try this.text(f.name),
                try this.fmtGenericParams(f.genericParams),
                try this.fmtParams(f.params),
                try this.fmtReturnTypeRef(f.returnType, f.typeGuardParam),
                try this.text(";"),
            });
        }

        // Optional generator label after the return type: ` :gen`.
        const labelDoc: *const Doc = if (f.label) |lbl|
            try this.text(try std.fmt.allocPrint(this.arena, " :{s}", .{lbl}))
        else
            this.nil();

        return this.concatAll(&.{
            try this.fmtAnnotations(f.annotations),
            prefix,
            try this.text(f.name),
            try this.fmtGenericParams(f.genericParams),
            try this.fmtParams(f.params),
            try this.fmtReturnTypeRef(f.returnType, f.typeGuardParam),
            labelDoc,
            try this.text(" "),
            try this.fmtBody(f.body),
        });
    }

    /// `test { … }` / `test "name" { … }` — top-level test declaration.
    fn fmtTestDecl(this: *Formatter, t: ast.TestDecl) !*const Doc {
        const head: *const Doc = if (t.name) |n|
            try this.text(try std.fmt.allocPrint(this.arena, "test \"{s}\" ", .{n}))
        else
            try this.text("test ");
        return this.concatAll(&.{
            head,
            try this.fmtBody(t.body),
        });
    }

    fn fmtTypeRef(this: *Formatter, ref: ast.TypeRef) anyerror!*const Doc {
        return switch (ref) {
            .named => |n| this.text(n),
            .array => |elem| this.concat(try this.fmtTypeRef(elem.*), try this.text("[]")),
            .optional => |inner| this.concat(try this.text("?"), try this.fmtTypeRef(inner.*)),
            .tuple_ => |elems| blk: {
                var docs = try this.arena.alloc(*const Doc, elems.len);
                for (elems, 0..) |e, i| docs[i] = try this.fmtTypeRef(e);
                const inner = if (elems.len == 0)
                    this.nil()
                else
                    try this.join(docs, try this.text(", "));
                break :blk this.concatAll(&.{
                    try this.text("#("),
                    inner,
                    try this.text(")"),
                });
            },
            .labeledTuple => |lt| blk: {
                var docs = try this.arena.alloc(*const Doc, lt.elems.len);
                for (lt.elems, 0..) |e, i| docs[i] = try this.concatAll(&.{
                    try this.text(lt.labels[i]),
                    try this.text(": "),
                    try this.fmtTypeRef(e),
                });
                break :blk this.concatAll(&.{
                    try this.text("#("),
                    try this.join(docs, try this.text(", ")),
                    try this.text(")"),
                });
            },
            .function => |f| blk: {
                var paramDocs = try this.arena.alloc(*const Doc, f.params.len);
                for (f.params, 0..) |p, i| {
                    const name = if (f.paramNames.len == f.params.len) f.paramNames[i] else "";
                    paramDocs[i] = if (name.len > 0)
                        try this.concat(try this.text(try std.fmt.allocPrint(this.arena, "{s}: ", .{name})), try this.fmtTypeRef(p))
                    else
                        try this.fmtTypeRef(p);
                }
                const inner = if (f.params.len == 0)
                    this.nil()
                else
                    try this.join(paramDocs, try this.text(", "));
                // `fn(T)` with no arrow returns void.
                const isVoid = f.returnType.* == .named and std.mem.eql(u8, f.returnType.named, "void");
                break :blk this.concatAll(&.{
                    try this.text("fn("),
                    inner,
                    try this.text(")"),
                    if (isVoid) this.nil() else try this.concat(try this.text(" -> "), try this.fmtTypeRef(f.returnType.*)),
                });
            },
            .generic => |b| blk: {
                // A union type `A | B` (decision 8 §3) travels as a `generic`
                // under `ast.union_type_name`; it is written as its members.
                if (ref.unionMembers()) |members| {
                    var memberDocs = try this.arena.alloc(*const Doc, members.len);
                    for (members, 0..) |m, i| memberDocs[i] = try this.fmtTypeRef(m);
                    break :blk this.join(memberDocs, try this.text(" | "));
                }
                var argDocs = try this.arena.alloc(*const Doc, b.args.len);
                for (b.args, 0..) |a, i| argDocs[i] = try this.fmtTypeRef(a);
                const inner = if (b.args.len == 0)
                    this.nil()
                else
                    try this.join(argDocs, try this.text(", "));
                // A bare builtin type (`@Expr`) round-trips without `<>`.
                if (b.is_builtin and b.args.len == 0) {
                    break :blk this.concat(try this.text("@"), try this.text(b.name));
                }
                break :blk if (b.is_builtin)
                    this.concatAll(&.{
                        try this.text("@"),
                        try this.text(b.name),
                        try this.text("<"),
                        inner,
                        try this.text(">"),
                    })
                else
                    this.concatAll(&.{
                        try this.text(b.name),
                        try this.text("<"),
                        inner,
                        try this.text(">"),
                    });
            },
            .typeparam => |constraints| blk: {
                if (constraints.len == 0) break :blk this.text("type");
                var docs = try this.arena.alloc(*const Doc, constraints.len);
                for (constraints, 0..) |c, i| docs[i] = try this.fmtTypeRef(c);
                break :blk this.concat(
                    try this.text("type "),
                    try this.join(docs, try this.text(" | ")),
                );
            },
        };
    }

    fn fmtValDecl(this: *Formatter, v: ast.ValDecl) !*const Doc {
        if (v.typeAnnotation) |ann| {
            if (v.isPub) {
                return this.concatAll(&.{
                    try this.text("pub "),
                    try this.text("val "),
                    try this.text(v.name),
                    try this.text(": "),
                    try this.fmtTypeRef(ann),
                    try this.text(" = "),
                    try this.fmtExpr(v.value.*),
                });
            }
            return this.concatAll(&.{
                try this.text("val "),
                try this.text(v.name),
                try this.text(": "),
                try this.fmtTypeRef(ann),
                try this.text(" = "),
                try this.fmtExpr(v.value.*),
            });
        }
        if (v.isPub) {
            return this.concatAll(&.{
                try this.text("pub "),
                try this.text("val "),
                try this.text(v.name),
                try this.text(" = "),
                try this.fmtExpr(v.value.*),
            });
        }
        return this.concatAll(&.{
            try this.text("val "),
            try this.text(v.name),
            try this.text(" = "),
            try this.fmtExpr(v.value.*),
        });
    }
};

// ── renderer ──────────────────────────────────────────────────────────────────

const Mode = enum { flat, break_ };

const Item = struct {
    indent: usize,
    mode: Mode,
    doc: *const Doc,
};

/// Check whether the document fragment fits within `budget` remaining columns.
/// Scans in flat mode, stopping at hardlines (which always break).
fn fits(budget: isize, work: *std.ArrayList(Item)) bool {
    var remaining = budget;
    // Scan the current work stack backwards (top = last element) without modifying it.
    var i = work.items.len;
    while (i > 0) {
        i -= 1;
        if (remaining < 0) return false;
        const item = work.items[i];
        switch (item.doc.*) {
            .nil => {},
            .text => |s| remaining -= @intCast(s.len),
            .line => {
                if (item.mode == .flat) remaining -= 1 else return true;
            },
            .softline => {
                if (item.mode == .break_) return true;
                // flat mode: zero-width, nothing to deduct
            },
            .hardline => return true,
            .concat => |c| {
                // We can't push new items to work here without corrupting it.
                // Conservative: assume concat fits if remaining budget is positive.
                // This is suboptimal but safe. A full implementation would use a
                // separate temporary stack for the fits check.
                _ = c;
                return remaining >= 0;
            },
            .nest => |n| _ = n,
            .group => |d| _ = d,
            .forceBreak => return false,
        }
    }
    return remaining >= 0;
}

/// Render a `Doc` tree to a UTF-8 string, targeting `width` columns.
/// The returned slice is owned by `allocator`.
pub fn render(allocator: std.mem.Allocator, doc: *const Doc, width: usize) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // Use a temporary arena for the render work-list.
    var workArena = std.heap.ArenaAllocator.init(allocator);
    defer workArena.deinit();
    const wa = workArena.allocator();

    var work: std.ArrayList(Item) = .empty;
    try work.append(wa, .{ .indent = 0, .mode = .break_, .doc = doc });

    var col: usize = 0;

    while (work.items.len > 0) {
        const item = work.pop().?;
        switch (item.doc.*) {
            .nil => {},

            .text => |s| {
                try out.appendSlice(allocator, s);
                col += s.len;
            },

            .line => {
                if (item.mode == .flat) {
                    try out.append(allocator, ' ');
                    col += 1;
                } else {
                    try out.append(allocator, '\n');
                    try out.appendNTimes(allocator, ' ', item.indent);
                    col = item.indent;
                }
            },

            .softline => {
                if (item.mode == .break_) {
                    try out.append(allocator, '\n');
                    try out.appendNTimes(allocator, ' ', item.indent);
                    col = item.indent;
                }
                // flat mode: zero-width, emit nothing
            },

            .hardline => {
                try out.append(allocator, '\n');
                try out.appendNTimes(allocator, ' ', item.indent);
                col = item.indent;
            },

            .concat => |c| {
                // Right first (stack is LIFO ---- pop gives us left next).
                try work.append(wa, .{ .indent = item.indent, .mode = item.mode, .doc = c.right });
                try work.append(wa, .{ .indent = item.indent, .mode = item.mode, .doc = c.left });
            },

            .nest => |n| {
                try work.append(wa, .{
                    .indent = item.indent + n.amount,
                    .mode = item.mode,
                    .doc = n.doc,
                });
            },

            .group => |d| {
                // Try flat mode: scan remaining work to see if it fits.
                const budget: isize = @as(isize, @intCast(width)) - @as(isize, @intCast(col));
                // Push candidate in flat mode temporarily to check fits.
                try work.append(wa, .{ .indent = item.indent, .mode = .flat, .doc = d });
                const ok = fits(budget, &work);
                _ = work.pop().?; // remove the candidate we just pushed
                if (ok) {
                    try work.append(wa, .{ .indent = item.indent, .mode = .flat, .doc = d });
                } else {
                    try work.append(wa, .{ .indent = item.indent, .mode = .break_, .doc = d });
                }
            },

            .forceBreak => |d| {
                try work.append(wa, .{ .indent = item.indent, .mode = .break_, .doc = d });
            },
        }
    }

    return out.toOwnedSlice(allocator);
}

// ── public entry point ────────────────────────────────────────────────────────

/// Format a parsed `Program` to a UTF-8 string.
/// The returned slice is owned by `allocator`.
pub fn format(allocator: std.mem.Allocator, program: ast.Program) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var fmt = Formatter.init(arena.allocator());
    const doc = try fmt.fmtProgram(program);
    return render(allocator, doc, LINE_WIDTH);
}

/// A string literal's content (its raw lexeme between the quotes) needs the
/// `"""` fences when it spans lines or holds an unescaped `"` — a `"…"`
/// literal cannot carry either.
fn needsTripleQuotes(s: []const u8) bool {
    if (std.mem.indexOfScalar(u8, s, '\n') != null) return true;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] == '\\') {
            i += 1;
            continue;
        }
        if (s[i] == '"') return true;
    }
    return false;
}
