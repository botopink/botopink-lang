/// Decorator invocation — direct Erlang codegen.
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core serializes
/// that declaration into a `@Decl` handle and runs the decorator body inside
/// the persistent erl subprocess.
///
/// This module generates Erlang code directly from the decorator body AST,
/// bypassing the intermediate botopink source and compile() step.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlEmitter = @import("../codegen/beam/erl_emitter.zig");
const Term = @import("../codegen/beam/term.zig").Term;

/// Sole comptime runtime.
pub const Runtime = enum { erl };

/// Decl handle structure — passed directly without JSON serialization.
pub const DeclHandle = struct {
    kind: []const u8,
    name: []const u8,
    fields: []const FieldHandle,
    methods: []const ast.InterfaceMethod,
    returnType: []const u8,
    annotations: []const ast.Annotation,
};

pub const FieldHandle = struct {
    name: []const u8,
    typeName: []const u8,
    annotations: []const ast.Annotation,
};

pub const Outcome = union(enum) {
    ok: []const []const u8,
    fail: struct { message: []const u8, span: ?template.Span },
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) !Outcome {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, stdout, .{}) catch {
        return .{ .err = try std.fmt.allocPrint(arena, "decorator evaluator produced no result", .{}) };
    };
    const obj = switch (parsed) {
        .object => |o| o,
        else => return .{ .err = "decorator evaluator produced a non-object result" },
    };
    const kind = switch (obj.get("kind") orelse return .{ .err = "missing result kind" }) {
        .string => |s| s,
        else => return .{ .err = "missing result kind" },
    };
    if (std.mem.eql(u8, kind, "ok")) {
        var contributions: std.ArrayListUnmanaged([]const u8) = .empty;
        if (obj.get("contributions")) |c| switch (c) {
            .array => |items| for (items.items) |it| switch (it) {
                .string => |s| try contributions.append(arena, s),
                else => {},
            },
            else => {},
        };
        return .{ .ok = try contributions.toOwnedSlice(arena) };
    }
    if (std.mem.eql(u8, kind, "fail")) {
        const message = switch (obj.get("message") orelse .null) {
            .string => |s| s,
            else => "decorator rejected the declaration",
        };
        const span: ?template.Span = blk: {
            const sp = switch (obj.get("span") orelse .null) {
                .object => |o| o,
                else => break :blk null,
            };
            const start = jsonUsize(sp.get("start")) orelse break :blk null;
            const end = jsonUsize(sp.get("end")) orelse start;
            const line = jsonUsize(sp.get("line")) orelse 1;
            break :blk template.Span{ .start = start, .end = end, .line = line };
        };
        return .{ .fail = .{ .message = message, .span = span } };
    }
    const message = switch (obj.get("message") orelse .null) {
        .string => |s| s,
        else => "decorator evaluation failed",
    };
    return .{ .err = message };
}

fn jsonUsize(v: ?std.json.Value) ?usize {
    const val = v orelse return null;
    return switch (val) {
        .integer => |n| if (n >= 0) @intCast(n) else null,
        .float => |f| if (f >= 0) @intFromFloat(f) else null,
        else => null,
    };
}

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = build_root;
    return evaluateErl(arena, io, dfn, handle, plainArgs);
}

/// The `@Decl` handle as a BEAM term — the map the decorator body reads
/// (`decl.kind`, `decl.fields`, …). `kind` is an atom so it matches the lowering
/// of `DeclKind.Record` (`'Record'`); names and type names are binaries.
pub fn handleToTerm(arena: std.mem.Allocator, handle: DeclHandle) std.mem.Allocator.Error!Term {
    const fields = try arena.alloc(Term, handle.fields.len);
    for (handle.fields, 0..) |f, i| {
        const entries = try arena.alloc(Term.MapEntry, 3);
        entries[0] = Term.field("name", Term.str(f.name));
        entries[1] = Term.field("typeName", Term.str(f.typeName));
        entries[2] = Term.field("annotations", try annotationsToTerm(arena, f.annotations));
        fields[i] = Term.mapOf(entries);
    }

    const methods = try arena.alloc(Term, handle.methods.len);
    for (handle.methods, 0..) |m, i| {
        const params = try arena.alloc(Term, m.params.len);
        for (m.params, 0..) |p, j| {
            const pe = try arena.alloc(Term.MapEntry, 1);
            pe[0] = Term.field("name", Term.str(p.name));
            params[j] = Term.mapOf(pe);
        }
        const return_type: []const u8 = if (m.returnType) |rt| switch (rt) {
            .named => |n| n,
            .array => "array",
            .optional => "optional",
            else => "unknown",
        } else "";
        const entries = try arena.alloc(Term.MapEntry, 4);
        entries[0] = Term.field("name", Term.str(m.name));
        entries[1] = Term.field("params", Term.listOf(params));
        entries[2] = Term.field("returnType", Term.str(return_type));
        entries[3] = Term.field("annotations", try annotationsToTerm(arena, m.annotations));
        methods[i] = Term.mapOf(entries);
    }

    const entries = try arena.alloc(Term.MapEntry, 6);
    entries[0] = Term.field("kind", Term.atomOf(handle.kind));
    entries[1] = Term.field("name", Term.str(handle.name));
    entries[2] = Term.field("fields", Term.listOf(fields));
    entries[3] = Term.field("methods", Term.listOf(methods));
    entries[4] = Term.field("returnType", Term.str(handle.returnType));
    entries[5] = Term.field("annotations", try annotationsToTerm(arena, handle.annotations));
    return Term.mapOf(entries);
}

/// `[#{name => <<"getMapping">>, args => [<<"\"/users\"">>]}]` — args keep their
/// raw source lexemes (`DeclAnnotation.args` in `builtins.d.bp`).
fn annotationsToTerm(arena: std.mem.Allocator, anns: []const ast.Annotation) std.mem.Allocator.Error!Term {
    const items = try arena.alloc(Term, anns.len);
    for (anns, 0..) |a, i| {
        const args = try arena.alloc(Term, a.args.len);
        for (a.args, 0..) |arg, j| args[j] = Term.str(arg);
        const entries = try arena.alloc(Term.MapEntry, 2);
        entries[0] = Term.field("name", Term.str(a.name));
        entries[1] = Term.field("args", Term.listOf(args));
        items[i] = Term.mapOf(entries);
    }
    return Term.listOf(items);
}

/// Emit the `@Decl` handle as an Erlang map literal.
fn emitDeclHandle(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, handle: DeclHandle) !void {
    var aw: std.Io.Writer.Allocating = .init(arena);
    erlEmitter.writeTerm(&aw.writer, try handleToTerm(arena, handle)) catch return error.EvalFailed;
    try buf.appendSlice(arena, aw.written());
}

/// Emit Erlang code for an expression.
fn emitExpr(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, e: ast.Expr) !void {
    switch (e) {
        .literal => |lit| {
            switch (lit.kind) {
                .stringLit => |s| {
                    try buf.appendSlice(arena, "<<\"");
                    for (s) |c| {
                        switch (c) {
                            '"' => try buf.appendSlice(arena, "\\\""),
                            '\\' => try buf.appendSlice(arena, "\\\\"),
                            '\n' => try buf.appendSlice(arena, "\\n"),
                            '\r' => try buf.appendSlice(arena, "\\r"),
                            '\t' => try buf.appendSlice(arena, "\\t"),
                            else => try buf.append(arena, c),
                        }
                    }
                    try buf.appendSlice(arena, "\">>");
                },
                .numberLit => |n| {
                    try buf.appendSlice(arena, n);
                },
                .null_ => {
                    try buf.appendSlice(arena, "undefined");
                },
                else => {
                    try buf.appendSlice(arena, "undefined");
                },
            }
        },
        .identifier => |ident| {
            switch (ident.kind) {
                .ident => |name| {
                    // Convert to Erlang variable (uppercase first letter)
                    if (name.len > 0) {
                        var first = name[0];
                        if (first >= 'a' and first <= 'z') {
                            first = first - 32;
                        }
                        try buf.append(arena, first);
                        try buf.appendSlice(arena, name[1..]);
                    }
                },
                .identAccess => |access| {
                    // receiver.member → maps:get(member, Receiver)
                    try buf.appendSlice(arena, "maps:get('");
                    try buf.appendSlice(arena, access.member);
                    try buf.appendSlice(arena, "', ");
                    try emitExpr(buf, arena, access.receiver.*);
                    try buf.append(arena, ')');
                },
                else => {
                    try buf.appendSlice(arena, "undefined");
                },
            }
        },
        .binaryOp => |binOp| {
            try buf.append(arena, '(');
            try emitExpr(buf, arena, binOp.lhs.*);
            try buf.appendSlice(arena, " ");
            switch (binOp.op) {
                .add => try buf.appendSlice(arena, "+"),
                .sub => try buf.appendSlice(arena, "-"),
                .mul => try buf.appendSlice(arena, "*"),
                .div => try buf.appendSlice(arena, "div"),
                .mod => try buf.appendSlice(arena, "rem"),
                .eq => try buf.appendSlice(arena, "=="),
                .ne => try buf.appendSlice(arena, "/="),
                .lt => try buf.appendSlice(arena, "<"),
                .gt => try buf.appendSlice(arena, ">"),
                .lte => try buf.appendSlice(arena, "=<"),
                .gte => try buf.appendSlice(arena, ">="),
                .@"and" => try buf.appendSlice(arena, "andalso"),
                .@"or" => try buf.appendSlice(arena, "orelse"),
            }
            try buf.appendSlice(arena, " ");
            try emitExpr(buf, arena, binOp.rhs.*);
            try buf.append(arena, ')');
        },
        .call => |call| {
            // call is MakeExpr(phase, CallExprOf.Kind), so we need to access call.kind
            switch (call.kind) {
                .call => |c| {
                    // Check for special host functions
                    const callee = c.callee;
                    // fail(msg) → fail(Decl, Msg)
                    if (std.mem.eql(u8, callee, "fail")) {
                        try buf.appendSlice(arena, "fail(Decl, ");
                        if (c.args.len > 0) {
                            try emitExpr(buf, arena, c.args[0].value.*);
                        } else {
                            try buf.appendSlice(arena, "<<\"unknown error\">>");
                        }
                        try buf.append(arena, ')');
                        return;
                    }
                    // @emit(src) → emit(Src)
                    if (std.mem.eql(u8, callee, "emit")) {
                        try buf.appendSlice(arena, "emit(");
                        if (c.args.len > 0) {
                            try emitExpr(buf, arena, c.args[0].value.*);
                        }
                        try buf.append(arena, ')');
                        return;
                    }
                    // @compilerError(msg) → compilerError(Msg)
                    if (std.mem.eql(u8, callee, "compilerError")) {
                        try buf.appendSlice(arena, "compilerError(");
                        if (c.args.len > 0) {
                            try emitExpr(buf, arena, c.args[0].value.*);
                        }
                        try buf.append(arena, ')');
                        return;
                    }
                    // Regular function call
                    try buf.appendSlice(arena, callee);
                    try buf.append(arena, '(');
                    for (c.args, 0..) |arg, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitExpr(buf, arena, arg.value.*);
                    }
                    try buf.append(arena, ')');
                },
                .pipeline => |p| {
                    // Pipeline: expr |> fn
                    try emitExpr(buf, arena, p.lhs.*);
                    try buf.appendSlice(arena, " |> ");
                    try emitExpr(buf, arena, p.rhs.*);
                },
            }
        },
        .collection => |coll| {
            switch (coll.kind) {
                .recordLit => |rec| {
                    try buf.appendSlice(arena, "#{");
                    for (rec.fields, 0..) |field, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try buf.append(arena, '\'');
                        try buf.appendSlice(arena, field.name);
                        try buf.appendSlice(arena, "' => ");
                        try emitExpr(buf, arena, field.value.*);
                    }
                    try buf.appendSlice(arena, "}");
                },
                .arrayLit => |arr| {
                    try buf.append(arena, '[');
                    for (arr.elems, 0..) |elem, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitExpr(buf, arena, elem);
                    }
                    try buf.append(arena, ']');
                },
                else => {
                    try buf.appendSlice(arena, "undefined");
                },
            }
        },
        else => {
            try buf.appendSlice(arena, "undefined");
        },
    }
}

/// Emit Erlang code for a statement.
fn emitStmt(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, stmt: ast.Stmt, indent: usize) !void {
    const spaces = try arena.alloc(u8, indent);
    defer arena.free(spaces);
    @memset(spaces, ' ');
    const ind = try std.fmt.allocPrint(arena, "{s}", .{spaces});
    defer arena.free(ind);

    // Stmt is a struct with an `expr` field of type Expr
    const e = stmt.expr;
    switch (e) {
        .jump => |jump| {
            switch (jump.kind) {
                .@"return" => |ret| {
                    try buf.appendSlice(arena, ind);
                    try buf.appendSlice(arena, "erlang:return(");
                    if (ret) |expr| {
                        try emitExpr(buf, arena, expr.*);
                    } else {
                        try buf.appendSlice(arena, "undefined");
                    }
                    try buf.appendSlice(arena, ")");
                },
                else => {
                    try buf.appendSlice(arena, ind);
                    try buf.appendSlice(arena, "ok");
                },
            }
        },
        .binding => |bind| {
            try buf.appendSlice(arena, ind);
            // bind is MakeExpr(phase, BindingExprOf.Kind), access bind.kind
            switch (bind.kind) {
                .localBind => |lb| {
                    // Convert variable name to Erlang (uppercase first letter)
                    var varName = lb.name;
                    if (varName.len > 0) {
                        var first = varName[0];
                        if (first >= 'a' and first <= 'z') {
                            first = first - 32;
                        }
                        const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, varName[1..] });
                        try buf.appendSlice(arena, erlVar);
                        try buf.appendSlice(arena, " = ");
                        try emitExpr(buf, arena, lb.value.*);
                    }
                },
                .assign => |a| {
                    // Assignment: target = value
                    switch (a.target) {
                        .name => |n| {
                            var varName = n;
                            if (varName.len > 0) {
                                var first = varName[0];
                                if (first >= 'a' and first <= 'z') {
                                    first = first - 32;
                                }
                                const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, varName[1..] });
                                try buf.appendSlice(arena, erlVar);
                                try buf.appendSlice(arena, " = ");
                                try emitExpr(buf, arena, a.value.*);
                            }
                        },
                        .fieldAccess => |fa| {
                            // Field assignment: receiver.field = value
                            try emitExpr(buf, arena, fa.receiver.*);
                            try buf.appendSlice(arena, " = ");
                            try emitExpr(buf, arena, a.value.*);
                        },
                    }
                },
                else => {
                    try buf.appendSlice(arena, "undefined");
                },
            }
        },
        else => {
            try buf.appendSlice(arena, ind);
            try emitExpr(buf, arena, e);
        },
    }
}

/// Emit Erlang code for the decorator body.
fn emitBody(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, body: []const ast.Stmt, indent: usize) !void {
    for (body, 0..) |stmt, i| {
        if (i > 0) try buf.appendSlice(arena, ",\n");
        try emitStmt(buf, arena, stmt, indent);
    }
}

/// Build the complete Erlang module for decorator evaluation.
fn buildErlModule(
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError![]const u8 {
    const hash = std.hash.Wyhash.hash(0, dfn.name);
    const moduleName = try std.fmt.allocPrint(arena, "decorator_{x}", .{hash});

    var out: std.ArrayListUnmanaged(u8) = .empty;

    // Module header
    try out.appendSlice(arena, "-module(");
    try out.appendSlice(arena, moduleName);
    try out.appendSlice(arena, ").\n");
    try out.appendSlice(arena, "-export([main/0]).\n\n");

    // Plain arg bindings
    for (plainArgs) |pa| {
        var paramName = pa.paramName;
        if (paramName.len > 0) {
            var first = paramName[0];
            if (first >= 'a' and first <= 'z') {
                first = first - 32;
            }
            const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, paramName[1..] });
            try out.appendSlice(arena, erlVar);
            try out.appendSlice(arena, "() -> ");
            try out.appendSlice(arena, pa.jsValue);
            try out.appendSlice(arena, ".\n\n");
        }
    }

    // Decl handle binding
    var declParamName = dfn.params[0].name;
    if (declParamName.len > 0) {
        var first = declParamName[0];
        if (first >= 'a' and first <= 'z') {
            first = first - 32;
        }
        const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, declParamName[1..] });
        try out.appendSlice(arena, erlVar);
        try out.appendSlice(arena, "() -> ");
        try emitDeclHandle(&out, arena, handle);
        try out.appendSlice(arena, ".\n\n");
    }

    // Decorator body function
    try out.appendSlice(arena, dfn.name);
    try out.appendSlice(arena, "(Decl");
    for (plainArgs) |pa| {
        try out.appendSlice(arena, ", ");
        var paramName = pa.paramName;
        if (paramName.len > 0) {
            var first = paramName[0];
            if (first >= 'a' and first <= 'z') {
                first = first - 32;
            }
            const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, paramName[1..] });
            try out.appendSlice(arena, erlVar);
        }
    }
    try out.appendSlice(arena, ") ->\n    ");
    try emitBody(&out, arena, dfn.body, 4);
    try out.appendSlice(arena, ".\n\n");

    // Host functions
    try out.appendSlice(arena, "fail(_Decl, Msg) -> erlang:throw({comptime_fail, Msg, #{}}).\n");
    try out.appendSlice(arena, "compilerError(Msg) -> erlang:throw({comptime_fail, Msg, #{}}).\n");
    try out.appendSlice(arena, "emit(Src) -> erlang:put('__emit', [Src | emit_stack()]).\n");
    try out.appendSlice(arena, "emit_stack() -> case erlang:get('__emit') of undefined -> []; L -> L end.\n\n");

    // Main function
    try out.appendSlice(arena, "main() ->\n");
    try out.appendSlice(arena, "    erlang:erase('__emit'),\n");
    try out.appendSlice(arena, "    try\n");
    try out.appendSlice(arena, "        ");
    try out.appendSlice(arena, dfn.name);
    try out.appendSlice(arena, "(");
    var declParamName2 = dfn.params[0].name;
    if (declParamName2.len > 0) {
        var first = declParamName2[0];
        if (first >= 'a' and first <= 'z') {
            first = first - 32;
        }
        const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, declParamName2[1..] });
        try out.appendSlice(arena, erlVar);
        try out.appendSlice(arena, "()");
    }
    for (plainArgs) |pa| {
        try out.appendSlice(arena, ", ");
        var paramName = pa.paramName;
        if (paramName.len > 0) {
            var first = paramName[0];
            if (first >= 'a' and first <= 'z') {
                first = first - 32;
            }
            const erlVar = try std.fmt.allocPrint(arena, "{c}{s}", .{ first, paramName[1..] });
            try out.appendSlice(arena, erlVar);
            try out.appendSlice(arena, "()");
        }
    }
    try out.appendSlice(arena, "),\n");
    try out.appendSlice(arena, "        json:encode(#{kind => <<\"ok\">>, contributions => lists:reverse(emit_stack())})\n");
    try out.appendSlice(arena, "    catch\n");
    try out.appendSlice(arena, "        throw:{comptime_fail, Msg, _} ->\n");
    try out.appendSlice(arena, "            json:encode(#{kind => <<\"fail\">>, message => Msg})\n");
    try out.appendSlice(arena, "    end.\n");

    return out.items;
}

fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    std.debug.print("decorator_eval: starting direct Erlang evaluation for fn '{s}'\n", .{dfn.name});

    // Build Erlang module directly from AST
    const erl_code = buildErlModule(arena, dfn, handle, plainArgs) catch |err| {
        std.debug.print("decorator_eval: buildErlModule failed: {}\n", .{err});
        return error.EvalFailed;
    };

    std.debug.print("decorator_eval: generated Erlang code:\n{s}\n", .{erl_code});

    // Write to temp file
    const hash = std.hash.Wyhash.hash(0, dfn.name);
    const tmp_dir = try std.fmt.allocPrint(arena, ".botopinkbuild/tmp/decorator_{x}", .{hash});
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch |err| {
        std.debug.print("decorator_eval: createDirPath failed: {}\n", .{err});
        return error.EvalFailed;
    };
    const erl_path = try std.fmt.allocPrint(arena, "{s}/decorator_body.erl", .{tmp_dir});
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = erl_code }) catch |err| {
        std.debug.print("decorator_eval: writeFile failed: {}\n", .{err});
        return error.EvalFailed;
    };

    // Execute via persistent erl
    const persistent_erl = @import("./runtime/persistent_erl.zig");
    const stdout = persistent_erl.eval(arena, io, erl_path) catch |err| {
        std.debug.print("decorator_eval: persistent_erl.eval failed: {}\n", .{err});
        return error.EvalFailed;
    };
    defer arena.free(stdout);

    std.debug.print("decorator_eval: erl stdout: {s}\n", .{stdout});

    return parseOutcome(arena, stdout) catch |err| {
        std.debug.print("decorator_eval: parseOutcome failed: {}\n", .{err});
        return error.EvalFailed;
    };
}
