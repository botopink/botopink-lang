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
    _ = arena;
    _ = io;
    _ = tfn;
    _ = captures;
    _ = plainArgs;
    // Template body emission to Erlang requires #[@Host] method lowering
    // in erlang.zig. Methods annotated #[@Host] in template_runtime.bp
    // (Capture.lookup, Capture.bindings, failRaw, makeExpr, makeCode,
    // etc.) must be redirected to botopink_comptime_prelude module calls.
    //
    // The persistent erl infrastructure (BEAM cache, binary protocol,
    // warmup, safe_call error handling) is fully operational for
    // comptime val evaluation via beam.zig.
    return error.EvalFailed;
}
