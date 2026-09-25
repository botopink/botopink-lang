//! One wasm module out of two: the runtime's prebuilt bytes (`rt.zig`,
//! compiled at `zig build`) and a lowered comptime program (`lower.zig`'s
//! `wat_ast.Module`, which imports its runtime calls from `"rt"`).
//!
//! The runtime's sections are kept as they are — its code bodies are copied
//! byte for byte, never re-encoded — and the program's are appended:
//!
//!   types      the runtime's, then the program's new signatures
//!   imports    the runtime's (the program's `"rt"` imports resolve to the
//!              runtime's exported functions and disappear)
//!   functions  the runtime's, then the program's
//!   table      grown by the program's closures; `__tbase` is where they start
//!   memory     grown to hold the program's literals past the runtime's data
//!   globals    the runtime's, then `__lit`, `__lit_end`, `__tbase` (constants)
//!              and any other the program declares
//!   exports    the runtime's, then the program's (`bp_init`, `bp_main`)
//!   elements   the runtime's segment, then one for the program's table slots
//!   code       the runtime's bodies, then the program's (encoded by
//!              `codegen/wat/wasm_binary_emitter.zig` against the merged
//!              index spaces)
//!   data       the runtime's segments, then the program's literals at `__lit`
//!
//! Custom sections of the runtime (names, producers) are dropped. A program
//! import the runtime does not export is refused by name
//! (`error.UnknownRuntimeFunction`).
const std = @import("std");
const wat = @import("../../../codegen/wat/wat_ast.zig");
const bin = @import("../../../codegen/wat/wasm_binary_emitter.zig");

pub const Error = bin.Error || error{ Malformed, UnknownRuntimeFunction };

const Section = struct { id: u8, body: []const u8 };

const Reader = struct {
    s: []const u8,
    i: usize = 0,

    fn byte(r: *Reader) Error!u8 {
        if (r.i >= r.s.len) return error.Malformed;
        r.i += 1;
        return r.s[r.i - 1];
    }

    fn uleb(r: *Reader) Error!u32 {
        var v: u32 = 0;
        var shift: u5 = 0;
        while (true) {
            const b = try r.byte();
            v |= @as(u32, b & 0x7f) << shift;
            if (b & 0x80 == 0) return v;
            if (shift >= 28) return error.Malformed;
            shift += 7;
        }
    }

    fn bytes(r: *Reader, n: usize) Error![]const u8 {
        if (r.i + n > r.s.len) return error.Malformed;
        r.i += n;
        return r.s[r.i - n .. r.i];
    }

    /// Skip a constant expression up to and including its `end`.
    fn constExpr(r: *Reader) Error!?i64 {
        const op = try r.byte();
        var value: ?i64 = null;
        switch (op) {
            0x41 => value = try r.sleb(),
            0x42 => value = try r.sleb(),
            0x43 => _ = try r.bytes(4),
            0x44 => _ = try r.bytes(8),
            0x23 => _ = try r.uleb(),
            else => return error.Malformed,
        }
        if (try r.byte() != 0x0B) return error.Malformed;
        return value;
    }

    fn sleb(r: *Reader) Error!i64 {
        var v: i64 = 0;
        var shift: u6 = 0;
        var b: u8 = 0;
        while (true) {
            b = try r.byte();
            v |= @as(i64, b & 0x7f) << shift;
            shift += 7;
            if (b & 0x80 == 0) break;
            if (shift >= 63) return error.Malformed;
        }
        if (shift < 64 and (b & 0x40) != 0) v |= @as(i64, -1) << shift;
        return v;
    }
};

fn valType(b: u8) Error!wat.ValType {
    return switch (b) {
        0x7F => .i32,
        0x7E => .i64,
        0x7D => .f32,
        0x7C => .f64,
        else => error.Malformed,
    };
}

/// What the runtime's bytes declare, read once.
pub const Runtime = struct {
    sections: []const Section,
    types: []const wat.FuncType,
    n_imported_funcs: u32,
    func_types: []const u32,
    exports: std.StringHashMapUnmanaged(u32),
    n_globals: u32,
    table_min: u32,
    memory_min: u32,
    /// First byte past the runtime's static data and stack.
    data_end: u32,

    pub fn parse(ar: std.mem.Allocator, bytes: []const u8) Error!Runtime {
        if (bytes.len < 8 or !std.mem.eql(u8, bytes[0..8], &.{ 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 })) return error.Malformed;
        var r: Reader = .{ .s = bytes, .i = 8 };
        var sections: std.ArrayListUnmanaged(Section) = .empty;
        var rt: Runtime = .{
            .sections = &.{},
            .types = &.{},
            .n_imported_funcs = 0,
            .func_types = &.{},
            .exports = .empty,
            .n_globals = 0,
            .table_min = 0,
            .memory_min = 1,
            .data_end = 0,
        };
        var stack_top: i64 = 0;
        var global_inits: std.ArrayListUnmanaged(?i64) = .empty;
        var heap_base_global: ?u32 = null;
        while (r.i < bytes.len) {
            const id = try r.byte();
            const len = try r.uleb();
            const body = try r.bytes(len);
            if (id != 0) try sections.append(ar, .{ .id = id, .body = body });
            var s: Reader = .{ .s = body };
            switch (id) {
                1 => {
                    const n = try s.uleb();
                    const types = try ar.alloc(wat.FuncType, n);
                    for (types) |*t| {
                        if (try s.byte() != 0x60) return error.Malformed;
                        const np = try s.uleb();
                        const params = try ar.alloc(wat.ValType, np);
                        for (params) |*p| p.* = try valType(try s.byte());
                        const nr = try s.uleb();
                        if (nr > 1) return error.Malformed;
                        t.* = .{ .params = params, .result = if (nr == 1) try valType(try s.byte()) else null };
                    }
                    rt.types = types;
                },
                2 => {
                    const n = try s.uleb();
                    for (0..n) |_| {
                        _ = try s.bytes(try s.uleb());
                        _ = try s.bytes(try s.uleb());
                        const kind = try s.byte();
                        switch (kind) {
                            0 => {
                                _ = try s.uleb();
                                rt.n_imported_funcs += 1;
                            },
                            else => return error.Malformed, // the runtime imports functions only
                        }
                    }
                },
                3 => {
                    const n = try s.uleb();
                    const ft = try ar.alloc(u32, n);
                    for (ft) |*t| t.* = try s.uleb();
                    rt.func_types = ft;
                },
                4 => {
                    if (try s.uleb() != 1) return error.Malformed;
                    if (try s.byte() != 0x70) return error.Malformed;
                    const flags = try s.byte();
                    rt.table_min = try s.uleb();
                    if (flags == 1) _ = try s.uleb();
                },
                5 => {
                    if (try s.uleb() != 1) return error.Malformed;
                    const flags = try s.byte();
                    rt.memory_min = try s.uleb();
                    if (flags == 1) _ = try s.uleb();
                },
                6 => {
                    rt.n_globals = try s.uleb();
                    for (0..rt.n_globals) |gi| {
                        _ = try s.byte(); // type
                        _ = try s.byte(); // mut
                        const v = try s.constExpr();
                        try global_inits.append(ar, v);
                        // global 0 is `__stack_pointer`: its initial value is the
                        // stack top, which data must not overlap.
                        if (gi == 0) if (v) |top| {
                            stack_top = top;
                        };
                    }
                },
                7 => {
                    const n = try s.uleb();
                    for (0..n) |_| {
                        const name = try s.bytes(try s.uleb());
                        const kind = try s.byte();
                        const idx = try s.uleb();
                        if (kind == 0) try rt.exports.put(ar, name, idx);
                        if (kind == 3 and std.mem.eql(u8, name, "__heap_base")) heap_base_global = idx;
                    }
                },
                11 => {
                    const n = try s.uleb();
                    for (0..n) |_| {
                        const flags = try s.uleb();
                        if (flags != 0) return error.Malformed;
                        const off = (try s.constExpr()) orelse return error.Malformed;
                        const len_ = try s.uleb();
                        _ = try s.bytes(len_);
                        rt.data_end = @max(rt.data_end, @as(u32, @intCast(off)) + len_);
                    }
                },
                else => {},
            }
        }
        rt.data_end = @max(rt.data_end, @as(u32, @intCast(@max(stack_top, 0))));
        // `.bss` has no data segment: only `__heap_base` (exported by the
        // runtime's build) says where static memory ends.
        const hb = heap_base_global orelse return error.Malformed;
        if (hb >= global_inits.items.len) return error.Malformed;
        const hbv = global_inits.items[hb] orelse return error.Malformed;
        rt.data_end = @max(rt.data_end, @as(u32, @intCast(hbv)));
        rt.sections = sections.items;
        return rt;
    }

    fn section(rt: Runtime, id: u8) ?[]const u8 {
        for (rt.sections) |s| if (s.id == id) return s.body;
        return null;
    }
};

/// The runtime's entries of a vector section, as raw bytes after the count.
fn vecBody(body: ?[]const u8) Error!struct { count: u32, rest: []const u8 } {
    const b = body orelse return .{ .count = 0, .rest = &.{} };
    var r: Reader = .{ .s = b };
    const n = try r.uleb();
    return .{ .count = n, .rest = b[r.i..] };
}

/// Link `program` (with its literal `data`) into the runtime `rt_bytes`.
/// Answers the module's bytes; `alloc` owns them.
pub fn link(alloc: std.mem.Allocator, rt_bytes: []const u8, program: wat.Module, data: []const u8) Error![]u8 {
    try wat.validateModule(program);
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const rt = try Runtime.parse(ar, rt_bytes);

    const lit_base = std.mem.alignForward(u32, rt.data_end, 16);
    const lit_end = lit_base + @as(u32, @intCast(data.len));
    const tbase = rt.table_min;

    // The merged index spaces, seeded with the runtime's.
    var e: bin.Encoder = .{ .ar = ar, .m = program };
    for (rt.types) |t| try e.types.append(ar, t);
    const n_rt_funcs = rt.n_imported_funcs + @as(u32, @intCast(rt.func_types.len));
    // A runtime function's symbol is its export name; the others get a name
    // no program symbol can collide with.
    const names = try ar.alloc([]const u8, n_rt_funcs);
    for (names, 0..) |*n, i| n.* = try std.fmt.allocPrint(ar, "\x00rt{d}", .{i});
    var eit = rt.exports.iterator();
    while (eit.next()) |kv| names[kv.value_ptr.*] = kv.key_ptr.*;
    try e.funcs.appendSlice(ar, names);
    for (0..rt.n_globals) |i| try e.globals.append(ar, try std.fmt.allocPrint(ar, "\x00g{d}", .{i}));

    // Program imports must be runtime exports.
    for (program.items) |it| switch (it) {
        .import => |im| {
            if (!std.mem.eql(u8, im.module, "rt") or !rt.exports.contains(im.name)) {
                return error.UnknownRuntimeFunction;
            }
            if (!std.mem.eql(u8, im.func, im.name)) return error.UnknownRuntimeFunction;
        },
        else => {},
    };

    // Program functions, globals, table.
    var prog_funcs: std.ArrayListUnmanaged(wat.Func) = .empty;
    var prog_globals: std.ArrayListUnmanaged(wat.Global) = .empty;
    var prog_table: []const []const u8 = &.{};
    for (program.items) |it| switch (it) {
        .func => |f| {
            try e.funcs.append(ar, f.name);
            try prog_funcs.append(ar, f);
        },
        .global => |g| {
            try e.globals.append(ar, g.name);
            try prog_globals.append(ar, g);
        },
        .table => |t| prog_table = t,
        .import, .comment => {},
        .memory, .start, .data => return error.Malformed, // the program has none of these
    };
    for (prog_funcs.items) |f| _ = try e.typeIndex(try bin.funcType(ar, f));
    var bodies: std.ArrayListUnmanaged([]const u8) = .empty;
    for (prog_funcs.items) |f| try bodies.append(ar, try e.funcBody(f));

    var out: bin.Bytes = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, &.{ 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 });
    var sec: bin.Bytes = .empty;

    // 1 type
    sec = .empty;
    try bin.uleb(ar, &sec, e.types.items.len);
    for (e.types.items) |t| {
        try sec.append(ar, 0x60);
        try bin.uleb(ar, &sec, t.params.len);
        for (t.params) |p| try sec.append(ar, bin.valType(p));
        if (t.result) |res| {
            try sec.append(ar, 1);
            try sec.append(ar, bin.valType(res));
        } else try sec.append(ar, 0);
    }
    try bin.section(alloc, &out, 1, sec.items);

    // 2 import (unchanged)
    if (rt.section(2)) |b| try bin.section(alloc, &out, 2, b);

    // 3 function
    {
        const v = try vecBody(rt.section(3));
        sec = .empty;
        try bin.uleb(ar, &sec, v.count + prog_funcs.items.len);
        try sec.appendSlice(ar, v.rest);
        for (prog_funcs.items) |f| try bin.uleb(ar, &sec, try e.typeIndex(try bin.funcType(ar, f)));
        try bin.section(alloc, &out, 3, sec.items);
    }

    // 4 table
    {
        const size = tbase + @as(u32, @intCast(prog_table.len));
        sec = .empty;
        try bin.uleb(ar, &sec, 1);
        try sec.append(ar, 0x70);
        try sec.append(ar, 0x01);
        try bin.uleb(ar, &sec, size);
        try bin.uleb(ar, &sec, size);
        try bin.section(alloc, &out, 4, sec.items);
    }

    // 5 memory
    {
        const need_pages: u32 = @intCast((@as(u64, lit_end) + 65536 + 65535) / 65536);
        sec = .empty;
        try bin.uleb(ar, &sec, 1);
        try sec.append(ar, 0x00);
        try bin.uleb(ar, &sec, @max(rt.memory_min, need_pages));
        try bin.section(alloc, &out, 5, sec.items);
    }

    // 6 global
    {
        const v = try vecBody(rt.section(6));
        sec = .empty;
        try bin.uleb(ar, &sec, v.count + prog_globals.items.len);
        try sec.appendSlice(ar, v.rest);
        for (prog_globals.items) |g| {
            try sec.append(ar, bin.valType(g.ty));
            try sec.append(ar, @intFromBool(g.mutable));
            const init: []const u8 = if (std.mem.eql(u8, g.name, "__lit"))
                try std.fmt.allocPrint(ar, "{d}", .{lit_base})
            else if (std.mem.eql(u8, g.name, "__lit_end"))
                try std.fmt.allocPrint(ar, "{d}", .{lit_end})
            else if (std.mem.eql(u8, g.name, "__tbase"))
                try std.fmt.allocPrint(ar, "{d}", .{tbase})
            else
                g.init;
            try bin.constInstr(ar, &sec, g.ty, init);
            try sec.append(ar, 0x0B);
        }
        try bin.section(alloc, &out, 6, sec.items);
    }

    // 7 export
    {
        const v = try vecBody(rt.section(7));
        var extra: bin.Bytes = .empty;
        var n_extra: usize = 0;
        for (prog_funcs.items, 0..) |f, i| for (f.exports) |x| {
            try bin.name(ar, &extra, x);
            try extra.append(ar, 0x00);
            try bin.uleb(ar, &extra, n_rt_funcs + i);
            n_extra += 1;
        };
        sec = .empty;
        try bin.uleb(ar, &sec, v.count + n_extra);
        try sec.appendSlice(ar, v.rest);
        try sec.appendSlice(ar, extra.items);
        try bin.section(alloc, &out, 7, sec.items);
    }

    // 9 element
    {
        const v = try vecBody(rt.section(9));
        const add: usize = if (prog_table.len > 0) 1 else 0;
        if (v.count + add > 0) {
            sec = .empty;
            try bin.uleb(ar, &sec, v.count + add);
            try sec.appendSlice(ar, v.rest);
            if (add == 1) {
                try sec.append(ar, 0x00);
                try sec.append(ar, 0x41);
                try bin.sleb(ar, &sec, tbase);
                try sec.append(ar, 0x0B);
                try bin.uleb(ar, &sec, prog_table.len);
                for (prog_table) |n| try bin.uleb(ar, &sec, try e.funcIndex(n));
            }
            try bin.section(alloc, &out, 9, sec.items);
        }
    }

    // 10 code
    {
        const v = try vecBody(rt.section(10));
        sec = .empty;
        try bin.uleb(ar, &sec, v.count + bodies.items.len);
        try sec.appendSlice(ar, v.rest);
        for (bodies.items) |b| {
            try bin.uleb(ar, &sec, b.len);
            try sec.appendSlice(ar, b);
        }
        try bin.section(alloc, &out, 10, sec.items);
    }

    // 11 data
    {
        const v = try vecBody(rt.section(11));
        const add: usize = if (data.len > 0) 1 else 0;
        sec = .empty;
        try bin.uleb(ar, &sec, v.count + add);
        try sec.appendSlice(ar, v.rest);
        if (add == 1) {
            try sec.append(ar, 0x00);
            try sec.append(ar, 0x41);
            try bin.sleb(ar, &sec, lit_base);
            try sec.append(ar, 0x0B);
            try bin.uleb(ar, &sec, data.len);
            try sec.appendSlice(ar, data);
        }
        try bin.section(alloc, &out, 11, sec.items);
    }

    return out.toOwnedSlice(alloc);
}
