/// Erlang codegen backend.
///
/// Translates the botopink typed AST to Erlang source.
///
/// Conventions used:
///   - Variables → CamelCase (first letter uppercased)
///   - String literals → <<"...">> binaries
///   - Function bodies → comma-separated expressions; last is return value
///   - OR patterns  → expanded to multiple Erlang case clauses
///   - `return expr` → bare `expr` (Erlang last-expr return)
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    allocator: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .validationError => |verr| {
                try results.append(allocator, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try allocator.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitErlang(allocator, ct.name, ok.transformed, ok.comptime_vals);
                try results.append(allocator, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try allocator.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ─────────────────────────────────────────────────────────

fn emitErlang(
    allocator: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();

    var em = Emitter.init(allocator, &aw.writer, comptime_vals);

    // Module header
    try aw.writer.print("-module({s}).\n", .{module_name});

    // Collect public function names for export
    var pub_fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    defer pub_fns.deinit(allocator);
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (f.isPub) try pub_fns.append(allocator, f),
            else => {},
        }
    }
    if (pub_fns.items.len > 0) {
        try aw.writer.writeAll("-export([");
        for (pub_fns.items, 0..) |f, i| {
            if (i > 0) try aw.writer.writeAll(", ");
            const arity = blk: {
                var n: usize = 0;
                for (f.params) |p| {
                    if (!std.mem.eql(u8, p.name, "self")) n += 1;
                }
                break :blk n;
            };
            try aw.writer.print("{s}/{d}", .{ f.name, arity });
        }
        try aw.writer.writeAll("]).\n");
    }

    // Emit declarations
    for (program.decls) |decl| {
        try aw.writer.writeByte('\n');
        switch (decl) {
            .val => |v| try em.emitTopVal(v, comptime_vals),
            .@"fn" => |f| try em.emitFn(f),
            .@"struct" => |s| try em.emitStruct(s),
            .record => |r| try em.emitRecord(r),
            .@"enum" => |e| try em.emitEnum(e),
            .interface => |i| try em.emitInterface(i),
            .implement => |im| try em.emitImplement(im),
            .use => |u| try em.emitUse(u),
            .delegate => |d| try aw.writer.print("%% delegate {s}\n", .{d.name}),
        }
    }

    return aw.toOwnedSlice();
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Return a heap-allocated copy of `name` with the first byte uppercased.
/// Caller owns the result.
fn erlangVar(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return allocator.dupe(u8, name);
    const buf = try allocator.dupe(u8, name);
    buf[0] = std.ascii.toUpper(buf[0]);
    return buf;
}

fn isComptimeExpr(e: ast.Expr) bool {
    return switch (e.kind) {
        .@"comptime", .comptimeBlock => true,
        else => false,
    };
}

// ── Emitter ───────────────────────────────────────────────────────────────────

const Emitter = struct {
    out: *std.Io.Writer,
    alloc: std.mem.Allocator,
    cv: std.StringHashMap([]const u8),
    indent: usize = 0,

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8)) Emitter {
        return .{ .out = out, .alloc = alloc, .cv = cv };
    }

    fn w(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }

    fn fmt(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.out.print(f, args);
    }

    fn writeIndent(self: *Emitter) !void {
        for (0..self.indent) |_| try self.w("    ");
    }

    // ── top-level val ─────────────────────────────────────────────────────────

    fn emitTopVal(self: *Emitter, v: ast.ValDecl, cv: std.StringHashMap([]const u8)) !void {
        if (isComptimeExpr(v.value.*)) {
            _ = cv;
            try self.fmt("%% comptime val {s}\n", .{v.name});
            return;
        }
        // Emit as a 0-arity function (Erlang has no top-level constants)
        try self.fmt("{s}() ->\n", .{v.name});
        const saved = self.indent;
        self.indent = 1;
        try self.writeIndent();
        try self.emitExpr(v.value.*);
        self.indent = saved;
        try self.w(".\n");
    }

    // ── fn ────────────────────────────────────────────────────────────────────

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        try self.w(f.name);
        try self.w("(");
        var first = true;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            if (!first) try self.w(", ");
            const vname = try erlangVar(self.alloc, p.name);
            defer self.alloc.free(vname);
            try self.w(vname);
            first = false;
        }
        try self.w(") ->\n");
        const saved = self.indent;
        self.indent = 1;
        try self.emitBody(f.body);
        self.indent = saved;
        try self.w(".\n");
    }

    // ── body (comma-separated stmts; does NOT emit trailing newline) ──────────
    //
    // Callers are responsible for the terminator that follows on the same line:
    //   emitFn  → ".\n"
    //   fun end → "\nINDENT end"

    fn emitBody(self: *Emitter, body: []const ast.Stmt) !void {
        for (body, 0..) |stmt, i| {
            const is_last = (i == body.len - 1);
            try self.writeIndent();
            try self.emitBodyStmt(stmt, is_last);
            if (!is_last) try self.w(",\n");
        }
    }

    /// Emit a statement inside a function body.
    /// When `is_last` is true, `return expr` is emitted as bare `expr`.
    fn emitBodyStmt(self: *Emitter, stmt: ast.Stmt, is_last: bool) !void {
        const e = stmt.expr;
        switch (e.kind) {
            .localBind => |lb| {
                const vname = try erlangVar(self.alloc, lb.name);
                defer self.alloc.free(vname);
                try self.fmt("{s} = ", .{vname});
                try self.emitExpr(lb.value.*);
            },
            .localBindDestruct => |lb| {
                switch (lb.pattern) {
                    .record_ => |ns| {
                        // Emit as a tuple match — limited Erlang mapping
                        try self.w("{");
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            const vname = try erlangVar(self.alloc, n);
                            defer self.alloc.free(vname);
                            try self.w(vname);
                        }
                        try self.w("} = ");
                    },
                    .tuple_ => |ns| {
                        try self.w("{");
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            const vname = try erlangVar(self.alloc, n);
                            defer self.alloc.free(vname);
                            try self.w(vname);
                        }
                        try self.w("} = ");
                    },
                }
                try self.emitExpr(lb.value.*);
            },
            .assign => |a| {
                const vname = try erlangVar(self.alloc, a.name);
                defer self.alloc.free(vname);
                try self.fmt("{s} = ", .{vname});
                try self.emitExpr(a.value.*);
            },
            .@"return" => |r| {
                // In Erlang the last expression is the return value.
                // Emit a bare expression; if not last, wrap in a noop binding.
                if (is_last) {
                    try self.emitExpr(r.*);
                } else {
                    try self.emitExpr(r.*);
                }
            },
            else => try self.emitExpr(e),
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn emitExpr(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e.kind) {
            .numberLit => |n| try self.w(n),
            .stringLit => |s| try self.emitBinary(s),
            .null_ => try self.w("undefined"),
            .ident => |n| {
                const vname = try erlangVar(self.alloc, n);
                defer self.alloc.free(vname);
                try self.w(vname);
            },
            .identAccess => |ia| {
                try self.emitExpr(ia.receiver.*);
                try self.fmt("_{s}", .{ia.member});
            },
            .dotIdent => |n| try self.fmt("{s}", .{n}),
            .todo => try self.w("erlang:error(not_implemented)"),

            .add => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" + ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .sub => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" - ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .mul => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" * ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .div => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" div ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .mod => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" rem ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .lt => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" < ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .gt => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" > ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .lte => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" =< ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .gte => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" >= ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .eq => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" =:= ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .ne => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" =/= ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },

            .@"return" => |r| try self.emitExpr(r.*),
            .throw_ => |r| {
                try self.w("erlang:throw(");
                try self.emitExpr(r.*);
                try self.w(")");
            },

            .localBind => |lb| {
                const vname = try erlangVar(self.alloc, lb.name);
                defer self.alloc.free(vname);
                try self.fmt("{s} = ", .{vname});
                try self.emitExpr(lb.value.*);
            },
            .assign => |a| {
                const vname = try erlangVar(self.alloc, a.name);
                defer self.alloc.free(vname);
                try self.fmt("{s} = ", .{vname});
                try self.emitExpr(a.value.*);
            },
            .localBindDestruct => |lb| {
                switch (lb.pattern) {
                    .record_, .tuple_ => |ns| {
                        try self.w("{");
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            const vname = try erlangVar(self.alloc, n);
                            defer self.alloc.free(vname);
                            try self.w(vname);
                        }
                        try self.w("} = ");
                    },
                }
                try self.emitExpr(lb.value.*);
            },

            .fieldAssign => |sfa| {
                // Erlang records don't support mutation like this; emit a comment
                try self.fmt("%% {s}.{s} = ...", .{ "self", sfa.field });
            },
            .fieldPlusEq => |sfpe| {
                _ = sfpe;
                try self.w("%% field += not directly supported in Erlang");
            },

            .staticCall => |sc| {
                try self.fmt("{s}:{s}(", .{ sc.receiver, sc.method });
                try self.emitExpr(sc.arg.*);
                try self.w(")");
            },

            .call => |c| {
                if (c.receiver) |recv| {
                    try self.fmt("{s}:{s}(", .{ recv, c.callee });
                } else {
                    try self.fmt("{s}(", .{c.callee});
                }
                var first = true;
                for (c.args) |arg| {
                    if (!first) try self.w(", ");
                    try self.emitExpr(arg.value.*);
                    first = false;
                }
                // Trailing lambdas: emit as fun args
                for (c.trailing) |tl| {
                    if (!first) try self.w(", ");
                    first = false;
                    try self.w("fun(");
                    for (tl.params, 0..) |p, pi| {
                        if (pi > 0) try self.w(", ");
                        const vname = try erlangVar(self.alloc, p);
                        defer self.alloc.free(vname);
                        try self.w(vname);
                    }
                    try self.w(") ->\n");
                    const tl_saved = self.indent;
                    self.indent = self.indent + 1;
                    try self.emitBody(tl.body);
                    self.indent = tl_saved;
                    try self.w("\n");
                    try self.writeIndent();
                    try self.w("end");
                }
                try self.w(")");
            },

            .builtinCall => |bc| {
                try self.fmt("{s}(", .{bc.name});
                for (bc.args, 0..) |arg, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(arg.value.*);
                }
                try self.w(")");
            },

            .lambda => |l| {
                try self.w("fun(");
                for (l.params, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    const vname = try erlangVar(self.alloc, p);
                    defer self.alloc.free(vname);
                    try self.w(vname);
                }
                try self.w(") ->\n");
                const lam_saved = self.indent;
                self.indent = self.indent + 1;
                try self.emitBody(l.body);
                self.indent = lam_saved;
                try self.w("\n");
                try self.writeIndent();
                try self.w("end");
            },

            .arrayLit => |elems| {
                try self.w("[");
                for (elems, 0..) |elem, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(elem);
                }
                try self.w("]");
            },
            .tupleLit => |elems| {
                try self.w("{");
                for (elems, 0..) |elem, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(elem);
                }
                try self.w("}");
            },

            .case => |c| try self.emitCase(c.subject.*, c.arms),

            .if_ => |i| {
                try self.w("case ");
                try self.emitExpr(i.cond.*);
                try self.w(" of\n");
                self.indent += 1;
                try self.writeIndent();
                if (i.binding) |_| {
                    try self.w("undefined -> undefined;\n");
                    try self.writeIndent();
                    try self.w("_ ->\n");
                } else {
                    try self.w("true ->\n");
                }
                self.indent += 1;
                try self.emitBranchBody(i.then_);
                self.indent -= 1;
                if (i.else_) |els| {
                    try self.w(";\n");
                    try self.writeIndent();
                    try self.w("false ->\n");
                    self.indent += 1;
                    try self.emitBranchBody(els);
                    self.indent -= 1;
                }
                self.indent -= 1;
                try self.w("\n");
                try self.writeIndent();
                try self.w("end");
            },

            .try_ => |t| try self.emitExpr(t.*),

            .tryCatch => |tc| {
                try self.w("try\n");
                self.indent += 1;
                try self.writeIndent();
                try self.emitExpr(tc.expr.*);
                self.indent -= 1;
                try self.w("\ncatch\n");
                self.indent += 1;
                try self.writeIndent();
                try self.w("_Err ->\n");
                self.indent += 1;
                try self.writeIndent();
                try self.emitExpr(tc.handler.*);
                try self.w("(_Err)");
                self.indent -= 2;
                try self.w("\nend");
            },

            .@"comptime" => |inner| try self.emitExpr(inner.*),
            .comptimeBlock => |cb| {
                for (cb.body) |stmt| {
                    switch (stmt.expr.kind) {
                        .@"break" => |y| {
                            if (y) |yp| try self.emitExpr(yp.*);
                            return;
                        },
                        else => {},
                    }
                }
            },
            .@"break" => |y| if (y) |yp| try self.emitExpr(yp.*),
            .yield => |y| try self.emitExpr(y.*),
            .@"continue" => try self.w("%% continue"),

            .range => |r| {
                try self.w("lists:seq(");
                try self.emitExpr(r.start.*);
                try self.w(", ");
                if (r.end) |end| try self.emitExpr(end.*) else try self.w("infinity");
                try self.w(")");
            },

            .loop => |lp| {
                const has_yield = blk: {
                    for (lp.body) |stmt| {
                        if (stmt.expr.kind == .yield) break :blk true;
                    }
                    break :blk false;
                };
                const fun_kw = if (has_yield) "lists:map" else "lists:foreach";
                try self.fmt("{s}(fun(", .{fun_kw});
                for (lp.params, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    const vname = try erlangVar(self.alloc, p);
                    defer self.alloc.free(vname);
                    try self.w(vname);
                }
                try self.w(") ->\n");
                const fun_body_indent = self.indent + 1;
                const saved2 = self.indent;
                self.indent = fun_body_indent;
                try self.emitBody(lp.body);
                self.indent = saved2;
                try self.w("\n");
                try self.writeIndent();
                try self.w("end, ");
                try self.emitExpr(lp.iter.*);
                try self.w(")");
            },
        }
    }

    // ── if branch body (delegates to emitBody) ────────────────────────────────

    fn emitBranchBody(self: *Emitter, body: []const ast.Stmt) !void {
        try self.emitBody(body);
    }

    // ── case expression ───────────────────────────────────────────────────────

    fn emitCase(self: *Emitter, subject: ast.Expr, arms: []ast.CaseArm) !void {
        try self.w("case ");
        try self.emitExpr(subject);
        try self.w(" of\n");
        self.indent += 1;

        var first_clause = true;
        for (arms) |arm| {
            // OR patterns expand to multiple Erlang clauses with the same body
            switch (arm.pattern) {
                .@"or" => |pats| {
                    for (pats) |p| {
                        if (!first_clause) try self.w(";\n");
                        try self.writeIndent();
                        try self.emitPattern(p);
                        try self.w(" ->\n");
                        self.indent += 1;
                        try self.emitCaseBody(arm.body);
                        self.indent -= 1;
                        first_clause = false;
                    }
                },
                else => {
                    if (!first_clause) try self.w(";\n");
                    try self.writeIndent();
                    try self.emitPattern(arm.pattern);
                    try self.w(" ->\n");
                    self.indent += 1;
                    try self.emitCaseBody(arm.body);
                    self.indent -= 1;
                    first_clause = false;
                },
            }
        }

        self.indent -= 1;
        try self.w("\n");
        try self.writeIndent();
        try self.w("end");
    }

    fn emitPattern(self: *Emitter, pat: ast.Pattern) !void {
        switch (pat) {
            .wildcard => try self.w("_"),
            .ident => |n| try self.w(n), // enum variant → atom
            .numberLit => |n| try self.w(n),
            .stringLit => |s| try self.emitBinary(s),
            .variantFields => |vf| {
                try self.fmt("{{tag, {s}", .{vf.name});
                for (vf.bindings) |bb| {
                    try self.w(", ");
                    const vname = try erlangVar(self.alloc, bb);
                    defer self.alloc.free(vname);
                    try self.w(vname);
                }
                try self.w("}");
            },
            .list => |lp| {
                if (lp.spread) |sp| {
                    if (lp.elems.len == 0 and sp.len == 0) {
                        try self.w("_");
                    } else {
                        try self.w("[");
                        for (lp.elems, 0..) |elem, i| {
                            if (i > 0) try self.w(", ");
                            try self.emitListPatElem(elem);
                        }
                        if (sp.len > 0) {
                            if (lp.elems.len > 0) try self.w(" | ");
                            const vname = try erlangVar(self.alloc, sp);
                            defer self.alloc.free(vname);
                            try self.w(vname);
                        } else {
                            try self.w(" | _");
                        }
                        try self.w("]");
                    }
                } else if (lp.elems.len == 0) {
                    try self.w("[]");
                } else {
                    try self.w("[");
                    for (lp.elems, 0..) |elem, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitListPatElem(elem);
                    }
                    try self.w("]");
                }
            },
            .@"or" => |pats| {
                // Should be expanded by emitCase; fallback: emit first
                if (pats.len > 0) try self.emitPattern(pats[0]);
            },
        }
    }

    fn emitListPatElem(self: *Emitter, elem: ast.ListPatternElem) !void {
        switch (elem) {
            .wildcard => try self.w("_"),
            .bind => |name| {
                const vname = try erlangVar(self.alloc, name);
                defer self.alloc.free(vname);
                try self.w(vname);
            },
            .numberLit => |n| try self.w(n),
        }
    }

    fn emitCaseBody(self: *Emitter, body: ast.Expr) !void {
        if (body.kind == .lambda) {
            // Multi-statement block: emitBody handles indentation via self.indent
            try self.emitBody(body.kind.lambda.body);
        } else {
            // Single expression: emit with current indentation
            try self.writeIndent();
            try self.emitExpr(body);
        }
    }

    // ── struct / record / enum ────────────────────────────────────────────────

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        try self.fmt("-record({s}, {{", .{s.name});
        var first = true;
        for (s.members) |m| switch (m) {
            .field => |f| {
                if (!first) try self.w(", ");
                try self.w(f.name);
                first = false;
            },
            else => {},
        };
        try self.w("}).\n");
        // Emit methods as standalone functions
        for (s.members) |m| switch (m) {
            .method => |md| {
                if (md.is_declare) continue;
                try self.w("\n");
                try self.emitFn(.{
                    .isPub = false,
                    .name = md.name,
                    .annotations = &.{},
                    .genericParams = &.{},
                    .params = md.params,
                    .returnType = md.returnType,
                    .body = md.body orelse &.{},
                });
            },
            else => {},
        };
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        try self.fmt("-record({s}, {{", .{r.name});
        for (r.fields, 0..) |f, i| {
            if (i > 0) try self.w(", ");
            try self.w(f.name);
        }
        try self.w("}).\n");
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try self.w("\n");
            try self.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        try self.fmt("%% enum {s}\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try self.fmt("%%   {s}\n", .{v.name});
            } else {
                try self.fmt("%%   {s}(", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(f.name);
                }
                try self.w(")\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try self.w("\n");
            try self.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitInterface(self: *Emitter, i: ast.InterfaceDecl) !void {
        try self.fmt("%% interface {s}\n", .{i.name});
    }

    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        try self.w("%% implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try self.w(", ");
            try self.w(iface);
        }
        try self.fmt(" for {s}\n", .{im.target});
        for (im.methods) |m| {
            try self.w("\n");
            try self.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body,
            });
        }
    }

    fn emitUse(self: *Emitter, u: ast.UseDecl) !void {
        switch (u.source) {
            .stringPath => |p| {
                try self.fmt("-import({s}, [", .{p});
                for (u.imports, 0..) |name, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(name);
                    try self.w("/0"); // arity unknown at this point, use 0 as placeholder
                }
                try self.w("]).\n");
            },
            .functionCall => |name| try self.fmt("%% use {s}()\n", .{name}),
        }
    }

    // ── binary string helper ─────────────────────────────────────────────────

    fn emitBinary(self: *Emitter, s: []const u8) !void {
        try self.w("<<\"");
        for (s) |c| switch (c) {
            '"' => try self.w("\\\""),
            '\\' => try self.w("\\\\"),
            '\n' => try self.w("\\n"),
            '\r' => try self.w("\\r"),
            '\t' => try self.w("\\t"),
            else => try self.out.writeByte(c),
        };
        try self.w("\">>");
    }
};
