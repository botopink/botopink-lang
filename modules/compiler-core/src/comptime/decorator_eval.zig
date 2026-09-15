/// Decorator invocation — single persistent erl runtime.
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core serializes
/// that declaration into a `@Decl` handle and runs the decorator body inside
/// the persistent erl subprocess.
///
/// The decompiler (emitBpBody / emitBpStmt / emitBpExpr) is shared with
/// template_eval.zig and lives there as public functions.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const comptimeMod = @import("../comptime.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

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
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = build_root;
    return evaluateErl(arena, io, dfn, handleJson, plainArgs);
}

/// Build a `DeclKind` record literal AST expression: a record whose fields map
/// the DeclKind string values to themselves.
fn buildDeclKindRecord(arena: std.mem.Allocator) !*ast.Expr {
    const kinds = [_][]const u8{ "Record", "Fn", "Method", "Interface", "Enum", "Struct", "Val" };
    const fields = try arena.alloc(ast.RecordLitFieldOf(.untyped), kinds.len);
    for (kinds, 0..) |kind, i| {
        const val = try arena.create(ast.Expr);
        val.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .stringLit = kind } } };
        fields[i] = .{ .name = kind, .value = val };
    }
    const expr = try arena.create(ast.Expr);
    expr.* = .{ .collection = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .recordLit = .{ .fields = fields } } } };
    return expr;
}

/// Convert a JSON value to an AST expression.
fn jsonToExpr(arena: std.mem.Allocator, v: std.json.Value, isDecl: bool) !*ast.Expr {
    const expr = try arena.create(ast.Expr);
    switch (v) {
        .integer => |n| {
            const lit = try std.fmt.allocPrint(arena, "{d}", .{n});
            expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .numberLit = lit } } };
        },
        .float => |f| {
            const lit = try std.fmt.allocPrint(arena, "{d}", .{f});
            expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .numberLit = lit } } };
        },
        .string => |str| {
            expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .stringLit = str } } };
        },
        .bool => |b| {
            expr.* = .{ .identifier = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .ident = if (b) "true" else "false" } } };
        },
        .null => {
            expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .null_ } };
        },
        .array => |items| {
            var elems = try arena.alloc(ast.Expr, items.items.len);
            for (items.items, 0..) |item, i| {
                const elemExpr = try jsonToExpr(arena, item, false);
                elems[i] = elemExpr.*;
            }
            expr.* = .{ .collection = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .arrayLit = .{ .elems = elems, .spreadExpr = null, .comments = &.{}, .commentsPerElem = &.{}, .trailingComma = false } } } };
        },
        .object => |obj| {
            if (isDecl) {
                // Generate @Decl(kind: DeclKind.Record, name: ..., ...) as interfaceLit
                const fields = try arena.alloc(ast.RecordLitFieldOf(.untyped), obj.count());
                var i: usize = 0;
                var it = obj.iterator();
                while (it.next()) |entry| {
                    // Special handling for "kind" field — wrap in DeclKind.X access
                    if (std.mem.eql(u8, entry.key_ptr.*, "kind") and entry.value_ptr.* == .string) {
                        const kindAccess = try arena.create(ast.Expr);
                        const declKindIdent = try arena.create(ast.Expr);
                        declKindIdent.* = .{ .identifier = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .ident = "DeclKind" } } };
                        kindAccess.* = .{ .identifier = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .identAccess = .{ .receiver = declKindIdent, .member = entry.value_ptr.*.string } } } };
                        fields[i] = .{ .name = entry.key_ptr.*, .value = kindAccess };
                    } else {
                        fields[i] = .{ .name = entry.key_ptr.*, .value = try jsonToExpr(arena, entry.value_ptr.*, false) };
                    }
                    i += 1;
                }
                expr.* = .{ .collection = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .interfaceLit = .{ .name = "Decl", .fields = fields } } } };
            } else {
                const fields = try arena.alloc(ast.RecordLitFieldOf(.untyped), obj.count());
                var i: usize = 0;
                var it = obj.iterator();
                while (it.next()) |entry| {
                    fields[i] = .{ .name = entry.key_ptr.*, .value = try jsonToExpr(arena, entry.value_ptr.*, false) };
                    i += 1;
                }
                expr.* = .{ .collection = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .recordLit = .{ .fields = fields } } } };
            }
        },
        else => {
            expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .null_ } };
        },
    }
    return expr;
}

fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    std.debug.print("decorator_eval: starting evaluation for fn '{s}'\n", .{dfn.name});

    // Build the synthetic AST program directly (skip lex/parse).
    // The decorator fn's first param is stripped of its `comptime` modifier so
    // the transform keeps it (comptime-only fns are dropped from codegen).
    var decls = try arena.alloc(ast.DeclKind, 3 + plainArgs.len);
    var decl_idx: usize = 0;

    // 1. Plain args as val declarations.
    for (plainArgs) |pa| {
        const val_expr = try arena.create(ast.Expr);
        val_expr.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .stringLit = pa.jsValue } } };
        decls[decl_idx] = .{ .val = .{ .name = pa.paramName, .value = val_expr } };
        decl_idx += 1;
    }

    // 2. DeclKind record.
    decls[decl_idx] = .{ .val = .{ .name = "DeclKind", .value = try buildDeclKindRecord(arena) } };
    decl_idx += 1;

    // 3. @Decl handle.
    const parsed_handle = std.json.parseFromSliceLeaky(std.json.Value, arena, handleJson, .{}) catch {
        return error.EvalFailed;
    };
    decls[decl_idx] = .{ .val = .{ .name = dfn.params[0].name, .value = try jsonToExpr(arena, parsed_handle, true) } };
    decl_idx += 1;

    // 4. The decorator fn — strip `comptime` from its first param so the
    // transform keeps it in codegen.
    var fn_copy = dfn;
    var params_copy = try arena.alloc(ast.Param, dfn.params.len);
    for (dfn.params, 0..) |p, i| {
        params_copy[i] = p;
        if (i == 0) params_copy[i].modifier = .none;
    }
    fn_copy.params = params_copy;
    decls[decl_idx] = .{ .@"fn" = fn_copy };
    decl_idx += 1;

    const program = ast.Program{ .decls = decls[0..decl_idx] };

    // Compile via compileFromAst (skip lex/parse).
    const erlang_codegen = @import("../codegen/erlang.zig");
    var session = comptimeMod.compileFromAst(arena, "decorator_body", program, io, null, "erlang") catch |err| {
        std.debug.print("decorator_eval: compileFromAst failed: {}\n", .{err});
        return error.EvalFailed;
    };
    defer session.deinit(arena);

    const erl_src: ?[]const u8 = blk: {
        for (session.outputs.items) |out| {
            if (out.outcome == .ok) {
                var outputs = [_]comptimeMod.ComptimeOutput{out};
                var results = erlang_codegen.codegenEmit(arena, &outputs, .{ .targetSource = .erlang }) catch |err| {
                    std.debug.print("decorator_eval: codegenEmit failed: {}\n", .{err});
                    break :blk null;
                };
                defer {
                    for (results.items) |*r| r.result.deinit(arena);
                    results.deinit(arena);
                }
                for (results.items) |r| {
                    if (r.result.js.len > 0) {
                        // Copy before the results are deinit'd (arena-backed).
                        const code_copy = try arena.alloc(u8, r.result.js.len);
                        @memcpy(code_copy, r.result.js);
                        break :blk code_copy;
                    }
                }
            }
        }
        break :blk null;
    };
    const erl_code = erl_src orelse {
        std.debug.print("decorator_eval: no erl_src generated\n", .{});
        return error.EvalFailed;
    };

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

    const persistent_erl = @import("./runtime/persistent_erl.zig");
    const stdout = persistent_erl.eval(arena, io, erl_path) catch |err| {
        std.debug.print("decorator_eval: persistent_erl.eval failed: {}\n", .{err});
        return error.EvalFailed;
    };
    defer arena.free(stdout);
    return parseOutcome(arena, stdout) catch |err| {
        std.debug.print("decorator_eval: parseOutcome failed: {}\n", .{err});
        return error.EvalFailed;
    };
}
