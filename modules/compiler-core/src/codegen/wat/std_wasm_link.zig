//! Decision 440 (2) — std-wasm transpiled into a `--target wasm` program.
//!
//! `std_wasm.wasm` (`modules/std-wasm/src/wasm.zig`, built by `build.zig` as
//! a position-independent side module and embedded here) is decoded into
//! `wat_ast` and its functions are emitted as ordinary functions of the
//! program: one module, its `.wat` the whole program, the binary rendered
//! from the same model — no second module, no host change, no splicing of
//! binaries.
//!
//! What the side module imports is bound to the program:
//!
//! | Import | Bound to |
//! |---|---|
//! | `env.memory` | the program's memory |
//! | `env.__memory_base` | the constant address the program places std-wasm's data at (`global.get` → `i32.const`) |
//! | `env.__stack_pointer` | the program's global `$__std_sp`, the top of a stack region placed after the data |
//! | `env.bp_alloc` | `$__alloc`, the program's bump allocator |
//!
//! The stack is sized from the code: each function's frame (its prologue
//! `global.get $sp; i32.const N; i32.sub`) summed along the deepest call
//! chain of the functions the program reaches. The start function wasm-ld
//! writes to zero `.bss` (a Zig `var`) is dropped: a fresh instance's memory
//! is zero. Anything else — a function table (`call_indirect`,
//! `__table_base`), another start function, a global of its own, another
//! import, an opcode outside the MVP and bulk memory, a recursive call — is
//! refused with `error.Unsupported` naming it: std-wasm's program face is
//! written so it needs none, and `codegen/tests/wat.zig` decodes every export
//! of the real module.
//!
//! Only the functions a program reaches are decoded: the exports it names
//! (`link`'s `wanted`) and what they call; and std-wasm's data is placed only
//! when one of them reads `__memory_base` (decision 442: a module calling
//! `text.split` carries no float table).

const std = @import("std");
const ast = @import("wat_ast.zig");
const binary = @import("wasm_binary_emitter.zig");

/// std-wasm's program face, as `zig build` linked it.
pub const module_bytes: []const u8 = @embedFile("std_wasm.wasm");

pub const Error = std.mem.Allocator.Error || error{
    /// A byte sequence that is no wasm module this reader knows.
    Malformed,
    /// A construct std-wasm's program face must not use (`Diag` names it).
    Unsupported,
};

/// Why `link` failed, for the refusal's text.
pub const Diag = struct { message: []const u8 = "" };

/// What every export of the program face is named after: its `std:` cell's
/// text (`std:hash.contentHash`).
pub const export_prefix = "std:";

/// The global the program holds std-wasm's stack pointer in.
pub const stack_global = "__std_sp";

/// The program function an export of std-wasm is emitted as:
/// `number.floatToString` → `__std_number_floatToString`.
pub fn entryName(ar: std.mem.Allocator, export_name: []const u8) ![]const u8 {
    const out = try std.fmt.allocPrint(ar, "__std_{s}", .{export_name});
    std.mem.replaceScalar(u8, out, '.', '_');
    return out;
}

/// What `link` hands the program.
pub const Linked = struct {
    /// The stack-pointer global, the raw data segments and the functions,
    /// in that order.
    items: []const ast.Item,
    /// The first byte past std-wasm's data and stack: where the program's
    /// heap starts.
    end: u32,
    /// The functions among `items`, in the same order: what a snapshot shows
    /// in place of each body (decision 446).
    funcs: []const Fn,
};

/// One function transpiled from std-wasm, identified for a snapshot.
pub const Fn = struct {
    /// The program symbol (`__std_number_floatToString`, `__std_f4`).
    symbol: []const u8,
    /// `std:<module>.<function>` for an export, the symbol for a helper.
    label: []const u8,
    /// The first 12 hex digits of the sha256 of the function's bytes in
    /// `std_wasm.wasm` (its code-section entry: locals and instructions).
    hash: [12]u8,
};

fn hashOf(bytes: []const u8) [12]u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return std.fmt.bytesToHex(digest[0..6].*, .lower);
}

// ── the module, read ─────────────────────────────────────────────────────────

const GlobalRole = enum { stack_pointer, memory_base, table_base };

const Module = struct {
    types: []const ast.FuncType,
    /// The program function each imported function is bound to.
    func_imports: []const []const u8,
    func_import_types: []const u32,
    global_imports: []const GlobalRole,
    func_types: []const u32,
    bodies: []const []const u8,
    exports: []const struct { name: []const u8, func: u32 },
    data: []const []const u8,
    mem_size: u32,
    mem_align: u32,
    table_size: u32,
};

const Reader = struct {
    b: []const u8,
    i: usize = 0,

    fn byte(r: *Reader) Error!u8 {
        if (r.i >= r.b.len) return error.Malformed;
        r.i += 1;
        return r.b[r.i - 1];
    }

    fn uleb(r: *Reader) Error!u64 {
        var v: u64 = 0;
        var shift: u7 = 0;
        while (true) {
            const x = try r.byte();
            if (shift >= 64) return error.Malformed;
            v |= @as(u64, x & 0x7f) << @intCast(shift);
            shift += 7;
            if (x & 0x80 == 0) return v;
        }
    }

    fn u32_(r: *Reader) Error!u32 {
        return std.math.cast(u32, try r.uleb()) orelse error.Malformed;
    }

    fn sleb(r: *Reader, comptime bits: u7) Error!i64 {
        var v: i64 = 0;
        var shift: u7 = 0;
        while (true) {
            const x = try r.byte();
            if (shift >= 64) return error.Malformed;
            v |= @as(i64, x & 0x7f) << @intCast(shift);
            shift += 7;
            if (x & 0x80 == 0) {
                if (shift < 64 and x & 0x40 != 0) v |= @as(i64, -1) << @intCast(shift);
                if (bits == 32) return @as(i32, @truncate(v));
                return v;
            }
        }
    }

    fn take(r: *Reader, n: usize) Error![]const u8 {
        if (r.i + n > r.b.len) return error.Malformed;
        r.i += n;
        return r.b[r.i - n .. r.i];
    }

    fn name(r: *Reader) Error![]const u8 {
        return r.take(try r.u32_());
    }
};

fn unsupported(diag: *Diag, comptime what: []const u8) Error {
    diag.message = what;
    return error.Unsupported;
}

fn valType(b: u8) Error!ast.ValType {
    return switch (b) {
        0x7F => .i32,
        0x7E => .i64,
        0x7D => .f32,
        0x7C => .f64,
        else => error.Malformed,
    };
}

fn read(ar: std.mem.Allocator, bytes: []const u8, diag: *Diag) Error!Module {
    if (bytes.len < 8 or !std.mem.eql(u8, bytes[0..8], &.{ 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 })) return error.Malformed;
    var r: Reader = .{ .b = bytes, .i = 8 };
    var types: std.ArrayListUnmanaged(ast.FuncType) = .empty;
    var func_imports: std.ArrayListUnmanaged([]const u8) = .empty;
    var func_import_types: std.ArrayListUnmanaged(u32) = .empty;
    var global_imports: std.ArrayListUnmanaged(GlobalRole) = .empty;
    var func_types: std.ArrayListUnmanaged(u32) = .empty;
    var bodies: std.ArrayListUnmanaged([]const u8) = .empty;
    var exports: std.ArrayListUnmanaged(@typeInfo(@FieldType(Module, "exports")).pointer.child) = .empty;
    var data: std.ArrayListUnmanaged([]const u8) = .empty;
    var m: Module = undefined;
    var dylink = false;
    var start: ?u32 = null;
    m.table_size = 0;
    while (r.i < bytes.len) {
        const id = try r.byte();
        const len = try r.u32_();
        var s: Reader = .{ .b = try r.take(len) };
        switch (id) {
            0 => {
                const n = try s.name();
                if (!std.mem.eql(u8, n, "dylink.0")) continue;
                while (s.i < s.b.len) {
                    const sub = try s.byte();
                    var t: Reader = .{ .b = try s.take(try s.u32_()) };
                    if (sub != 1) continue; // WASM_DYLINK_MEM_INFO
                    m.mem_size = try t.u32_();
                    m.mem_align = try t.u32_();
                    m.table_size = try t.u32_();
                    _ = try t.u32_();
                    dylink = true;
                }
            },
            1 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) {
                    if (try s.byte() != 0x60) return error.Malformed;
                    const params = try ar.alloc(ast.ValType, try s.u32_());
                    for (params) |*p| p.* = try valType(try s.byte());
                    const nr = try s.u32_();
                    if (nr > 1) return unsupported(diag, "a function answering several values");
                    const result: ?ast.ValType = if (nr == 1) try valType(try s.byte()) else null;
                    try types.append(ar, .{ .params = params, .result = result });
                }
            },
            2 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) {
                    const mod = try s.name();
                    const field = try s.name();
                    const kind = try s.byte();
                    if (!std.mem.eql(u8, mod, "env")) return unsupported(diag, "an import outside `env`");
                    switch (kind) {
                        0 => {
                            const ti = try s.u32_();
                            if (!std.mem.eql(u8, field, "bp_alloc")) return unsupported(diag, "a function import other than `env.bp_alloc`");
                            try func_imports.append(ar, "__alloc");
                            try func_import_types.append(ar, ti);
                        },
                        1 => {
                            _ = try s.byte();
                            const flags = try s.byte();
                            _ = try s.u32_();
                            if (flags & 1 != 0) _ = try s.u32_();
                        },
                        2 => {
                            const flags = try s.byte();
                            _ = try s.u32_();
                            if (flags & 1 != 0) _ = try s.u32_();
                            if (!std.mem.eql(u8, field, "memory")) return unsupported(diag, "a memory import other than `env.memory`");
                        },
                        3 => {
                            _ = try s.byte();
                            _ = try s.byte();
                            const role: GlobalRole = if (std.mem.eql(u8, field, "__stack_pointer"))
                                .stack_pointer
                            else if (std.mem.eql(u8, field, "__memory_base"))
                                .memory_base
                            else if (std.mem.eql(u8, field, "__table_base"))
                                .table_base
                            else
                                return unsupported(diag, "a global import other than `__stack_pointer`, `__memory_base`, `__table_base` (a `GOT` entry)");
                            try global_imports.append(ar, role);
                        },
                        else => return error.Malformed,
                    }
                }
            },
            3 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) try func_types.append(ar, try s.u32_());
            },
            4 => return unsupported(diag, "a function table of its own"),
            5 => return unsupported(diag, "a memory of its own"),
            6 => if (try s.u32_() > 0) return unsupported(diag, "a global of its own"),
            7 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) {
                    const name = try s.name();
                    const kind = try s.byte();
                    const idx = try s.u32_();
                    if (kind == 0) try exports.append(ar, .{ .name = name, .func = idx });
                }
            },
            8 => start = try s.u32_(),
            9 => return unsupported(diag, "an element segment (a function table)"),
            10 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) try bodies.append(ar, try s.take(try s.u32_()));
            },
            11 => {
                var n = try s.u32_();
                while (n > 0) : (n -= 1) {
                    if (try s.u32_() != 0) return unsupported(diag, "a passive data segment");
                    // `global.get $__memory_base` `end`: the segment starts at the base.
                    if (try s.byte() != 0x23) return unsupported(diag, "a data segment not placed at `__memory_base`");
                    const g = try s.u32_();
                    if (g >= global_imports.items.len or global_imports.items[g] != .memory_base) return unsupported(diag, "a data segment not placed at `__memory_base`");
                    if (try s.byte() != 0x0B) return unsupported(diag, "a data segment not placed at `__memory_base`");
                    try data.append(ar, try s.take(try s.u32_()));
                }
            },
            12 => {},
            else => return error.Malformed,
        }
    }
    if (!dylink) return unsupported(diag, "a module with no `dylink.0` section (not a position-independent side module)");
    if (m.table_size != 0) return unsupported(diag, "a function table");
    if (func_types.items.len != bodies.items.len) return error.Malformed;
    // wasm-ld gives a side module whose data has a zero-initialised part
    // (`.bss`: a `var` of std-wasm's) a start function that zeroes it. A
    // fresh instance's memory is zero already, and std-wasm's region lies
    // below the heap, so that start is a no-op here and is dropped; any other
    // start is refused.
    if (start) |st| {
        if (st < func_imports.items.len) return unsupported(diag, "a start function");
        const memory_base = for (global_imports.items, 0..) |g, gi| {
            if (g == .memory_base) break gi;
        } else return unsupported(diag, "a start function");
        if (!zeroesBss(bodies.items[st - func_imports.items.len], @intCast(memory_base))) return unsupported(diag, "a start function other than the zeroing of `.bss`");
    }
    m.types = types.items;
    m.func_imports = func_imports.items;
    m.func_import_types = func_import_types.items;
    m.global_imports = global_imports.items;
    m.func_types = func_types.items;
    m.bodies = bodies.items;
    m.exports = exports.items;
    m.data = data.items;
    return m;
}

/// Whether `body` is the start wasm-ld writes for `.bss` and nothing else:
/// no locals, then `i32.const a; global.get $__memory_base; i32.add;
/// i32.const 0; i32.const n; memory.fill` repeated, then `end`.
fn zeroesBss(body: []const u8, memory_base: u32) bool {
    var r: Reader = .{ .b = body };
    if ((r.u32_() catch return false) != 0) return false;
    while (true) {
        const op = r.byte() catch return false;
        if (op == 0x0B) return r.i == body.len;
        if (op != 0x41) return false;
        _ = r.sleb(32) catch return false;
        if ((r.byte() catch return false) != 0x23) return false;
        if ((r.u32_() catch return false) != memory_base) return false;
        if ((r.byte() catch return false) != 0x6A) return false;
        if ((r.byte() catch return false) != 0x41) return false;
        if ((r.sleb(32) catch return false) != 0) return false;
        if ((r.byte() catch return false) != 0x41) return false;
        _ = r.sleb(32) catch return false;
        if ((r.byte() catch return false) != 0xFC) return false;
        if ((r.u32_() catch return false) != 11) return false;
        if ((r.byte() catch return false) != 0) return false;
    }
}

// ── a function body, decoded ────────────────────────────────────────────────

const Decoded = struct {
    func: ast.Func,
    /// Bytes the function's prologue takes off the stack pointer.
    frame: u32,
    callees: []const u32,
    /// Whether it reads `__memory_base` — addresses std-wasm's data.
    uses_base: bool,
};

const Body = struct {
    ar: std.mem.Allocator,
    m: *const Module,
    names: []const []const u8,
    base: u32,
    diag: *Diag,
    r: Reader,
    nparams: usize,
    labels: std.ArrayListUnmanaged([]const u8) = .empty,
    next_label: u32 = 0,
    fn_label_used: bool = false,
    frame: u32 = 0,
    uses_base: bool = false,
    callees: std.ArrayListUnmanaged(u32) = .empty,
    /// The two instructions before the current one, for the prologue.
    last: [2]?ast.Instr = .{ null, null },

    const fn_label = "fn";

    fn local(b: *Body, idx: u32) ![]const u8 {
        if (idx < b.nparams) return std.fmt.allocPrint(b.ar, "p{d}", .{idx});
        return std.fmt.allocPrint(b.ar, "l{d}", .{idx - b.nparams});
    }

    fn label(b: *Body, depth: u32) ![]const u8 {
        const n = b.labels.items.len;
        if (depth == n) {
            b.fn_label_used = true;
            return fn_label;
        }
        if (depth > n) return error.Malformed;
        return b.labels.items[n - 1 - depth];
    }

    fn blockType(b: *Body) Error!?ast.ValType {
        const t = try b.r.byte();
        if (t == 0x40) return null;
        return valType(t) catch b.refuse("a block typed by a type index (multi-value)");
    }

    fn refuse(b: *Body, comptime what: []const u8) Error {
        return unsupported(b.diag, what);
    }

    fn freshLabel(b: *Body) ![]const u8 {
        b.next_label += 1;
        return std.fmt.allocPrint(b.ar, "b{d}", .{b.next_label - 1});
    }

    const End = enum { end, @"else" };

    /// Instructions up to the `end` (or `else`) that closes the current
    /// block, each at column `indent`.
    fn seq(b: *Body, indent: u8, lines: *std.ArrayListUnmanaged(ast.Line)) Error!End {
        while (true) {
            const op = try b.r.byte();
            const instr: ast.Instr = switch (op) {
                0x0B => return .end,
                0x05 => return .@"else",
                0x00 => .@"unreachable",
                0x01 => continue,
                0x02, 0x03 => {
                    const result = try b.blockType();
                    const name = try b.freshLabel();
                    try b.labels.append(b.ar, name);
                    var inner: std.ArrayListUnmanaged(ast.Line) = .empty;
                    if (try b.seq(deeper(indent, 2), &inner) != .end) return error.Malformed;
                    _ = b.labels.pop();
                    try lines.append(b.ar, .{ .indent = indent, .instr = .{ .block = .{
                        .kind = if (op == 0x02) .block else .loop,
                        .label = name,
                        .result = result,
                        .body = .{ .lines = inner.items, .stack = if (result) |t| .{ .value = t } else .none },
                    } } });
                    b.last = .{ null, null };
                    continue;
                },
                0x04 => {
                    const result = try b.blockType();
                    const name = try b.freshLabel();
                    try b.labels.append(b.ar, name);
                    var then: std.ArrayListUnmanaged(ast.Line) = .empty;
                    const how = try b.seq(deeper(indent, 4), &then);
                    var els: ?ast.If.Arm = null;
                    if (how == .@"else") {
                        var e: std.ArrayListUnmanaged(ast.Line) = .empty;
                        if (try b.seq(deeper(indent, 4), &e) != .end) return error.Malformed;
                        els = .{ .seq = .{ .lines = e.items, .stack = if (result) |t| .{ .value = t } else .none } };
                    }
                    _ = b.labels.pop();
                    try lines.append(b.ar, .{ .indent = indent, .instr = .{ .@"if" = .{
                        .label = name,
                        .result = result,
                        .then = .{ .seq = .{ .lines = then.items, .stack = if (result) |t| .{ .value = t } else .none } },
                        .@"else" = els,
                    } } });
                    b.last = .{ null, null };
                    continue;
                },
                0x0C => .{ .br = try b.label(try b.r.u32_()) },
                0x0D => .{ .br_if = try b.label(try b.r.u32_()) },
                0x0E => blk: {
                    const n = try b.r.u32_();
                    const ls = try b.ar.alloc([]const u8, n);
                    for (ls) |*l| l.* = try b.label(try b.r.u32_());
                    break :blk .{ .br_table = .{ .labels = ls, .default = try b.label(try b.r.u32_()) } };
                },
                0x0F => .@"return",
                0x10 => blk: {
                    const idx = try b.r.u32_();
                    if (idx >= b.names.len) return error.Malformed;
                    if (idx >= b.m.func_imports.len) try b.callees.append(b.ar, idx);
                    break :blk .{ .call = b.names[idx] };
                },
                0x11 => return b.refuse("`call_indirect` (a function table)"),
                0x1A => .drop,
                0x1B => .select,
                0x1C => blk: {
                    if (try b.r.u32_() != 1) return error.Malformed;
                    _ = try b.r.byte();
                    break :blk .select;
                },
                0x20 => .{ .local_get = try b.local(try b.r.u32_()) },
                0x21 => .{ .local_set = try b.local(try b.r.u32_()) },
                0x22 => .{ .local_tee = try b.local(try b.r.u32_()) },
                0x23, 0x24 => blk: {
                    const g = try b.r.u32_();
                    if (g >= b.m.global_imports.len) return error.Malformed;
                    switch (b.m.global_imports[g]) {
                        .stack_pointer => break :blk if (op == 0x23) ast.Instr{ .global_get = stack_global } else ast.Instr{ .global_set = stack_global },
                        .memory_base => {
                            if (op == 0x24) return b.refuse("a write of `__memory_base`");
                            b.uses_base = true;
                            break :blk .{ .@"const" = .{ .ty = .i32, .text = try std.fmt.allocPrint(b.ar, "{d}", .{b.base}) } };
                        },
                        .table_base => return b.refuse("`__table_base` (a function table)"),
                    }
                },
                0x28...0x3E => blk: {
                    _ = try b.r.u32_(); // alignment: natural is always valid
                    const offset = try b.r.u32_();
                    break :blk memInstr(op, offset);
                },
                0x3F, 0x40 => blk: {
                    if (try b.r.byte() != 0) return error.Malformed;
                    break :blk if (op == 0x3F) .memory_size else .memory_grow;
                },
                0x41 => .{ .@"const" = .{ .ty = .i32, .text = try std.fmt.allocPrint(b.ar, "{d}", .{try b.r.sleb(32)}) } },
                0x42 => .{ .@"const" = .{ .ty = .i64, .text = try std.fmt.allocPrint(b.ar, "{d}", .{try b.r.sleb(64)}) } },
                0x43 => return b.refuse("an `f32.const`"),
                0x44 => .{ .@"const" = .{ .ty = .f64, .text = try f64Text(b.ar, std.mem.readInt(u64, (try b.r.take(8))[0..8], .little), b.diag) } },
                0xFC => blk: {
                    const sub = try b.r.u32_();
                    switch (sub) {
                        10 => {
                            if (try b.r.byte() != 0 or try b.r.byte() != 0) return error.Malformed;
                            break :blk .memory_copy;
                        },
                        11 => {
                            if (try b.r.byte() != 0) return error.Malformed;
                            break :blk .memory_fill;
                        },
                        else => break :blk try numeric(&.{ 0xFC, @intCast(sub) }, b.diag),
                    }
                },
                else => try numeric(&.{op}, b.diag),
            };
            // The prologue `global.get $sp; i32.const N; i32.sub` opens a frame of N bytes.
            if (instr == .op and instr.op.ty == .i32 and std.mem.eql(u8, instr.op.name, "sub")) {
                if (b.last[1]) |k| if (k == .@"const" and k.@"const".ty == .i32) if (b.last[0]) |g| if (g == .global_get and std.mem.eql(u8, g.global_get, stack_global)) {
                    const n = std.fmt.parseInt(u32, k.@"const".text, 10) catch return error.Malformed;
                    b.frame = @max(b.frame, n);
                };
            }
            b.last = .{ b.last[1], instr };
            try lines.append(b.ar, .{ .indent = indent, .instr = instr });
        }
    }
};

/// The column a nested line sits at: two or four deeper, but never past
/// `max_indent` — LLVM lowers a `switch` (the case tables, decision 443) to
/// hundreds of nested blocks, and a column per level wrote a `.wat` of a
/// megabyte of spaces for one `toUpper`.
fn deeper(indent: u8, by: u8) u8 {
    return @min(indent +| by, max_indent);
}

const max_indent = 40;

/// A load or store opcode (0x28 … 0x3E) as its `MemArg`.
fn memInstr(op: u8, offset: u32) ast.Instr {
    const L = struct { ty: ast.ValType, width: ast.Width = .full, signed: bool = false };
    const loads = [_]L{
        .{ .ty = .i32 },                                 .{ .ty = .i64 },                 .{ .ty = .f32 },                                 .{ .ty = .f64 },
        .{ .ty = .i32, .width = .byte, .signed = true }, .{ .ty = .i32, .width = .byte }, .{ .ty = .i32, .width = .half, .signed = true }, .{ .ty = .i32, .width = .half },
        .{ .ty = .i64, .width = .byte, .signed = true }, .{ .ty = .i64, .width = .byte }, .{ .ty = .i64, .width = .half, .signed = true }, .{ .ty = .i64, .width = .half },
        .{ .ty = .i64, .width = .word, .signed = true }, .{ .ty = .i64, .width = .word },
    };
    const stores = [_]L{
        .{ .ty = .i32 },                 .{ .ty = .i64 },                 .{ .ty = .f32 },                 .{ .ty = .f64 }, .{ .ty = .i32, .width = .byte }, .{ .ty = .i32, .width = .half },
        .{ .ty = .i64, .width = .byte }, .{ .ty = .i64, .width = .half }, .{ .ty = .i64, .width = .word },
    };
    if (op <= 0x35) {
        const l = loads[op - 0x28];
        return .{ .load = .{ .ty = l.ty, .width = l.width, .signed = l.signed, .offset = offset } };
    }
    const s = stores[op - 0x36];
    return .{ .store = .{ .ty = s.ty, .width = s.width, .offset = offset } };
}

/// A numeric instruction by its opcode bytes, through the binary emitter's
/// own table (`opcodes`), so decoding and encoding read one list.
fn numeric(code: []const u8, diag: *Diag) Error!ast.Instr {
    for (binary.opcodes) |entry| {
        if (std.mem.eql(u8, entry[1], code)) {
            const dot = std.mem.indexOfScalar(u8, entry[0], '.').?;
            return .{ .op = .{ .ty = ast.ValType.parse(entry[0][0..dot]), .name = entry[0][dot + 1 ..] } };
        }
    }
    diag.message = "an opcode outside the MVP numeric instructions and bulk memory";
    return error.Unsupported;
}

/// An `f64.const`'s numeral: the shortest decimal that reads back as the
/// same bits (what the binary emitter parses), `inf` / `-inf`, or `nan` for
/// the canonical quiet NaN — another payload is refused.
fn f64Text(ar: std.mem.Allocator, bits: u64, diag: *Diag) Error![]const u8 {
    const v: f64 = @bitCast(bits);
    if (std.math.isNan(v)) {
        if (bits & 0x7FFF_FFFF_FFFF_FFFF != 0x7FF8_0000_0000_0000) return unsupported(diag, "an `f64.const` NaN with a payload");
        return if (bits >> 63 != 0) "-nan" else "nan";
    }
    if (std.math.isInf(v)) return if (v < 0) "-inf" else "inf";
    return std.fmt.allocPrint(ar, "{e}", .{v});
}

fn decode(ar: std.mem.Allocator, m: *const Module, names: []const []const u8, idx: u32, base: u32, diag: *Diag) Error!Decoded {
    const def = idx - m.func_imports.len;
    const ty = m.types[m.func_types[def]];
    var b: Body = .{ .ar = ar, .m = m, .names = names, .base = base, .diag = diag, .r = .{ .b = m.bodies[def] }, .nparams = ty.params.len };
    const params = try ar.alloc(ast.Param, ty.params.len);
    for (params, ty.params, 0..) |*p, t, i| p.* = .{ .name = try std.fmt.allocPrint(ar, "p{d}", .{i}), .ty = t };
    var locals: std.ArrayListUnmanaged(ast.Local) = .empty;
    var runs = try b.r.u32_();
    while (runs > 0) : (runs -= 1) {
        const n = try b.r.u32_();
        const t = try valType(try b.r.byte());
        for (0..n) |_| try locals.append(ar, .{ .name = try std.fmt.allocPrint(ar, "l{d}", .{locals.items.len}), .ty = t });
    }
    // Six declarations to a line.
    var groups: std.ArrayListUnmanaged([]const ast.Local) = .empty;
    var at: usize = 0;
    while (at < locals.items.len) : (at += 6) try groups.append(ar, locals.items[at..@min(at + 6, locals.items.len)]);

    var lines: std.ArrayListUnmanaged(ast.Line) = .empty;
    if (try b.seq(4, &lines) != .end) return error.Malformed;
    if (b.r.i != b.r.b.len) return error.Malformed;
    const stack: ast.Stack = if (ty.result) |t| .{ .value = t } else .none;
    var body: ast.Seq = .{ .lines = lines.items, .stack = stack };
    if (b.fn_label_used) {
        // A branch to the function's own block: the body in a block of that name.
        for (lines.items) |*l| reindent(l, 2);
        const outer = try ar.alloc(ast.Line, 1);
        outer[0] = .{ .indent = 4, .instr = .{ .block = .{ .kind = .block, .label = Body.fn_label, .result = ty.result, .body = body } } };
        body = .{ .lines = outer, .stack = stack };
    }
    return .{
        .func = .{ .name = names[idx], .params = params, .result = ty.result, .locals = groups.items, .body = body },
        .frame = b.frame,
        .callees = b.callees.items,
        .uses_base = b.uses_base,
    };
}

/// `l` and everything nested in it `by` columns further in.
fn reindent(l: *ast.Line, by: u8) void {
    l.indent = deeper(l.indent, by);
    switch (l.instr) {
        .block => |*blk| for (@constCast(blk.body.lines)) |*x| reindent(x, by),
        .@"if" => |*n| {
            for (@constCast(n.then.seq.lines)) |*x| reindent(x, by);
            if (n.@"else") |e| for (@constCast(e.seq.lines)) |*x| reindent(x, by);
        },
        else => {},
    }
}

// ── linked into a program ───────────────────────────────────────────────────

/// std-wasm's functions the program reaches — the exports named `wanted`
/// (`<module>.<function>`, each emitted as `entryName`) and every function
/// they call — with its data placed at the first address at or after `floor`
/// its alignment allows, and its stack after the data.
pub fn link(ar: std.mem.Allocator, wanted: []const []const u8, floor: u32, diag: *Diag) Error!Linked {
    return linkModule(ar, module_bytes, wanted, floor, diag);
}

pub fn linkModule(ar: std.mem.Allocator, bytes: []const u8, wanted: []const []const u8, floor: u32, diag: *Diag) Error!Linked {
    const m = try read(ar, bytes, diag);
    const nimp = m.func_imports.len;
    const total = nimp + m.bodies.len;
    const names = try ar.alloc([]const u8, total);
    for (names, 0..) |*n, i| n.* = if (i < nimp) m.func_imports[i] else try std.fmt.allocPrint(ar, "__std_f{d}", .{i - nimp});
    for (m.exports) |e| {
        if (!std.mem.startsWith(u8, e.name, export_prefix)) return unsupported(diag, "an export not named `std:<module>.<function>`");
        names[e.func] = try entryName(ar, e.name[export_prefix.len..]);
    }

    const align_to = @as(u32, 1) << @intCast(@max(m.mem_align, 3));
    const base = std.mem.alignForward(u32, floor, align_to);

    // The functions reached from `wanted`, decoded once each.
    var decoded: std.AutoArrayHashMapUnmanaged(u32, Decoded) = .empty;
    var queue: std.ArrayListUnmanaged(u32) = .empty;
    for (wanted) |w| {
        const e = for (m.exports) |e| {
            if (std.mem.startsWith(u8, e.name, export_prefix) and std.mem.eql(u8, e.name[export_prefix.len..], w)) break e;
        } else {
            diag.message = try std.fmt.allocPrint(ar, "std-wasm's program face exports no `{s}`", .{w});
            return error.Unsupported;
        };
        try queue.append(ar, e.func);
    }
    while (queue.pop()) |idx| {
        if (decoded.contains(idx)) continue;
        const d = try decode(ar, &m, names, idx, base, diag);
        try decoded.put(ar, idx, d);
        for (d.callees) |c| try queue.append(ar, c);
    }
    // In index order, so the module is the same whatever order `wanted` names them in.
    const Ctx = struct {
        keys: []const u32,
        pub fn lessThan(c: @This(), a: usize, b: usize) bool {
            return c.keys[a] < c.keys[b];
        }
    };
    decoded.sort(Ctx{ .keys = decoded.keys() });

    // The deepest chain of frames; a recursive call has none.
    var depth: std.AutoHashMapUnmanaged(u32, u32) = .empty;
    var on_path: std.AutoHashMapUnmanaged(u32, void) = .empty;
    var stack_bytes: u32 = 0;
    for (decoded.keys()) |idx| stack_bytes = @max(stack_bytes, try chain(ar, &decoded, &depth, &on_path, idx, diag));

    var items: std.ArrayListUnmanaged(ast.Item) = .empty;
    var size: u32 = 0;
    for (m.data) |seg| size += @intCast(seg.len);
    if (size > m.mem_size) return error.Malformed;
    // std-wasm's data (its tables, literals and `var`s) is addressed through
    // `__memory_base` alone: when no function the program reaches reads it,
    // none of the data is placed.
    var uses_data = false;
    for (decoded.values()) |d| uses_data = uses_data or d.uses_base;
    const mem_size: u32 = if (uses_data) m.mem_size else 0;
    const top = std.mem.alignForward(u32, base + mem_size + stack_bytes, 16);
    var uses_sp = false;
    for (decoded.values()) |d| if (usesGlobal(d.func.body, stack_global)) {
        uses_sp = true;
    };
    if (uses_sp) try items.append(ar, .{ .global = .{ .name = stack_global, .ty = .i32, .mutable = true, .init = try std.fmt.allocPrint(ar, "{d}", .{top}) } });
    var off = base;
    if (uses_data) for (m.data) |seg| {
        try items.append(ar, .{ .data = .{ .offset = off, .len_prefix = null, .bytes = seg } });
        off += @intCast(seg.len);
    };
    var funcs: std.ArrayListUnmanaged(Fn) = .empty;
    for (decoded.keys(), decoded.values()) |idx, d| {
        try items.append(ar, .{ .func = d.func });
        const label = for (m.exports) |e| {
            if (e.func == idx) break e.name;
        } else d.func.name;
        try funcs.append(ar, .{ .symbol = d.func.name, .label = label, .hash = hashOf(m.bodies[idx - nimp]) });
    }
    return .{ .items = items.items, .end = top, .funcs = funcs.items };
}

fn chain(
    ar: std.mem.Allocator,
    decoded: *const std.AutoArrayHashMapUnmanaged(u32, Decoded),
    depth: *std.AutoHashMapUnmanaged(u32, u32),
    on_path: *std.AutoHashMapUnmanaged(u32, void),
    idx: u32,
    diag: *Diag,
) Error!u32 {
    if (depth.get(idx)) |d| return d;
    if (on_path.contains(idx)) return unsupported(diag, "a recursive call (its stack has no bound)");
    try on_path.put(ar, idx, {});
    const d = decoded.get(idx).?;
    var deepest: u32 = 0;
    for (d.callees) |c| deepest = @max(deepest, try chain(ar, decoded, depth, on_path, c, diag));
    _ = on_path.remove(idx);
    const total = d.frame + deepest;
    try depth.put(ar, idx, total);
    return total;
}

fn usesGlobal(s: ast.Seq, name: []const u8) bool {
    for (s.lines) |l| switch (l.instr) {
        .global_get, .global_set => |g| if (std.mem.eql(u8, g, name)) return true,
        .block => |b| if (usesGlobal(b.body, name)) return true,
        .@"if" => |n| {
            if (usesGlobal(n.then.seq, name)) return true;
            if (n.@"else") |e| if (usesGlobal(e.seq, name)) return true;
        },
        else => {},
    };
    return false;
}

// Decision 446 — a snapshot shows one line per transpiled function, keyed by
// the hash of its bytes: a change inside one function of std_wasm.wasm moves
// exactly that function's hash.
test "Fn.hash ---- a change in one function's bytes changes that function's hash and no other" {
    const alloc = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const ar = arena.allocator();
    const stdWasm = @import("std_wasm");
    var wanted: [stdWasm.exports.len][]const u8 = undefined;
    for (stdWasm.exports, 0..) |e, i| wanted[i] = e.name;
    var diag: Diag = .{};
    const base = try link(ar, &wanted, 301, &diag);
    try std.testing.expect(base.funcs.len > 1);

    const m = try read(ar, module_bytes, &diag);
    const copy = try ar.dupe(u8, module_bytes);
    // Flip one bit of the first byte, counting from the end of an exported
    // function's body, whose module still links to the same set of functions.
    var changed: ?usize = null;
    const body = m.bodies[m.exports[0].func - m.func_imports.len];
    const start = @intFromPtr(body.ptr) - @intFromPtr(module_bytes.ptr);
    var at: usize = body.len;
    while (at > 0) : (at -= 1) {
        const off = start + at - 1;
        copy[off] ^= 0x01;
        defer copy[off] ^= 0x01;
        var d2: Diag = .{};
        const l2 = linkModule(ar, copy, &wanted, 301, &d2) catch continue;
        if (l2.funcs.len != base.funcs.len) continue;
        var same = true;
        for (base.funcs, l2.funcs) |a, b| {
            if (!std.mem.eql(u8, a.symbol, b.symbol)) same = false;
        }
        if (!same) continue;
        var differing: usize = 0;
        for (base.funcs, l2.funcs) |a, b| {
            if (!std.mem.eql(u8, &a.hash, &b.hash)) differing += 1;
        }
        try std.testing.expectEqual(@as(usize, 1), differing);
        changed = off;
        break;
    }
    try std.testing.expect(changed != null);
}
