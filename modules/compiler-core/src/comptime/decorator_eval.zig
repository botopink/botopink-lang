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
const templateEval = @import("./template_eval.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

/// Convert a JSON value to a botopink source expression
fn jsonToBpSrc(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, v: std.json.Value, isDecl: bool) !void {
    switch (v) {
        .integer => |n| {
            try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "{d}", .{n}));
        },
        .float => |f| {
            try buf.appendSlice(arena, try std.fmt.allocPrint(arena, "{d}", .{f}));
        },
        .string => |str| {
            try buf.append(arena, '"');
            try buf.appendSlice(arena, str);
            try buf.append(arena, '"');
        },
        .bool => |b| {
            try buf.appendSlice(arena, if (b) "true" else "false");
        },
        .null => {
            try buf.appendSlice(arena, "null");
        },
        .array => |items| {
            try buf.append(arena, '[');
            for (items.items, 0..) |item, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try jsonToBpSrc(buf, arena, item, false);
            }
            try buf.append(arena, ']');
        },
        .object => |obj| {
            if (isDecl) {
                // Generate @Decl(kind: DeclKind.Record, name: ..., ...) for interface instantiation
                try buf.appendSlice(arena, "@Decl(");
                var first = true;
                var it = obj.iterator();
                while (it.next()) |entry| {
                    if (!first) try buf.appendSlice(arena, ", ");
                    first = false;
                    try buf.appendSlice(arena, entry.key_ptr.*);
                    try buf.appendSlice(arena, ": ");
                    // Special handling for "kind" field - convert string to DeclKind enum
                    if (std.mem.eql(u8, entry.key_ptr.*, "kind")) {
                        if (entry.value_ptr.* == .string) {
                            try buf.appendSlice(arena, "DeclKind.");
                            try buf.appendSlice(arena, entry.value_ptr.*.string);
                        } else {
                            try jsonToBpSrc(buf, arena, entry.value_ptr.*, false);
                        }
                    } else {
                        try jsonToBpSrc(buf, arena, entry.value_ptr.*, false);
                    }
                }
                try buf.appendSlice(arena, ")");
            } else {
                try buf.appendSlice(arena, "record { ");
                var first = true;
                var it = obj.iterator();
                while (it.next()) |entry| {
                    if (!first) try buf.appendSlice(arena, ", ");
                    first = false;
                    try buf.appendSlice(arena, entry.key_ptr.*);
                    try buf.appendSlice(arena, ": ");
                    try jsonToBpSrc(buf, arena, entry.value_ptr.*, false);
                }
                try buf.appendSlice(arena, " }");
            }
        },
        else => try buf.appendSlice(arena, "null"),
    }
}

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

fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    // Build synthetic .bp module and compile to Erlang via the full pipeline.
    var bp_src: std.ArrayListUnmanaged(u8) = .empty;
    defer bp_src.deinit(arena);

    std.debug.print("decorator_eval: starting evaluation for fn '{s}'\n", .{dfn.name});
    std.debug.print("decorator_eval: handleJson = {s}\n", .{handleJson});

    // Bind plain args.
    for (plainArgs) |pa| {
        try bp_src.appendSlice(arena, "val ");
        try bp_src.appendSlice(arena, pa.paramName);
        try bp_src.appendSlice(arena, " = ");
        try bp_src.appendSlice(arena, pa.jsValue);
        try bp_src.appendSlice(arena, ";\n");
    }

    // Define DeclKind enum as a record with string values for decorator body evaluation
    // Must be defined BEFORE the @Decl(...) call that references it
    try bp_src.appendSlice(arena, "val DeclKind = record { Record: \"Record\", Fn: \"Fn\", Method: \"Method\", Interface: \"Interface\", Enum: \"Enum\", Struct: \"Struct\", Val: \"Val\" };\n");

    // Bind the @Decl handle as the first parameter (a JSON value).
    // Convert JSON to @Decl(...) interface literal syntax.
    try bp_src.appendSlice(arena, "val ");
    try bp_src.appendSlice(arena, dfn.params[0].name);
    try bp_src.appendSlice(arena, " = ");
    const parsedHandle = std.json.parseFromSliceLeaky(std.json.Value, arena, handleJson, .{}) catch {
        std.debug.print("decorator_eval: failed to parse handleJson as JSON\n", .{});
        return error.EvalFailed;
    };
    try jsonToBpSrc(&bp_src, arena, parsedHandle, true);
    try bp_src.appendSlice(arena, ";\n");

    try bp_src.appendSlice(arena, "pub fn ");
    try bp_src.appendSlice(arena, dfn.name);
    try bp_src.append(arena, '(');
    for (dfn.params, 0..) |p, i| {
        if (i > 0) try bp_src.appendSlice(arena, ", ");
        try bp_src.appendSlice(arena, p.name);
        try bp_src.appendSlice(arena, ": @Decl");
    }
    try bp_src.appendSlice(arena, ") -> void {\n");
    std.debug.print("decorator_eval: body has {} statements\n", .{dfn.body.len});
    try templateEval.emitBpBody(&bp_src, arena, dfn.body);
    std.debug.print("decorator_eval: after emitBpBody, bp_src len = {}\n", .{bp_src.items.len});
    try bp_src.appendSlice(arena, "}\n");

    std.debug.print("decorator_eval: generated bp_src:\n{s}\n", .{bp_src.items});

    const comptimeMod = @import("../comptime.zig");
    const erlang_codegen = @import("../codegen/erlang.zig");
    var session = comptimeMod.compile(arena, &.{.{ .path = "decorator_body", .source = bp_src.items }}, io, null, "erlang") catch |err| {
        std.debug.print("decorator_eval: compile failed: {}\n", .{err});
        return error.EvalFailed;
    };
    defer session.deinit(arena);

    const erl_src: ?[]const u8 = blk: {
        for (session.outputs.items) |out| {
            std.debug.print("decorator_eval: checking outcome: {}\n", .{out.outcome});
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
                    if (r.result.js.len > 0) break :blk r.result.js;
                }
            } else if (out.outcome == .parseError) {
                std.debug.print("decorator_eval: parseError - full output: {any}\n", .{out});
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
