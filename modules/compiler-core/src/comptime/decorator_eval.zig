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

    // Bind the @Decl handle as the first parameter (a JSON value).
    try bp_src.appendSlice(arena, "val ");
    try bp_src.appendSlice(arena, dfn.params[0].name);
    try bp_src.appendSlice(arena, " = ");
    try bp_src.appendSlice(arena, handleJson);
    try bp_src.appendSlice(arena, ";\n");

    // Bind plain args.
    for (plainArgs) |pa| {
        try bp_src.appendSlice(arena, "val ");
        try bp_src.appendSlice(arena, pa.paramName);
        try bp_src.appendSlice(arena, " = ");
        try bp_src.appendSlice(arena, pa.jsValue);
        try bp_src.appendSlice(arena, ";\n");
    }

    try bp_src.appendSlice(arena, "pub fn ");
    try bp_src.appendSlice(arena, dfn.name);
    try bp_src.append(arena, '(');
    for (dfn.params, 0..) |p, i| {
        if (i > 0) try bp_src.appendSlice(arena, ", ");
        try bp_src.appendSlice(arena, p.name);
        try bp_src.appendSlice(arena, ": _");
    }
    try bp_src.appendSlice(arena, ") -> void {\n");
    try templateEval.emitBpBody(&bp_src, arena, dfn.body);
    try bp_src.appendSlice(arena, "}\n");

    const comptimeMod = @import("../comptime.zig");
    const erlang_codegen = @import("../codegen/erlang.zig");
    var session = comptimeMod.compile(arena, &.{.{ .path = "decorator_body", .source = bp_src.items }}, io, null, "erlang") catch return error.EvalFailed;
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

    const hash = std.hash.Wyhash.hash(0, dfn.name);
    const tmp_dir = try std.fmt.allocPrint(arena, ".botopinkbuild/tmp/decorator_{x}", .{hash});
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    const erl_path = try std.fmt.allocPrint(arena, "{s}/decorator_body.erl", .{tmp_dir});
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = erl_code }) catch return error.EvalFailed;

    const persistent_erl = @import("./runtime/persistent_erl.zig");
    const stdout = persistent_erl.eval(arena, io, erl_path) catch return error.EvalFailed;
    defer arena.free(stdout);
    return parseOutcome(arena, stdout) catch error.EvalFailed;
}
