//! WebAssembly binary emitter — the `wat_ast.zig` model in the binary format.
//!
//! `wat_emitter.zig` writes the text a snapshot records; this file writes the
//! bytes an engine instantiates (`WebAssembly.instantiate` in the browser build,
//! wasm3 on the comptime path, `wasmtime` for the RUN LOG). Both render the same
//! `Module`, so the text and the binary can only disagree through one of the two
//! emitters, never through the lowering; there is no text re-parse anywhere.
//!
//! Sections, in the order the format requires: type (1), import (2),
//! function (3), table (4), memory (5), global (6), export (7), start (8),
//! element (9), code (10), data (11). One function type per distinct
//! signature; LEB128 everywhere; no custom sections (names live in the text).
//!
//! The module is validated first (`wat_ast.validateModule`), as the text
//! emitter does, and everything the text resolves by name is resolved here to
//! an index: functions (imports first, then definitions, in item order),
//! globals, locals (parameters, then the declared locals) and branch labels
//! (the depth of the named `block`/`loop`, counting every `if` between).
//! A name that resolves to nothing, an operator this table does not know and
//! a numeral that does not parse are errors, not guesses.

const std = @import("std");
const ast = @import("wat_ast.zig");

pub const Error = std.mem.Allocator.Error || ast.Invalid || error{
    /// `local.get $x` / `global.set $x` / `br $x` naming nothing in scope.
    UnknownName,
    /// An `op` or `convert` spelling with no opcode in `opcodes`.
    UnknownOp,
    /// A `const` (or a global's initialiser) whose numeral does not parse.
    BadNumeral,
};

/// Render `m` to the binary format. The bytes are owned by the caller.
pub fn encodeModule(alloc: std.mem.Allocator, m: ast.Module) Error![]u8 {
    try ast.validateModule(m);
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const ar = arena_state.allocator();

    var e: Encoder = .{ .ar = ar, .m = m };
    try e.index();

    // Every type the module names is known only once the bodies are encoded
    // (`call_indirect` carries its own), and the type section comes first:
    // register the imports' and functions' types, encode the bodies, then
    // write the sections.
    for (m.items) |it| switch (it) {
        .import => |im| _ = try e.typeIndex(im.type),
        .func => |f| _ = try e.typeIndex(try funcType(ar, f)),
        else => {},
    };
    var bodies: std.ArrayListUnmanaged([]const u8) = .empty;
    for (m.items) |it| switch (it) {
        .func => |f| try bodies.append(ar, try e.funcBody(f)),
        else => {},
    };

    var out: Bytes = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, &.{ 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 });

    var sec: Bytes = .empty;
    // type
    try uleb(ar, &sec, e.types.items.len);
    for (e.types.items) |t| {
        try sec.append(ar, 0x60);
        try uleb(ar, &sec, t.params.len);
        for (t.params) |p| try sec.append(ar, valType(p));
        if (t.result) |r| {
            try sec.append(ar, 1);
            try sec.append(ar, valType(r));
        } else try sec.append(ar, 0);
    }
    try section(alloc, &out, 1, sec.items);

    // import
    if (e.n_imports > 0) {
        sec = .empty;
        try uleb(ar, &sec, e.n_imports);
        for (m.items) |it| switch (it) {
            .import => |im| {
                try name(ar, &sec, im.module);
                try name(ar, &sec, im.name);
                try sec.append(ar, 0x00);
                try uleb(ar, &sec, try e.typeIndex(im.type));
            },
            else => {},
        };
        try section(alloc, &out, 2, sec.items);
    }

    // function
    const n_funcs = e.funcs.items.len - e.n_imports;
    if (n_funcs > 0) {
        sec = .empty;
        try uleb(ar, &sec, n_funcs);
        for (m.items) |it| switch (it) {
            .func => |f| try uleb(ar, &sec, try e.typeIndex(try funcType(ar, f))),
            else => {},
        };
        try section(alloc, &out, 3, sec.items);
    }

    // table
    if (e.table) |names| {
        sec = .empty;
        try uleb(ar, &sec, 1);
        try sec.append(ar, 0x70);
        try sec.append(ar, 0x01);
        try uleb(ar, &sec, names.len);
        try uleb(ar, &sec, names.len);
        try section(alloc, &out, 4, sec.items);
    }

    // memory
    if (e.memory) |mem| {
        sec = .empty;
        try uleb(ar, &sec, 1);
        try sec.append(ar, 0x00);
        try uleb(ar, &sec, mem.min_pages);
        try section(alloc, &out, 5, sec.items);
    }

    // global
    if (e.globals.items.len > 0) {
        sec = .empty;
        try uleb(ar, &sec, e.globals.items.len);
        for (m.items) |it| switch (it) {
            .global => |g| {
                try sec.append(ar, valType(g.ty));
                try sec.append(ar, @intFromBool(g.mutable));
                try constInstr(ar, &sec, g.ty, g.init);
                try sec.append(ar, 0x0B);
            },
            else => {},
        };
        try section(alloc, &out, 6, sec.items);
    }

    // export
    {
        sec = .empty;
        var count: usize = 0;
        var body: Bytes = .empty;
        if (e.memory) |mem| if (mem.@"export") |x| {
            try name(ar, &body, x);
            try body.append(ar, 0x02);
            try uleb(ar, &body, 0);
            count += 1;
        };
        var fi: usize = e.n_imports;
        var gi: usize = 0;
        for (m.items) |it| switch (it) {
            .func => |f| {
                for (f.exports) |x| {
                    try name(ar, &body, x);
                    try body.append(ar, 0x00);
                    try uleb(ar, &body, fi);
                    count += 1;
                }
                fi += 1;
            },
            .global => |g| {
                for (g.exports) |x| {
                    try name(ar, &body, x);
                    try body.append(ar, 0x03);
                    try uleb(ar, &body, gi);
                    count += 1;
                }
                gi += 1;
            },
            else => {},
        };
        if (count > 0) {
            try uleb(ar, &sec, count);
            try sec.appendSlice(ar, body.items);
            try section(alloc, &out, 7, sec.items);
        }
    }

    // start
    if (e.start) |s| {
        sec = .empty;
        try uleb(ar, &sec, try e.funcIndex(s));
        try section(alloc, &out, 8, sec.items);
    }

    // element
    if (e.table) |names| {
        sec = .empty;
        try uleb(ar, &sec, 1);
        try sec.append(ar, 0x00);
        try sec.appendSlice(ar, &.{ 0x41, 0x00, 0x0B });
        try uleb(ar, &sec, names.len);
        for (names) |n| try uleb(ar, &sec, try e.funcIndex(n));
        try section(alloc, &out, 9, sec.items);
    }

    // code
    if (n_funcs > 0) {
        sec = .empty;
        try uleb(ar, &sec, n_funcs);
        for (bodies.items) |body| {
            try uleb(ar, &sec, body.len);
            try sec.appendSlice(ar, body);
        }
        try section(alloc, &out, 10, sec.items);
    }

    // data
    if (e.n_data > 0) {
        sec = .empty;
        try uleb(ar, &sec, e.n_data);
        for (m.items) |it| switch (it) {
            .data => |d| {
                try sec.append(ar, 0x00);
                try sec.append(ar, 0x41);
                try sleb(ar, &sec, @as(i64, @as(i32, @bitCast(d.offset))));
                try sec.append(ar, 0x0B);
                try uleb(ar, &sec, 4 + d.bytes.len);
                var prefix: [4]u8 = undefined;
                std.mem.writeInt(u32, &prefix, d.len_prefix, .little);
                try sec.appendSlice(ar, &prefix);
                try sec.appendSlice(ar, d.bytes);
            },
            else => {},
        };
        try section(alloc, &out, 11, sec.items);
    }

    return out.toOwnedSlice(alloc);
}

// ── indexing ─────────────────────────────────────────────────────────────────

pub const Bytes = std.ArrayListUnmanaged(u8);

/// The index spaces of one module being encoded. `link.zig` (the wat comptime
/// runtime) pre-seeds `types`, `funcs` and `globals` with a prebuilt module's,
/// so the functions it adds are encoded against the merged numbering.
pub const Encoder = struct {
    ar: std.mem.Allocator,
    m: ast.Module,
    types: std.ArrayListUnmanaged(ast.FuncType) = .empty,
    /// Every callable symbol by index: imports first, then definitions.
    funcs: std.ArrayListUnmanaged([]const u8) = .empty,
    globals: std.ArrayListUnmanaged([]const u8) = .empty,
    n_imports: usize = 0,
    n_data: usize = 0,
    memory: ?ast.Memory = null,
    table: ?[]const []const u8 = null,
    start: ?[]const u8 = null,

    fn index(e: *Encoder) Error!void {
        for (e.m.items) |it| switch (it) {
            .import => |im| {
                try e.funcs.append(e.ar, im.func);
                e.n_imports += 1;
            },
            else => {},
        };
        for (e.m.items) |it| switch (it) {
            .func => |f| try e.funcs.append(e.ar, f.name),
            .global => |g| try e.globals.append(e.ar, g.name),
            .memory => |mem| e.memory = mem,
            .table => |names| e.table = names,
            .start => |s| e.start = s,
            .data => e.n_data += 1,
            .import, .comment => {},
        };
    }

    pub fn typeIndex(e: *Encoder, t: ast.FuncType) Error!usize {
        for (e.types.items, 0..) |have, i| {
            if (sameType(have, t)) return i;
        }
        try e.types.append(e.ar, t);
        return e.types.items.len - 1;
    }

    pub fn funcIndex(e: *Encoder, sym: []const u8) Error!usize {
        for (e.funcs.items, 0..) |n, i| if (std.mem.eql(u8, n, sym)) return i;
        return error.UnknownName;
    }

    fn globalIndex(e: *Encoder, sym: []const u8) Error!usize {
        for (e.globals.items, 0..) |n, i| if (std.mem.eql(u8, n, sym)) return i;
        return error.UnknownName;
    }

    pub fn funcBody(e: *Encoder, f: ast.Func) Error![]const u8 {
        var locals: std.ArrayListUnmanaged([]const u8) = .empty;
        for (f.params) |p| try locals.append(e.ar, p.name);
        var decl: std.ArrayListUnmanaged(ast.ValType) = .empty;
        for (f.locals) |group| for (group) |l| {
            try locals.append(e.ar, l.name);
            try decl.append(e.ar, l.ty);
        };

        var b: Bytes = .empty;
        // Locals as runs of one type.
        var runs: usize = 0;
        var i: usize = 0;
        while (i < decl.items.len) : (runs += 1) {
            var j = i + 1;
            while (j < decl.items.len and decl.items[j] == decl.items[i]) j += 1;
            i = j;
        }
        try uleb(e.ar, &b, runs);
        i = 0;
        while (i < decl.items.len) {
            var j = i + 1;
            while (j < decl.items.len and decl.items[j] == decl.items[i]) j += 1;
            try uleb(e.ar, &b, j - i);
            try b.append(e.ar, valType(decl.items[i]));
            i = j;
        }

        var ctx: Body = .{ .e = e, .out = &b, .locals = locals.items };
        try ctx.seq(f.body);
        try b.append(e.ar, 0x0B);
        return b.items;
    }
};

/// One function body being encoded: its locals by index and the labels of the
/// structured forms around the current instruction (innermost last; `null` for
/// an `if`, which a branch can only reach by depth).
const Body = struct {
    e: *Encoder,
    out: *Bytes,
    locals: []const []const u8,
    labels: std.ArrayListUnmanaged(?[]const u8) = .empty,

    fn seq(c: *Body, s: ast.Seq) Error!void {
        for (s.lines) |l| try c.instr(l.instr);
    }

    fn localIndex(c: *Body, sym: []const u8) Error!usize {
        // The last declaration of a name wins, as in the text format's
        // identifier binding (a name is declared once in practice).
        var i = c.locals.len;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, c.locals[i], sym)) return i;
        }
        return error.UnknownName;
    }

    fn labelDepth(c: *Body, sym: []const u8) Error!usize {
        var i = c.labels.items.len;
        while (i > 0) {
            i -= 1;
            if (c.labels.items[i]) |l| if (std.mem.eql(u8, l, sym))
                return c.labels.items.len - 1 - i;
        }
        return error.UnknownName;
    }

    fn blockType(c: *Body, r: ?ast.ValType) Error!void {
        try c.out.append(c.e.ar, if (r) |t| valType(t) else 0x40);
    }

    fn instr(c: *Body, i: ast.Instr) Error!void {
        const ar = c.e.ar;
        const o = c.out;
        switch (i) {
            .@"const" => |k| try constInstr(ar, o, k.ty, k.text),
            .local_get => |n| {
                try o.append(ar, 0x20);
                try uleb(ar, o, try c.localIndex(n));
            },
            .local_set => |n| {
                try o.append(ar, 0x21);
                try uleb(ar, o, try c.localIndex(n));
            },
            .local_tee => |n| {
                try o.append(ar, 0x22);
                try uleb(ar, o, try c.localIndex(n));
            },
            .global_get => |n| {
                try o.append(ar, 0x23);
                try uleb(ar, o, try c.e.globalIndex(n));
            },
            .global_set => |n| {
                try o.append(ar, 0x24);
                try uleb(ar, o, try c.e.globalIndex(n));
            },
            .op => |op| try o.appendSlice(ar, try opcode(op.ty.text(), op.name)),
            .convert => |full| {
                const dot = std.mem.indexOfScalar(u8, full, '.') orelse return error.UnknownOp;
                try o.appendSlice(ar, try opcode(full[0..dot], full[dot + 1 ..]));
            },
            .load => |m| {
                try o.append(ar, switch (m.width) {
                    .full => switch (m.ty) {
                        .i32 => 0x28,
                        .i64 => 0x29,
                        .f32 => 0x2A,
                        .f64 => 0x2B,
                    },
                    .byte => switch (m.ty) {
                        .i32 => 0x2D,
                        .i64 => 0x31,
                        else => return error.UnknownOp,
                    },
                });
                try memArg(ar, o, m);
            },
            .store => |m| {
                try o.append(ar, switch (m.width) {
                    .full => switch (m.ty) {
                        .i32 => 0x36,
                        .i64 => 0x37,
                        .f32 => 0x38,
                        .f64 => 0x39,
                    },
                    .byte => switch (m.ty) {
                        .i32 => 0x3A,
                        .i64 => 0x3C,
                        else => return error.UnknownOp,
                    },
                });
                try memArg(ar, o, m);
            },
            .call => |n| {
                try o.append(ar, 0x10);
                try uleb(ar, o, try c.e.funcIndex(n));
            },
            .call_indirect => |t| {
                try o.append(ar, 0x11);
                try uleb(ar, o, try c.e.typeIndex(t));
                try o.append(ar, 0x00);
            },
            .br => |l| {
                try o.append(ar, 0x0C);
                try uleb(ar, o, try c.labelDepth(l));
            },
            .br_if => |l| {
                try o.append(ar, 0x0D);
                try uleb(ar, o, try c.labelDepth(l));
            },
            .drop => try o.append(ar, 0x1A),
            .@"return" => try o.append(ar, 0x0F),
            .@"unreachable" => try o.append(ar, 0x00),
            .memory_copy => try o.appendSlice(ar, &.{ 0xFC, 0x0A, 0x00, 0x00 }),
            .comment => {},
            .@"if" => |n| {
                try o.append(ar, 0x04);
                try c.blockType(n.result);
                try c.labels.append(ar, null);
                try c.seq(n.then.seq);
                if (n.@"else") |el| {
                    try o.append(ar, 0x05);
                    try c.seq(el.seq);
                }
                _ = c.labels.pop();
                try o.append(ar, 0x0B);
            },
            .block => |b| {
                try o.append(ar, switch (b.kind) {
                    .block => 0x02,
                    .loop => 0x03,
                });
                try c.blockType(b.result);
                try c.labels.append(ar, b.label);
                try c.seq(b.body);
                _ = c.labels.pop();
                try o.append(ar, 0x0B);
            },
        }
    }
};

// ── encoding primitives ──────────────────────────────────────────────────────

pub fn section(alloc: std.mem.Allocator, out: *Bytes, id: u8, body: []const u8) Error!void {
    try out.append(alloc, id);
    var len: [5]u8 = undefined;
    const n = ulebInto(&len, body.len);
    try out.appendSlice(alloc, len[0..n]);
    try out.appendSlice(alloc, body);
}

fn ulebInto(buf: *[5]u8, value: usize) usize {
    var v = value;
    var n: usize = 0;
    while (true) {
        const byte: u8 = @truncate(v & 0x7f);
        v >>= 7;
        if (v == 0) {
            buf[n] = byte;
            return n + 1;
        }
        buf[n] = byte | 0x80;
        n += 1;
    }
}

pub fn uleb(ar: std.mem.Allocator, out: *Bytes, value: usize) Error!void {
    var v = value;
    while (true) {
        const byte: u8 = @truncate(v & 0x7f);
        v >>= 7;
        if (v == 0) return out.append(ar, byte);
        try out.append(ar, byte | 0x80);
    }
}

pub fn sleb(ar: std.mem.Allocator, out: *Bytes, value: i64) Error!void {
    var v = value;
    while (true) {
        const byte: u8 = @truncate(@as(u64, @bitCast(v)) & 0x7f);
        v >>= 7;
        const done = (v == 0 and byte & 0x40 == 0) or (v == -1 and byte & 0x40 != 0);
        if (done) return out.append(ar, byte);
        try out.append(ar, byte | 0x80);
    }
}

pub fn name(ar: std.mem.Allocator, out: *Bytes, s: []const u8) Error!void {
    try uleb(ar, out, s.len);
    try out.appendSlice(ar, s);
}

pub fn valType(t: ast.ValType) u8 {
    return switch (t) {
        .i32 => 0x7F,
        .i64 => 0x7E,
        .f32 => 0x7D,
        .f64 => 0x7C,
    };
}

fn memArg(ar: std.mem.Allocator, out: *Bytes, m: ast.MemArg) Error!void {
    const log2_align: u8 = switch (m.width) {
        .byte => 0,
        .full => switch (m.ty) {
            .i32, .f32 => 2,
            .i64, .f64 => 3,
        },
    };
    try out.append(ar, log2_align);
    try uleb(ar, out, m.offset);
}

fn sameType(a: ast.FuncType, b: ast.FuncType) bool {
    if (a.result != b.result) return false;
    return std.mem.eql(ast.ValType, a.params, b.params);
}

pub fn funcType(ar: std.mem.Allocator, f: ast.Func) Error!ast.FuncType {
    const params = try ar.alloc(ast.ValType, f.params.len);
    for (f.params, 0..) |p, i| params[i] = p.ty;
    return .{ .params = params, .result = f.result };
}

/// `<ty>.const <text>` — the numeral as the text format spells it: decimal or
/// `0x` hex, an optional sign, `_` separators; a float may be `inf`/`nan`.
pub fn constInstr(ar: std.mem.Allocator, out: *Bytes, ty: ast.ValType, text: []const u8) Error!void {
    var buf: [128]u8 = undefined;
    var n: usize = 0;
    for (text) |ch| {
        if (ch == '_') continue;
        if (n == buf.len) return error.BadNumeral;
        buf[n] = ch;
        n += 1;
    }
    const clean = buf[0..n];
    switch (ty) {
        .i32 => {
            try out.append(ar, 0x41);
            const v = try parseInt(clean, 32);
            try sleb(ar, out, @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(v)))))));
        },
        .i64 => {
            try out.append(ar, 0x42);
            try sleb(ar, out, try parseInt(clean, 64));
        },
        .f32 => {
            try out.append(ar, 0x43);
            const f: f32 = @floatCast(try parseFloat(clean));
            var b: [4]u8 = undefined;
            std.mem.writeInt(u32, &b, @bitCast(f), .little);
            try out.appendSlice(ar, &b);
        },
        .f64 => {
            try out.append(ar, 0x44);
            const f = try parseFloat(clean);
            var b: [8]u8 = undefined;
            std.mem.writeInt(u64, &b, @bitCast(f), .little);
            try out.appendSlice(ar, &b);
        },
    }
}

/// An integer numeral of at most `bits` bits, signed or unsigned — the text
/// format accepts both (`i32.const 4294967295` is `-1`), so the value is
/// returned as the i64 whose low `bits` bits are the constant.
fn parseInt(s: []const u8, comptime bits: u8) Error!i64 {
    var neg = false;
    var digits = s;
    if (digits.len > 0 and (digits[0] == '-' or digits[0] == '+')) {
        neg = digits[0] == '-';
        digits = digits[1..];
    }
    var radix: u8 = 10;
    if (digits.len > 2 and digits[0] == '0' and (digits[1] == 'x' or digits[1] == 'X')) {
        radix = 16;
        digits = digits[2..];
    }
    const mag = std.fmt.parseUnsigned(u64, digits, radix) catch return error.BadNumeral;
    if (bits == 32 and mag > std.math.maxInt(u32)) return error.BadNumeral;
    const v: i64 = @bitCast(mag);
    return if (neg) -%v else v;
}

fn parseFloat(s: []const u8) Error!f64 {
    var body = s;
    var neg = false;
    if (body.len > 0 and (body[0] == '-' or body[0] == '+')) {
        neg = body[0] == '-';
        body = body[1..];
    }
    const v: f64 = if (std.mem.eql(u8, body, "inf"))
        std.math.inf(f64)
    else if (std.mem.eql(u8, body, "nan"))
        std.math.nan(f64)
    else if (body.len > 2 and body[0] == '0' and (body[1] == 'x' or body[1] == 'X'))
        std.fmt.parseFloat(f64, body) catch return error.BadNumeral
    else
        std.fmt.parseFloat(f64, body) catch return error.BadNumeral;
    return if (neg) -v else v;
}

// ── opcodes ──────────────────────────────────────────────────────────────────

/// The numeric instructions of the MVP (plus sign extension and the
/// saturating truncations), by their text spelling `<ty>.<name>`.
fn opcode(ty: []const u8, op: []const u8) Error![]const u8 {
    var key_buf: [48]u8 = undefined;
    const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ ty, op }) catch return error.UnknownOp;
    inline for (opcodes) |entry| {
        if (std.mem.eql(u8, entry[0], key)) return entry[1];
    }
    return error.UnknownOp;
}

const opcodes = [_]struct { []const u8, []const u8 }{
    .{ "i32.eqz", &.{0x45} },                     .{ "i32.eq", &.{0x46} },                      .{ "i32.ne", &.{0x47} },
    .{ "i32.lt_s", &.{0x48} },                    .{ "i32.lt_u", &.{0x49} },                    .{ "i32.gt_s", &.{0x4A} },
    .{ "i32.gt_u", &.{0x4B} },                    .{ "i32.le_s", &.{0x4C} },                    .{ "i32.le_u", &.{0x4D} },
    .{ "i32.ge_s", &.{0x4E} },                    .{ "i32.ge_u", &.{0x4F} },                    .{ "i64.eqz", &.{0x50} },
    .{ "i64.eq", &.{0x51} },                      .{ "i64.ne", &.{0x52} },                      .{ "i64.lt_s", &.{0x53} },
    .{ "i64.lt_u", &.{0x54} },                    .{ "i64.gt_s", &.{0x55} },                    .{ "i64.gt_u", &.{0x56} },
    .{ "i64.le_s", &.{0x57} },                    .{ "i64.le_u", &.{0x58} },                    .{ "i64.ge_s", &.{0x59} },
    .{ "i64.ge_u", &.{0x5A} },                    .{ "f32.eq", &.{0x5B} },                      .{ "f32.ne", &.{0x5C} },
    .{ "f32.lt", &.{0x5D} },                      .{ "f32.gt", &.{0x5E} },                      .{ "f32.le", &.{0x5F} },
    .{ "f32.ge", &.{0x60} },                      .{ "f64.eq", &.{0x61} },                      .{ "f64.ne", &.{0x62} },
    .{ "f64.lt", &.{0x63} },                      .{ "f64.gt", &.{0x64} },                      .{ "f64.le", &.{0x65} },
    .{ "f64.ge", &.{0x66} },                      .{ "i32.clz", &.{0x67} },                     .{ "i32.ctz", &.{0x68} },
    .{ "i32.popcnt", &.{0x69} },                  .{ "i32.add", &.{0x6A} },                     .{ "i32.sub", &.{0x6B} },
    .{ "i32.mul", &.{0x6C} },                     .{ "i32.div_s", &.{0x6D} },                   .{ "i32.div_u", &.{0x6E} },
    .{ "i32.rem_s", &.{0x6F} },                   .{ "i32.rem_u", &.{0x70} },                   .{ "i32.and", &.{0x71} },
    .{ "i32.or", &.{0x72} },                      .{ "i32.xor", &.{0x73} },                     .{ "i32.shl", &.{0x74} },
    .{ "i32.shr_s", &.{0x75} },                   .{ "i32.shr_u", &.{0x76} },                   .{ "i32.rotl", &.{0x77} },
    .{ "i32.rotr", &.{0x78} },                    .{ "i64.clz", &.{0x79} },                     .{ "i64.ctz", &.{0x7A} },
    .{ "i64.popcnt", &.{0x7B} },                  .{ "i64.add", &.{0x7C} },                     .{ "i64.sub", &.{0x7D} },
    .{ "i64.mul", &.{0x7E} },                     .{ "i64.div_s", &.{0x7F} },                   .{ "i64.div_u", &.{0x80} },
    .{ "i64.rem_s", &.{0x81} },                   .{ "i64.rem_u", &.{0x82} },                   .{ "i64.and", &.{0x83} },
    .{ "i64.or", &.{0x84} },                      .{ "i64.xor", &.{0x85} },                     .{ "i64.shl", &.{0x86} },
    .{ "i64.shr_s", &.{0x87} },                   .{ "i64.shr_u", &.{0x88} },                   .{ "i64.rotl", &.{0x89} },
    .{ "i64.rotr", &.{0x8A} },                    .{ "f32.abs", &.{0x8B} },                     .{ "f32.neg", &.{0x8C} },
    .{ "f32.ceil", &.{0x8D} },                    .{ "f32.floor", &.{0x8E} },                   .{ "f32.trunc", &.{0x8F} },
    .{ "f32.nearest", &.{0x90} },                 .{ "f32.sqrt", &.{0x91} },                    .{ "f32.add", &.{0x92} },
    .{ "f32.sub", &.{0x93} },                     .{ "f32.mul", &.{0x94} },                     .{ "f32.div", &.{0x95} },
    .{ "f32.min", &.{0x96} },                     .{ "f32.max", &.{0x97} },                     .{ "f32.copysign", &.{0x98} },
    .{ "f64.abs", &.{0x99} },                     .{ "f64.neg", &.{0x9A} },                     .{ "f64.ceil", &.{0x9B} },
    .{ "f64.floor", &.{0x9C} },                   .{ "f64.trunc", &.{0x9D} },                   .{ "f64.nearest", &.{0x9E} },
    .{ "f64.sqrt", &.{0x9F} },                    .{ "f64.add", &.{0xA0} },                     .{ "f64.sub", &.{0xA1} },
    .{ "f64.mul", &.{0xA2} },                     .{ "f64.div", &.{0xA3} },                     .{ "f64.min", &.{0xA4} },
    .{ "f64.max", &.{0xA5} },                     .{ "f64.copysign", &.{0xA6} },                .{ "i32.wrap_i64", &.{0xA7} },
    .{ "i32.trunc_f32_s", &.{0xA8} },             .{ "i32.trunc_f32_u", &.{0xA9} },             .{ "i32.trunc_f64_s", &.{0xAA} },
    .{ "i32.trunc_f64_u", &.{0xAB} },             .{ "i64.extend_i32_s", &.{0xAC} },            .{ "i64.extend_i32_u", &.{0xAD} },
    .{ "i64.trunc_f32_s", &.{0xAE} },             .{ "i64.trunc_f32_u", &.{0xAF} },             .{ "i64.trunc_f64_s", &.{0xB0} },
    .{ "i64.trunc_f64_u", &.{0xB1} },             .{ "f32.convert_i32_s", &.{0xB2} },           .{ "f32.convert_i32_u", &.{0xB3} },
    .{ "f32.convert_i64_s", &.{0xB4} },           .{ "f32.convert_i64_u", &.{0xB5} },           .{ "f32.demote_f64", &.{0xB6} },
    .{ "f64.convert_i32_s", &.{0xB7} },           .{ "f64.convert_i32_u", &.{0xB8} },           .{ "f64.convert_i64_s", &.{0xB9} },
    .{ "f64.convert_i64_u", &.{0xBA} },           .{ "f64.promote_f32", &.{0xBB} },             .{ "i32.reinterpret_f32", &.{0xBC} },
    .{ "i64.reinterpret_f64", &.{0xBD} },         .{ "f32.reinterpret_i32", &.{0xBE} },         .{ "f64.reinterpret_i64", &.{0xBF} },
    .{ "i32.extend8_s", &.{0xC0} },               .{ "i32.extend16_s", &.{0xC1} },              .{ "i64.extend8_s", &.{0xC2} },
    .{ "i64.extend16_s", &.{0xC3} },              .{ "i64.extend32_s", &.{0xC4} },              .{ "i32.trunc_sat_f32_s", &.{ 0xFC, 0x00 } },
    .{ "i32.trunc_sat_f32_u", &.{ 0xFC, 0x01 } }, .{ "i32.trunc_sat_f64_s", &.{ 0xFC, 0x02 } }, .{ "i32.trunc_sat_f64_u", &.{ 0xFC, 0x03 } },
    .{ "i64.trunc_sat_f32_s", &.{ 0xFC, 0x04 } }, .{ "i64.trunc_sat_f32_u", &.{ 0xFC, 0x05 } }, .{ "i64.trunc_sat_f64_s", &.{ 0xFC, 0x06 } },
    .{ "i64.trunc_sat_f64_u", &.{ 0xFC, 0x07 } },
};

// ── tests ────────────────────────────────────────────────────────────────────

test "LEB128: unsigned and signed boundaries" {
    const alloc = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const ar = arena.allocator();
    var b: Bytes = .empty;
    try uleb(ar, &b, 624485);
    try std.testing.expectEqualSlices(u8, &.{ 0xE5, 0x8E, 0x26 }, b.items);
    b = .empty;
    try sleb(ar, &b, -123456);
    try std.testing.expectEqualSlices(u8, &.{ 0xC0, 0xBB, 0x78 }, b.items);
    b = .empty;
    try sleb(ar, &b, 64);
    try std.testing.expectEqualSlices(u8, &.{ 0xC0, 0x00 }, b.items);
    b = .empty;
    try sleb(ar, &b, -1);
    try std.testing.expectEqualSlices(u8, &.{0x7F}, b.items);
}

test "numerals: the text format's spellings" {
    try std.testing.expectEqual(@as(i64, -1), try parseInt("-1", 32));
    try std.testing.expectEqual(@as(i64, 4294967295), try parseInt("4294967295", 32));
    try std.testing.expectEqual(@as(i64, 255), try parseInt("0xff", 32));
    try std.testing.expectError(error.BadNumeral, parseInt("4294967296", 32));
    try std.testing.expectError(error.BadNumeral, parseInt("1.5", 32));
    try std.testing.expectEqual(@as(f64, 3.14), try parseFloat("3.14"));
    try std.testing.expect(std.math.isInf(try parseFloat("-inf")));
    try std.testing.expect(std.math.isNan(try parseFloat("nan")));
}

test "a module encodes to the exact bytes of its sections" {
    const alloc = std.testing.allocator;
    // (module
    //   (import "env" "log" (func $log (param i32)))
    //   (memory (export "memory") 1)
    //   (global $g (mut i32) (i32.const 7))
    //   (func $f (export "f") (param $p i32) (result i32) (local $x i32)
    //     (block $out (loop $again local.get $p br_if $out br $again))
    //     local.get $p i32.const 1 i32.add local.tee $x call $log
    //     global.get $g)
    //   (data (i32.const 16) "\01\00\00\00a"))
    const loop_body: ast.Seq = .{ .stack = .terminated, .lines = &.{
        .{ .instr = .{ .local_get = "p" } },
        .{ .instr = .{ .br_if = "out" } },
        .{ .instr = .{ .br = "again" } },
    } };
    const m: ast.Module = .{ .items = &.{
        .{ .import = .{ .module = "env", .name = "log", .func = "log", .type = .{ .params = &.{.i32} } } },
        .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } },
        .{ .global = .{ .name = "g", .ty = .i32, .mutable = true, .init = "7" } },
        .{ .func = .{
            .name = "f",
            .exports = &.{"f"},
            .params = &.{.{ .name = "p", .ty = .i32 }},
            .result = .i32,
            .locals = &.{&.{.{ .name = "x", .ty = .i32 }}},
            .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
                .{ .instr = .{ .block = .{ .kind = .block, .label = "out", .body = .{ .lines = &.{
                    .{ .instr = .{ .block = .{ .kind = .loop, .label = "again", .body = loop_body } } },
                } } } } },
                .{ .instr = .{ .local_get = "p" } },
                .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .instr = .{ .local_tee = "x" } },
                .{ .instr = .{ .call = "log" } },
                .{ .instr = .{ .comment = "not encoded" } },
                .{ .instr = .{ .global_get = "g" } },
            } },
        } },
        .{ .data = .{ .offset = 16, .len_prefix = 1, .bytes = "a" } },
    } };
    const bytes = try encodeModule(alloc, m);
    defer alloc.free(bytes);
    const want = [_]u8{
        0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
        // type: (i32) -> (), (i32) -> i32
        0x01, 0x0A, 0x02, 0x60, 0x01, 0x7F, 0x00, 0x60,
        0x01, 0x7F, 0x01, 0x7F,
        // import env.log func type 0
        0x02, 0x0B, 0x01, 0x03,
        'e',  'n',  'v',  0x03, 'l',  'o',  'g',  0x00,
        0x00,
        // function: one, type 1
        0x03, 0x02, 0x01, 0x01,
        // memory: min 1
        0x05, 0x03, 0x01,
        0x00, 0x01,
        // global: mut i32 = 7
        0x06, 0x06, 0x01, 0x7F, 0x01, 0x41,
        0x07, 0x0B,
        // export: "memory" mem 0, "f" func 1
        0x07, 0x0E, 0x02, 0x06, 'm',  'e',
        'm',  'o',  'r',  'y',  0x02, 0x00, 0x01, 'f',
        0x00, 0x01,
        // code
        0x0A, 0x1D, 0x01, 0x1B, 0x01, 0x01,
        0x7F, 0x02, 0x40, 0x03, 0x40, 0x20, 0x00, 0x0D,
        0x01, 0x0C, 0x00, 0x0B, 0x0B, 0x20, 0x00, 0x41,
        0x01, 0x6A, 0x22, 0x01, 0x10, 0x00, 0x23, 0x00,
        0x0B,
        // data: at 16, "\01\00\00\00a"
        0x0B, 0x0B, 0x01, 0x00, 0x41, 0x10, 0x0B,
        0x05, 0x01, 0x00, 0x00, 0x00, 'a',
    };
    try std.testing.expectEqualSlices(u8, &want, bytes);
}

test "a name nothing declares is refused, not guessed" {
    const alloc = std.testing.allocator;
    const m: ast.Module = .{ .items = &.{.{ .func = .{
        .name = "f",
        .body = .{ .lines = &.{ .{ .instr = .{ .local_get = "nope" } }, .{ .instr = .drop } } },
    } }} };
    try std.testing.expectError(error.UnknownName, encodeModule(alloc, m));
    const bad_op: ast.Module = .{ .items = &.{.{ .func = .{
        .name = "f",
        .body = .{ .lines = &.{
            .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
            .{ .instr = .{ .op = .{ .ty = .i32, .name = "frobnicate" } } },
            .{ .instr = .drop },
        } },
    } }} };
    try std.testing.expectError(error.UnknownOp, encodeModule(alloc, bad_op));
}
