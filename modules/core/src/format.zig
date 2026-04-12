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

    fn alloc(self: *Formatter, doc: Doc) !*const Doc {
        const p = try self.arena.create(Doc);
        p.* = doc;
        return p;
    }

    pub fn nil(_: *Formatter) *const Doc {
        return &DOC_NIL;
    }

    pub fn text(self: *Formatter, s: []const u8) !*const Doc {
        return self.alloc(.{ .text = s });
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

    pub fn concat(self: *Formatter, left: *const Doc, right: *const Doc) !*const Doc {
        return self.alloc(.{ .concat = .{ .left = left, .right = right } });
    }

    pub fn nest(self: *Formatter, amount: usize, doc: *const Doc) !*const Doc {
        return self.alloc(.{ .nest = .{ .amount = amount, .doc = doc } });
    }

    pub fn group(self: *Formatter, doc: *const Doc) !*const Doc {
        return self.alloc(.{ .group = doc });
    }

    pub fn forceBreak(self: *Formatter, doc: *const Doc) !*const Doc {
        return self.alloc(.{ .forceBreak = doc });
    }

    // ── higher-level combinators ───────────────────────────────────────────────

    /// Concatenate a slice of documents left-to-right.
    fn concatAll(self: *Formatter, docs: []const *const Doc) !*const Doc {
        if (docs.len == 0) return self.nil();
        var acc = docs[docs.len - 1];
        var i = docs.len - 1;
        while (i > 0) {
            i -= 1;
            acc = try self.concat(docs[i], acc);
        }
        return acc;
    }

    /// Join documents with a separator in between.
    fn join(self: *Formatter, items: []const *const Doc, sep: *const Doc) !*const Doc {
        if (items.len == 0) return self.nil();
        var acc = items[0];
        for (items[1..]) |item| {
            acc = try self.concat(acc, try self.concat(sep, item));
        }
        return acc;
    }

    /// Like `join` but the separator is placed BETWEEN items (no trailing).
    fn joinWith(self: *Formatter, items: []const *const Doc, sep: *const Doc) !*const Doc {
        return self.join(items, sep);
    }

    /// `open inner close` with no breaks (for single-line formatting).
    fn surroundFlat(self: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return try self.concatAll(&.{
            try self.text(open),
            try self.text(" "),
            inner,
            try self.text(" "),
            try self.text(close),
        });
    }

    /// `open` + nest(INDENT, line + inner) + line + `close`, grouped.
    /// In flat mode: `open inner close`; in break mode: multi-line block.
    fn surround(self: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return self.group(try self.concatAll(&.{
            try self.text(open),
            try self.nest(INDENT, try self.concat(self.line(), inner)),
            self.line(),
            try self.text(close),
        }));
    }

    /// Like `surround` but always breaks (for bodies that are multi-statement).
    fn surroundBreak(self: *Formatter, open: []const u8, inner: *const Doc, close: []const u8) !*const Doc {
        return self.forceBreak(try self.concatAll(&.{
            try self.text(open),
            try self.nest(INDENT, try self.concat(self.hardline(), inner)),
            self.hardline(),
            try self.text(close),
        }));
    }

    /// Comma-separated list grouped in `open`/`close` delimiters.
    /// In flat mode: `(a, b, c)` ---- no extra spaces inside.
    /// In break mode: each item on its own indented line.
    fn commaList(self: *Formatter, open: []const u8, items: []const *const Doc, close: []const u8) !*const Doc {
        if (items.len == 0) {
            return self.text(try std.fmt.allocPrint(self.arena, "{s}{s}", .{ open, close }));
        }
        // `line` after comma: space in flat, newline+indent in break.
        const commaLine = try self.concat(try self.text(","), self.line());
        const inner = try self.join(items, commaLine);
        // `softline` at boundaries: empty in flat, newline+indent in break.
        return self.group(try self.concatAll(&.{
            try self.text(open),
            try self.nest(INDENT, try self.concat(self.softline(), inner)),
            self.softline(),
            try self.text(close),
        }));
    }

    // ── parameter formatting ───────────────────────────────────────────────────

    fn fmtGenericParams(self: *Formatter, gps: []ast.GenericParam) !*const Doc {
        if (gps.len == 0) return self.nil();
        var items = try self.arena.alloc(*const Doc, gps.len);
        for (gps, 0..) |gp, i| items[i] = try self.text(gp.name);
        return self.commaList("<", items, ">");
    }

    fn fmtFnType(self: *Formatter, ft: ast.FnType) !*const Doc {
        var items = try self.arena.alloc(*const Doc, ft.params.len);
        for (ft.params, 0..) |p, i| {
            items[i] = try self.text(try std.fmt.allocPrint(
                self.arena,
                "{s}: {s}",
                .{ p.name, p.typeName },
            ));
        }
        const paramsDoc = try self.commaList("(", items, ")");
        if (ft.returnType) |ret| {
            return self.concatAll(&.{
                try self.text("fn"),
                paramsDoc,
                try self.text(try std.fmt.allocPrint(self.arena, " -> {s}", .{ret})),
            });
        }
        return self.concat(try self.text("fn"), paramsDoc);
    }

    fn fmtParam(self: *Formatter, p: ast.Param) !*const Doc {
        // Destructuring param
        if (p.destruct) |d| {
            const names = switch (d) {
                .record_, .tuple_ => |ns| ns,
            };
            var nameDocs = try self.arena.alloc(*const Doc, names.len);
            for (names, 0..) |n, i| nameDocs[i] = try self.text(n);
            const namesList = try self.join(nameDocs, try self.text(", "));
            const pattern: *const Doc = switch (d) {
                .record_ => try self.concat(try self.text("{ "), try self.concat(namesList, try self.text(" }"))),
                .tuple_ => try self.concatAll(&.{ try self.text("#("), namesList, try self.text(")") }),
            };
            return self.concatAll(&.{
                pattern,
                try self.text(": "),
                try self.text(p.typeName),
            });
        }
        // Typeinfo params use a special form: `comptime: typeinfo TypeVar [constraints]`
        // where `p.name` holds the type-variable name (e.g. `T`).
        if (p.modifier == .typeinfo) {
            const constraintDoc: *const Doc = if (p.typeinfoConstraints) |cs| blk: {
                var parts = try self.arena.alloc(*const Doc, cs.len);
                for (cs, 0..) |c, i| parts[i] = try self.text(c);
                const joined = try self.join(parts, try self.text(" | "));
                break :blk try self.concat(try self.text(" "), joined);
            } else self.nil();
            return self.concatAll(&.{
                try self.text("comptime: typeinfo "),
                try self.text(p.name),
                constraintDoc,
            });
        }
        // For comptime and syntax params the modifier appears between the name and
        // the colon: `name comptime: [syntax] type`.
        const preColon: *const Doc = switch (p.modifier) {
            .none => try self.text(": "),
            .@"comptime" => try self.text(" comptime: "),
            .syntax => try self.text(" comptime: syntax "),
            .typeinfo => unreachable, // handled above
        };
        const typeDoc: *const Doc = if (p.modifier == .syntax) blk: {
            if (p.fnType) |ft| break :blk try self.fmtFnType(ft);
            break :blk try self.text(p.typeName);
        } else try self.text(p.typeName);
        return self.concatAll(&.{
            try self.text(p.name),
            preColon,
            typeDoc,
        });
    }

    fn fmtParams(self: *Formatter, params: []const ast.Param) !*const Doc {
        var items = try self.arena.alloc(*const Doc, params.len);
        for (params, 0..) |p, i| items[i] = try self.fmtParam(p);
        return self.commaList("(", items, ")");
    }

    fn fmtReturnType(self: *Formatter, ret: ?[]const u8) !*const Doc {
        if (ret) |r| return self.text(try std.fmt.allocPrint(self.arena, " -> {s}", .{r}));
        return self.nil();
    }

    fn fmtReturnTypeRef(self: *Formatter, ret: ?ast.TypeRef) !*const Doc {
        if (ret) |r| return self.concat(try self.text(" -> "), try self.fmtTypeRef(r));
        return self.nil();
    }

    // ── body / statements ──────────────────────────────────────────────────────

    fn fmtBody(self: *Formatter, stmts: []ast.Stmt) !*const Doc {
        if (stmts.len == 0) return self.text("{}");
        var items = try self.arena.alloc(*const Doc, stmts.len);
        for (stmts, 0..) |s, i| {
            const exprDoc = try self.fmtExpr(s.expr);
            items[i] = try self.concat(exprDoc, try self.text(";"));
        }
        const inner = try self.join(items, self.hardline());
        return self.surroundBreak("{", inner, "}");
    }

    fn fmtOptionalBody(self: *Formatter, body: ?[]ast.Stmt) !*const Doc {
        if (body) |stmts| return self.fmtBody(stmts);
        return self.nil();
    }

    // ── expressions ───────────────────────────────────────────────────────────

    pub fn fmtExpr(self: *Formatter, expr: ast.Expr) anyerror!*const Doc {
        return switch (expr.kind) {
            .stringLit => |s| self.text(try std.fmt.allocPrint(self.arena, "\"{s}\"", .{s})),
            .numberLit => |n| self.text(n),
            .ident => |id| self.text(id),
            .dotIdent => |name| self.text(
                try std.fmt.allocPrint(self.arena, ".{s}", .{name}),
            ),
            .todo => self.text("todo"),

            .builtinCall => |c| blk: {
                var argDocs = try self.arena.alloc(*const Doc, c.args.len);
                for (c.args, 0..) |a, i| {
                    argDocs[i] = try self.fmtExpr(a.value.*);
                }
                const argsDoc = if (c.args.len == 0)
                    self.nil()
                else
                    try self.join(argDocs, try self.text(", "));
                break :blk self.concatAll(&.{
                    try self.text(c.name),
                    try self.text("("),
                    argsDoc,
                    try self.text(")"),
                });
            },

            .identAccess => |ia| self.concatAll(&.{
                try self.fmtExpr(ia.receiver.*),
                try self.text("."),
                try self.text(ia.member),
            }),

            .fieldAssign => |a| self.concatAll(&.{
                try self.fmtExpr(a.receiver.*),
                try self.text("."),
                try self.text(a.field),
                try self.text(" = "),
                try self.fmtExpr(a.value.*),
            }),

            .fieldPlusEq => |a| self.concatAll(&.{
                try self.fmtExpr(a.receiver.*),
                try self.text("."),
                try self.text(a.field),
                try self.text(" += "),
                try self.fmtExpr(a.value.*),
            }),

            .@"return" => |e| self.concat(try self.text("return "), try self.fmtExpr(e.*)),

            .throw_ => |e| self.concat(try self.text("throw "), try self.fmtExpr(e.*)),

            .null_ => self.text("null"),

            .if_ => |i| blk: {
                const condDoc = try self.fmtExpr(i.cond.*);
                // Build then block: with or without binding
                const thenDoc = if (i.binding) |b| blk2: {
                    var items = try self.arena.alloc(*const Doc, i.then_.len);
                    for (i.then_, 0..) |s, idx| items[idx] = try self.fmtExpr(s.expr);
                    const body = try self.join(items, self.hardline());
                    const inner = try self.concatAll(&.{
                        try self.text(b),
                        try self.text(" ->"),
                        self.hardline(),
                        body,
                    });
                    break :blk2 try self.surroundBreak("{", inner, "}");
                } else try self.fmtBody(i.then_);
                if (i.else_) |els| {
                    break :blk self.concatAll(&.{
                        try self.text("if ("),
                        condDoc,
                        try self.text(") "),
                        thenDoc,
                        try self.text(" else "),
                        try self.fmtBody(els),
                    });
                }
                break :blk self.concatAll(&.{
                    try self.text("if ("),
                    condDoc,
                    try self.text(") "),
                    thenDoc,
                });
            },

            .try_ => |e| self.concat(try self.text("try "), try self.fmtExpr(e.*)),

            .tryCatch => |tc| self.concatAll(&.{
                try self.text("try "),
                try self.fmtExpr(tc.expr.*),
                try self.text(" catch "),
                try self.fmtExpr(tc.handler.*),
            }),

            .add => |op| self.fmtBinop(op.lhs.*, " + ", op.rhs.*),
            .sub => |op| self.fmtBinop(op.lhs.*, " - ", op.rhs.*),
            .mul => |op| self.fmtBinop(op.lhs.*, " * ", op.rhs.*),
            .div => |op| self.fmtBinop(op.lhs.*, " / ", op.rhs.*),
            .mod => |op| self.fmtBinop(op.lhs.*, " % ", op.rhs.*),
            .lt => |op| self.fmtBinop(op.lhs.*, " < ", op.rhs.*),
            .gt => |op| self.fmtBinop(op.lhs.*, " > ", op.rhs.*),
            .lte => |op| self.fmtBinop(op.lhs.*, " <= ", op.rhs.*),
            .gte => |op| self.fmtBinop(op.lhs.*, " >= ", op.rhs.*),
            .eq => |op| self.fmtBinop(op.lhs.*, " == ", op.rhs.*),
            .ne => |op| self.fmtBinop(op.lhs.*, " != ", op.rhs.*),

            .staticCall => |c| self.concatAll(&.{
                try self.text(try std.fmt.allocPrint(self.arena, "{s}.{s}(", .{ c.receiver, c.method })),
                try self.fmtExpr(c.arg.*),
                try self.text(")"),
            }),

            .call => |c| try self.fmtCall(c),

            .lambda => |l| try self.fmtLambda(l.params, l.body),

            .case => |c| try self.fmtCase(c.subject.*, c.arms),

            .localBind => |lb| self.concatAll(&.{
                try self.text(if (lb.mutable) "var " else "val "),
                try self.text(lb.name),
                try self.text(" = "),
                try self.fmtExpr(lb.value.*),
            }),

            .assign => |a| self.concatAll(&.{
                try self.text(a.name),
                try self.text(" = "),
                try self.fmtExpr(a.value.*),
            }),

            .localBindDestruct => |lb| blk: {
                const kw = if (lb.mutable) "var " else "val ";
                const names = switch (lb.pattern) {
                    .record_, .tuple_ => |ns| ns,
                };
                var nameDocs = try self.arena.alloc(*const Doc, names.len);
                for (names, 0..) |n, i| nameDocs[i] = try self.text(n);
                const namesList = try self.join(nameDocs, try self.text(", "));
                const pattern: *const Doc = switch (lb.pattern) {
                    .record_ => try self.concat(try self.text("{ "), try self.concat(namesList, try self.text(" }"))),
                    .tuple_ => try self.concatAll(&.{ try self.text("#("), namesList, try self.text(")") }),
                };
                break :blk self.concatAll(&.{
                    try self.text(kw),
                    pattern,
                    try self.text(" = "),
                    try self.fmtExpr(lb.value.*),
                });
            },

            .arrayLit => |elems| blk: {
                var docs = try self.arena.alloc(*const Doc, elems.len);
                for (elems, 0..) |e, i| docs[i] = try self.fmtExpr(e);
                const inner = if (elems.len == 0)
                    self.nil()
                else
                    try self.join(docs, try self.text(", "));
                break :blk self.concatAll(&.{
                    try self.text("["),
                    inner,
                    try self.text("]"),
                });
            },

            .tupleLit => |elems| blk: {
                var docs = try self.arena.alloc(*const Doc, elems.len);
                for (elems, 0..) |e, i| docs[i] = try self.fmtExpr(e);
                const inner = if (elems.len == 0)
                    self.nil()
                else
                    try self.join(docs, try self.text(", "));
                break :blk self.concatAll(&.{
                    try self.text("#("),
                    inner,
                    try self.text(")"),
                });
            },

            .@"comptime" => |e| self.concat(try self.text("comptime "), try self.fmtExpr(e.*)),

            .comptimeBlock => |cb| blk: {
                var items = try self.arena.alloc(*const Doc, cb.body.len);
                for (cb.body, 0..) |s, i| {
                    const exprDoc = try self.fmtExpr(s.expr);
                    items[i] = try self.concat(exprDoc, try self.text(";"));
                }
                const inner = try self.join(items, self.hardline());
                break :blk self.concat(
                    try self.text("comptime "),
                    try self.surroundBreak("{", inner, "}"),
                );
            },

            .@"break" => |e| if (e) |ep|
                self.concat(try self.text("break "), try self.fmtExpr(ep.*))
            else
                self.text("break"),
            .yield => |e| self.concat(try self.text("yield "), try self.fmtExpr(e.*)),
            .@"continue" => self.text("continue"),
            .range => |r| if (r.end) |end|
                self.concat(try self.fmtExpr(r.start.*), try self.concat(try self.text(".."), try self.fmtExpr(end.*)))
            else
                self.concat(try self.fmtExpr(r.start.*), try self.text("..")),
            .loop => |lp| blk: {
                var doc: *const Doc = try self.text("loop (");
                doc = try self.concat(doc, try self.fmtExpr(lp.iter.*));
                if (lp.indexRange) |ir| {
                    doc = try self.concat(doc, try self.text(", "));
                    doc = try self.concat(doc, try self.fmtExpr(ir.*));
                }
                doc = try self.concat(doc, try self.text(") {"));
                for (lp.params, 0..) |p, i| {
                    doc = try self.concat(doc, if (i == 0) try self.text(" ") else try self.text(", "));
                    doc = try self.concat(doc, try self.text(p));
                }
                doc = try self.concat(doc, try self.text(" ->"));
                for (lp.body) |stmt| {
                    doc = try self.concat(doc, try self.surroundBreak("", try self.fmtExpr(stmt.expr), ""));
                }
                doc = try self.concat(doc, try self.text("}"));
                break :blk doc;
            },
        };
    }

    fn fmtBinop(self: *Formatter, lhs: ast.Expr, op: []const u8, rhs: ast.Expr) !*const Doc {
        return self.concatAll(&.{
            try self.fmtExpr(lhs),
            try self.text(op),
            try self.fmtExpr(rhs),
        });
    }

    fn fmtCall(self: *Formatter, c: anytype) anyerror!*const Doc {
        // Build regular arg list
        var argDocs = try self.arena.alloc(*const Doc, c.args.len);
        for (c.args, 0..) |a, i| {
            if (a.label) |lbl| {
                argDocs[i] = try self.concatAll(&.{
                    try self.text(lbl),
                    try self.text(": "),
                    try self.fmtExpr(a.value.*),
                });
            } else {
                argDocs[i] = try self.fmtExpr(a.value.*);
            }
        }

        const callee: *const Doc = if (c.receiver) |recv|
            try self.text(try std.fmt.allocPrint(self.arena, "{s}.{s}", .{ recv, c.callee }))
        else
            try self.text(c.callee);

        const argsDoc = try self.commaList("(", argDocs, ")");

        // No trailing lambdas → simple call
        if (c.trailing.len == 0) {
            // If there were explicit parens but no args, still emit ()
            if (c.args.len > 0) {
                return self.concat(callee, argsDoc);
            }
            return self.concat(callee, argsDoc);
        }

        // Build trailing lambdas
        var parts: std.ArrayList(*const Doc) = .empty;
        try parts.append(self.arena, callee);
        if (c.args.len > 0) try parts.append(self.arena, argsDoc);
        try parts.append(self.arena, try self.text(" "));

        for (c.trailing, 0..) |tl, ti| {
            if (ti > 0) try parts.append(self.arena, try self.text(" "));
            if (tl.label) |lbl| {
                try parts.append(self.arena, try self.text(lbl));
                try parts.append(self.arena, try self.text(": "));
            }
            try parts.append(self.arena, try self.fmtLambda(tl.params, tl.body));
        }

        return self.concatAll(parts.items);
    }

    fn fmtLambda(self: *Formatter, params: []const []const u8, body: []ast.Stmt) !*const Doc {
        var innerItems = try self.arena.alloc(*const Doc, body.len);
        for (body, 0..) |s, i| {
            const exprDoc = try self.fmtExpr(s.expr);
            innerItems[i] = try self.concat(exprDoc, try self.text(";"));
        }
        const inner = try self.join(innerItems, self.hardline());

        if (params.len == 0) {
            return self.surroundBreak("{", inner, "}");
        }

        // `{ a, b -> ... }`
        var paramDocs = try self.arena.alloc(*const Doc, params.len);
        for (params, 0..) |p, i| paramDocs[i] = try self.text(p);
        const paramList = try self.join(paramDocs, try self.text(", "));

        // `{ a, b ->\n    body\n}`
        return self.forceBreak(try self.concatAll(&.{
            try self.text("{ "),
            paramList,
            try self.text(" ->"),
            try self.nest(INDENT, try self.concat(self.hardline(), inner)),
            self.hardline(),
            try self.text("}"),
        }));
    }

    fn fmtCase(self: *Formatter, subject: ast.Expr, arms: []ast.CaseArm) !*const Doc {
        var armDocs = try self.arena.alloc(*const Doc, arms.len);
        for (arms, 0..) |arm, i| {
            armDocs[i] = try self.concatAll(&.{
                try self.fmtPattern(arm.pattern),
                try self.text(" -> "),
                try self.fmtExpr(arm.body),
                try self.text(";"),
            });
        }
        const armsDoc = try self.join(armDocs, self.hardline());
        return self.concatAll(&.{
            try self.text("case "),
            try self.fmtExpr(subject),
            try self.text(" "),
            try self.surroundBreak("{", armsDoc, "}"),
        });
    }

    // ── patterns ──────────────────────────────────────────────────────────────

    fn fmtPattern(self: *Formatter, pat: ast.Pattern) !*const Doc {
        return switch (pat) {
            .wildcard => self.text("else"),
            .ident => |id| self.text(id),
            .numberLit => |n| self.text(n),
            .stringLit => |s| self.text(try std.fmt.allocPrint(self.arena, "\"{s}\"", .{s})),

            .variantFields => |vf| {
                var items = try self.arena.alloc(*const Doc, vf.bindings.len);
                for (vf.bindings, 0..) |b, i| items[i] = try self.text(b);
                return self.concat(
                    try self.text(vf.name),
                    try self.commaList("(", items, ")"),
                );
            },

            .list => |l| {
                var items: std.ArrayList(*const Doc) = .empty;
                for (l.elems) |elem| {
                    const d: *const Doc = switch (elem) {
                        .wildcard => try self.text("_"),
                        .bind => |b| try self.text(b),
                        .numberLit => |n| try self.text(n),
                    };
                    try items.append(self.arena, d);
                }
                if (l.spread) |sp| {
                    const spreadDoc = if (sp.len == 0)
                        try self.text("..")
                    else
                        try self.text(try std.fmt.allocPrint(self.arena, "..{s}", .{sp}));
                    try items.append(self.arena, spreadDoc);
                }
                return self.commaList("[", items.items, "]");
            },

            .@"or" => |pats| {
                var docs = try self.arena.alloc(*const Doc, pats.len);
                for (pats, 0..) |p, i| docs[i] = try self.fmtPattern(p);
                return self.join(docs, try self.text(" | "));
            },
        };
    }

    // ── declarations ──────────────────────────────────────────────────────────

    pub fn fmtProgram(self: *Formatter, program: ast.Program) !*const Doc {
        if (program.decls.len == 0) return self.nil();
        var docs = try self.arena.alloc(*const Doc, program.decls.len);
        for (program.decls, 0..) |d, i| {
            const declDoc = try self.fmtDecl(d);
            // Add semicolon after declarations that don't have a body
            // (use, delegate, struct/record/enum/interface without methods)
            // But NOT after fn or declarations with methods
            const needsSemi = switch (d) {
                .@"fn" => false,
                .val => true,
                .@"struct" => true,
                .record => true,
                .@"enum" => true,
                .interface => true,
                .use, .delegate, .implement => true,
            };
            docs[i] = if (needsSemi)
                try self.concat(declDoc, try self.text(";"))
            else
                declDoc;
        }
        // Two newlines between top-level declarations (blank line).
        const sep = try self.concat(self.hardline(), self.hardline());
        return self.join(docs, sep);
    }

    fn fmtDecl(self: *Formatter, decl: ast.DeclKind) !*const Doc {
        return switch (decl) {
            .use => |u| self.fmtUse(u),
            .interface => |iface| self.fmtInterface(iface),
            .delegate => |d| self.fmtDelegate(d),
            .@"struct" => |s| self.fmtStruct(s),
            .record => |r| self.fmtRecord(r),
            .@"enum" => |e| self.fmtEnum(e),
            .implement => |impl| self.fmtImplement(impl),
            .@"fn" => |f| self.fmtFnDecl(f),
            .val => |v| self.fmtValDecl(v),
        };
    }

    fn fmtUse(self: *Formatter, u: ast.UseDecl) !*const Doc {
        var items = try self.arena.alloc(*const Doc, u.imports.len);
        for (u.imports, 0..) |imp, i| items[i] = try self.text(imp);
        const importsDoc = try self.commaList("{", items, "}");
        const sourceDoc: *const Doc = switch (u.source) {
            .stringPath => |s| try self.text(try std.fmt.allocPrint(self.arena, "\"{s}\"", .{s})),
            .functionCall => |f| try self.text(try std.fmt.allocPrint(self.arena, "{s}()", .{f})),
        };
        return self.concatAll(&.{
            try self.text("use "),
            importsDoc,
            try self.text(" from "),
            sourceDoc,
        });
    }

    fn fmtDelegate(self: *Formatter, d: ast.DelegateDecl) !*const Doc {
        const prefix: *const Doc = if (d.isPub)
            try self.text("pub declare fn ")
        else
            try self.text("declare fn ");
        return self.concatAll(&.{
            prefix,
            try self.text(d.name),
            try self.fmtParams(d.params),
            try self.fmtReturnType(d.returnType),
        });
    }

    fn fmtAnnotations(self: *Formatter, annotations: []const ast.Annotation) !*const Doc {
        if (annotations.len == 0) return self.nil();
        var docs: std.ArrayList(*const Doc) = .empty;
        defer docs.deinit(self.arena);
        for (annotations) |ann| {
            if (ann.args.len == 0) {
                try docs.append(self.arena, try self.text(
                    try std.fmt.allocPrint(self.arena, "#[{s}]", .{ann.name}),
                ));
            } else {
                const argsStr = try std.mem.join(self.arena, ", ", ann.args);
                try docs.append(self.arena, try self.text(
                    try std.fmt.allocPrint(self.arena, "#[{s}({s})]", .{ ann.name, argsStr }),
                ));
            }
        }
        const sep = try self.concat(self.hardline(), try self.text(""));
        const annsDoc = try self.join(docs.items, sep);
        return self.concat(annsDoc, self.hardline());
    }

    fn fmtInterface(self: *Formatter, iface: ast.InterfaceDecl) !*const Doc {
        var members: std.ArrayList(*const Doc) = .empty;

        for (iface.fields) |f| {
            try members.append(self.arena, try self.text(
                try std.fmt.allocPrint(self.arena, "val {s}: {s},", .{ f.name, f.typeName }),
            ));
        }
        for (iface.methods) |m| {
            const methodDoc = try self.fmtInterfaceMethod(m);
            try members.append(self.arena, methodDoc);
        }

        const body = if (members.items.len == 0)
            try self.text("{}")
        else blk: {
            const inner = try self.join(members.items, self.hardline());
            break :blk try self.surroundBreak("{", inner, "}");
        };

        const extendsDoc = if (iface.extends.len == 0)
            try self.text("")
        else blk: {
            var parts: std.ArrayList(*const Doc) = .empty;
            defer parts.deinit(self.arena);
            try parts.append(self.arena, try self.text(" extends "));
            for (iface.extends, 0..) |sup, i| {
                if (i > 0) try parts.append(self.arena, try self.text(", "));
                try parts.append(self.arena, try self.text(sup));
            }
            break :blk try self.concatAll(parts.items);
        };

        return self.concatAll(&.{
            try self.fmtAnnotations(iface.annotations),
            try self.text("val "),
            try self.text(iface.name),
            try self.fmtGenericParams(iface.genericParams),
            try self.text(" = interface"),
            extendsDoc,
            try self.text(" "),
            body,
        });
    }

    fn fmtInterfaceMethod(self: *Formatter, m: ast.InterfaceMethod) !*const Doc {
        const pub_prefix: *const Doc = if (m.isPub) try self.text("pub ") else try self.text("");
        const fn_kw = if (m.is_default)
            try self.text("default fn ")
        else if (m.is_declare)
            try self.text("declare fn ")
        else
            try self.text("fn ");
        const sig = try self.concatAll(&.{
            pub_prefix,
            fn_kw,
            try self.text(m.name),
            try self.fmtGenericParams(m.genericParams),
            try self.fmtParams(m.params),
            try self.fmtReturnTypeRef(m.returnType),
        });
        if (m.body) |stmts| {
            return self.concatAll(&.{
                sig,
                try self.text(" "),
                try self.fmtBody(stmts),
            });
        }
        // Abstract method - add semicolon
        return self.concat(sig, try self.text(";"));
    }

    fn fmtStruct(self: *Formatter, s: ast.StructDecl) !*const Doc {
        // Check if there are any methods (fn/get/set)
        var hasMethods = false;
        for (s.members) |m| {
            switch (m) {
                .field => {},
                .getter, .setter, .method => hasMethods = true,
            }
        }

        var members = try self.arena.alloc(*const Doc, s.members.len);
        for (s.members, 0..) |m, i| {
            members[i] = try self.fmtStructMemberWithComma(m);
        }

        const body = if (members.len == 0)
            try self.text("{}")
        else if (!hasMethods) blk: {
            // Single line: struct {field: Type = expr, field2: Type = expr}
            const withCommas = try self.arena.alloc(*const Doc, members.len);
            for (members, 0..) |item, i| {
                const isLast = i == members.len - 1;
                withCommas[i] = if (!isLast)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.joinWith(withCommas, try self.text(" "));
            break :blk try self.surroundFlat("{", inner, "}");
        }
        else blk: {
            const withCommas = try self.arena.alloc(*const Doc, members.len);
            for (members, 0..) |item, i| {
                const isLastItem = i == members.len - 1;
                // Add comma after fields but not after methods
                const needsComma = switch (s.members[i]) {
                    .field => true,
                    .getter, .setter, .method => false,
                };
                withCommas[i] = if (needsComma and !isLastItem)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.join(withCommas, self.hardline());
            break :blk try self.surroundBreak("{", inner, "}");
        };

        return self.concatAll(&.{
            try self.fmtAnnotations(s.annotations),
            try self.text("val "),
            try self.text(s.name),
            try self.fmtGenericParams(s.genericParams),
            try self.text(" = struct "),
            body,
        });
    }

    fn fmtStructMemberWithComma(self: *Formatter, m: ast.StructMember) !*const Doc {
        return switch (m) {
            .field => |f| self.fmtStructField(f),
            .getter => |g| self.fmtGetter(g),
            .setter => |s| self.fmtSetter(s),
            .method => |meth| self.fmtInterfaceMethod(meth),
        };
    }

    fn fmtStructMember(self: *Formatter, m: ast.StructMember) !*const Doc {
        return switch (m) {
            .field => |f| self.fmtStructField(f),
            .getter => |g| self.fmtGetter(g),
            .setter => |s| self.fmtSetter(s),
            .method => |meth| self.fmtInterfaceMethod(meth),
        };
    }

    fn fmtStructField(self: *Formatter, f: ast.StructField) !*const Doc {
        if (f.init) |initExpr| {
            return self.concatAll(&.{
                try self.text(f.name),
                try self.text(": "),
                try self.text(f.typeName),
                try self.text(" = "),
                try self.fmtExpr(initExpr),
            });
        } else {
            return self.concatAll(&.{
                try self.text(f.name),
                try self.text(": "),
                try self.text(f.typeName),
            });
        }
    }

    fn fmtGetter(self: *Formatter, g: ast.StructGetter) !*const Doc {
        const selfParams: []const ast.Param = &.{g.selfParam};
        return self.concatAll(&.{
            try self.text("get "),
            try self.text(g.name),
            try self.fmtParams(selfParams),
            try self.text(try std.fmt.allocPrint(self.arena, " -> {s} ", .{g.returnType})),
            try self.fmtBody(g.body),
        });
    }

    fn fmtSetter(self: *Formatter, s: ast.StructSetter) !*const Doc {
        return self.concatAll(&.{
            try self.text("set "),
            try self.text(s.name),
            try self.fmtParams(s.params),
            try self.text(" "),
            try self.fmtBody(s.body),
        });
    }

    fn fmtRecord(self: *Formatter, r: ast.RecordDecl) !*const Doc {
        // Check if there are any methods
        var hasMethods = false;
        for (r.methods) |_| {
            hasMethods = true;
            break;
        }

        var fieldDocs = try self.arena.alloc(*const Doc, r.fields.len);
        for (r.fields, 0..) |f, i| {
            const typeDoc = try self.fmtTypeRef(f.typeRef);
            fieldDocs[i] = try self.concatAll(&.{
                try self.text(f.name),
                try self.text(": "),
                typeDoc,
            });
            if (f.default) |d| {
                fieldDocs[i] = try self.concatAll(&.{
                    fieldDocs[i],
                    try self.text(" = "),
                    try self.fmtExpr(d),
                });
            }
        }

        var methodDocs = try self.arena.alloc(*const Doc, r.methods.len);
        for (r.methods, 0..) |m, i| methodDocs[i] = try self.fmtInterfaceMethod(m);

        const allItems = try self.arena.alloc(*const Doc, fieldDocs.len + methodDocs.len);
        @memcpy(allItems[0..fieldDocs.len], fieldDocs);
        @memcpy(allItems[fieldDocs.len..], methodDocs);

        const body = if (allItems.len == 0)
            try self.text("{}")
        else if (!hasMethods) blk: {
            // Single line: record { field: Type, field2: Type }
            const withCommas = try self.arena.alloc(*const Doc, allItems.len);
            for (allItems, 0..) |item, i| {
                const isLast = i == allItems.len - 1;
                withCommas[i] = if (!isLast)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.joinWith(withCommas, try self.text(" "));
            break :blk try self.surroundFlat("{", inner, "}");
        }
        else blk: {
            const withCommas = try self.arena.alloc(*const Doc, allItems.len);
            for (allItems, 0..) |item, i| {
                const isLast = i == allItems.len - 1;
                withCommas[i] = if (!isLast)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.join(withCommas, self.hardline());
            break :blk try self.surroundBreak("{", inner, "}");
        };

        return self.concatAll(&.{
            try self.fmtAnnotations(r.annotations),
            try self.text("val "),
            try self.text(r.name),
            try self.fmtGenericParams(r.genericParams),
            try self.text(" = record "),
            body,
        });
    }

    fn fmtEnum(self: *Formatter, e: ast.EnumDecl) !*const Doc {
        // Check if there are any methods
        var hasMethods = false;
        for (e.methods) |_| {
            hasMethods = true;
            break;
        }

        var variantDocs = try self.arena.alloc(*const Doc, e.variants.len);
        for (e.variants, 0..) |v, i| {
            if (v.fields.len == 0) {
                variantDocs[i] = try self.text(v.name);
            } else {
                var fieldDocs = try self.arena.alloc(*const Doc, v.fields.len);
                for (v.fields, 0..) |f, fi| {
                    fieldDocs[fi] = try self.concatAll(&.{
                        try self.text(f.name),
                        try self.text(": "),
                        try self.fmtTypeRef(f.typeRef),
                    });
                }
                variantDocs[i] = try self.concat(
                    try self.text(v.name),
                    try self.commaList("(", fieldDocs, ")"),
                );
            }
        }

        var methodDocs = try self.arena.alloc(*const Doc, e.methods.len);
        for (e.methods, 0..) |m, i| methodDocs[i] = try self.fmtInterfaceMethod(m);

        const allItems = try self.arena.alloc(*const Doc, variantDocs.len + methodDocs.len);
        @memcpy(allItems[0..variantDocs.len], variantDocs);
        @memcpy(allItems[variantDocs.len..], methodDocs);

        const body = if (allItems.len == 0)
            try self.text("{}")
        else if (!hasMethods) blk: {
            // Single line: enum { Variant1, Variant2 }
            const withCommas = try self.arena.alloc(*const Doc, allItems.len);
            for (allItems, 0..) |item, i| {
                const isLast = i == allItems.len - 1;
                withCommas[i] = if (!isLast)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.joinWith(withCommas, try self.text(" "));
            break :blk try self.surroundFlat("{", inner, "}");
        }
        else blk: {
            const withCommas = try self.arena.alloc(*const Doc, allItems.len);
            for (allItems, 0..) |item, i| {
                const isLast = i == allItems.len - 1;
                withCommas[i] = if (!isLast)
                    try self.concat(item, try self.text(","))
                else
                    item;
            }
            const inner = try self.join(withCommas, self.hardline());
            break :blk try self.surroundBreak("{", inner, "}");
        };

        return self.concatAll(&.{
            try self.fmtAnnotations(e.annotations),
            try self.text("val "),
            try self.text(e.name),
            try self.fmtGenericParams(e.genericParams),
            try self.text(" = enum "),
            body,
        });
    }

    fn fmtImplement(self: *Formatter, impl: ast.ImplementDecl) !*const Doc {
        // `implement Interface1, Interface2 for Type`
        var ifaceDocs = try self.arena.alloc(*const Doc, impl.interfaces.len);
        for (impl.interfaces, 0..) |iface, i| ifaceDocs[i] = try self.text(iface);
        const ifacesDoc = try self.join(ifaceDocs, try self.text(", "));

        var methodDocs = try self.arena.alloc(*const Doc, impl.methods.len);
        for (impl.methods, 0..) |m, i| methodDocs[i] = try self.fmtImplementMethod(m);

        const body = if (methodDocs.len == 0)
            try self.text("{}")
        else blk: {
            const inner = try self.join(methodDocs, self.hardline());
            break :blk try self.surroundBreak("{", inner, "}");
        };

        return self.concatAll(&.{
            try self.text("val "),
            try self.text(impl.name),
            try self.fmtGenericParams(impl.genericParams),
            try self.text(" = implement "),
            ifacesDoc,
            try self.text(" for "),
            try self.text(impl.target),
            try self.text(" "),
            body,
        });
    }

    fn fmtImplementMethod(self: *Formatter, m: ast.ImplementMethod) !*const Doc {
        const nameDoc: *const Doc = if (m.qualifier) |q|
            try self.text(try std.fmt.allocPrint(self.arena, "{s}.{s}", .{ q, m.name }))
        else
            try self.text(m.name);

        return self.concatAll(&.{
            try self.text("fn "),
            nameDoc,
            try self.fmtParams(m.params),
            try self.text(" "),
            try self.fmtBody(m.body),
        });
    }

    fn fmtFnDecl(self: *Formatter, f: ast.FnDecl) !*const Doc {
        const pubPrefix: *const Doc = if (f.isPub)
            try self.text("pub fn ")
        else
            try self.text("fn ");

        return self.concatAll(&.{
            try self.fmtAnnotations(f.annotations),
            pubPrefix,
            try self.text(f.name),
            try self.fmtGenericParams(f.genericParams),
            try self.fmtParams(f.params),
            try self.fmtReturnTypeRef(f.returnType),
            try self.text(" "),
            try self.fmtBody(f.body),
        });
    }

    fn fmtTypeRef(self: *Formatter, ref: ast.TypeRef) anyerror!*const Doc {
        return switch (ref) {
            .named => |n| self.text(n),
            .array => |elem| self.concat(try self.fmtTypeRef(elem.*), try self.text("[]")),
            .optional => |inner| self.concat(try self.text("?"), try self.fmtTypeRef(inner.*)),
            .errorUnion => |eu| self.concatAll(&.{
                try self.fmtTypeRef(eu.errorType.*),
                try self.text("!"),
                try self.fmtTypeRef(eu.payload.*),
            }),
            .tuple_ => |elems| blk: {
                var docs = try self.arena.alloc(*const Doc, elems.len);
                for (elems, 0..) |e, i| docs[i] = try self.fmtTypeRef(e);
                const inner = if (elems.len == 0)
                    self.nil()
                else
                    try self.join(docs, try self.text(", "));
                break :blk self.concatAll(&.{
                    try self.text("#("),
                    inner,
                    try self.text(")"),
                });
            },
        };
    }

    fn fmtValDecl(self: *Formatter, v: ast.ValDecl) !*const Doc {
        if (v.typeAnnotation) |ann| {
            return self.concatAll(&.{
                try self.text("val "),
                try self.text(v.name),
                try self.text(": "),
                try self.fmtTypeRef(ann),
                try self.text(" = "),
                try self.fmtExpr(v.value.*),
            });
        }
        return self.concatAll(&.{
            try self.text("val "),
            try self.text(v.name),
            try self.text(" = "),
            try self.fmtExpr(v.value.*),
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
