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
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitErlang(alloc, ct.name, ok.transformed, ok.comptime_vals);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
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
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    var em = Emitter.init(alloc, &aw.writer, comptime_vals);

    // Module header
    try aw.writer.print("-module({s}).\n", .{module_name});

    // Collect public function names for export
    var pub_fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    defer pub_fns.deinit(alloc);
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (f.isPub) try pub_fns.append(alloc, f),
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
            .comment => |c| {
                const prefix = if (c.is_doc) "%%" else if (c.is_module) "%%%" else "%";
                try aw.writer.print("{s} {s}\n", .{ prefix, c.text });
            },
        }
    }

    return aw.toOwnedSlice();
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Return a heap-allocated copy of `name` with the first byte uppercased.
/// Caller owns the result.
fn erlangVar(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return alloc.dupe(u8, name);
    const buf = try alloc.dupe(u8, name);
    buf[0] = std.ascii.toUpper(buf[0]);
    return buf;
}

// ── Emitter ───────────────────────────────────────────────────────────────────

const Emitter = struct {
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),
    indent: usize = 0,
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8)) Emitter {
        return .{ .out = out, .cv = cv, .alloc = alloc };
    }

    fn w(this: *Emitter, s: []const u8) !void {
        try this.out.writeAll(s);
    }

    fn fmt(this: *Emitter, comptime f: []const u8, args: anytype) !void {
        try this.out.print(f, args);
    }

    fn writeIndent(this: *Emitter) !void {
        for (0..this.indent) |_| try this.w("    ");
    }

    // ── top-level val ─────────────────────────────────────────────────────────

    fn emitTopVal(this: *Emitter, v: ast.ValDecl, cv: std.StringHashMap([]const u8)) !void {
        if (v.value.isComptimeExpr()) {
            _ = cv;
            try this.fmt("%% comptime val {s}\n", .{v.name});
            return;
        }
        // Emit as a 0-arity function (Erlang has no top-level constants)
        try this.fmt("{s}() ->\n", .{v.name});
        const saved = this.indent;
        this.indent = 1;
        try this.writeIndent();
        try this.emitExpr(v.value.*);
        this.indent = saved;
        try this.w(".\n");
    }

    // ── fn ────────────────────────────────────────────────────────────────────

    fn emitFn(this: *Emitter, f: ast.FnDecl) !void {
        try this.w(f.name);
        try this.w("(");
        var first = true;
        for (f.params) |p| {
            if (p.destruct) |d| {
                switch (d) {
                    .names => |*n| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (n.fields, 0..) |fld, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, fld.bind_name);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        }
                        if (n.hasSpread) try this.w(", _");
                        try this.w("}");
                        first = false;
                    },
                    .tuple_ => |t| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (t, 0..) |nm, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, nm);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        }
                        try this.w("}");
                        first = false;
                    },
                    .list => {}, // List pattern — placeholder
                    .ctor => {}, // Constructor pattern — placeholder
                }
            } else if (!std.mem.eql(u8, p.name, "self")) {
                if (!first) try this.w(", ");
                const vname = try erlangVar(this.alloc, p.name);
                defer this.alloc.free(vname);
                try this.w(vname);
                first = false;
            }
        }
        try this.w(") ->\n");
        const saved = this.indent;
        this.indent = 1;
        try this.emitBody(f.body);
        this.indent = saved;
        try this.w(".\n");
    }

    // ── body (comma-separated stmts; does NOT emit trailing newline) ──────────
    //
    // Callers are responsible for the terminator that follows on the same line:
    //   emitFn  → ".\n"
    //   fun end → "\nINDENT end"

    fn emitBody(this: *Emitter, body: []const ast.Stmt) !void {
        for (body, 0..) |stmt, i| {
            const is_last = (i == body.len - 1);
            try this.writeIndent();
            try this.emitBodyStmt(stmt, is_last);
            if (!is_last) try this.w(",\n");
        }
    }

    /// Emit a statement inside a function body.
    /// When `is_last` is true, `return expr` is emitted as bare `expr`.
    fn emitBodyStmt(this: *Emitter, stmt: ast.Stmt, is_last: bool) !void {
        const e = stmt.expr;
        switch (e) {
            .controlFlow => |cf| switch (cf.kind) {
                .@"return" => |r| {
                    // In Erlang the last expression is the return value.
                    // Emit a bare expression; if not last, wrap in a noop binding.
                    _ = is_last;
                    try this.emitExpr(r.*);
                },
                else => try this.emitExpr(e),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    const vname = try erlangVar(this.alloc, a.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(a.value.*);
                },
                .assignPlus => |a| {
                    const vname = try erlangVar(this.alloc, a.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = {s} + ", .{ vname, vname });
                    try this.emitExpr(a.value.*);
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
                else => try this.emitExpr(e),
            },
            else => try this.emitExpr(e),
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn emitBinaryOp(this: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
        try this.w("(");
        try this.emitExpr(lhs.*);
        try this.w(" ");
        try this.w(op);
        try this.w(" ");
        try this.emitExpr(rhs.*);
        try this.w(")");
    }

    fn emitExpr(this: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| try this.w(n),
                .comment => |c| {
                    const prefix = switch (c.kind) {
                        .normal => "%",
                        .doc => "%%",
                        .module => "%%%",
                    };
                    try this.fmt("{s} {s}", .{ prefix, c.text });
                },
                .stringLit => |s| try this.emitBinary(s),
                .null_ => try this.w("undefined"),
            },

            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    const vname = try erlangVar(this.alloc, n);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                },
                .identAccess => |ia| {
                    try this.emitExpr(ia.receiver.*);
                    try this.fmt("_{s}", .{ia.member});
                },
                .dotIdent => |n| try this.fmt("{s}", .{n}),
            },

            .binaryOp => |bin| switch (bin.kind) {
                .add => |b| try this.emitBinaryOp("+", b.lhs, b.rhs),
                .sub => |b| try this.emitBinaryOp("-", b.lhs, b.rhs),
                .mul => |b| try this.emitBinaryOp("*", b.lhs, b.rhs),
                .div => |b| try this.emitBinaryOp("div", b.lhs, b.rhs),
                .mod => |b| try this.emitBinaryOp("rem", b.lhs, b.rhs),
                .lt => |b| try this.emitBinaryOp("<", b.lhs, b.rhs),
                .gt => |b| try this.emitBinaryOp(">", b.lhs, b.rhs),
                .lte => |b| try this.emitBinaryOp("=<", b.lhs, b.rhs),
                .gte => |b| try this.emitBinaryOp(">=", b.lhs, b.rhs),
                .eq => |b| try this.emitBinaryOp("=:=", b.lhs, b.rhs),
                .ne => |b| try this.emitBinaryOp("=/=", b.lhs, b.rhs),
                .@"and" => |b| try this.emitBinaryOp("and", b.lhs, b.rhs),
                .@"or" => |b| try this.emitBinaryOp("or", b.lhs, b.rhs),
            },

            .unaryOp => |un| switch (un.kind) {
                .not => |operand| {
                    try this.w("(not ");
                    try this.emitExpr(operand.*);
                    try this.w(")");
                },
                .neg => |operand| {
                    try this.w("(-");
                    try this.emitExpr(operand.*);
                    try this.w(")");
                },
            },

            .call => |c| switch (c.kind) {
                .pipeline => |b| {
                    // Flatten the pipeline chain
                    var items: std.ArrayList(ast.Expr) = .empty;
                    defer items.deinit(this.alloc);
                    try items.append(this.alloc, b.lhs.*);
                    var current = b.rhs.*;
                    while (true) {
                        switch (current) {
                            .call => |cc| switch (cc.kind) {
                                .pipeline => |p| {
                                    try items.append(this.alloc, p.lhs.*);
                                    current = p.rhs.*;
                                    continue;
                                },
                                else => {},
                            },
                            else => {},
                        }
                        break;
                    }
                    try items.append(this.alloc, current);

                    // Emit as nested calls: last(...(first))
                    var i: usize = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.emitExpr(items.items[i]);
                        try this.w("(");
                    }
                    try this.emitExpr(items.items[0]);
                    i = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.w(")");
                    }
                },

                .call => |cc| {
                    if (cc.receiver) |recv| {
                        try this.fmt("{s}:{s}(", .{ recv, cc.callee });
                    } else {
                        try this.fmt("{s}(", .{cc.callee});
                    }
                    var first = true;
                    for (cc.args) |arg| {
                        if (!first) try this.w(", ");
                        try this.emitExpr(arg.value.*);
                        first = false;
                    }
                    // Trailing lambdas: emit as fun args
                    for (cc.trailing) |tl| {
                        if (!first) try this.w(", ");
                        first = false;
                        try this.w("fun(");
                        for (tl.params, 0..) |p, pi| {
                            if (pi > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, p);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        }
                        try this.w(") ->\n");
                        const tl_saved = this.indent;
                        this.indent = this.indent + 1;
                        try this.emitBody(tl.body);
                        this.indent = tl_saved;
                        try this.w("\n");
                        try this.writeIndent();
                        try this.w("end");
                    }
                    try this.w(")");
                },

                .staticCall => |sc| {
                    try this.fmt("{s}:{s}(", .{ sc.receiver, sc.method });
                    try this.emitExpr(sc.arg.*);
                    try this.w(")");
                },

                .builtinCall => |bc| {
                    if (std.mem.eql(u8, bc.name, "@todo")) {
                        try this.w("erlang:error({todo, ");
                        if (bc.args.len > 0) {
                            try this.emitExpr(bc.args[0].value.*);
                        } else {
                            try this.w("\"not implemented\"");
                        }
                        try this.w("})");
                        return;
                    }
                    if (std.mem.eql(u8, bc.name, "@panic")) {
                        try this.w("erlang:error({panic, ");
                        if (bc.args.len > 0) {
                            try this.emitExpr(bc.args[0].value.*);
                        } else {
                            try this.w("\"panic\"");
                        }
                        try this.w("})");
                        return;
                    }
                    if (std.mem.eql(u8, bc.name, "@block")) {
                        // @block { ... } becomes a fun that executes the block
                        if (bc.args.len != 1) return error.InvalidArgs;
                        const arg = bc.args[0].value;
                        const block_body = switch (arg.*) {
                            .collection => |col| switch (col.kind) {
                                .block => |blk| blk.body,
                                else => return error.InvalidArgs,
                            },
                            else => return error.InvalidArgs,
                        };

                        try this.w("fun() ->\n");
                        this.indent += 1;

                        // Emit the block content directly (begin...end)
                        try this.w("begin\n");
                        this.indent += 1;
                        for (block_body, 0..) |stmt, i| {
                            try this.writeIndent();
                            try this.emitBodyStmt(stmt, i == block_body.len - 1);
                            if (i < block_body.len - 1) try this.w(",\n");
                        }
                        this.indent -= 1;
                        try this.w("\n");
                        try this.writeIndent();
                        try this.w("end");

                        this.indent -= 1;
                        try this.w("\n");
                        try this.writeIndent();
                        try this.w("end\n");
                        return;
                    }
                    try this.fmt("{s}(", .{bc.name});
                    for (bc.args, 0..) |arg, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitExpr(arg.value.*);
                    }
                    try this.w(")");
                },
            },

            .function => |func| switch (func.kind) {
                .lambda => |l| {
                    try this.w("fun(");
                    for (l.params, 0..) |p, i| {
                        if (i > 0) try this.w(", ");
                        const vname = try erlangVar(this.alloc, p);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                    try this.w(") ->\n");
                    const lam_saved = this.indent;
                    this.indent = this.indent + 1;
                    try this.emitBody(l.body);
                    this.indent = lam_saved;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },

                .fnExpr => |f| {
                    try this.w("fun(");
                    for (f.params, 0..) |p, i| {
                        if (i > 0) try this.w(", ");
                        const vname = try erlangVar(this.alloc, p);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                    try this.w(") ->\n");
                    const lam_saved = this.indent;
                    this.indent = this.indent + 1;
                    try this.emitBody(f.body);
                    this.indent = lam_saved;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
            },

            .collection => |col| switch (col.kind) {
                .grouped => |inner| {
                    try this.w("(");
                    try this.emitExpr(inner.*);
                    try this.w(")");
                },
                .block => |b| {
                    // Erlang: use begin...end for block expressions
                    try this.w("begin\n");
                    this.indent += 1;
                    for (b.body, 0..) |stmt, i| {
                        try this.writeIndent();
                        try this.emitBodyStmt(stmt, i == b.body.len - 1);
                        if (i < b.body.len - 1) try this.w(",\n");
                    }
                    this.indent -= 1;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end\n");
                },
                .arrayLit => |al| {
                    // Special handling for spreadExpr: use ++ operator for list concatenation
                    if (al.spreadExpr) |se| {
                        // Emit the first part as a list
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        try this.w("]");

                        // Use ++ to concatenate with the spread expression
                        try this.w(" ++ ");
                        try this.emitExpr(se.*);
                    } else {
                        // Normal array literal or simple spread (identifier)
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        if (al.spread) |name| {
                            if (al.elems.len > 0) try this.w(", ");
                            if (name.len > 0) try this.w(name);
                        }
                        try this.w("]");
                    }
                },
                .tupleLit => |tl| {
                    try this.w("{");
                    for (tl.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitExpr(elem);
                    }
                    try this.w("}");
                },
                .case => |c| try this.emitCase(c.subjects, c.arms),
                .range => |r| {
                    try this.w("lists:seq(");
                    try this.emitExpr(r.start.*);
                    try this.w(", ");
                    if (r.end) |end| try this.emitExpr(end.*) else try this.w("infinity");
                    try this.w(")");
                },
            },

            .controlFlow => |cf| switch (cf.kind) {
                .if_ => |i| {
                    try this.w("case ");
                    try this.emitExpr(i.cond.*);
                    try this.w(" of\n");
                    this.indent += 1;
                    try this.writeIndent();
                    if (i.binding) |_| {
                        try this.w("undefined -> undefined;\n");
                        try this.writeIndent();
                        try this.w("_ ->\n");
                    } else {
                        try this.w("true ->\n");
                    }
                    this.indent += 1;
                    try this.emitBranchBody(i.then_);
                    this.indent -= 1;
                    if (i.else_) |els| {
                        try this.w(";\n");
                        try this.writeIndent();
                        try this.w("false ->\n");
                        this.indent += 1;
                        try this.emitBranchBody(els);
                        this.indent -= 1;
                    }
                    this.indent -= 1;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
                .@"return" => |r| try this.emitExpr(r.*),
                .throw_ => |r| {
                    try this.w("erlang:throw(");
                    try this.emitExpr(r.*);
                    try this.w(")");
                },
                .try_ => |t| try this.emitExpr(t.*),
                .tryCatch => |tc| {
                    const handlerIsStatement = switch (tc.handler.*) {
                        .controlFlow => |hcf| switch (hcf.kind) {
                            .throw_, .@"return" => true,
                            else => false,
                        },
                        else => false,
                    };
                    try this.w("try\n");
                    this.indent += 1;
                    try this.writeIndent();
                    try this.emitExpr(tc.expr.*);
                    this.indent -= 1;
                    try this.w("\ncatch\n");
                    this.indent += 1;
                    try this.writeIndent();
                    try this.w("_Err ->\n");
                    this.indent += 1;
                    try this.writeIndent();
                    if (handlerIsStatement) {
                        try this.emitExpr(tc.handler.*);
                    } else {
                        try this.emitExpr(tc.handler.*);
                        try this.w("(_Err)");
                    }
                    this.indent -= 2;
                    try this.w("\nend");
                },
                .@"break" => |b| if (b) |bp| try this.emitExpr(bp.*),
                .yield => |y| try this.emitExpr(y.*),
                .@"continue" => try this.w("%% continue"),
                .loop => |lp| {
                    const has_yield = blk: {
                        for (lp.body) |stmt| {
                            switch (stmt.expr) {
                                .controlFlow => |scf| switch (scf.kind) {
                                    .yield => break :blk true,
                                    else => {},
                                },
                                else => {},
                            }
                        }
                        break :blk false;
                    };
                    const fun_kw = if (has_yield) "lists:map" else "lists:foreach";
                    try this.fmt("{s}(fun(", .{fun_kw});
                    for (lp.params, 0..) |p, i| {
                        if (i > 0) try this.w(", ");
                        const vname = try erlangVar(this.alloc, p);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                    try this.w(") ->\n");
                    const fun_body_indent = this.indent + 1;
                    const saved2 = this.indent;
                    this.indent = fun_body_indent;
                    try this.emitBody(lp.body);
                    this.indent = saved2;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end, ");
                    try this.emitExpr(lp.iter.*);
                    try this.w(")");
                },
            },

            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    const vname = try erlangVar(this.alloc, a.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(a.value.*);
                },
                .assignPlus => |a| {
                    const vname = try erlangVar(this.alloc, a.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = {s} + ", .{ vname, vname });
                    try this.emitExpr(a.value.*);
                },
                .fieldAssign => |sfa| {
                    // Erlang records don't support mutation like this; emit a comment
                    try this.fmt("%% {s}.{s} = ...", .{ "self", sfa.field });
                },
                .fieldPlusEq => |sfpe| {
                    _ = sfpe;
                    try this.w("%% field += not directly supported in Erlang");
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
            },

            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| try this.emitExpr(inner.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .controlFlow => |cf| switch (cf.kind) {
                                .@"break" => |y| {
                                    if (y) |yp| try this.emitExpr(yp.*);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                    }
                },
                .@"assert" => |a| {
                    // Erlang doesn't have built-in assert, so we use pattern matching
                    try this.w("true = (");
                    try this.emitExpr(a.condition.*);
                    try this.w(")");
                },
                .assertPattern => |ap| {
                    // Use Erlang's native pattern matching with case expressions
                    try this.w("case ");
                    try this.emitExpr(ap.expr.*);
                    try this.w(" of ");

                    // Emit the pattern
                    try this.emitPattern(ap.pattern);
                    try this.w(" -> ");

                    // On successful match, return the matched value
                    try this.emitExpr(ap.expr.*);

                    try this.w("; _ -> ");

                    // Handle the failure case
                    try this.emitExpr(ap.handler.*);

                    try this.w(" end");
                },
            },
        }
    }

    // ── if branch body (delegates to emitBody) ────────────────────────────────

    fn emitBranchBody(this: *Emitter, body: []const ast.Stmt) !void {
        try this.emitBody(body);
    }

    // ── case expression ───────────────────────────────────────────────────────

    fn emitCase(this: *Emitter, subjects: []ast.Expr, arms: []ast.CaseArm) !void {
        try this.w("case ");
        if (subjects.len == 1) {
            try this.emitExpr(subjects[0]);
        } else {
            try this.w("{");
            for (subjects, 0..) |s, i| {
                if (i > 0) try this.w(", ");
                try this.emitExpr(s);
            }
            try this.w("}");
        }
        try this.w(" of\n");
        this.indent += 1;

        var first_clause = true;
        for (arms) |arm| {
            // OR patterns expand to multiple Erlang clauses with the same body
            switch (arm.pattern) {
                .@"or" => |pats| {
                    for (pats) |p| {
                        if (!first_clause) try this.w(";\n");
                        try this.writeIndent();
                        try this.emitPattern(p);
                        try this.w(" ->\n");
                        this.indent += 1;
                        try this.emitCaseBody(arm.body);
                        this.indent -= 1;
                        first_clause = false;
                    }
                },
                .multi => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
                else => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
            }
        }

        this.indent -= 1;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end");
    }

    fn emitPattern(this: *Emitter, pat: ast.Pattern) !void {
        switch (pat) {
            .wildcard => try this.w("_"),
            .ident => |n| try this.w(n), // enum variant → atom
            .numberLit => |n| try this.w(n),
            .stringLit => |s| try this.emitBinary(s),
            .variantBinding => |vb| {
                const vname = try erlangVar(this.alloc, vb.binding);
                defer this.alloc.free(vname);
                try this.fmt("{{tag, {s}, {s}}}", .{ vb.name, vname });
            },
            .variantFields => |vf| {
                try this.fmt("{{tag, {s}", .{vf.name});
                for (vf.bindings) |bb| {
                    try this.w(", ");
                    const vname = try erlangVar(this.alloc, bb);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w("}");
            },
            .variantLiterals => |vl| {
                try this.fmt("{{tag, {s}", .{vl.name});
                for (vl.args) |arg| {
                    try this.w(", ");
                    try this.emitPattern(arg);
                }
                try this.w("}");
            },
            .list => |lp| {
                if (lp.spread) |sp| {
                    if (lp.elems.len == 0 and sp.len == 0) {
                        try this.w("_");
                    } else {
                        try this.w("[");
                        for (lp.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitListPatElem(elem);
                        }
                        if (sp.len > 0) {
                            if (lp.elems.len > 0) try this.w(" | ");
                            const vname = try erlangVar(this.alloc, sp);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        } else {
                            try this.w(" | _");
                        }
                        try this.w("]");
                    }
                } else if (lp.elems.len == 0) {
                    try this.w("[]");
                } else {
                    try this.w("[");
                    for (lp.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitListPatElem(elem);
                    }
                    try this.w("]");
                }
            },
            .@"or" => |pats| {
                // Should be expanded by emitCase; fallback: emit first
                if (pats.len > 0) try this.emitPattern(pats[0]);
            },
            .multi => |pats| {
                try this.w("{");
                for (pats, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    try this.emitPattern(p);
                }
                try this.w("}");
            },
        }
    }

    fn emitListPatElem(this: *Emitter, elem: ast.ListPatternElem) !void {
        switch (elem) {
            .wildcard => try this.w("_"),
            .bind => |name| {
                const vname = try erlangVar(this.alloc, name);
                defer this.alloc.free(vname);
                try this.w(vname);
            },
            .numberLit => |n| try this.w(n),
        }
    }

    fn emitCaseBody(this: *Emitter, body: ast.Expr) !void {
        switch (body) {
            .function => |func| switch (func.kind) {
                .lambda => |l| {
                    // Multi-statement block: emitBody handles indentation via this.indent
                    try this.emitBody(l.body);
                },
                else => {
                    // Single expression: emit with current indentation
                    try this.writeIndent();
                    try this.emitExpr(body);
                },
            },
            else => {
                // Single expression: emit with current indentation
                try this.writeIndent();
                try this.emitExpr(body);
            },
        }
    }

    // ── struct / record / enum ────────────────────────────────────────────────

    fn emitStruct(this: *Emitter, s: ast.StructDecl) !void {
        try this.fmt("-record({s}, {{", .{s.name});
        var first = true;
        for (s.members) |m| switch (m) {
            .field => |f| {
                if (!first) try this.w(", ");
                try this.w(f.name);
                first = false;
            },
            else => {},
        };
        try this.w("}).\n");
        // Emit methods as standalone functions
        for (s.members) |m| switch (m) {
            .method => |md| {
                if (md.is_declare) continue;
                try this.w("\n");
                try this.emitFn(.{
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

    fn emitRecord(this: *Emitter, r: ast.RecordDecl) !void {
        try this.fmt("-record({s}, {{", .{r.name});
        for (r.fields, 0..) |f, i| {
            if (i > 0) try this.w(", ");
            try this.w(f.name);
        }
        try this.w("}).\n");
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            try this.emitFn(.{
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

    fn emitEnum(this: *Emitter, e: ast.EnumDecl) !void {
        try this.fmt("%% enum {s}\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try this.fmt("%%   {s}\n", .{v.name});
            } else {
                try this.fmt("%%   {s}(", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try this.w(", ");
                    try this.w(f.name);
                }
                try this.w(")\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            try this.emitFn(.{
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

    fn emitInterface(this: *Emitter, i: ast.InterfaceDecl) !void {
        try this.fmt("%% interface {s}\n", .{i.name});
    }

    fn emitImplement(this: *Emitter, im: ast.ImplementDecl) !void {
        try this.w("%% implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try this.w(", ");
            try this.w(iface);
        }
        try this.fmt(" for {s}\n", .{im.target});
        for (im.methods) |m| {
            try this.w("\n");
            try this.emitFn(.{
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

    fn emitUse(this: *Emitter, u: ast.UseDecl) !void {
        switch (u.source) {
            .stringPath => |p| {
                try this.fmt("-import({s}, [", .{p});
                for (u.imports, 0..) |name, i| {
                    if (i > 0) try this.w(", ");
                    try this.w(name);
                    try this.w("/0"); // arity unknown at this point, use 0 as placeholder
                }
                try this.w("]).\n");
            },
            .functionCall => |name| try this.fmt("%% use {s}()\n", .{name}),
        }
    }

    // ── binary string helper ─────────────────────────────────────────────────

    fn emitBinary(this: *Emitter, s: []const u8) !void {
        try this.w("<<\"");
        for (s) |c| switch (c) {
            '"' => try this.w("\\\""),
            '\\' => try this.w("\\\\"),
            '\n' => try this.w("\\n"),
            '\r' => try this.w("\\r"),
            '\t' => try this.w("\\t"),
            else => try this.out.writeByte(c),
        };
        try this.w("\">>");
    }
};
