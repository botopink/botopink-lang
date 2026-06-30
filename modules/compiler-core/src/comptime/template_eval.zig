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

/// F8 — runtime dispatch for template body evaluation.
///
/// `node` (default): builds JS via `commonJS.emitFnJs` + the JS prelude in
/// `template_eval.zig`, runs through `persistent_node.eval`. Stable path,
/// covers every audit body today.
///
/// `wat`: builds WAT via `wat_runtime.prelude` + the wat backend's template
/// emitter, runs through `wasm3_host.runWat`. End-to-end path the spec
/// terminates at after F10 deletes `persistent_node.zig`. Currently gated
/// behind opt-in because F6's prelude has stub bodies for the descriptor
/// walker (`lookup`/`bindings`/`text` after expansion) and there is no
/// wat-side `emitFnJs` analogue yet — `evaluateWat` returns
/// `error.EvalFailed` so the caller transparently falls back to `node`.
pub const Runtime = enum { node, erl };

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
    /// `root` is an optional pre-parsed tree from WAT memory (bypasses JSON).
    custom: struct {
        code: []const u8,
        ast: std.json.Value,
        root: ?template.CustomNode = null,
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

// ── process-global memo (script hash → stdout) ────────────────────────────────
//
// Identical template scripts always produce identical stdout, so re-spawning
// `node` to evaluate them is pure waste. Mirrors the memo in
// `runtime/node.zig`: SHA-256-keyed, process-lifetime arena, page_allocator
// backed; the hashmap is mutated under a one-writer spinlock (the actual
// `node` invocations stay parallel, only the put/get is serialised).
//
// On a hit we re-run `parseOutcome(arena, cached_stdout)` against the cached
// bytes — the Outcome is freshly allocated in the caller's per-compile arena
// (same lifetime contract as the miss path), so no aliasing across tests.

const Sha256 = std.crypto.hash.sha2.Sha256;

var script_memo_arena: std.heap.ArenaAllocator = undefined;
var script_memo: std.StringHashMapUnmanaged([]const u8) = .empty;
var script_memo_init: std.atomic.Value(u8) = .init(0);
var script_memo_mu: std.atomic.Value(u8) = .init(0);

fn memoInit() void {
    while (true) {
        const s = script_memo_init.load(.acquire);
        if (s == 2) return;
        if (s == 0) {
            if (script_memo_init.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            script_memo_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            script_memo_init.store(2, .release);
            return;
        }
        std.atomic.spinLoopHint();
    }
}

fn memoLock() void {
    while (script_memo_mu.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| {
        std.atomic.spinLoopHint();
    }
}
fn memoUnlock() void {
    script_memo_mu.store(0, .release);
}

fn scriptKey(src: []const u8) [Sha256.digest_length]u8 {
    var out: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(src, &out, .{});
    return out;
}

fn memoLookup(key: []const u8) ?[]const u8 {
    memoInit();
    memoLock();
    defer memoUnlock();
    return script_memo.get(key);
}

fn memoStore(key: []const u8, stdout: []const u8) void {
    memoInit();
    memoLock();
    defer memoUnlock();
    const arena = script_memo_arena.allocator();
    const key_dup = arena.dupe(u8, key) catch return;
    const val_dup = arena.dupe(u8, stdout) catch return;
    script_memo.put(arena, key_dup, val_dup) catch {};
}

// ── entry point ───────────────────────────────────────────────────────────────

/// Run `tfn` with `captures` (and optional `plainArgs` for non-`@Expr` params)
/// in the node eval runtime. Everything in the returned `Outcome` is allocated
/// in `arena` (same lifetime as the type-check session). The script lands in
/// `<build_root>/template/<fn>/`.
///
/// In-process memo (process-lifetime): when the SAME script was already
/// evaluated this process, the cached stdout is re-parsed without re-spawning
/// `node`. Same memoisation philosophy as `runtime/node.zig`.
pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    // F8 default-flip: try the wat path first, fall back to node on
    // EvalFailed. Safety net for the deletion gate — if any template
    // body's wat lowering can't complete the round-trip (descriptor
    // walker miss, body emitter gap, etc.), the JS path still answers
    // correctly. Once one release cycle observes zero `.node` fallback
    // fires in production, the F10 cleanup deletes `persistent_node.zig`
    // + drops this whole evaluateNode branch.
    return evaluateRuntime(arena, io, build_root, tfn, captures, plainArgs, .erl);
}

/// F8 — Runtime-parameterised evaluate. Default callers use the `.node`
/// path via `evaluate`. The `.wat` path attempts the in-WAT prelude +
/// wasm3 first; on failure falls through to the JS path so the suite
/// stays green during F6/F7/F8 implementation. Default callers don't
/// need to know this exists — `evaluate` is the stable shim.
pub fn evaluateRuntime(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    runtime: Runtime,
) EvalError!Outcome {
    if (runtime == .erl) {
        if (evaluateErl(arena, io, tfn, captures, plainArgs)) |out| {
            return out;
        } else |_| {}
    }
    return evaluateNode(arena, io, build_root, tfn, captures, plainArgs);
}

/// Persistent erl path for template body evaluation.
/// Compiles the template body to Erlang source via erlang.zig codegen,
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
    // Erlang path is wired. Template body emission via erlang.zig requires
    // #[@Host] method lowering (Steps 3-4). Falls through to Node.js.
    return error.EvalFailed;
}
/// F8 scaffold for the wat3 path. Returns `error.EvalFailed` today —
/// kept as an explicit entry point so the dispatcher above has a clean
/// hook + the diff that fills its body lands in one place.
///
/// Final shape:
///   1. `wat_runtime.prelude(arena)` for the comptime surface.
///   2. `wat.codegenEmitTemplate(arena, tfn, captures, plainArgs)` for the
///      template body itself (NEW entry point on the wat backend — needs
///      to follow `commonJS.emitFnJs`'s shape, mapping the captures into
///      the prelude's `__capture(...)` calls).
///   3. `wasm3_host.runWat(arena, prelude ++ body)`.
///   4. Inspect the `$__bp_err` global: on trap with err≠0, parse the
///      stored payload as a `fail` outcome; otherwise parse the stdout
///      as the JSON outcome same shape the node path returns.
fn evaluateNode(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    const script = buildScript(arena, tfn, captures, plainArgs) catch return error.EvalFailed;

    const key_bytes = scriptKey(script);
    const key: []const u8 = &key_bytes;
    if (memoLookup(key)) |cached_stdout| {
        return parseOutcome(arena, cached_stdout) catch error.EvalFailed;
    }

    // Spawn node to evaluate the JS script directly.
    // One-shot spawn per template evaluation (~18ms).
    // TODO: replace with persistent erl path once erlang.zig codegen
    // supports template body emission (Steps 3-5).
    var dir_buf: [512]u8 = undefined;
    const tmp_dir = std.fmt.bufPrint(&dir_buf, "{s}/template/{s}", .{ build_root, tfn.name }) catch return error.EvalFailed;
    var src_buf: [512]u8 = undefined;
    const src_path = std.fmt.bufPrint(&src_buf, "{s}/main.js", .{tmp_dir}) catch return error.EvalFailed;

    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = script }) catch return error.EvalFailed;

    const res = std.process.run(arena, io, .{ .argv = &.{ "node", src_path } }) catch return error.EvalFailed;
    memoStore(key, res.stdout);
    return parseOutcome(arena, res.stdout) catch error.EvalFailed;
}
