/// Runtime-backed template evaluation (expr-templates F6-full, slice 1).
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, this module *runs* the body: the captures become JS objects
/// carrying the comptime surface (`text`/`parts`/`source`/`context`/`lookup`/
/// `bindings`/`build`/`fail`/`failAt`), the template fn is emitted as plain
/// JS (reusing the commonJS emitter), and the script reports one result:
///
///   {"kind":"code","source":"…"}                  ← build() / @code
///   {"kind":"value","value":<json>}               ← @expr(v)
///   {"kind":"capture","param":"template"}         ← `return template;`
///   {"kind":"custom","source":"…","ast":<json>}   ← custom(tree, code)
///   {"kind":"fail","message","param","span"}      ← fail()/failAt()
///   {"kind":"error","message"}                    ← anything else thrown
///
/// Template evaluation always uses the **node** runtime regardless of the
/// compile target — it is host-side comptime work, like the existing eval
/// backends (erlang parity is a recorded follow-up). Tooling paths
/// (compileTypesOnly / LSP) never reach this module.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const commonJS = @import("../codegen/commonJS.zig");

// ── outcome ───────────────────────────────────────────────────────────────────

pub const Outcome = union(enum) {
    /// Generated source text to parse and splice at the call site.
    code: []const u8,
    /// A comptime value to lift as a literal (JSON-encoded).
    value: std.json.Value,
    /// Pass-through of the named `@Expr` parameter's capture.
    capture: []const u8,
    /// `q.custom(tree, code)` — the executable `code` half (source text, spliced
    /// like `code` above) plus the reference `ast` tree (a JSON `CustomNode`,
    /// stored by call-location for tooling, never lowered). expr-custom.
    custom: struct {
        code: []const u8,
        ast: std.json.Value,
    },
    /// `fail`/`failAt` — abort expansion with a template diagnostic.
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    /// The script itself failed (JS exception, protocol violation, …).
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

// ── JS prelude ────────────────────────────────────────────────────────────────

/// The comptime surface, implemented over the serialized capture handle
/// (`template.contextJsonAlloc` shape: file/line/col/multiline/text/scope).
const prelude =
    \\"use strict";
    \\function __expr(v) { return { __lift: v }; }
    \\function __code(s) { return { __code: String(s) }; }
    \\function Span(start, end, line) { return { start, end, line }; }
    \\// `CustomNode(kind, span, label, ref, children)` — the reference-tree node a
    \\// sub-language template builds for `q.custom`. Named-arg construction lowers
    \\// to positional in field-declaration order; a returned object satisfies both
    \\// the plain-call and `new`-call forms.
    \\function CustomNode(kind, span, label, ref, children) { return { kind, span, label, ref, children }; }
    \\function __failRaw(message, param, span) {
    \\    throw { __bpfail: { message: String(message), param: param ?? null, span: span ?? null } };
    \\}
    \\function __compilerError(message) { __failRaw(message, null, null); }
    \\// `parts` is null for a hole-free template (synthesized from `text`); a
    \\// holed template carries explicit parts whose Interp entries expose a
    \\// `code` placeholder (`__bp_hole_<param>_<i>`) — embedding it in built
    \\// source splices the caller's hole expression back at expansion.
    \\function __capture(param, d, parts) {
    \\    return {
    \\        __cap: param,
    \\        value() { __failRaw("value() is only available after expansion", param); },
    \\        text() {
    \\            if (d.text === null) __failRaw("text() unavailable: template has ${...} holes — use parts()", param);
    \\            return d.text;
    \\        },
    \\        parts() {
    \\            if (parts !== null) return parts;
    \\            if (d.text === null) return [];
    \\            return [{ kind: "Text", text: d.text, span: { start: 0, end: d.text.length, line: 1 } }];
    \\        },
    \\        source() { return { file: d.file, line: d.line, col: d.col }; },
    \\        context() { return { source: this.source(), text: d.text, multiline: d.multiline }; },
    \\        lookup(name) {
    \\            const kind = d.scope[name];
    \\            return kind ? { name, kind, ref() { return { __code: name }; } } : null;
    \\        },
    \\        bindings() { return Object.entries(d.scope).map(([name, kind]) => ({ name, kind, ref() { return { __code: name }; } })); },
    \\        build(s) { return { __code: String(s) }; },
    \\        custom(ast, code) {
    \\            const source = (code && code.__code !== undefined) ? String(code.__code) : String(code);
    \\            return { __custom: { source, ast } };
    \\        },
    \\        fail(message) { __failRaw(message, param, null); },
    \\        failAt(span, message) { __failRaw(message, param, span); },
    \\    };
    \\}
    \\
;

/// Serialize a holed capture's `stringTemplate` parts as the JSON array the
/// prelude's `parts()` returns: Text entries carry their raw text, Interp
/// entries a `code` placeholder (`__bp_hole_<param>_<i>`) that the built
/// source embeds and `infer.substituteHoles` replaces with the caller's hole
/// expression. Spans are template-relative byte offsets (holes are 0-width).
fn appendPartsJson(
    buf: *std.ArrayList(u8),
    arena: std.mem.Allocator,
    cap: *const template.CapturedExpr,
) !void {
    const parts = cap.node.literal.kind.stringTemplate.parts;
    try buf.append(arena, '[');
    var offset: usize = 0;
    var line: usize = 1;
    var holeIdx: usize = 0;
    for (parts, 0..) |part, i| {
        if (i > 0) try buf.append(arena, ',');
        switch (part) {
            .text => |txt| {
                try buf.appendSlice(arena, "{\"kind\":\"Text\",\"text\":");
                try template.appendJsonString(buf, arena, txt);
                try appendSpanJson(buf, arena, offset, offset + txt.len, line);
                offset += txt.len;
                line += std.mem.count(u8, txt, "\n");
            },
            .expr => {
                try buf.appendSlice(arena, "{\"kind\":\"Interp\",\"code\":");
                const placeholder = try std.fmt.allocPrint(arena, "\"__bp_hole_{s}_{d}\"", .{ cap.paramName, holeIdx });
                try buf.appendSlice(arena, placeholder);
                try appendSpanJson(buf, arena, offset, offset, line);
                holeIdx += 1;
            },
        }
    }
    try buf.append(arena, ']');
}

fn appendSpanJson(buf: *std.ArrayList(u8), arena: std.mem.Allocator, start: usize, end: usize, line: usize) !void {
    var num: [96]u8 = undefined;
    const span = std.fmt.bufPrint(&num, ",\"span\":{{\"start\":{d},\"end\":{d},\"line\":{d}}}}}", .{ start, end, line }) catch unreachable;
    try buf.appendSlice(arena, span);
}

// ── script builder ────────────────────────────────────────────────────────────

fn buildScript(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(arena);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll(prelude);

    // Plain comptime arg bindings (non-@Expr params with literal values) — emitted
    // before capture objects so the body can reference them freely.
    for (plainArgs) |pa| {
        try bw.print("const {s} = {s};\n", .{ pa.paramName, pa.jsValue });
    }

    // One capture object per `@Expr` parameter, bound to the param's name.
    for (captures) |*cap| {
        const ctxJson = try template.contextJsonAlloc(cap, arena);
        const partsJson: []const u8 = if (cap.text == null) blk: {
            var buf: std.ArrayList(u8) = .empty;
            try appendPartsJson(&buf, arena, cap);
            break :blk try buf.toOwnedSlice(arena);
        } else "null";
        try bw.print("const {s} = __capture(\"{s}\", {s}, {s});\n", .{ cap.paramName, cap.paramName, ctxJson, partsJson });
    }

    // The template fn body as plain JS (params receive the capture objects).
    try commonJS.emitFnJs(arena, bw, tfn);
    try bw.writeAll("\n");

    // Call it with params in declaration order — each param name is already
    // bound to either a capture object or a plain arg value above.
    try bw.print("let __r;\ntry {{\n    const r = {s}(", .{tfn.name});
    for (tfn.params, 0..) |p, i| {
        if (i > 0) try bw.writeAll(", ");
        try bw.writeAll(p.name);
    }
    try bw.writeAll(
        \\);
        \\    if (r && r.__code !== undefined) __r = { kind: "code", source: r.__code };
        \\    else if (r && r.__lift !== undefined) __r = { kind: "value", value: r.__lift };
        \\    else if (r && r.__cap !== undefined) __r = { kind: "capture", param: r.__cap };
        \\    else if (r && r.__custom !== undefined) __r = { kind: "custom", source: r.__custom.source, ast: r.__custom.ast };
        \\    else __r = { kind: "error", message: "template returned a plain value — construct code with @expr(...), @code(...), build(...), or custom(...)" };
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
        return .{ .err = try std.fmt.allocPrint(arena, "template evaluator produced no result (output: {s})", .{stdout[0..@min(stdout.len, 200)]}) };
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
        const param: ?[]const u8 = switch (obj.get("param") orelse .null) {
            .string => |s| s,
            else => null,
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
        return .{ .fail = .{ .message = message, .param = param, .span = span } };
    }
    const message = switch (obj.get("message") orelse .null) {
        .string => |s| s,
        else => "template evaluation failed",
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

/// Run `tfn` with `captures` (and optional `plainArgs` for non-`@Expr` params)
/// in the node eval runtime. Everything in the returned `Outcome` is allocated
/// in `arena` (same lifetime as the type-check session). The script lands in
/// `<build_root>/template/<fn>/`.
pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    const script = buildScript(arena, tfn, captures, plainArgs) catch return error.EvalFailed;

    var dir_buf: [512]u8 = undefined;
    const tmp_dir = std.fmt.bufPrint(&dir_buf, "{s}/template/{s}", .{ build_root, tfn.name }) catch return error.EvalFailed;
    var src_buf: [512]u8 = undefined;
    const src_path = std.fmt.bufPrint(&src_buf, "{s}/main.js", .{tmp_dir}) catch return error.EvalFailed;

    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = script }) catch return error.EvalFailed;

    const res = std.process.run(arena, io, .{ .argv = &.{ "node", src_path } }) catch return error.EvalFailed;
    return parseOutcome(arena, res.stdout) catch error.EvalFailed;
}
