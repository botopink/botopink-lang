//! The web comptime host (decisions 1035, 1038 (2), 1059; piece C3b): one
//! evaluation over comptime units on the page's engine, the browser build's
//! counterpart of the native host (`comptime_host.zig`, C3a) under the same
//! contract — `codegen.wasmComptimeHost` is this file on a wasm host and that
//! one natively.
//!
//! **Everything but the engine is the compiler's.** `plan` reads each unit's
//! imports and sorts them with the native host's own `serviceOf`, words each
//! forbidden one with its `classText` and writes each refusal with its words,
//! and lays the units, the input and `runtime_unit.zig`'s crossing names into
//! one buffer; the page's glue (`modules/compiler-web/glue.js`
//! `runComptimeUnits`) only follows it on its engine — GC and exceptions on
//! (1033 (1)), every unit compiled and instantiated afresh in dependency
//! order (`comptime_host.reset`), every `__bp_init` in order, the input at
//! the core's `__alloc` in its `memory`, the evaluated module's
//! `__bp_comptime_eval(ptr, len) -> (ptr, len)` read back. `finish` turns its
//! answer into the native host's shape — the `Fault` with the class and the
//! import that trapped and the backtrace's named frames (1063 (1)), the reply
//! the native `hostReply` builds when no codec ran. So both hosts give one
//! reply for one unit, byte for byte, but for the engine's own trap words
//! (`glue.js` maps V8's to the names the native host gives wasmtime's trap
//! codes). The page reads frames through V8's stack-trace API; another engine
//! gives none — degraded, never refused (1069 (3)). The page links these units
//! through the one path its own `run()` and the term runtime's `run_module`
//! link through (`glue.js` `linkUnits`, 1069 (4), (5)).
//!
//! **The call**: `bp_host.run_units(plan_ptr, plan_len) -> status` (0 the
//! reply, 1 raised — `{"message","import","frames":[{"module","function"}]}`
//! —, 2 a compile refusal), then `result_len` / `result_copy` and
//! `printed_len` / `printed_copy`.
//!
//! **The plan** (little-endian; `str` = u32 length, then the bytes): u32 unit
//! count; per unit `str` name, `str` bytes, u32 import count and per import
//! `str` module, `str` name, u32 `Action`, `str` text; then `str` input and
//! the five crossing names — the core unit, its memory, its alloc, the
//! evaluation export, the evaluated unit.
//!
//! The page has no epoch: no deadline (`Options.deadline_ns` is not armed
//! there) and the compiler's interrupt is a no-op, as `persistent_wat`'s
//! `Page` is today. The evaluators still run
//! `comptime/runtime/persistent_wat.zig` until C4.
const std = @import("std");
const builtin = @import("builtin");
const ru = @import("runtime_unit.zig");
const native = @import("comptime_host.zig");

const is_wasm = builtin.cpu.arch.isWasm();

pub const Error = std.mem.Allocator.Error;
pub const Unit = native.Unit;
pub const reset = native.reset;
pub const hostReply = native.hostReply;
pub const Fault = native.Fault;
pub const Frame = native.Frame;

pub const Options = struct {
    /// Native only; the page keeps compiled code in the page.
    cache_dir: ?[]const u8 = null,
    cold: bool = false,
    /// The page has no epoch: never armed there.
    deadline_ns: ?u64 = null,
};

pub const Outcome = union(enum) {
    /// The evaluation export's reply JSON, as the codec wrote it.
    reply: []u8,
    /// No codec ran: the reply the host built, and what raised.
    raised: struct { reply: []u8, fault: Fault },
    /// A unit the engine refused, an import the host does not serve, or a
    /// crossing export missing.
    compile_error: []u8,
};

/// How the evaluation ended: always `exited` on the page (no epoch).
pub const End = enum { exited, interrupted, timed_out };

pub const Answer = struct {
    outcome: Outcome,
    /// What fd 1 and 2 received, in order.
    printed: []u8,
    end: End = .exited,

    pub fn deinit(self: Answer, alloc: std.mem.Allocator) void {
        switch (self.outcome) {
            .reply, .compile_error => |t| alloc.free(t),
            .raised => |r| {
                alloc.free(r.reply);
                r.fault.deinit(alloc);
            },
        }
        alloc.free(self.printed);
    }
};

/// What the page does with one import.
pub const Action = enum(u32) {
    /// An earlier unit's export, by its module name.
    unit = 0,
    /// `fd_write`: fd 1 / 2 captured, any other fd traps with the text.
    print = 1,
    /// `sched_yield`: answers 0.
    yield = 2,
    /// Traps with the text.
    trap = 3,
    /// The evaluation is refused, with the text, when this unit links.
    refuse = 4,
};

const host = if (is_wasm) struct {
    extern "bp_host" fn run_units(plan_ptr: [*]const u8, plan_len: usize) u32;
    extern "bp_host" fn result_len() usize;
    extern "bp_host" fn result_copy(dst: [*]u8) void;
    extern "bp_host" fn printed_len() usize;
    extern "bp_host" fn printed_copy(dst: [*]u8) void;
} else struct {};

/// Run one evaluation of the module `module`'s body on the page's engine.
/// Every text of the answer is owned by `alloc`.
pub fn evaluate(alloc: std.mem.Allocator, io: std.Io, units: []const Unit, module: []const u8, input: []const u8, opts: Options) Error!Answer {
    _ = io;
    _ = opts;
    if (comptime !is_wasm) @compileError("comptime_page runs on a wasm host only; natively the host is comptime_host.zig");
    const p = try plan(alloc, units, module, input);
    defer alloc.free(p);
    const status = host.run_units(p.ptr, p.len);
    const text = try alloc.alloc(u8, host.result_len());
    defer alloc.free(text);
    host.result_copy(text.ptr);
    const printed = try alloc.alloc(u8, host.printed_len());
    defer alloc.free(printed);
    host.printed_copy(printed.ptr);
    return finish(alloc, status, text, printed) catch |e| switch (e) {
        error.OutOfMemory => error.OutOfMemory,
        error.BadAnswer => .{ .outcome = .{ .compile_error = try alloc.dupe(u8, "the page's comptime host answered no raise it can read") }, .printed = try alloc.dupe(u8, printed) },
    };
}

/// The native host's `Answer` for the page's `status`, `text` and `printed`
/// (copied).
pub fn finish(alloc: std.mem.Allocator, status: u32, text: []const u8, printed: []const u8) (Error || error{BadAnswer})!Answer {
    const p = try alloc.dupe(u8, printed);
    errdefer alloc.free(p);
    const outcome: Outcome = switch (status) {
        0 => .{ .reply = try alloc.dupe(u8, text) },
        2 => .{ .compile_error = try alloc.dupe(u8, text) },
        else => blk: {
            const f = try faultOf(alloc, text);
            errdefer f.deinit(alloc);
            break :blk .{ .raised = .{ .reply = try hostReply(alloc, f, p), .fault = f } };
        },
    };
    return .{ .outcome = outcome, .printed = p };
}

/// The page's raise, `{"message","import","frames"}`, as the native `Fault`.
fn faultOf(alloc: std.mem.Allocator, text: []const u8) (Error || error{BadAnswer})!Fault {
    const Raw = struct { message: []const u8, import: []const u8 = "", frames: []const struct { module: []const u8, function: []const u8 } = &.{} };
    const parsed = std.json.parseFromSlice(Raw, alloc, text, .{}) catch |e| return if (e == error.OutOfMemory) error.OutOfMemory else error.BadAnswer;
    defer parsed.deinit();
    const raw = parsed.value;
    var f: Fault = .{ .message = try alloc.dupe(u8, raw.message) };
    errdefer f.deinit(alloc);
    f.import = try alloc.dupe(u8, raw.import);
    if (std.mem.indexOfScalar(u8, raw.import, '.')) |dot| f.service = native.serviceOf(raw.import[0..dot], raw.import[dot + 1 ..]);
    const n = @min(raw.frames.len, native.max_frames);
    const frames = try alloc.alloc(Frame, n);
    var made: usize = 0;
    errdefer {
        for (frames[0..made]) |fr| {
            alloc.free(fr.module);
            alloc.free(fr.function);
        }
        alloc.free(frames);
    }
    for (raw.frames[0..n], frames) |r, *fr| {
        const module = try alloc.dupe(u8, r.module);
        errdefer alloc.free(module);
        fr.* = .{ .module = module, .function = try alloc.dupe(u8, r.function) };
        made += 1;
    }
    f.frames = frames;
    return f;
}

/// The plan of one evaluation (the file comment). Owned.
pub fn plan(alloc: std.mem.Allocator, units: []const Unit, module: []const u8, input: []const u8) Error![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(alloc);
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const ar = arena.allocator();
    try int(alloc, &out, units.len);
    for (units, 0..) |u, i| {
        try str(alloc, &out, u.name);
        try str(alloc, &out, u.bytes);
        // A unit that does not read is the engine's to refuse first.
        const imports = importsOf(ar, u.bytes) catch &.{};
        try int(alloc, &out, imports.len);
        for (imports) |imp| {
            const action, const text = try actionOf(ar, u, imp, units[0..i]);
            try str(alloc, &out, imp.module);
            try str(alloc, &out, imp.name);
            try int(alloc, &out, @intFromEnum(action));
            try str(alloc, &out, text);
        }
    }
    try str(alloc, &out, input);
    for ([_][]const u8{ ru.name, ru.memory_export, ru.alloc_export, ru.comptime_eval_export, module }) |n| try str(alloc, &out, n);
    return out.toOwnedSlice(alloc);
}

/// The native host's sorting of one import (`comptime_host.defineImports`).
fn actionOf(ar: std.mem.Allocator, unit: Unit, imp: Import, earlier: []const Unit) Error!struct { Action, []const u8 } {
    const service = native.serviceOf(imp.module, imp.name) orelse {
        for (earlier) |e| {
            if (std.mem.eql(u8, e.name, imp.module)) return .{ .unit, "" };
        }
        return .{ .refuse, try std.fmt.allocPrint(ar, "unit {s} imports {s}.{s}: no earlier unit is {s}, and the comptime host serves no such import", .{ unit.name, imp.module, imp.name, imp.module }) };
    };
    if (imp.kind != 0)
        return .{ .refuse, try std.fmt.allocPrint(ar, "unit {s} imports {s}.{s} as no function: the comptime host serves functions only", .{ unit.name, imp.module, imp.name }) };
    if (service == .yield) return .{ .yield, "" };
    // `fd_write` beyond fd 1 / 2 is a file.
    return .{ if (service == .print) .print else .trap, native.classText(service) };
}

fn int(alloc: std.mem.Allocator, out: *std.ArrayList(u8), v: usize) Error!void {
    var b: [4]u8 = undefined;
    std.mem.writeInt(u32, &b, @intCast(v), .little);
    try out.appendSlice(alloc, &b);
}

fn str(alloc: std.mem.Allocator, out: *std.ArrayList(u8), s: []const u8) Error!void {
    try int(alloc, out, s.len);
    try out.appendSlice(alloc, s);
}

/// One import of a binary module: its names and its kind (0 a function).
pub const Import = struct { module: []const u8, name: []const u8, kind: u8 };

/// The imports of the binary module `bytes`, in order (slices of `bytes`).
pub fn importsOf(ar: std.mem.Allocator, bytes: []const u8) (Error || error{Malformed})![]const Import {
    if (bytes.len < 8 or !std.mem.eql(u8, bytes[0..4], "\x00asm")) return error.Malformed;
    var r: Reader = .{ .b = bytes, .at = 8 };
    while (r.at < bytes.len) {
        const id = try r.byte();
        const size = try r.uleb();
        const end = r.at + size;
        if (end > bytes.len) return error.Malformed;
        if (id != 2) {
            r.at = end;
            continue;
        }
        const n = try r.uleb();
        const list = try ar.alloc(Import, n);
        for (list) |*imp| {
            const m = try r.name();
            const f = try r.name();
            const kind = try r.byte();
            switch (kind) {
                0 => _ = try r.uleb(),
                1 => {
                    try r.valType();
                    try r.limits();
                },
                2 => try r.limits(),
                3 => {
                    try r.valType();
                    _ = try r.byte();
                },
                4 => {
                    _ = try r.byte();
                    _ = try r.uleb();
                },
                else => return error.Malformed,
            }
            imp.* = .{ .module = m, .name = f, .kind = kind };
        }
        return list;
    }
    return &.{};
}

const Reader = struct {
    b: []const u8,
    at: usize,

    fn byte(r: *Reader) error{Malformed}!u8 {
        if (r.at >= r.b.len) return error.Malformed;
        r.at += 1;
        return r.b[r.at - 1];
    }

    fn uleb(r: *Reader) error{Malformed}!usize {
        var v: u64 = 0;
        var shift: u7 = 0;
        while (true) {
            const x = try r.byte();
            if (shift < 64) v |= @as(u64, x & 0x7f) << @intCast(shift);
            if (x & 0x80 == 0) break;
            shift += 7;
            if (shift > 70) return error.Malformed;
        }
        return @intCast(v);
    }

    fn name(r: *Reader) error{Malformed}![]const u8 {
        const n = try r.uleb();
        if (r.at + n > r.b.len) return error.Malformed;
        r.at += n;
        return r.b[r.at - n .. r.at];
    }

    /// A value or reference type: one byte, or `ref` / `ref null` and a
    /// heap type (an s33).
    fn valType(r: *Reader) error{Malformed}!void {
        const t = try r.byte();
        if (t == 0x63 or t == 0x64) _ = try r.uleb();
    }

    fn limits(r: *Reader) error{Malformed}!void {
        const flags = try r.byte();
        _ = try r.uleb();
        if (flags & 1 != 0) _ = try r.uleb();
    }
};

/// Stop every body running now: a no-op on the page's engine.
pub fn interrupt() void {}

/// Whether a comptime body is running now: never observable on the page.
pub fn running() bool {
    return false;
}

test "comptime page: importsOf reads a module's imports, GC reference types included" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    // (import "a" "f" (func (type 0))) (import "b" "g" (global (ref null 0) mut))
    // (import "c" "m" (memory 1 2)) (import "d" "t" (tag (type 0)))
    const bytes = "\x00asm\x01\x00\x00\x00" ++ "\x01\x04\x01\x60\x00\x00" ++
        "\x02\x1e\x04" ++ "\x01a\x01f\x00\x00" ++ "\x01b\x01g\x03\x63\x00\x01" ++ "\x01c\x01m\x02\x01\x01\x02" ++ "\x01d\x01t\x04\x00\x00";
    const imps = try importsOf(arena.allocator(), bytes);
    try std.testing.expectEqual(@as(usize, 4), imps.len);
    try std.testing.expectEqualStrings("b", imps[1].module);
    try std.testing.expectEqualStrings("g", imps[1].name);
    try std.testing.expectEqual(@as(u8, 3), imps[1].kind);
    try std.testing.expectEqualStrings("t", imps[3].name);
    try std.testing.expectError(error.Malformed, importsOf(arena.allocator(), "(module)"));
}
