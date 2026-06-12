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
const persistent_node = @import("./runtime/persistent_node.zig");
const wat_runtime = @import("./runtime/wat_runtime.zig");
const wat = @import("../codegen/wat.zig");
const wasm3_host = @import("./runtime/wasm3_host.zig");

/// F9 — runtime dispatch for decorator body evaluation. Mirrors
/// `template_eval.Runtime`. Default callers use the `.node` path via
/// `evaluate`; the `.wat` path is an opt-in scaffold that returns
/// `error.EvalFailed` until F6 prelude bodies + the wat-side body
/// emitter land.
pub const Runtime = enum { node, wat };

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
    return evaluateRuntime(arena, io, build_root, dfn, handleJson, plainArgs, .wat);
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
    if (runtime == .wat) {
        if (evaluateWat(arena, io, dfn, handleJson, plainArgs)) |out| {
            return out;
        } else |_| {}
    }
    return evaluateNode(arena, io, build_root, dfn, handleJson, plainArgs);
}

/// F9 scaffold for the wat3 path. Returns `error.EvalFailed` today —
/// same shape as `template_eval.evaluateWat`. Once F6 prelude bodies +
/// wat-side body emitter land, the final body:
///
///   1. `wat_runtime.prelude(arena)` for the comptime surface (incl. the
///      __decl reflection methods).
///   2. `wat.codegenEmitDecorator(arena, dfn, handleJson, plainArgs)` for
///      the decorator body itself (NEW entry point — mirrors
///      template_eval's `buildScript` but emits WAT).
///   3. `wasm3_host.runWat(arena, prelude ++ body)`.
///   4. Inspect `$__bp_err`: on trap with err≠0, parse the stored
///      payload as a `fail` outcome; otherwise parse stdout.
fn evaluateWat(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = plainArgs;

    var aw: std.Io.Writer.Allocating = .init(arena);
    defer aw.deinit();
    const bw = &aw.writer;

    bw.writeAll("(module\n") catch return error.EvalFailed;

    const prelude_bytes = wat_runtime.prelude(arena, io) catch return error.EvalFailed;
    bw.writeAll(prelude_bytes) catch return error.EvalFailed;

    // Parse the JSON and build a properly-structured DeclHandle record
    // in WAT linear memory so that `decl.kind` / `decl.methods` / etc.
    // (which the bp backend lowers to `i32.load offset=N`) read valid
    // pointers into length-prefixed strings and arrays.
    const decl_layout = try buildDeclLayout(arena, handleJson);

    // Emit data segments for all string and record data.
    {
        var off: u32 = 600;
        for (decl_layout.segments.items) |seg| {
            bw.print("(data (i32.const {d}) \"", .{off}) catch return error.EvalFailed;
            for (seg) |b| switch (b) {
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
            off += @intCast(seg.len);
        }
    }

    wat.emitFnWat(arena, bw, dfn) catch return error.EvalFailed;

    // Pass the DeclHandle record pointer to the decorator body.
    // After the body returns, flush accumulated @emit contributions.
    // If the body called fail() the trap skips this — wasm3_host catches it.
    bw.print(
        "  (func $_botopink_main (export \"_botopink_main\") (export \"_start\")\n" ++
            "    i32.const {d}\n" ++
            "    call ${s}\n",
        .{ decl_layout.decl_handle_offset, dfn.name },
    ) catch return error.EvalFailed;
    if (dfn.returnType != null) {
        bw.writeAll("    drop\n") catch return error.EvalFailed;
    }
    bw.writeAll("    call $__emit_flush\n") catch return error.EvalFailed;
    bw.writeAll("  )\n") catch return error.EvalFailed;

    bw.writeAll(")\n") catch return error.EvalFailed;

    const wat_source = aw.toOwnedSlice() catch return error.EvalFailed;

    const out = wasm3_host.runWat(arena, wat_source) catch return error.EvalFailed;

    if (out.len == 0) return error.EvalFailed;
    return parseOutcome(arena, out) catch error.EvalFailed;
}

const DeclLayout = struct {
    segments: std.ArrayListUnmanaged([]const u8),
    decl_handle_offset: u32,
};

fn buildDeclLayout(arena: std.mem.Allocator, json: []const u8) !DeclLayout {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, json, .{}) catch
        return error.EvalFailed;
    const obj = switch (parsed) {
        .object => |o| o,
        else => return error.EvalFailed,
    };

    const kind = switch (obj.get("kind") orelse return error.EvalFailed) {
        .string => |s| s,
        else => return error.EvalFailed,
    };
    const name = switch (obj.get("name") orelse return error.EvalFailed) {
        .string => |s| s,
        else => return error.EvalFailed,
    };
    const returnType = switch (obj.get("returnType") orelse return error.EvalFailed) {
        .string => |s| s,
        else => return error.EvalFailed,
    };

    // Extract method/field names from the JSON arrays.
    var method_names: std.ArrayListUnmanaged([]const u8) = .empty;
    if (obj.get("methods")) |mv| switch (mv) {
        .array => |items| for (items.items) |it| switch (it) {
            .object => |mo| if (mo.get("name")) |mn| switch (mn) {
                .string => |ms| try method_names.append(arena, ms),
                else => {},
            },
            else => {},
        },
        else => {},
    };

    var field_names: std.ArrayListUnmanaged([]const u8) = .empty;
    if (obj.get("fields")) |fv| switch (fv) {
        .array => |items| for (items.items) |it| switch (it) {
            .object => |fo| if (fo.get("name")) |fn_| switch (fn_) {
                .string => |fs| try field_names.append(arena, fs),
                else => {},
            },
            else => {},
        },
        else => {},
    };

    var segments: std.ArrayListUnmanaged([]const u8) = .empty;

    // Helper: append a length-prefixed string segment (4-byte LE length + bytes).
    const appendStr = struct {
        fn f(segments_: *std.ArrayListUnmanaged([]const u8), arena_: std.mem.Allocator, s: []const u8) !void {
            const buf = try arena_.alloc(u8, 4 + s.len);
            std.mem.writeInt(u32, buf[0..4], @intCast(s.len), .little);
            @memcpy(buf[4..], s);
            try segments_.append(arena_, buf);
        }
    }.f;

    // Helper: append raw bytes.
    const appendRaw = struct {
        fn f(segments_: *std.ArrayListUnmanaged([]const u8), arena_: std.mem.Allocator, bytes: []const u8) !void {
            const buf = try arena_.alloc(u8, bytes.len);
            @memcpy(buf, bytes);
            try segments_.append(arena_, buf);
        }
    }.f;

    // Helper: write a u32 as 4 little-endian bytes.
    const writeU32 = struct {
        fn f(bytes: *[4]u8, v: u32) void {
            std.mem.writeInt(u32, bytes, v, .little);
        }
    }.f;

    // Build segments in order, tracking nothing about offsets yet.
    // Segment 0: kind string
    try appendStr(&segments, arena, kind);
    // Segment 1: name string
    try appendStr(&segments, arena, name);
    // Segment 2: returnType string
    try appendStr(&segments, arena, returnType);
    // For each field: name string + 4-byte record
    for (field_names.items) |fn_| {
        try appendStr(&segments, arena, fn_);
        var rec: [4]u8 = undefined;
        writeU32(&rec, 0); // placeholder, will be patched
        try appendRaw(&segments, arena, &rec);
    }
    // Fields array: [len: u32][ptr0: u32]...
    {
        const arr_len: u32 = @intCast(4 + field_names.items.len * 4);
        const arr = try arena.alloc(u8, arr_len);
        @memset(arr, 0); // will be patched
        try segments.append(arena, arr);
    }
    // For each method: name string + 4-byte record
    for (method_names.items) |mn| {
        try appendStr(&segments, arena, mn);
        var rec: [4]u8 = undefined;
        writeU32(&rec, 0); // placeholder
        try appendRaw(&segments, arena, &rec);
    }
    // Methods array: [len: u32][ptr0: u32]...
    {
        const arr_len: u32 = @intCast(4 + method_names.items.len * 4);
        const arr = try arena.alloc(u8, arr_len);
        @memset(arr, 0); // will be patched
        try segments.append(arena, arr);
    }
    // Annotations array: empty [0]
    {
        const arr: [4]u8 = .{ 0, 0, 0, 0 };
        try appendRaw(&segments, arena, &arr);
    }
    // DeclHandle record: 6 slots × 4 bytes = 24 bytes
    {
        const arr = try arena.alloc(u8, 24);
        @memset(arr, 0); // will be patched
        try segments.append(arena, arr);
    }

    // Now compute all offsets from segments.
    const DATA_BASE: u32 = 600;
    var off: u32 = 0;
    var seg_offsets = try arena.alloc(u32, segments.items.len);
    for (segments.items, 0..) |seg, i| {
        seg_offsets[i] = DATA_BASE + off;
        off += @as(u32, @intCast(seg.len));
    }

    // Patch field records with their name string pointers.
    {
        var si: u32 = 3; // first field name string is segment index 3
        for (0..field_names.items.len) |_| {
            const name_ptr = seg_offsets[si]; // name string
            std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(segments.items[si + 1].ptr))), name_ptr, .little);
            si += 2;
        }
    }

    // Patch fields array.
    {
        const field_arr_start = 3 + @as(u32, @intCast(field_names.items.len * 2));
        const arr_seg = segments.items[field_arr_start];
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(arr_seg.ptr))), @intCast(field_names.items.len), .little);
        var rp: u32 = seg_offsets[3]; // first field record
        for (0..field_names.items.len) |i| {
            const elem_ptr: *[4]u8 = @ptrCast(@constCast(arr_seg.ptr + 4 + i * 4));
            std.mem.writeInt(u32, elem_ptr, rp, .little);
            rp += 4; // each field record is just 4 bytes (name pointer)
        }
    }

    // Patch method records with their name string pointers.
    {
        const method_name_start = 3 + @as(u32, @intCast(field_names.items.len * 2)) + 1; // +1 for fields array
        var si = method_name_start;
        for (0..method_names.items.len) |_| {
            const name_ptr = seg_offsets[si];
            std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(segments.items[si + 1].ptr))), name_ptr, .little);
            si += 2;
        }
    }

    // Patch methods array.
    {
        const method_arr_si = 3 + @as(u32, @intCast(field_names.items.len * 2)) + 1 + @as(u32, @intCast(method_names.items.len * 2));
        const arr_seg = segments.items[method_arr_si];
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(arr_seg.ptr))), @intCast(method_names.items.len), .little);
        const method_rec_start = seg_offsets[3 + @as(u32, @intCast(field_names.items.len * 2)) + 1];
        for (0..method_names.items.len) |i| {
            const elem_ptr: *[4]u8 = @ptrCast(@constCast(arr_seg.ptr + 4 + i * 4));
            std.mem.writeInt(u32, elem_ptr, method_rec_start + @as(u32, @intCast(i)) * 4, .little);
        }
    }

    // Patch DeclHandle record.
    {
        const decl_handle_si = 3 + @as(u32, @intCast(field_names.items.len * 2)) + 1 + @as(u32, @intCast(method_names.items.len * 2)) + 1 + 1; // fields arr + methods arr + annotations arr
        const rec = segments.items[decl_handle_si];
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr))), seg_offsets[0], .little); // kind
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr + 4))), seg_offsets[1], .little); // name
        const fields_arr_si = 3 + @as(u32, @intCast(field_names.items.len * 2));
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr + 8))), seg_offsets[fields_arr_si], .little); // fields
        const methods_arr_si = fields_arr_si + 1 + @as(u32, @intCast(method_names.items.len * 2));
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr + 12))), seg_offsets[methods_arr_si], .little); // methods
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr + 16))), seg_offsets[2], .little); // returnType
        std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(@constCast(rec.ptr + 20))), seg_offsets[methods_arr_si + 1], .little); // annotations
    }

    const decl_handle_si = 3 + @as(u32, @intCast(field_names.items.len * 2)) + 1 + @as(u32, @intCast(method_names.items.len * 2)) + 1 + 1;
    const decl_handle_offset = seg_offsets[decl_handle_si];

    return .{ .segments = segments, .decl_handle_offset = decl_handle_offset };
}


// F9 readiness gate. Symmetric to template_eval's.
test "F9 evaluateRuntime dispatches node default; wat scaffold falls back to node" {
    try std.testing.expect(@hasDecl(@This(), "Runtime"));
    const r_node: Runtime = .node;
    const r_wat: Runtime = .wat;
    try std.testing.expect(r_node == .node);
    try std.testing.expect(r_wat == .wat);
    try std.testing.expect(@hasDecl(@This(), "evaluateRuntime"));
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

    // Fast path: persistent `node` runner (~1ms per call). Falls back to
    // one-shot `node main.js` if the runner can't be spawned. Same wiring
    // pattern as `template_eval.evaluate` and `runtime/node.zig run`.
    if (persistent_node.eval(arena, io, script)) |out| {
        memoStore(key, out);
        return parseOutcome(arena, out) catch error.EvalFailed;
    } else |_| {}

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
