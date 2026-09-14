/// Template evaluation — single persistent erl runtime.
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, this module runs the body inside the persistent erl subprocess.
///
/// Outcome format:
///   {"kind":"code","source":"…"}                  ← build() / @code
///   {"kind":"value","value":<json>}               ← @expr(v)
///   {"kind":"capture","param":"template"}         ← `return template;`
///   {"kind":"custom","source":"…","ast":<json>}   ← custom(tree, code)
///   {"kind":"fail","message","param","span"}      ← fail()/failAt()
///   {"kind":"error","message"}                    ← anything else thrown
///
/// NOTE: evaluateErl() returns EvalFailed until erlang.zig gains #[@Host]
/// method lowering. Methods like Capture.lookup(), Capture.bindings(),
/// failRaw(), makeExpr(), makeCode() are annotated #[@Host] in
/// template_runtime.bp and must be redirected to botopink_comptime_prelude
/// module calls. The persistent erl infrastructure (BEAM cache, binary
/// protocol, warmup) is fully operational for comptime val evaluation
/// (beam.zig path).
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

// ── outcome ───────────────────────────────────────────────────────────────────

pub const Outcome = union(enum) {
    code: []const u8,
    value: std.json.Value,
    capture: []const u8,
    custom: struct {
        code: []const u8,
        ast: std.json.Value,
        root: ?template.CustomNode = null,
    },
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

// ── evaluate ──────────────────────────────────────────────────────────────────

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = build_root;
    return evaluateErl(arena, io, tfn, captures, plainArgs);
}

pub fn evaluateRuntime(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    runtime: Runtime,
) EvalError!Outcome {
    _ = runtime;
    _ = build_root;
    return evaluateErl(arena, io, tfn, captures, plainArgs);
}

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) !Outcome {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, stdout, .{}) catch {
        return .{ .err = try std.fmt.allocPrint(arena, "template evaluator produced no result", .{}) };
    };
    const obj = switch (parsed) {
        .object => |o| o,
        else => return .{ .err = "template evaluator produced a non-object result" },
    };
    const kind = switch (obj.get("kind") orelse return .{ .err = "missing result kind" }) {
        .string => |s| s,
        else => return .{ .err = "missing result kind" },
    };
    if (std.mem.eql(u8, kind, "code")) {
        const src = switch (obj.get("source") orelse .null) {
            .string => |s| s,
            else => return .{ .err = "code result without source text" },
        };
        return .{ .code = src };
    }
    if (std.mem.eql(u8, kind, "value")) {
        return .{ .value = obj.get("value") orelse .null };
    }
    if (std.mem.eql(u8, kind, "capture")) {
        const param = switch (obj.get("param") orelse .null) {
            .string => |s| s,
            else => return .{ .err = "capture result without param name" },
        };
        return .{ .capture = param };
    }
    if (std.mem.eql(u8, kind, "custom")) {
        const src = switch (obj.get("source") orelse .null) {
            .string => |s| s,
            else => return .{ .err = "custom result without code source" },
        };
        return .{ .custom = .{ .code = src, .ast = obj.get("ast") orelse .null } };
    }
    if (std.mem.eql(u8, kind, "fail")) {
        const message = switch (obj.get("message") orelse .null) {
            .string => |s| s,
            else => "template failed",
        };
        return .{ .fail = .{ .message = message, .param = null, .span = null } };
    }
    const message = switch (obj.get("message") orelse .null) {
        .string => |s| s,
        else => "template evaluation failed",
    };
    return .{ .err = message };
}

fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = captures;
    // Build synthetic .bp module and compile to Erlang via the full pipeline.
    var bp_src: std.ArrayListUnmanaged(u8) = .empty;
    defer bp_src.deinit(arena);
    for (plainArgs) |pa| {
        try bp_src.appendSlice(arena, "val ");
        try bp_src.appendSlice(arena, pa.paramName);
        try bp_src.appendSlice(arena, " = ");
        try bp_src.appendSlice(arena, pa.jsValue);
        try bp_src.appendSlice(arena, ";\n");
    }
    try bp_src.appendSlice(arena, "pub fn ");
    try bp_src.appendSlice(arena, tfn.name);
    try bp_src.append(arena, '(');
    for (tfn.params, 0..) |p, i| {
        if (i > 0) try bp_src.appendSlice(arena, ", ");
        try bp_src.appendSlice(arena, p.name);
        try bp_src.appendSlice(arena, ": _");
    }
    try bp_src.appendSlice(arena, ") -> void {\n");
    try emitBpBody(&bp_src, arena, tfn.body);
    try bp_src.appendSlice(arena, "}\n");

    const comptimeMod = @import("../comptime.zig");
    const erlang_codegen = @import("../codegen/erlang.zig");
    var session = comptimeMod.compile(arena, &.{.{ .path = "template_body", .source = bp_src.items }}, io, null, "erlang") catch return error.EvalFailed;
    defer session.deinit(arena);

    const erl_src: ?[]const u8 = blk: {
        for (session.outputs.items) |out| {
            if (out.outcome == .ok) {
                var outputs = [_]comptimeMod.ComptimeOutput{out};
                var results = erlang_codegen.codegenEmit(arena, &outputs, .{ .targetSource = .erlang }) catch break :blk null;
                defer {
                    for (results.items) |*r| r.result.deinit(arena);
                    results.deinit(arena);
                }
                for (results.items) |r| {
                    if (r.result.js.len > 0) break :blk r.result.js;
                }
            }
        }
        break :blk null;
    };
    const erl_code = erl_src orelse return error.EvalFailed;

    const hash = std.hash.Wyhash.hash(0, tfn.name);
    const tmp_dir = try std.fmt.allocPrint(arena, ".botopinkbuild/tmp/template_{x}", .{hash});
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    const erl_path = try std.fmt.allocPrint(arena, "{s}/template_body.erl", .{tmp_dir});
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = erl_code }) catch return error.EvalFailed;

    const persistent_erl = @import("./runtime/persistent_erl.zig");
    const stdout = persistent_erl.eval(arena, io, erl_path) catch return error.EvalFailed;
    defer arena.free(stdout);
    return parseOutcome(arena, stdout) catch error.EvalFailed;
}

pub fn emitBpBody(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, body: []const ast.Stmt) std.mem.Allocator.Error!void {
    for (body) |stmt| {
        try emitBpStmt(buf, arena, stmt);
    }
}

pub fn emitBpStmt(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, stmt: ast.Stmt) std.mem.Allocator.Error!void {
    switch (stmt.expr) {
        .jump => |j| switch (j.kind) {
            .@"return" => |r| {
                try buf.appendSlice(arena, "  return");
                if (r) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
                try buf.appendSlice(arena, ";\n");
            },
            .throw_ => |t| {
                try buf.appendSlice(arena, "  throw");
                if (t) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
                try buf.appendSlice(arena, ";\n");
            },
            .@"break" => |b| {
                if (b.label) |lbl| {
                    try buf.appendSlice(arena, "  break :");
                    try buf.appendSlice(arena, lbl);
                } else {
                    try buf.appendSlice(arena, "  break");
                }
                if (b.value) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
                try buf.appendSlice(arena, ";\n");
            },
            .@"continue" => {
                try buf.appendSlice(arena, "  continue;\n");
            },
            .yield => |y| {
                if (y.label) |lbl| {
                    try buf.appendSlice(arena, "  yield :");
                    try buf.appendSlice(arena, lbl);
                } else {
                    try buf.appendSlice(arena, "  yield");
                }
                if (y.value) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
                try buf.appendSlice(arena, ";\n");
            },
            .try_ => |t| {
                try buf.appendSlice(arena, "  try");
                if (t) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
                try buf.appendSlice(arena, ";\n");
            },
            .await_ => |a| {
                try buf.appendSlice(arena, "  await ");
                try emitBpExpr(buf, arena, a.*);
                try buf.appendSlice(arena, ";\n");
            },
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                try buf.appendSlice(arena, "  if (");
                try emitBpExpr(buf, arena, i.cond.*);
                try buf.appendSlice(arena, ")");
                if (i.binding) |b| {
                    try buf.appendSlice(arena, " { ");
                    try buf.appendSlice(arena, b);
                    try buf.appendSlice(arena, " ->");
                }
                try buf.appendSlice(arena, " {\n");
                for (i.then_) |*s| {
                    try emitBpStmt(buf, arena, s.*);
                }
                try buf.appendSlice(arena, "  }");
                if (i.else_) |els| {
                    try buf.appendSlice(arena, " else {\n");
                    for (els) |*s| {
                        try emitBpStmt(buf, arena, s.*);
                    }
                    try buf.appendSlice(arena, "  }");
                }
                try buf.appendSlice(arena, ";\n");
            },
            .tryCatch => |tc| {
                try buf.appendSlice(arena, "  try ");
                try emitBpExpr(buf, arena, tc.expr.*);
                try buf.appendSlice(arena, " catch ");
                try emitBpExpr(buf, arena, tc.handler.*);
                try buf.appendSlice(arena, ";\n");
            },
        },
        .loop => |l| {
            try buf.appendSlice(arena, "  loop");
            if (l.label) |lbl| {
                try buf.appendSlice(arena, " :");
                try buf.appendSlice(arena, lbl);
            }
            if (l.awaitLoop) {
                try buf.appendSlice(arena, " await");
            }
            try buf.appendSlice(arena, " (");
            try emitBpExpr(buf, arena, l.iter.*);
            if (l.indexRange) |ir| {
                try buf.appendSlice(arena, ", ");
                try emitBpExpr(buf, arena, ir.*);
            }
            try buf.appendSlice(arena, ") { ");
            if (l.params.len > 0) {
                for (l.params, 0..) |p, idx| {
                    if (idx > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, p);
                }
                try buf.appendSlice(arena, " ->");
            }
            try buf.appendSlice(arena, "\n");
            for (l.body) |*s| {
                try emitBpStmt(buf, arena, s.*);
            }
            try buf.appendSlice(arena, "  };\n");
        },
        .binding => |b| switch (b.kind) {
            .localBind => |lb| {
                try buf.appendSlice(arena, "  ");
                if (lb.mutable) {
                    try buf.appendSlice(arena, "var ");
                } else {
                    try buf.appendSlice(arena, "val ");
                }
                try buf.appendSlice(arena, lb.name);
                if (lb.typeAnnotation) |ann| {
                    try buf.appendSlice(arena, ": ");
                    try emitTypeRef(buf, arena, ann);
                }
                try buf.appendSlice(arena, " = ");
                try emitBpExpr(buf, arena, lb.value.*);
                try buf.appendSlice(arena, ";\n");
            },
            .assign => |a| {
                try buf.appendSlice(arena, "  ");
                switch (a.target) {
                    .name => |n| try buf.appendSlice(arena, n),
                    .fieldAccess => |fa| {
                        try emitBpExpr(buf, arena, fa.receiver.*);
                        try buf.append(arena, '.');
                        try buf.appendSlice(arena, fa.field);
                    },
                }
                try buf.append(arena, ' ');
                if (a.op == .plusAssign) {
                    try buf.appendSlice(arena, "+");
                }
                try buf.appendSlice(arena, "= ");
                try emitBpExpr(buf, arena, a.value.*);
                try buf.appendSlice(arena, ";\n");
            },
            .localBindDestruct => |ld| {
                try buf.appendSlice(arena, "  ");
                if (ld.mutable) {
                    try buf.appendSlice(arena, "var ");
                } else {
                    try buf.appendSlice(arena, "val ");
                }
                try emitBpDestruct(buf, arena, ld.pattern);
                try buf.appendSlice(arena, " = ");
                try emitBpExpr(buf, arena, ld.value.*);
                try buf.appendSlice(arena, ";\n");
            },
        },
        .useHook => |u| {
            try buf.appendSlice(arena, "  use ");
            try emitBpExpr(buf, arena, u.kind.inner.*);
            try buf.appendSlice(arena, ";\n");
        },
        else => {
            try buf.appendSlice(arena, "  ");
            try emitBpExpr(buf, arena, stmt.expr);
            try buf.appendSlice(arena, ";\n");
        },
    }
}

fn binOpToString(op: anytype) []const u8 {
    return switch (op) {
        .lt => "<",
        .gt => ">",
        .lte => "<=",
        .gte => ">=",
        .eq => "==",
        .ne => "!=",
        .add => "+",
        .sub => "-",
        .mul => "*",
        .div => "/",
        .mod => "%",
        .@"and" => "&&",
        .@"or" => "||",
    };
}

pub fn emitBpExpr(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, te: ast.Expr) std.mem.Allocator.Error!void {
    switch (te) {
        .literal => |lit| switch (lit.kind) {
            .stringLit => |s| {
                try buf.append(arena, '"');
                try buf.appendSlice(arena, s);
                try buf.append(arena, '"');
            },
            .stringTemplate => |st| {
                if (st.multiline) {
                    try buf.appendSlice(arena, "\"\"\"");
                    for (st.parts) |*part| switch (part.*) {
                        .text => |t| try buf.appendSlice(arena, t),
                        .expr => |e| {
                            try buf.appendSlice(arena, "${");
                            try emitBpExpr(buf, arena, e.*);
                            try buf.appendSlice(arena, "}");
                        },
                    };
                    try buf.appendSlice(arena, "\"\"\"");
                } else {
                    try buf.append(arena, '"');
                    for (st.parts) |*part| switch (part.*) {
                        .text => |t| try buf.appendSlice(arena, t),
                        .expr => |e| {
                            try buf.appendSlice(arena, "${");
                            try emitBpExpr(buf, arena, e.*);
                            try buf.appendSlice(arena, "}");
                        },
                    };
                    try buf.append(arena, '"');
                }
            },
            .numberLit => |n| try buf.appendSlice(arena, n),
            .null_ => try buf.appendSlice(arena, "null"),
            .comment => |c| {
                switch (c.kind) {
                    .normal => {
                        try buf.appendSlice(arena, "//");
                        try buf.appendSlice(arena, c.text);
                    },
                    .doc => {
                        try buf.appendSlice(arena, "///");
                        try buf.appendSlice(arena, c.text);
                    },
                    .module => {
                        try buf.appendSlice(arena, "////");
                        try buf.appendSlice(arena, c.text);
                    },
                }
            },
        },
        .identifier => |id| switch (id.kind) {
            .ident => |name| try buf.appendSlice(arena, name),
            .dotIdent => |name| {
                try buf.append(arena, '.');
                try buf.appendSlice(arena, name);
            },
            .identAccess => |ia| {
                try emitBpExpr(buf, arena, ia.receiver.*);
                if (ia.optional) {
                    try buf.appendSlice(arena, "?.");
                } else {
                    try buf.append(arena, '.');
                }
                try buf.appendSlice(arena, ia.member);
            },
        },
        .call => |cc| switch (cc.kind) {
            .call => |c| {
                if (c.is_builtin) try buf.append(arena, '@');
                if (c.receiver) |recv| {
                    try emitBpExpr(buf, arena, recv.*);
                    if (c.optional) {
                        try buf.appendSlice(arena, "?.");
                    } else {
                        try buf.append(arena, '.');
                    }
                }
                try buf.appendSlice(arena, c.callee);
                if (c.is_tagged) {
                    // tagged call: callee "arg"
                    try buf.append(arena, ' ');
                    if (c.args.len > 0) {
                        try emitBpExpr(buf, arena, c.args[0].value.*);
                    }
                } else {
                    try buf.append(arena, '(');
                    for (c.args, 0..) |arg, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        if (arg.label) |lbl| {
                            try buf.appendSlice(arena, lbl);
                            try buf.appendSlice(arena, ": ");
                        }
                        try emitBpExpr(buf, arena, arg.value.*);
                    }
                    try buf.append(arena, ')');
                }
                for (c.trailing) |*tl| {
                    try buf.appendSlice(arena, " {");
                    if (tl.label) |lbl| {
                        try buf.appendSlice(arena, " ");
                        try buf.appendSlice(arena, lbl);
                        try buf.appendSlice(arena, ":");
                    }
                    if (tl.params.len > 0) {
                        try buf.append(arena, ' ');
                        for (tl.params, 0..) |p, pi| {
                            if (pi > 0) try buf.appendSlice(arena, ", ");
                            try buf.appendSlice(arena, p);
                        }
                        try buf.appendSlice(arena, " ->");
                    }
                    try buf.append(arena, '\n');
                    for (tl.body) |*s| {
                        try emitBpStmt(buf, arena, s.*);
                    }
                    try buf.appendSlice(arena, "  }");
                }
            },
            .pipeline => |p| {
                try emitBpExpr(buf, arena, p.lhs.*);
                try buf.appendSlice(arena, " |> ");
                try emitBpExpr(buf, arena, p.rhs.*);
            },
        },
        .binaryOp => |b| {
            try emitBpExpr(buf, arena, b.lhs.*);
            try buf.append(arena, ' ');
            try buf.appendSlice(arena, binOpToString(b.op));
            try buf.append(arena, ' ');
            try emitBpExpr(buf, arena, b.rhs.*);
        },
        .unaryOp => |u| {
            switch (u.op) {
                .neg => try buf.appendSlice(arena, "-"),
                .not => try buf.appendSlice(arena, "not "),
            }
            try emitBpExpr(buf, arena, u.expr.*);
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| {
                try buf.append(arena, '(');
                try emitBpExpr(buf, arena, g.*);
                try buf.append(arena, ')');
            },
            .arrayLit => |a| {
                try buf.append(arena, '[');
                for (a.elems, 0..) |*e, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try emitBpExpr(buf, arena, e.*);
                }
                if (a.spread) |s| {
                    if (a.elems.len > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, "..");
                    if (s.len > 0) try buf.appendSlice(arena, s);
                }
                if (a.spreadExpr) |se| {
                    try buf.appendSlice(arena, " ..");
                    try emitBpExpr(buf, arena, se.*);
                }
                try buf.append(arena, ']');
            },
            .tupleLit => |t| {
                try buf.appendSlice(arena, "#(");
                for (t.elems, 0..) |*e, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try emitBpExpr(buf, arena, e.*);
                }
                try buf.append(arena, ')');
            },
            .range => |r| {
                try emitBpExpr(buf, arena, r.start.*);
                try buf.appendSlice(arena, "..");
                if (r.end) |e| try emitBpExpr(buf, arena, e.*);
            },
            .case => |c| {
                try buf.appendSlice(arena, "case ");
                if (c.subjects.len == 1) {
                    try emitBpExpr(buf, arena, c.subjects[0]);
                } else {
                    for (c.subjects, 0..) |*s, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitBpExpr(buf, arena, s.*);
                    }
                }
                try buf.appendSlice(arena, " {\n");
                for (c.arms) |*arm| {
                    try buf.appendSlice(arena, "  ");
                    try emitBpPattern(buf, arena, arm.pattern);
                    if (arm.guard) |g| {
                        try buf.appendSlice(arena, " if ");
                        try emitBpExpr(buf, arena, g);
                    }
                    try buf.appendSlice(arena, " -> ");
                    try emitBpExpr(buf, arena, arm.body);
                    try buf.appendSlice(arena, ";\n");
                }
                try buf.appendSlice(arena, "}");
            },
            .recordLit => |rl| {
                try buf.appendSlice(arena, "record { ");
                for (rl.fields, 0..) |*f, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, f.name);
                    try buf.appendSlice(arena, ": ");
                    try emitBpExpr(buf, arena, f.value.*);
                }
                try buf.appendSlice(arena, " }");
            },
            .interfaceLit => |il| {
                try buf.appendSlice(arena, "@");
                try buf.appendSlice(arena, il.name);
                try buf.appendSlice(arena, "(");
                for (il.fields, 0..) |*f, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, f.name);
                    try buf.appendSlice(arena, ": ");
                    try emitBpExpr(buf, arena, f.value.*);
                }
                try buf.appendSlice(arena, ")");
            },
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                try buf.appendSlice(arena, "if (");
                try emitBpExpr(buf, arena, i.cond.*);
                try buf.appendSlice(arena, ")");
                if (i.binding) |b| {
                    try buf.appendSlice(arena, " { ");
                    try buf.appendSlice(arena, b);
                    try buf.appendSlice(arena, " ->");
                }
                try buf.appendSlice(arena, " {\n");
                for (i.then_) |*s| {
                    try emitBpStmt(buf, arena, s.*);
                }
                try buf.appendSlice(arena, "}");
                if (i.else_) |els| {
                    try buf.appendSlice(arena, " else {\n");
                    for (els) |*s| {
                        try emitBpStmt(buf, arena, s.*);
                    }
                    try buf.appendSlice(arena, "}");
                }
            },
            .tryCatch => |tc| {
                try buf.appendSlice(arena, "try ");
                try emitBpExpr(buf, arena, tc.expr.*);
                try buf.appendSlice(arena, " catch ");
                try emitBpExpr(buf, arena, tc.handler.*);
            },
        },
        .function => |f| {
            switch (f.kind.syntax) {
                .lambda => {
                    try buf.append(arena, '{');
                    for (f.kind.params, 0..) |p, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try buf.appendSlice(arena, p);
                    }
                    if (f.kind.params.len > 0) try buf.appendSlice(arena, " ->");
                    try buf.append(arena, '\n');
                    for (f.kind.body) |*s| {
                        try emitBpStmt(buf, arena, s.*);
                    }
                    try buf.appendSlice(arena, "}");
                },
                .fnExpr => {
                    try buf.appendSlice(arena, "fn(");
                    for (f.kind.params, 0..) |p, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try buf.appendSlice(arena, p);
                    }
                    try buf.appendSlice(arena, ") {\n");
                    for (f.kind.body) |*s| {
                        try emitBpStmt(buf, arena, s.*);
                    }
                    try buf.appendSlice(arena, "}");
                },
            }
        },
        .binding => |b| switch (b.kind) {
            .localBind => |lb| {
                if (lb.mutable) {
                    try buf.appendSlice(arena, "var ");
                } else {
                    try buf.appendSlice(arena, "val ");
                }
                try buf.appendSlice(arena, lb.name);
                if (lb.typeAnnotation) |ann| {
                    try buf.appendSlice(arena, ": ");
                    try emitTypeRef(buf, arena, ann);
                }
                try buf.appendSlice(arena, " = ");
                try emitBpExpr(buf, arena, lb.value.*);
            },
            .assign => |a| {
                switch (a.target) {
                    .name => |n| try buf.appendSlice(arena, n),
                    .fieldAccess => |fa| {
                        try emitBpExpr(buf, arena, fa.receiver.*);
                        try buf.append(arena, '.');
                        try buf.appendSlice(arena, fa.field);
                    },
                }
                try buf.append(arena, ' ');
                if (a.op == .plusAssign) {
                    try buf.appendSlice(arena, "+");
                }
                try buf.appendSlice(arena, "= ");
                try emitBpExpr(buf, arena, a.value.*);
            },
            .localBindDestruct => |ld| {
                if (ld.mutable) {
                    try buf.appendSlice(arena, "var ");
                } else {
                    try buf.appendSlice(arena, "val ");
                }
                try emitBpDestruct(buf, arena, ld.pattern);
                try buf.appendSlice(arena, " = ");
                try emitBpExpr(buf, arena, ld.value.*);
            },
        },
        .loop => |l| {
            try buf.appendSlice(arena, "loop");
            if (l.label) |lbl| {
                try buf.appendSlice(arena, " :");
                try buf.appendSlice(arena, lbl);
            }
            if (l.awaitLoop) {
                try buf.appendSlice(arena, " await");
            }
            try buf.appendSlice(arena, " (");
            try emitBpExpr(buf, arena, l.iter.*);
            if (l.indexRange) |ir| {
                try buf.appendSlice(arena, ", ");
                try emitBpExpr(buf, arena, ir.*);
            }
            try buf.appendSlice(arena, ") { ");
            if (l.params.len > 0) {
                for (l.params, 0..) |p, idx| {
                    if (idx > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, p);
                }
                try buf.appendSlice(arena, " ->");
            }
            try buf.appendSlice(arena, "\n");
            for (l.body) |*s| {
                try emitBpStmt(buf, arena, s.*);
            }
            try buf.appendSlice(arena, "}");
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |b| {
                if (b.label) |lbl| {
                    try buf.appendSlice(arena, "break :");
                    try buf.appendSlice(arena, lbl);
                } else {
                    try buf.appendSlice(arena, "break");
                }
                if (b.value) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
            },
            .@"continue" => try buf.appendSlice(arena, "continue"),
            .yield => |y| {
                if (y.label) |lbl| {
                    try buf.appendSlice(arena, "yield :");
                    try buf.appendSlice(arena, lbl);
                } else {
                    try buf.appendSlice(arena, "yield");
                }
                if (y.value) |val| {
                    try buf.append(arena, ' ');
                    try emitBpExpr(buf, arena, val.*);
                }
            },
            else => try buf.appendSlice(arena, "null"),
        },
        .comptime_ => |c| switch (c.kind) {
            .comptimeExpr => |e| {
                try buf.appendSlice(arena, "comptime ");
                try emitBpExpr(buf, arena, e.*);
            },
            .comptimeBlock => |cb| {
                try buf.appendSlice(arena, "comptime {\n");
                for (cb.body) |*s| {
                    try emitBpStmt(buf, arena, s.*);
                }
                try buf.appendSlice(arena, "}");
            },
            .assert => |a| {
                try buf.appendSlice(arena, "assert ");
                try emitBpExpr(buf, arena, a.condition.*);
                if (a.message) |msg| {
                    try buf.appendSlice(arena, ", ");
                    try emitBpExpr(buf, arena, msg.*);
                }
            },
            .assertPattern => |ap| {
                try buf.appendSlice(arena, "assert ");
                try emitBpPattern(buf, arena, ap.pattern);
                try buf.appendSlice(arena, " = ");
                try emitBpExpr(buf, arena, ap.expr.*);
                try buf.appendSlice(arena, " catch ");
                try emitBpExpr(buf, arena, ap.handler.*);
            },
        },
        else => try buf.appendSlice(arena, "null"),
    }
}

pub fn emitBpPattern(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, pat: ast.Pattern) std.mem.Allocator.Error!void {
    switch (pat) {
        .wildcard => try buf.append(arena, '_'),
        .ident => |n| try buf.appendSlice(arena, n),
        .variant => |v| {
            try buf.appendSlice(arena, v.name);
            switch (v.payload) {
                .binding => |b| {
                    try buf.append(arena, ' ');
                    try buf.appendSlice(arena, b);
                },
                .fields => |fs| {
                    try buf.append(arena, '(');
                    for (fs, 0..) |f, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try buf.appendSlice(arena, f);
                    }
                    try buf.append(arena, ')');
                },
                .literals => |ls| {
                    try buf.append(arena, '(');
                    for (ls, 0..) |*l, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitBpPattern(buf, arena, l.*);
                    }
                    try buf.append(arena, ')');
                },
            }
        },
        .numberLit => |n| try buf.appendSlice(arena, n),
        .stringLit => |s| {
            try buf.append(arena, '"');
            try buf.appendSlice(arena, s);
            try buf.append(arena, '"');
        },
        .list => |l| {
            try buf.append(arena, '[');
            for (l.elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                switch (e) {
                    .wildcard => try buf.append(arena, '_'),
                    .bind => |n| try buf.appendSlice(arena, n),
                    .numberLit => |n| try buf.appendSlice(arena, n),
                }
            }
            if (l.spread) |s| {
                if (l.elems.len > 0) try buf.appendSlice(arena, ", ");
                try buf.appendSlice(arena, "..");
                if (s.len > 0) try buf.appendSlice(arena, s);
            }
            try buf.append(arena, ']');
        },
        .@"or" => |pats| {
            for (pats, 0..) |*p, i| {
                if (i > 0) try buf.appendSlice(arena, " | ");
                try emitBpPattern(buf, arena, p.*);
            }
        },
        .multi => |pats| {
            for (pats, 0..) |*p, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try emitBpPattern(buf, arena, p.*);
            }
        },
    }
}

pub fn emitBpDestruct(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, d: ast.ParamDestruct) std.mem.Allocator.Error!void {
    switch (d) {
        .names => |n| {
            if (n.hasSpread) try buf.appendSlice(arena, "{ ");
            for (n.fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                if (!std.mem.eql(u8, f.field_name, f.bind_name)) {
                    try buf.appendSlice(arena, f.field_name);
                    try buf.appendSlice(arena, ": ");
                    try buf.appendSlice(arena, f.bind_name);
                } else {
                    try buf.appendSlice(arena, f.bind_name);
                }
            }
            if (n.hasSpread) try buf.appendSlice(arena, " }");
        },
        .tuple_ => |t| {
            try buf.appendSlice(arena, "#(");
            for (t, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try buf.appendSlice(arena, f);
            }
            try buf.append(arena, ')');
        },
        .list => |*p| {
            try emitBpPattern(buf, arena, p.*);
        },
        .ctor => |*p| {
            try emitBpPattern(buf, arena, p.*);
        },
    }
}

pub fn emitTypeRef(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, tr: ast.TypeRef) std.mem.Allocator.Error!void {
    switch (tr) {
        .named => |n| try buf.appendSlice(arena, n),
        .array => |a| {
            try emitTypeRef(buf, arena, a.*);
            try buf.appendSlice(arena, "[]");
        },
        .optional => |o| {
            try buf.append(arena, '?');
            try emitTypeRef(buf, arena, o.*);
        },
        .tuple_ => |elems| {
            try buf.appendSlice(arena, "#(");
            for (elems, 0..) |*e, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try emitTypeRef(buf, arena, e.*);
            }
            try buf.append(arena, ')');
        },
        .function => |f| {
            try buf.appendSlice(arena, "fn(");
            for (f.params, 0..) |*p, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try emitTypeRef(buf, arena, p.*);
            }
            try buf.appendSlice(arena, ") -> ");
            try emitTypeRef(buf, arena, f.returnType.*);
        },
        .generic => |g| {
            if (g.is_builtin) try buf.append(arena, '@');
            try buf.appendSlice(arena, g.name);
            try buf.append(arena, '<');
            for (g.args, 0..) |*a, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try emitTypeRef(buf, arena, a.*);
            }
            try buf.append(arena, '>');
        },
        .typeparam => |tp| {
            try buf.appendSlice(arena, "type");
            if (tp.len > 0) {
                try buf.append(arena, ' ');
                for (tp, 0..) |*c, i| {
                    if (i > 0) try buf.appendSlice(arena, " | ");
                    try emitTypeRef(buf, arena, c.*);
                }
            }
        },
        .record_type => |rt| {
            try buf.appendSlice(arena, "record { ");
            for (rt, 0..) |*f, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try buf.appendSlice(arena, f.name);
                try buf.appendSlice(arena, ": ");
                try emitTypeRef(buf, arena, f.typeRef);
            }
            try buf.appendSlice(arena, " }");
        },
    }
}
