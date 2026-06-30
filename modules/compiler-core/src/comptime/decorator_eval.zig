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

/// F9 — runtime dispatch for decorator body evaluation. Mirrors
/// `template_eval.Runtime`. Default callers use the `.node` path via
/// `evaluate`; the `.wat` path is an opt-in scaffold that returns
/// `error.EvalFailed` until F6 prelude bodies + the wat-side body
/// emitter land.
pub const Runtime = enum { node, erl };

const Sha256 = std.crypto.hash.sha2.Sha256;

// ── process-global memo (script hash → stdout) ────────────────────────────────
//
// Identical decorator bodies always produce identical stdout (the body is pure
// — it only reads from `__decl(...)` and emits `{kind,…}` JSON). Re-spawning
// `node` for the same body across tests is pure waste. Mirrors the memo in
// `template_eval.zig`: SHA-256-keyed, process-lifetime arena, page_allocator
// backed; the hashmap mutates under a one-writer spinlock so the actual `node`
// IPC stays parallel. On a hit `parseOutcome(arena, cached_stdout)` re-runs
// against the cached bytes, so the freshly-allocated Outcome stays bound to
// the caller's per-compile arena.

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
    // F9 default-flip — see template_eval.evaluate's matching comment.
    return evaluateRuntime(arena, io, build_root, dfn, handleJson, plainArgs, .node);
}

/// F9 — runtime-parameterised evaluate. Default callers use `.node`; the
/// `.wat` path attempts the in-WAT prelude + wasm3 first; on failure
/// falls through to the JS path so the suite stays green during
/// F6/F7/F9 implementation.
pub fn evaluateRuntime(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
    runtime: Runtime,
) EvalError!Outcome {
    if (runtime == .erl) {
        if (evaluateErl(arena, io, dfn, handleJson, plainArgs)) |out| {
            return out;
        } else |_| {}
    }
    return evaluateNode(arena, io, build_root, dfn, handleJson, plainArgs);
}

/// Persistent erl path for decorator body evaluation. Returns error.EvalFailed
/// until the erlang.zig decorator body emitter is implemented.
fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = arena;
    _ = io;
    _ = dfn;
    _ = handleJson;
    _ = plainArgs;
    return error.EvalFailed;
}

fn evaluateNode(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    const script = buildScript(arena, dfn, handleJson, plainArgs) catch return error.EvalFailed;

    // Memo: identical decorator bodies → identical stdout. Re-parsing into a
    // per-arena Outcome keeps lifetime semantics the same as the cold path.
    const key_bytes = scriptKey(script);
    const key: []const u8 = &key_bytes;
    if (memoLookup(key)) |cached_stdout| {
        return parseOutcome(arena, cached_stdout) catch error.EvalFailed;
    }

    // Spawn node to evaluate the JS script directly.
    // One-shot spawn per decorator evaluation (~18ms).
    var dir_buf: [512]u8 = undefined;
    const tmp_dir = std.fmt.bufPrint(&dir_buf, "{s}/decorator/{s}", .{ build_root, dfn.name }) catch return error.EvalFailed;
    var src_buf: [512]u8 = undefined;
    const src_path = std.fmt.bufPrint(&src_buf, "{s}/main.js", .{tmp_dir}) catch return error.EvalFailed;

    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch return error.EvalFailed;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = script }) catch return error.EvalFailed;

    const res = std.process.run(arena, io, .{ .argv = &.{ "node", src_path } }) catch return error.EvalFailed;
    memoStore(key, res.stdout);
    return parseOutcome(arena, res.stdout) catch error.EvalFailed;
}
