/// Runtime-backed decorator invocation (annotation processors, P2).
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core serializes
/// that declaration into a `@Decl` handle (kind/name/fields/methods/returnType/
/// annotations) and *runs* the decorator body over it — exactly like an `@Expr`
/// template body (see `template_eval.zig`), but the handle is reflection data
/// rather than a captured expression, and the body returns nothing: it only
/// validates placement/arguments and (P3) contributes wiring.
///
/// The body is emitted as plain JS (reusing the commonJS emitter), the handle
/// becomes a `__decl(...)` object exposing the reflection fields + `fail`/
/// `failAt`, and the script reports one result:
///
///   {"kind":"ok"}                         ← body completed without failing
///   {"kind":"fail","message","span"}      ← decl.fail()/failAt()
///   {"kind":"error","message"}            ← anything else thrown
///
/// Like template evaluation this always uses the **node** runtime regardless of
/// the compile target — host-side comptime work. Tooling paths (LSP /
/// compileTypesOnly) pass no eval context and never reach this module.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const commonJS = @import("../codegen/commonJS.zig");

// ── outcome ───────────────────────────────────────────────────────────────────

pub const Outcome = union(enum) {
    /// The body ran to completion without raising — placement/args accepted.
    /// `ok` carries the sources the body contributed via `@emit(...)` (empty when
    /// it emitted nothing); each is parsed + spliced into the module.
    ok: []const []const u8,
    /// `fail`/`failAt` — a scoped diagnostic to surface at the annotated decl.
    fail: struct {
        message: []const u8,
        span: ?template.Span,
    },
    /// The script itself failed (JS exception, protocol violation, …).
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

// ── JS prelude ────────────────────────────────────────────────────────────────

/// `DeclKind` mirrors the enum registered in the type env (`decl_reflection_src`
/// in comptime.zig); commonJS lowers a body's `DeclKind.Record` to a property
/// access on this global, so the values must match the handle's `kind` string.
/// `__decl` wraps the serialized handle, exposing the reflection fields as plain
/// data plus `fail`/`failAt` (which throw the `__bpfail` protocol object).
const prelude =
    \\"use strict";
    \\const DeclKind = { Record: "Record", Struct: "Struct", Enum: "Enum", Interface: "Interface", Fn: "Fn", Method: "Method", Field: "Field" };
    \\function Span(start, end, line) { return { start, end, line }; }
    \\function __failRaw(message, span) {
    \\    throw { __bpfail: { message: String(message), span: span ?? null } };
    \\}
    \\function __compilerError(message) { __failRaw(message, null); }
    \\const __emits = [];
    \\function __emit(source) { __emits.push(String(source)); }
    \\function __decl(h) {
    \\    return {
    \\        kind: h.kind,
    \\        name: h.name,
    \\        fields: h.fields,
    \\        methods: h.methods,
    \\        returnType: h.returnType,
    \\        annotations: h.annotations,
    \\        fail(message) { __failRaw(message, null); },
    \\        failAt(span, message) { __failRaw(message, span); },
    \\    };
    \\}
    \\
;

// ── script builder ────────────────────────────────────────────────────────────

fn buildScript(
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(arena);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll(prelude);

    // The reflected declaration, bound to the decorator's first parameter.
    const declParam = dfn.params[0].name;
    try bw.print("const {s} = __decl({s});\n", .{ declParam, handleJson });

    // Trailing annotation arguments (already JS-literal lexemes), bound to the
    // remaining parameters in order.
    for (plainArgs) |pa| {
        try bw.print("const {s} = {s};\n", .{ pa.paramName, pa.jsValue });
    }

    // The decorator fn body as plain JS.
    try commonJS.emitFnJs(arena, bw, dfn);
    try bw.writeAll("\n");

    // Invoke it with params in declaration order; a clean return is `ok`, a
    // `fail`/`failAt` throw is a scoped diagnostic, anything else is an error.
    try bw.print("let __r;\ntry {{\n    {s}(", .{dfn.name});
    for (dfn.params, 0..) |p, i| {
        if (i > 0) try bw.writeAll(", ");
        try bw.writeAll(p.name);
    }
    try bw.writeAll(
        \\);
        \\    __r = { kind: "ok", contributions: __emits };
        \\} catch (e) {
        \\    if (e && e.__bpfail) __r = { kind: "fail", ...e.__bpfail };
        \\    else __r = { kind: "error", message: String((e && e.message) || e) };
        \\}
        \\process.stdout.write(JSON.stringify(__r));
        \\
    );

    return aw.toOwnedSlice();
}

// ── result parsing ────────────────────────────────────────────────────────────

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) !Outcome {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, stdout, .{}) catch {
        return .{ .err = try std.fmt.allocPrint(arena, "decorator evaluator produced no result (output: {s})", .{stdout[0..@min(stdout.len, 200)]}) };
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

// ── entry point ───────────────────────────────────────────────────────────────

/// Run decorator `dfn` over the serialized `handleJson` (the annotated decl's
/// `@Decl` shape) in the node runtime, with `plainArgs` for its trailing
/// parameters. Everything in the returned `Outcome` is allocated in `arena`. The
/// script lands in `<build_root>/decorator/<fn>/`.
pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    const script = buildScript(arena, dfn, handleJson, plainArgs) catch return error.EvalFailed;

    var dir_buf: [512]u8 = undefined;
    const tmp_dir = std.fmt.bufPrint(&dir_buf, "{s}/decorator/{s}", .{ build_root, dfn.name }) catch return error.EvalFailed;
    var src_buf: [512]u8 = undefined;
    const src_path = std.fmt.bufPrint(&src_buf, "{s}/main.js", .{tmp_dir}) catch return error.EvalFailed;

    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = script }) catch return error.EvalFailed;

    const res = std.process.run(arena, io, .{ .argv = &.{ "node", src_path } }) catch return error.EvalFailed;
    return parseOutcome(arena, res.stdout) catch error.EvalFailed;
}
