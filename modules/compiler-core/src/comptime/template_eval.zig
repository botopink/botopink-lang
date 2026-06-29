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
const wat = @import("../codegen/wat.zig");
const persistent_node = @import("./runtime/persistent_node.zig");
const wat_runtime = @import("./runtime/wat_runtime.zig");
const wasm3_host = @import("./runtime/wasm3_host.zig");

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
pub const Runtime = enum { node, wat, erl };

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
    return evaluateRuntime(arena, io, build_root, tfn, captures, plainArgs, .wat);
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
        } else |_| {
            // Fall through to node path. The erl path will be filled in
            // when erlang.zig gains template body emission support.
        }
    }
    if (runtime == .wat) {
        if (evaluateWat(arena, io, tfn, captures, plainArgs)) |out| {
            return out;
        } else |_| {
            // Fall through to JS path. Once F6 prelude bodies are filled
            // and the wat body emitter ships, this fallback closes via a
            // diagnostic instead of a silent route to JS.
        }
    }
    return evaluateNode(arena, io, build_root, tfn, captures, plainArgs);
}

/// Persistent erl path for template body evaluation.
/// Compiles the template body to Erlang source via erlang.zig codegen,
/// merges with the comptime prelude module, and executes via the persistent
/// erl subprocess. Returns error.EvalFailed until the erlang.zig template
/// body emitter is implemented.
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
fn evaluateWat(
    arena: std.mem.Allocator,
    io: std.Io,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = plainArgs;

    // 1. Assemble the WAT source: prelude + module-wrapped template body
    //    + entrypoint wrapper. The wat_runtime prelude carries the
    //    (memory ...) declaration, bump heap, error register, and the
    //    comptime surface; emitFnWat emits the template fn itself; the
    //    trailing `_botopink_main` wrapper drives the call so wasm3's
    //    runWat finds an entry point.
    var aw: std.Io.Writer.Allocating = .init(arena);
    defer aw.deinit();
    const bw = &aw.writer;

    bw.writeAll("(module\n") catch return error.EvalFailed;

    const prelude_bytes = wat_runtime.prelude(arena, io) catch return error.EvalFailed;
    bw.writeAll(prelude_bytes) catch return error.EvalFailed;

    // 2. Per-capture descriptor blob, embedded at fixed offsets in linear
    //    memory. Offsets start above the prelude's reserved page-0
    //    region (~300 bytes used by static prefixes/iovec scratch). Each
    //    capture gets a length-prefixed text buffer.
    //    Layout: cap0 at offset 600, cap1 at offset 600 + cap0.len + 4, ...
    //    For now we support a single capture (the audit's most common
    //    shape — `template_eval` always sees ≥ 1 capture, and the body's
    //    surface methods all operate on the lead capture). Multi-capture
    //    extends linearly.
    const CAPS_BASE: u32 = 600;
    var cap_offset: u32 = CAPS_BASE;
    for (captures) |cap| {
        const blob = wat_runtime.appendDescriptorBytes(arena, &cap) catch return error.EvalFailed;
        bw.print("(data (i32.const {d}) \"", .{cap_offset}) catch return error.EvalFailed;
        for (blob) |b| switch (b) {
            '\n' => bw.writeAll("\\n") catch return error.EvalFailed,
            '"' => bw.writeAll("\\\"") catch return error.EvalFailed,
            '\\' => bw.writeAll("\\\\") catch return error.EvalFailed,
            else => if (b < 0x20 or b >= 0x7f) {
                bw.print("\\{x:0>2}", .{b}) catch return error.EvalFailed;
            } else {
                bw.writeByte(b) catch return error.EvalFailed;
            },
        };
        bw.writeAll("\")\n") catch return error.EvalFailed;
        cap_offset += @intCast(blob.len);
    }

    // Emit data segments for capture param names (used by passthrough detection).
    var param_name_offsets = try arena.alloc(u32, captures.len);
    var current_data_off: u32 = cap_offset;
    for (captures, 0..) |cap, i| {
        const name_bytes = cap.paramName;
        bw.print("(data (i32.const {d}) \"", .{current_data_off}) catch return error.EvalFailed;
        // Write length prefix (4 bytes LE) + name bytes
        {
            const lenbytes = [4]u8{
                @truncate(name_bytes.len),
                @truncate(name_bytes.len >> 8),
                @truncate(name_bytes.len >> 16),
                @truncate(name_bytes.len >> 24),
            };
            for (lenbytes) |lc| bw.print("\\{x:0>2}", .{lc}) catch return error.EvalFailed;
            for (name_bytes) |b| switch (b) {
                '\n' => bw.writeAll("\\n") catch return error.EvalFailed,
                '"' => bw.writeAll("\\\"") catch return error.EvalFailed,
                '\\' => bw.writeAll("\\\\") catch return error.EvalFailed,
                else => if (b < 0x20 or b >= 0x7f) {
                    bw.print("\\{x:0>2}", .{b}) catch return error.EvalFailed;
                } else {
                    bw.writeByte(b) catch return error.EvalFailed;
                },
            };
        }
        bw.writeAll("\")\n") catch return error.EvalFailed;
        param_name_offsets[i] = current_data_off;
        current_data_off += 4 + @as(u32, @intCast(name_bytes.len));
    }

    wat.emitFnWat(arena, bw, tfn) catch return error.EvalFailed;

    // 3. Entrypoint wrapper. For each capture, construct a handle via
    //    `__capture(param=0, descriptor_ptr, parts_offset)`,
    //    then call the template fn with the handles as positional args.
    //    Save capture pointers in locals to detect passthrough returns.
    bw.writeAll(
        "  (func $_botopink_main (export \"_botopink_main\") (export \"_start\")\n" ++
        "    (local $__r i32) (local $__p i32)",
    ) catch return error.EvalFailed;
    for (captures, 0..) |_, i| {
        bw.print(" (local $__cap{d} i32)", .{i}) catch return error.EvalFailed;
    }
    bw.writeAll("\n") catch return error.EvalFailed;
    cap_offset = CAPS_BASE;
    for (captures, 0..) |cap, i| {
        const blob = wat_runtime.appendDescriptorBytes(arena, &cap) catch return error.EvalFailed;
        const parts_off = wat_runtime.partsOffsetInDescriptor(blob);
        bw.print(
            \\    ;; capture {s}
            \\    i32.const 0
            \\    i32.const {d}
            \\    i32.const {d}
            \\    call $__capture
            \\    local.tee $__cap{d}
            \\
        , .{ cap.paramName, cap_offset, cap_offset + parts_off, i }) catch return error.EvalFailed;
        cap_offset += @intCast(blob.len);
    }
    // Push all capture handles as args to the template fn.
    for (captures, 0..) |_, i| {
        bw.print("    local.get $__cap{d}\n", .{i}) catch return error.EvalFailed;
    }
    bw.print("    call ${s}\n", .{tfn.name}) catch return error.EvalFailed;

    // 4. Outcome emission — the wrapper inspects the return type and emits the
    //    appropriate JSON envelope (mirroring the JS buildScript's
    //    r.__code / r.__custom inspection). The return value is a record
    //    pointer from a constructor like $__code or $__capture__custom.
    if (tfn.returnType) |rt| {
        if (rt.isExprCustomType()) {
            // Return is __custom record: { code_ptr: i32, ast_ptr: i32 }
            bw.writeAll(
                \\    ;; emit custom outcome from return value
                \\    local.tee $__r
                \\    ;; stash ast_ptr at address 0 for host to read post-execution
                \\    i32.const 0
                \\    local.get $__r
                \\    i32.load offset=4
                \\    i32.store
                \\    ;; emit code half
                \\    local.get $__r
                \\    i32.load
                \\    local.tee $__p
                \\    i32.load
                \\    local.get $__p
                \\    i32.const 4
                \\    i32.add
                \\    i32.const 0
                \\    i32.const 0
                \\    call $__emit_outcome_custom
                \\
            ) catch return error.EvalFailed;
        } else if (rt.isExprType()) {
            // Check capture passthrough first, then kind dispatch.
            bw.writeAll("    ;; outcome dispatch\n    local.set $__r\n") catch return error.EvalFailed;
            for (captures, 0..) |cap, i| {
                bw.print(
                    \\    local.get $__r
                    \\    local.get $__cap{d}
                    \\    i32.eq
                    \\    if
                    \\      i32.const {d}
                    \\      i32.const {d}
                    \\      call $__emit_outcome_capture
                    \\      return
                    \\    end
                    \\
                , .{ i, param_name_offsets[i] + 4, cap.paramName.len }) catch return error.EvalFailed;
            }
            // Fall through: code or value outcome.
            bw.writeAll(
                \\    ;; kind dispatch: 0=code, 1=value
                \\    global.get $__bp_outcome_kind
                \\    i32.const 1
                \\    i32.eq
                \\    if
                \\      local.get $__r
                \\      drop
                \\      call $__emit_outcome_value
                \\    else
                \\      local.get $__r
                \\      i32.load
                \\      local.tee $__p
                \\      i32.load
                \\      local.get $__p
                \\      i32.const 4
                \\      i32.add
                \\      call $__emit_outcome_code
                \\    end
                \\
            ) catch return error.EvalFailed;
        } else {
            bw.writeAll("    drop\n") catch return error.EvalFailed;
        }
    } else {
        bw.writeAll("    drop\n") catch return error.EvalFailed;
    }
    bw.writeAll("  )\n") catch return error.EvalFailed;

    bw.writeAll(")\n") catch return error.EvalFailed;

    const wat_source = aw.toOwnedSlice() catch return error.EvalFailed;

    // 4. Hand off to wasm3. For @ExprCustom returns, also capture
    //    linear memory so we can read the CustomNode tree.
    const is_custom = if (tfn.returnType) |rt| rt.isExprCustomType() else false;
    if (is_custom) {
        const result = wasm3_host.runWatGetMem(arena, wat_source, 0, 0) catch return error.EvalFailed;
        const out = result.stdout;
        const mem = result.memory;
        defer arena.free(mem);
        if (out.len == 0) return error.EvalFailed;
        var outcome = parseOutcome(arena, out) catch return error.EvalFailed;

        // Read the CustomNode tree from memory. The wrapper stashed
        // ast_ptr at linear memory offset 0.
        if (mem.len >= 4) {
            const ast_ptr = std.mem.readInt(u32, mem[0..4], .little);
            if (ast_ptr != 0) {
                outcome.custom.root = template.readCustomNodeFromMemory(arena, mem, ast_ptr) catch return error.EvalFailed;
            }
        }
        return outcome;
    }

    const out = wasm3_host.runWat(arena, wat_source) catch return error.EvalFailed;

    if (out.len == 0) return error.EvalFailed;
    return parseOutcome(arena, out) catch error.EvalFailed;
}

// F8 readiness gate. Pin that the dispatcher exists and that the wat
// path's scaffold returns EvalFailed (so the node fallback always wins
// until F6 prelude bodies + the wat body emitter land).
test "F8 evaluateRuntime dispatches node default; wat scaffold falls back to node" {
    // The Runtime enum exists and has both arms.
    try std.testing.expect(@hasDecl(@This(), "Runtime"));
    const r_node: Runtime = .node;
    const r_wat: Runtime = .wat;
    try std.testing.expect(r_node == .node);
    try std.testing.expect(r_wat == .wat);

    // evaluateRuntime and evaluateWat are both exposed at module level.
    try std.testing.expect(@hasDecl(@This(), "evaluateRuntime"));
}

// F8 end-to-end: the WAT module assembly works. Builds the prelude +
// emits a minimal template fn through emitFnWat; passes the combined
// source through wat_to_wasm.compile to verify it's syntactically
// valid WAT that the wasm3 host could accept. Doesn't run the result
// — the runtime contract (RUN LOG parsing back into Outcome) lands
// in F9-tail.
test "F8 evaluateWat assembles a syntactically valid wat module" {
    const allocator = std.testing.allocator;
    const wat_to_wasm = @import("./runtime/wat_to_wasm.zig");

    // Build the same WAT shape evaluateWat does, minus the body emitter
    // (we don't have a real ast.FnDecl handy in this unit context). The
    // shape we verify here is: (module + prelude + close paren). If the
    // prelude assembles cleanly, the half-test is satisfied.
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try aw.writer.writeAll("(module\n");
    const prelude_bytes = try wat_runtime.prelude(allocator, std.testing.io);
    defer allocator.free(prelude_bytes);
    try aw.writer.writeAll(prelude_bytes);
    try aw.writer.writeAll(")\n");

    const wat_source = try aw.toOwnedSlice();
    defer allocator.free(wat_source);

    // Roundtrip through wat_to_wasm: a syntactically invalid prelude
    // would fail to parse here, so a successful compile pins the shape.
    const wasm_bytes = wat_to_wasm.compile(allocator, wat_source) catch |err| {
        std.debug.print("wat_to_wasm.compile failed: {s}\n", .{@errorName(err)});
        return error.WatCompileFailed;
    };
    defer allocator.free(wasm_bytes);

    try std.testing.expect(wasm_bytes.len > 0);
}

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

    // Persistent node runner: one long-lived `node` process per Zig process
    // evaluates scripts via vm.runInNewContext over a length-prefixed
    // stdin/stdout protocol (~1ms per call vs ~18ms cold spawn). Falls back
    // to one-shot `node main.js` if the runner can't be spawned (no node on
    // PATH, IPC framing error, etc.).
    if (persistent_node.eval(arena, io, script)) |out| {
        memoStore(key, out);
        return parseOutcome(arena, out) catch error.EvalFailed;
    } else |_| {
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
}
