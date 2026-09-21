//! `.beam` container writer — a BEAM module file assembled in Zig, no `erlc`.
//!
//! Takes a small instruction model (`Module` → `Function` → `Instr` → `Arg`) and
//! writes the bytes `code:load_binary/3` loads: the `FOR1`/`BEAM` IFF container
//! with the chunks `AtU8`, `Code`, `StrT`, `ImpT`, `ExpT`, `FunT` (when a fun is
//! made), `LitT` (when a compound literal is used) and `Line`. The format is
//! OTP's own (`beam_asm.erl`, `beam_dict.erl`), read off the OTP 29 sources and
//! validated by loading; the opcode table is `opcodes.zig`, pinned to OTP 28
//! and restricted to the subset present since OTP 24 (decision 86) — an
//! instruction outside that subset is refused here, never written.
//!
//! What the model spells is the `.S` model `beam_emitter.zig` renders as text
//! (registers, labels, atoms, integers, `{literal, …}`, `{extfunc, M, F, A}`,
//! `{list, …}`), one `Arg` variant per operand kind, so the adapter from that
//! emitter's `Operand`/`Dest`/`TestOp`/`GcBif`/`Callee` is a mapping and not a
//! re-encoding (`## Adapter` below). Nothing here reads botopink source: the
//! input is instructions, the output is bytes.
//!
//! Tables (the role `beam_dict.erl` plays):
//!
//! | Table | Rule |
//! |---|---|
//! | atoms (`AtU8`) | first insertion wins the index; index 1 is the module atom, inserted first; every `Arg.atom`, every module/function of an import, export or fun |
//! | imports (`ImpT`) | `(module, function, arity)` in first-use order; `Arg.ext` encodes as the row's index (`u`) |
//! | exports (`ExpT`) | one row `(name, arity, entry label)` per `Function` with `exported = true` |
//! | funs (`FunT`) | one row per distinct `make_fun3` entry label: the function at that label, its arity, the label, a sequential index, the environment size, and `old_uniq` (27 bits of a hash of the code, as `erlc` does) |
//! | literals (`LitT`) | one entry per distinct compound term, deduplicated by its external-term bytes (`comptime/runtime/etf.zig`, already pinned to OTP's byte vectors); scalars fold to `a`/`i` operands as `beam_asm` folds them |
//! | lines (`Line`) | one item per distinct `(file, line)`, indexed from 1 (0 is "no location"); `Arg.line` is the operand of `line`; the file is `Module.source_file` (fname 1) so a stack trace names the `.bp` |
//! | labels | `label N` defines N; `{f, N}` is encoded as the label **number** (the loader resolves labels, `beam_asm` does not); `label_count` in the `Code` header is one past the highest label |
//!
//! The `Code` header's `opcode_max` is a **version stamp**, not the highest
//! opcode used: the loader refuses a module that declares less than `swap`
//! (169, OTP 23) as "compiled for an old version of the runtime system"
//! (`beam_load.c`), and `erlc` sets it artificially to a recent opcode for that
//! reason (OTP 28's to `bs_create_bin`). This writer stamps the pinned table's
//! maximum, `opcodes.opcode_max` (184, OTP 28): a VM below decision 86's floor
//! refuses the module with the loader's own message ("compiled for a later
//! version … supports only up to N"), and the instructions themselves stay in
//! the OTP 24 subset.
//!
//! `LitT` is written as a zlib stream of **stored** blocks (no compression, valid
//! zlib): every OTP inflates it. OTP 28's `erlc` writes the table uncompressed
//! behind a zero size word instead, which a pre-28 loader cannot read — the
//! compressed framing is the one both sides of decision 86's floor accept, and
//! it costs nothing to write.
//!
//! Validation is by loading (`## Tests`): `beam_lib:info/1` and `beam_lib:chunks/2`
//! decode the tables, `code:load_binary/3` runs the loader's own checks (opcode
//! max, label ranges, `func_info` consistency), and the module's `main` answers.
//! This file has no `beam_validator` pass: a register misuse the loader accepts
//! is a run-time crash of the comptime body, which the parity test of step 3
//! catches and this file cannot.
//!
//! ## Adapter
//!
//! Step 1c's `beam_asm.zig` comptime mode (owned by another worktree while this
//! file was written) feeds this model instead of a `Writer`:
//! `Operand.x/.y/.f` → `Arg.x/.y/.f`; `Operand.term` → `Arg.literal` (the scalar
//! folding is here); `Operand.lexeme` → `Arg.literal` of `Term.str(resolved)`;
//! `Operand.untagged` → `Arg.u`; `Operand.number` → `Arg.i` or a float literal;
//! `Callee.ext` → `Arg.ext`; `GcBif` → `Arg.ext` of `erlang:<bif>/N` under
//! `gc_bif1/2/3`; `TestOp` → the `is_*` opcode with `[f, args…]`;
//! `writeMakeFun3(label, env)` → `make_fun3 [f label, dst, list env]` (the
//! `FunT` index is assigned here from the label).

const std = @import("std");
const opcodes = @import("opcodes.zig");
const Term = @import("term.zig").Term;
const etf = @import("../../comptime/runtime/etf.zig");

pub const Op = opcodes.Op;

pub const Error = std.mem.Allocator.Error || error{
    /// An instruction's operand count is not its opcode's arity.
    ArityMismatch,
    /// The opcode is obsolete or newer than OTP 24 (decision 86).
    OpcodeNotEmittable,
    /// A `{f, N}` names a label no `label` instruction defines.
    UndefinedLabel,
    /// Two `label` instructions define the same number.
    DuplicateLabel,
    /// A function's `entry` is not a label of its own code.
    EntryIsNotALabel,
    /// A fun's entry label is not a function's entry.
    FunEntryIsNotAFunction,
    /// An atom is empty, or longer than the 255 bytes `AtU8` encodes.
    InvalidAtom,
    /// `line` takes exactly one `Arg.line`; no other instruction takes one.
    LineOperand,
    /// A module with no functions has nothing to load.
    NoFunctions,
};

/// `{extfunc, Module, Function, Arity}` — a remote call or BIF target.
pub const ExtFunc = struct {
    module: []const u8,
    function: []const u8,
    arity: u32,
};

/// `{alloc, [{words, W}, {floats, F}, {funs, N}]}` — `test_heap`/`allocate_heap`'s
/// heap-need operand when it is not a plain word count.
pub const Alloc = struct {
    words: u32 = 0,
    floats: u32 = 0,
    funs: u32 = 0,
};

/// One instruction operand — the compact-term-encoded kinds of `beam_asm.erl`'s
/// `encode_arg/2`, plus the two the assembler resolves itself (`ext` to an
/// import index, `line` to a line-table index).
pub const Arg = union(enum) {
    /// A bare unsigned — an arity, a live count, a tuple index, a stack need.
    u: u64,
    /// `{integer, N}`.
    i: i64,
    /// `{atom, Name}` by its unquoted name.
    atom: []const u8,
    /// `nil` — the empty list.
    nil,
    /// `{x, N}`.
    x: u32,
    /// `{y, N}`.
    y: u32,
    /// `{f, N}` — a label; 0 is "no fail label" and is never defined.
    f: u32,
    /// `{literal, Term}`. Scalars fold to `atom`/`i`/`nil`; compound terms go to `LitT`.
    literal: Term,
    /// `{extfunc, M, F, A}` — an `ImpT` row.
    ext: ExtFunc,
    /// `{list, [...]}`.
    list: []const Arg,
    /// `{alloc, [...]}`.
    alloc: Alloc,
    /// The source line a `line` instruction records; 0 is "no location".
    line: u32,

    pub fn xr(n: anytype) Arg {
        return .{ .x = @intCast(n) };
    }
    pub fn yr(n: anytype) Arg {
        return .{ .y = @intCast(n) };
    }
    pub fn lbl(n: anytype) Arg {
        return .{ .f = @intCast(n) };
    }
    pub fn uint(n: anytype) Arg {
        return .{ .u = @intCast(n) };
    }
    pub fn int(n: anytype) Arg {
        return .{ .i = @intCast(n) };
    }
    pub fn atomOf(name: []const u8) Arg {
        return .{ .atom = name };
    }
    pub fn lit(term: Term) Arg {
        return .{ .literal = term };
    }
    pub fn extFn(module: []const u8, function: []const u8, arity: anytype) Arg {
        return .{ .ext = .{ .module = module, .function = function, .arity = @intCast(arity) } };
    }
    pub fn listOf(args: []const Arg) Arg {
        return .{ .list = args };
    }
    pub fn loc(line_number: anytype) Arg {
        return .{ .line = @intCast(line_number) };
    }
};

/// One instruction: an opcode and exactly `op.info().arity` operands.
pub const Instr = struct {
    op: Op,
    args: []const Arg,

    pub fn of(op: Op, args: []const Arg) Instr {
        return .{ .op = op, .args = args };
    }
};

/// `{function, Name, Arity, Entry}` and its code. The code holds its own
/// `label`s, including `entry` and (by convention) the `func_info` label before it.
pub const Function = struct {
    name: []const u8,
    arity: u32,
    entry: u32,
    exported: bool = true,
    code: []const Instr,
};

pub const Module = struct {
    /// The module atom — `AtU8` index 1.
    name: []const u8,
    functions: []const Function,
    /// The file the `Line` chunk names, i.e. what a stack trace's `{file, …}`
    /// says. Null leaves the loader's default, `<module>.erl`.
    source_file: ?[]const u8 = null,
};

/// Assemble `module` into `.beam` bytes owned by the caller.
pub fn assemble(alloc: std.mem.Allocator, module: Module) Error![]u8 {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    var asm_: Assembler = .{ .arena = arena_state.allocator(), .module = module };
    return asm_.run(alloc);
}

// ── compact term encoding ─────────────────────────────────────────────────────

const Tag = enum(u3) { u = 0, i = 1, a = 2, x = 3, y = 4, f = 5, h = 6, z = 7 };

const Bytes = std.ArrayListUnmanaged(u8);

/// `beam_asm:encode/2` for a non-negative value.
fn encodeUnsigned(arena: std.mem.Allocator, out: *Bytes, tag: Tag, n: u64) Error!void {
    const t: u8 = @intFromEnum(tag);
    if (n < 16) return out.append(arena, @as(u8, @intCast(n << 4)) | t);
    if (n < 0x800) {
        try out.append(arena, @as(u8, @intCast((n >> 3) & 0b1110_0000)) | t | 0b0000_1000);
        return out.append(arena, @truncate(n));
    }
    // Minimal big-endian bytes, with a leading zero when the top bit is set so
    // the value reads as positive.
    var buf: [9]u8 = undefined;
    buf[0] = 0;
    var len: usize = 0;
    var v = n;
    while (v != 0) : (v >>= 8) len += 1;
    std.mem.writeInt(u64, buf[1..9], n, .big);
    var start: usize = 9 - len;
    if (buf[start] & 0x80 != 0) start -= 1; // buf[start] is 0
    return encodeBytes(arena, out, tag, buf[start..]);
}

/// `beam_asm:encode/2` for a negative value (`negative_to_bytes`).
fn encodeNegative(arena: std.mem.Allocator, out: *Bytes, tag: Tag, n: i64) Error!void {
    std.debug.assert(n < 0);
    if (n >= -0x8000) {
        var two: [2]u8 = undefined;
        std.mem.writeInt(i16, &two, @intCast(n), .big);
        return encodeBytes(arena, out, tag, &two);
    }
    // Two's complement in as many bytes as the magnitude needs, sign-extended
    // by one 0xff byte when its top bit reads positive.
    const magnitude: u64 = @as(u64, @intCast(-(n + 1))) + 1;
    var mag_len: usize = 0;
    var v = magnitude;
    while (v != 0) : (v >>= 8) mag_len += 1;
    var buf: [9]u8 = undefined;
    std.mem.writeInt(i64, buf[1..9], n, .big);
    var start: usize = 9 - mag_len;
    if (buf[start] & 0x80 == 0) {
        start -= 1;
        buf[start] = 0xff;
    }
    return encodeBytes(arena, out, tag, buf[start..]);
}

/// `beam_asm:encode1/2` — a byte-counted value (2 to 8 bytes inline, more
/// behind a `u`-encoded count).
fn encodeBytes(arena: std.mem.Allocator, out: *Bytes, tag: Tag, bytes: []const u8) Error!void {
    const t: u8 = @intFromEnum(tag);
    std.debug.assert(bytes.len >= 2);
    if (bytes.len <= 8) {
        try out.append(arena, @as(u8, @intCast((bytes.len - 2) << 5)) | 0b0001_1000 | t);
    } else {
        try out.append(arena, 0b1111_1000 | t);
        try encodeUnsigned(arena, out, .u, bytes.len - 9);
    }
    return out.appendSlice(arena, bytes);
}

fn encodeSigned(arena: std.mem.Allocator, out: *Bytes, tag: Tag, n: i64) Error!void {
    if (n < 0) return encodeNegative(arena, out, tag, n);
    return encodeUnsigned(arena, out, tag, @intCast(n));
}

// ── the assembler ─────────────────────────────────────────────────────────────

const Import = struct { module: u32, function: u32, arity: u32 };
const LineItem = struct { fname: u32, line: u32 };
const Lambda = struct { label: u32, num_free: u32 };

const Assembler = struct {
    arena: std.mem.Allocator,
    module: Module,

    atoms: std.ArrayListUnmanaged([]const u8) = .empty,
    atom_index: std.StringHashMapUnmanaged(u32) = .empty,
    imports: std.ArrayListUnmanaged(Import) = .empty,
    literals: std.ArrayListUnmanaged([]const u8) = .empty,
    lines: std.ArrayListUnmanaged(LineItem) = .empty,
    line_instrs: u32 = 0,
    lambdas: std.ArrayListUnmanaged(Lambda) = .empty,
    labels: std.AutoHashMapUnmanaged(u32, void) = .empty,
    label_refs: std.ArrayListUnmanaged(u32) = .empty,
    highest_opcode: u8 = 0,
    code: Bytes = .empty,

    fn run(self: *Assembler, out_alloc: std.mem.Allocator) Error![]u8 {
        const module = self.module;
        if (module.functions.len == 0) return error.NoFunctions;
        // Index 1 is the module atom.
        _ = try self.atom(module.name);
        try self.collectLabels();

        for (module.functions) |f| {
            for (f.code) |ins| try self.instr(ins);
        }
        try self.instr(Instr.of(.int_code_end, &.{}));
        for (self.label_refs.items) |l| {
            if (!self.labels.contains(l)) return error.UndefinedLabel;
        }
        return self.build(out_alloc);
    }

    fn collectLabels(self: *Assembler) Error!void {
        for (self.module.functions) |f| {
            var has_entry = false;
            for (f.code) |ins| {
                if (ins.op != .label) continue;
                if (ins.args.len != 1 or ins.args[0] != .u) return error.ArityMismatch;
                const n: u32 = @intCast(ins.args[0].u);
                if (n == 0 or self.labels.contains(n)) return error.DuplicateLabel;
                try self.labels.put(self.arena, n, {});
                if (n == f.entry) has_entry = true;
            }
            if (!has_entry) return error.EntryIsNotALabel;
        }
    }

    fn labelCount(self: *Assembler) u32 {
        var max: u32 = 0;
        var it = self.labels.keyIterator();
        while (it.next()) |k| max = @max(max, k.*);
        return max + 1;
    }

    // ── tables ────────────────────────────────────────────────────────────────

    fn atom(self: *Assembler, name: []const u8) Error!u32 {
        if (name.len == 0 or name.len > 255) return error.InvalidAtom;
        if (self.atom_index.get(name)) |i| return i;
        try self.atoms.append(self.arena, name);
        const index: u32 = @intCast(self.atoms.items.len);
        try self.atom_index.put(self.arena, name, index);
        return index;
    }

    fn import(self: *Assembler, ext: ExtFunc) Error!u32 {
        const row: Import = .{
            .module = try self.atom(ext.module),
            .function = try self.atom(ext.function),
            .arity = ext.arity,
        };
        for (self.imports.items, 0..) |r, i| {
            if (r.module == row.module and r.function == row.function and r.arity == row.arity) return @intCast(i);
        }
        try self.imports.append(self.arena, row);
        return @intCast(self.imports.items.len - 1);
    }

    fn literal(self: *Assembler, term: Term) Error!u32 {
        const bytes = try etf.encode(self.arena, term);
        for (self.literals.items, 0..) |l, i| {
            if (std.mem.eql(u8, l, bytes)) return @intCast(i);
        }
        try self.literals.append(self.arena, bytes);
        return @intCast(self.literals.items.len - 1);
    }

    fn line(self: *Assembler, n: u32) Error!u32 {
        self.line_instrs += 1;
        if (n == 0) return 0;
        const item: LineItem = .{ .fname = if (self.module.source_file != null) 1 else 0, .line = n };
        for (self.lines.items, 0..) |l, i| {
            if (l.fname == item.fname and l.line == item.line) return @intCast(i + 1);
        }
        try self.lines.append(self.arena, item);
        return @intCast(self.lines.items.len);
    }

    fn lambda(self: *Assembler, label: u32, num_free: u32) Error!u32 {
        for (self.lambdas.items, 0..) |l, i| {
            if (l.label == label) return @intCast(i);
        }
        try self.lambdas.append(self.arena, .{ .label = label, .num_free = num_free });
        return @intCast(self.lambdas.items.len - 1);
    }

    // ── code ──────────────────────────────────────────────────────────────────

    fn instr(self: *Assembler, ins: Instr) Error!void {
        const info = ins.op.info();
        if (!ins.op.emittable()) return error.OpcodeNotEmittable;
        if (ins.args.len != info.arity) return error.ArityMismatch;
        if (ins.op == .line and ins.args[0] != .line) return error.LineOperand;

        const number: u8 = @intFromEnum(ins.op);
        self.highest_opcode = @max(self.highest_opcode, number);
        try self.code.append(self.arena, number);

        for (ins.args, 0..) |a, i| {
            // `make_fun3`'s first operand is the fun's entry label; the loader
            // wants the `FunT` index, which the environment size completes.
            if (ins.op == .make_fun3 and i == 0) {
                if (a != .f or ins.args[2] != .list) return error.ArityMismatch;
                const index = try self.lambda(a.f, @intCast(ins.args[2].list.len));
                try encodeUnsigned(self.arena, &self.code, .u, index);
                continue;
            }
            try self.arg(a, ins.op == .line);
        }
    }

    fn arg(self: *Assembler, a: Arg, in_line: bool) Error!void {
        const arena = self.arena;
        const out = &self.code;
        switch (a) {
            .u => |n| try encodeUnsigned(arena, out, .u, n),
            .i => |n| try encodeSigned(arena, out, .i, n),
            .atom => |name| try encodeUnsigned(arena, out, .a, try self.atom(name)),
            .nil => try encodeUnsigned(arena, out, .a, 0),
            .x => |n| try encodeUnsigned(arena, out, .x, n),
            .y => |n| try encodeUnsigned(arena, out, .y, n),
            .f => |n| {
                if (n != 0) try self.label_refs.append(arena, n);
                try encodeUnsigned(arena, out, .f, n);
            },
            .literal => |t| try self.literalArg(t),
            .ext => |e| try encodeUnsigned(arena, out, .u, try self.import(e)),
            .list => |items| {
                try encodeUnsigned(arena, out, .z, 1);
                try encodeUnsigned(arena, out, .u, items.len);
                for (items) |item| try self.arg(item, false);
            },
            .alloc => |al| {
                try encodeUnsigned(arena, out, .z, 3);
                try encodeUnsigned(arena, out, .u, 3);
                const pairs = [_][2]u32{ .{ 0, al.words }, .{ 1, al.floats }, .{ 2, al.funs } };
                for (pairs) |p| {
                    try encodeUnsigned(arena, out, .u, p[0]);
                    try encodeUnsigned(arena, out, .u, p[1]);
                }
            },
            .line => |n| {
                if (!in_line) return error.LineOperand;
                try encodeUnsigned(arena, out, .u, try self.line(n));
            },
        }
    }

    /// `{literal, T}` with `beam_asm`'s folding: `[]` is the atom table's
    /// index 0, an atom is an atom, an integer is an `i`; everything else
    /// (binaries, floats, non-empty lists, tuples, maps) goes to `LitT`.
    fn literalArg(self: *Assembler, t: Term) Error!void {
        const arena = self.arena;
        const out = &self.code;
        switch (t) {
            .nil => try encodeUnsigned(arena, out, .a, 0),
            .list => |items| if (items.len == 0) {
                try encodeUnsigned(arena, out, .a, 0);
            } else {
                try self.litRef(t);
            },
            .atom => |name| try encodeUnsigned(arena, out, .a, try self.atom(name)),
            .boolean => |b| try encodeUnsigned(arena, out, .a, try self.atom(if (b) "true" else "false")),
            .integer => |n| try encodeSigned(arena, out, .i, n),
            .binary, .float, .tuple, .map => try self.litRef(t),
        }
    }

    fn litRef(self: *Assembler, t: Term) Error!void {
        try encodeUnsigned(self.arena, &self.code, .z, 4);
        try encodeUnsigned(self.arena, &self.code, .u, try self.literal(t));
    }

    // ── chunks ────────────────────────────────────────────────────────────────

    fn build(self: *Assembler, out_alloc: std.mem.Allocator) Error![]u8 {
        const arena = self.arena;
        var chunks: Bytes = .empty;

        // AtU8: <count> then <u8 len><utf-8 bytes> per atom.
        {
            var body: Bytes = .empty;
            try putU32(arena, &body, @intCast(self.atoms.items.len));
            for (self.atoms.items) |name| {
                try body.append(arena, @intCast(name.len));
                try body.appendSlice(arena, name);
            }
            try chunk(arena, &chunks, "AtU8", body.items);
        }
        // Code: the 16-byte sub-header, then the stream (already ends in int_code_end).
        {
            var body: Bytes = .empty;
            try putU32(arena, &body, 16);
            try putU32(arena, &body, opcodes.format_number);
            try putU32(arena, &body, @max(self.highest_opcode, opcodes.opcode_max)); // the version stamp
            try putU32(arena, &body, self.labelCount());
            try putU32(arena, &body, @intCast(self.module.functions.len));
            try body.appendSlice(arena, self.code.items);
            try chunk(arena, &chunks, "Code", body.items);
        }
        // StrT: no `bs_put_string` is ever emitted; the (required) table is empty.
        try chunk(arena, &chunks, "StrT", "");
        // ImpT.
        {
            var body: Bytes = .empty;
            try putU32(arena, &body, @intCast(self.imports.items.len));
            for (self.imports.items) |r| {
                try putU32(arena, &body, r.module);
                try putU32(arena, &body, r.function);
                try putU32(arena, &body, r.arity);
            }
            try chunk(arena, &chunks, "ImpT", body.items);
        }
        // ExpT.
        {
            var body: Bytes = .empty;
            var count: u32 = 0;
            for (self.module.functions) |f| count += @intFromBool(f.exported);
            try putU32(arena, &body, count);
            for (self.module.functions) |f| {
                if (!f.exported) continue;
                try putU32(arena, &body, try self.atom(f.name));
                try putU32(arena, &body, f.arity);
                try putU32(arena, &body, f.entry);
            }
            try chunk(arena, &chunks, "ExpT", body.items);
        }
        // FunT — only when a fun is made, as `erlc` does.
        if (self.lambdas.items.len > 0) {
            var body: Bytes = .empty;
            try putU32(arena, &body, @intCast(self.lambdas.items.len));
            const old_uniq: u32 = @truncate(std.hash.Wyhash.hash(0, self.code.items) & 0x07FF_FFFF);
            for (self.lambdas.items, 0..) |l, index| {
                const f = for (self.module.functions) |f| {
                    if (f.entry == l.label) break f;
                } else return error.FunEntryIsNotAFunction;
                try putU32(arena, &body, try self.atom(f.name));
                try putU32(arena, &body, f.arity);
                try putU32(arena, &body, l.label);
                try putU32(arena, &body, @intCast(index));
                try putU32(arena, &body, l.num_free);
                try putU32(arena, &body, old_uniq);
            }
            try chunk(arena, &chunks, "FunT", body.items);
        }
        // LitT — only when there is a literal, as `erlc` does.
        if (self.literals.items.len > 0) {
            var table: Bytes = .empty;
            try putU32(arena, &table, @intCast(self.literals.items.len));
            for (self.literals.items) |l| {
                try putU32(arena, &table, @intCast(l.len));
                try table.appendSlice(arena, l);
            }
            var body: Bytes = .empty;
            try putU32(arena, &body, @intCast(table.items.len));
            try zlibStored(arena, &body, table.items);
            try chunk(arena, &chunks, "LitT", body.items);
        }
        // Line.
        {
            var body: Bytes = .empty;
            try putU32(arena, &body, 0); // version
            try putU32(arena, &body, 0); // flags
            try putU32(arena, &body, self.line_instrs);
            try putU32(arena, &body, @intCast(self.lines.items.len));
            try putU32(arena, &body, if (self.module.source_file != null) 1 else 0);
            var fname: u32 = 0;
            for (self.lines.items) |item| {
                if (item.fname != fname) {
                    try encodeUnsigned(arena, &body, .a, item.fname);
                    fname = item.fname;
                }
                try encodeUnsigned(arena, &body, .i, item.line);
            }
            if (self.module.source_file) |name| {
                var len: [2]u8 = undefined;
                std.mem.writeInt(u16, &len, @intCast(name.len), .big);
                try body.appendSlice(arena, &len);
                try body.appendSlice(arena, name);
            }
            try chunk(arena, &chunks, "Line", body.items);
        }

        var file: Bytes = .empty;
        try file.appendSlice(arena, "FOR1");
        try putU32(arena, &file, @intCast(4 + chunks.items.len));
        try file.appendSlice(arena, "BEAM");
        try file.appendSlice(arena, chunks.items);
        return out_alloc.dupe(u8, file.items);
    }
};

fn putU32(arena: std.mem.Allocator, out: *Bytes, n: u32) Error!void {
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, n, .big);
    try out.appendSlice(arena, &buf);
}

/// `<id><u32 len><body><pad to 4>`; the length is the unpadded size.
fn chunk(arena: std.mem.Allocator, out: *Bytes, id: *const [4]u8, body: []const u8) Error!void {
    try out.appendSlice(arena, id);
    try putU32(arena, out, @intCast(body.len));
    try out.appendSlice(arena, body);
    const rem = body.len % 4;
    if (rem != 0) try out.appendNTimes(arena, 0, 4 - rem);
}

/// A zlib stream (RFC 1950) of stored deflate blocks (RFC 1951, `BTYPE=00`):
/// no compression, every inflater accepts it, no dependency.
fn zlibStored(arena: std.mem.Allocator, out: *Bytes, data: []const u8) Error!void {
    try out.appendSlice(arena, &.{ 0x78, 0x01 }); // CMF: deflate, 32K window; FLG: no dict, check 0
    var rest = data;
    while (true) {
        const take: usize = @min(rest.len, 0xFFFF);
        const final = take == rest.len;
        try out.append(arena, @intFromBool(final));
        var len: [2]u8 = undefined;
        std.mem.writeInt(u16, &len, @intCast(take), .little);
        try out.appendSlice(arena, &len);
        std.mem.writeInt(u16, &len, @as(u16, @intCast(take)) ^ 0xFFFF, .little);
        try out.appendSlice(arena, &len);
        try out.appendSlice(arena, rest[0..take]);
        rest = rest[take..];
        if (final) break;
    }
    var adler: [4]u8 = undefined;
    std.mem.writeInt(u32, &adler, std.hash.Adler32.hash(data), .big);
    try out.appendSlice(arena, &adler);
}

// ── tests ─────────────────────────────────────────────────────────────────────
//
// The encoder is pinned to `beam_asm:encode/2` by byte vectors; the container
// is validated by OTP itself: `beam_lib:info/1` + `beam_lib:chunks/2` decode
// the tables, `code:load_binary/3` runs the loader's checks, and the module's
// `main` answers. `erl` is spawned once per test the way the CI gate expects
// it (OTP 28 there, 29 here).

fn expectEncoded(expected: []const u8, tag: Tag, n: i64) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var out: Bytes = .empty;
    try encodeSigned(arena_state.allocator(), &out, tag, n);
    try std.testing.expectEqualSlices(u8, expected, out.items);
}

test "beam_file: compact term encoding matches beam_asm:encode/2" {
    // Read off `beam_asm:encode(Tag, N)` on OTP 29.
    try expectEncoded(&.{0x00}, .u, 0);
    try expectEncoded(&.{0x12}, .a, 1);
    try expectEncoded(&.{0x03}, .x, 0);
    try expectEncoded(&.{ 0x09, 0x28 }, .i, 40);
    try expectEncoded(&.{ 0x19, 0xFF, 0xFF }, .i, -1);
    try expectEncoded(&.{ 0x18, 0x08, 0x00 }, .u, 0x800);
    try expectEncoded(&.{ 0xD8, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF }, .u, std.math.maxInt(i64));
    try expectEncoded(&.{ 0x39, 0xFF, 0x7F, 0xFF }, .i, -0x8001);
}

test "beam_file: a stored zlib stream carries its adler32" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var out: Bytes = .empty;
    try zlibStored(arena_state.allocator(), &out, "abc");
    try std.testing.expectEqualSlices(u8, &.{ 0x78, 0x01, 0x01, 3, 0, 0xFC, 0xFF, 'a', 'b', 'c', 0x02, 0x4D, 0x01, 0x27 }, out.items);
}

/// `-module(t). -export([main/0]). main() -> ok.` in the instruction model.
fn minimalModule() Module {
    const S = struct {
        const code = [_]Instr{
            Instr.of(.label, &.{Arg.uint(1)}),
            Instr.of(.func_info, &.{ Arg.atomOf("t"), Arg.atomOf("main"), Arg.uint(0) }),
            Instr.of(.label, &.{Arg.uint(2)}),
            Instr.of(.move, &.{ Arg.atomOf("ok"), Arg.xr(0) }),
            Instr.of(.@"return", &.{}),
        };
        const functions = [_]Function{.{ .name = "main", .arity = 0, .entry = 2, .code = &code }};
    };
    return .{ .name = "t", .functions = &S.functions };
}

/// `add(A, B) -> A + B. main() -> {add(40, 2), <<"hello">>}. boom() -> erlang:error(boom).`
/// — a compound literal, two imports (a gc_bif and a call_ext) and line
/// information naming `t2.bp`.
fn literalImportLineModule() Module {
    const S = struct {
        const m = "bp_beam_file_t2";
        const add = [_]Instr{
            Instr.of(.label, &.{Arg.uint(1)}),
            Instr.of(.line, &.{Arg.loc(3)}),
            Instr.of(.func_info, &.{ Arg.atomOf(m), Arg.atomOf("add"), Arg.uint(2) }),
            Instr.of(.label, &.{Arg.uint(2)}),
            Instr.of(.gc_bif2, &.{ Arg.lbl(0), Arg.uint(2), Arg.extFn("erlang", "+", 2), Arg.xr(0), Arg.xr(1), Arg.xr(0) }),
            Instr.of(.@"return", &.{}),
        };
        const main = [_]Instr{
            Instr.of(.label, &.{Arg.uint(3)}),
            Instr.of(.line, &.{Arg.loc(5)}),
            Instr.of(.func_info, &.{ Arg.atomOf(m), Arg.atomOf("main"), Arg.uint(0) }),
            Instr.of(.label, &.{Arg.uint(4)}),
            Instr.of(.allocate, &.{ Arg.uint(0), Arg.uint(0) }),
            Instr.of(.move, &.{ Arg.int(40), Arg.xr(0) }),
            Instr.of(.move, &.{ Arg.int(2), Arg.xr(1) }),
            Instr.of(.call, &.{ Arg.uint(2), Arg.lbl(2) }),
            Instr.of(.test_heap, &.{ Arg.uint(3), Arg.uint(1) }),
            Instr.of(.put_tuple2, &.{ Arg.xr(0), Arg.listOf(&.{ Arg.xr(0), Arg.lit(Term.str("hello")) }) }),
            Instr.of(.deallocate, &.{Arg.uint(0)}),
            Instr.of(.@"return", &.{}),
        };
        const boom = [_]Instr{
            Instr.of(.label, &.{Arg.uint(5)}),
            Instr.of(.line, &.{Arg.loc(7)}),
            Instr.of(.func_info, &.{ Arg.atomOf(m), Arg.atomOf("boom"), Arg.uint(0) }),
            Instr.of(.label, &.{Arg.uint(6)}),
            Instr.of(.line, &.{Arg.loc(7)}),
            Instr.of(.move, &.{ Arg.atomOf("boom"), Arg.xr(0) }),
            Instr.of(.call_ext_only, &.{ Arg.uint(1), Arg.extFn("erlang", "error", 1) }),
        };
        const functions = [_]Function{
            .{ .name = "add", .arity = 2, .entry = 2, .exported = false, .code = &add },
            .{ .name = "main", .arity = 0, .entry = 4, .code = &main },
            .{ .name = "boom", .arity = 0, .entry = 6, .code = &boom },
        };
    };
    return .{ .name = S.m, .functions = &S.functions, .source_file = "t2.bp" };
}

/// Write `beam` under the test tmp dir and run `erl -noshell -eval <eval>`
/// with `Path` bound to it; the eval's stdout comes back (caller owns it).
fn runErl(tmp: *std.testing.TmpDir, beam: []const u8, eval: []const u8) ![]u8 {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    try tmp.dir.writeFile(io, .{ .sub_path = "m.beam", .data = beam });
    const path = try std.fs.path.join(alloc, &.{ ".zig-cache", "tmp", &tmp.sub_path, "m.beam" });
    defer alloc.free(path);
    const script = try std.fmt.allocPrint(alloc, "Path = \"{s}\", {{ok, B}} = file:read_file(Path), {s}, halt().", .{ path, eval });
    defer alloc.free(script);

    const result = try std.process.run(alloc, io, .{
        .argv = &.{ "erl", "-noshell", "-eval", script },
        .timeout = .{ .duration = .{ .raw = .{ .nanoseconds = 60 * std.time.ns_per_s }, .clock = .real } },
    });
    defer alloc.free(result.stderr);
    errdefer alloc.free(result.stdout);
    if (result.term != .exited or result.term.exited != 0) {
        std.debug.print("\nerl failed:\n{s}\n{s}\n", .{ result.stdout, result.stderr });
        return error.ErlFailed;
    }
    return result.stdout;
}

fn expectLine(stdout: []const u8, expected: []const u8) !void {
    var it = std.mem.splitScalar(u8, stdout, '\n');
    while (it.next()) |l| {
        if (std.mem.eql(u8, l, expected)) return;
    }
    std.debug.print("\nexpected line:\n  {s}\nin erl output:\n{s}\n", .{ expected, stdout });
    return error.TestExpectedLine;
}

test "beam_file: a minimal module round-trips through beam_lib, code:load_binary and a call" {
    const beam = try assemble(std.testing.allocator, minimalModule());
    defer std.testing.allocator.free(beam);
    try std.testing.expectEqualSlices(u8, "FOR1", beam[0..4]);
    try std.testing.expectEqual(beam.len - 8, std.mem.readInt(u32, beam[4..8], .big));
    try std.testing.expectEqualSlices(u8, "BEAM", beam[8..12]);
    // The version stamp: OTP 28's highest opcode, whatever the module uses.
    const code = try codeChunk(beam);
    try std.testing.expectEqual(@as(u32, opcodes.opcode_max), std.mem.readInt(u32, beam[code.len_at + 4 + 8 ..][0..4], .big));

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const out = try runErl(&tmp, beam,
        \\Info = beam_lib:info(B),
        \\{module, Mod} = lists:keyfind(module, 1, Info),
        \\{chunks, Chunks} = lists:keyfind(chunks, 1, Info),
        \\{ok, {Mod, Tables}} = beam_lib:chunks(B, [atoms, imports, labeled_exports]),
        \\io:format("module=~w~nchunks=~500p~n", [Mod, [Id || {Id, _, _} <- Chunks]]),
        \\[io:format("~w=~500p~n", [K, lists:sort(V)]) || {K, V} <- Tables],
        \\io:format("load=~w~n", [code:load_binary(Mod, "", B)]),
        \\io:format("main=~w~n", [Mod:main()])
    );
    defer std.testing.allocator.free(out);
    try expectLine(out, "module=t");
    try expectLine(out, "chunks=[\"AtU8\",\"Code\",\"StrT\",\"ImpT\",\"ExpT\",\"Line\"]");
    try expectLine(out, "atoms=[{1,t},{2,main},{3,ok}]");
    try expectLine(out, "imports=[]");
    try expectLine(out, "labeled_exports=[{main,0,2}]");
    try expectLine(out, "load={module,t}");
    try expectLine(out, "main=ok");
}

test "beam_file: a literal, two imports and a Line chunk load, run, and name the .bp in a stack trace" {
    const beam = try assemble(std.testing.allocator, literalImportLineModule());
    defer std.testing.allocator.free(beam);

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const out = try runErl(&tmp, beam,
        \\{chunks, Chunks} = lists:keyfind(chunks, 1, beam_lib:info(B)),
        \\{ok, {Mod, Tables}} = beam_lib:chunks(B, [imports, labeled_exports, literals]),
        \\io:format("chunks=~500p~n", [[Id || {Id, _, _} <- Chunks]]),
        \\[io:format("~w=~500p~n", [K, lists:sort(V)]) || {K, V} <- Tables],
        \\{module, Mod} = code:load_binary(Mod, "", B),
        \\io:format("main=~500p~n", [Mod:main()]),
        \\try Mod:boom() catch error:boom:St -> io:format("frame=~500p~n", [lists:keyfind(Mod, 1, St)]) end
    );
    defer std.testing.allocator.free(out);
    try expectLine(out, "chunks=[\"AtU8\",\"Code\",\"StrT\",\"ImpT\",\"ExpT\",\"LitT\",\"Line\"]");
    try expectLine(out, "imports=[{erlang,'+',2},{erlang,error,1}]");
    try expectLine(out, "labeled_exports=[{boom,0,6},{main,0,4}]");
    try expectLine(out, "literals=[{0,<<\"hello\">>}]");
    try expectLine(out, "main={42,<<\"hello\">>}");
    try expectLine(out, "frame={bp_beam_file_t2,boom,0,[{file,\"t2.bp\"},{line,7}]}");
}

/// Byte offset of the `Code` chunk's length word and of its body end.
fn codeChunk(beam: []const u8) !struct { len_at: usize, body_end: usize } {
    var p: usize = 12;
    while (p + 8 <= beam.len) {
        const len = std.mem.readInt(u32, beam[p + 4 ..][0..4], .big);
        if (std.mem.eql(u8, beam[p..][0..4], "Code")) return .{ .len_at = p + 4, .body_end = p + 8 + len };
        p += 8 + ((len + 3) / 4) * 4;
    }
    return error.NoCodeChunk;
}

test "beam_file: a byte-flipped file is rejected by beam_lib and by the loader" {
    const alloc = std.testing.allocator;
    const beam = try assemble(alloc, minimalModule());
    defer alloc.free(beam);
    const code = try codeChunk(beam);

    // Three flips, each one byte: the form id (`beam_lib:info/1` refuses the
    // container), the atom chunk's id (`beam_lib:chunks/2` misses the table it
    // was asked for) and the `return` before `int_code_end` (the container is
    // fine, opcode 255 is not — the loader refuses).
    const bad_magic = try alloc.dupe(u8, beam);
    defer alloc.free(bad_magic);
    bad_magic[11] = 'N';
    const bad_atoms = try alloc.dupe(u8, beam);
    defer alloc.free(bad_atoms);
    try std.testing.expectEqualSlices(u8, "AtU8", bad_atoms[12..16]);
    bad_atoms[15] = '9';
    const bad_opcode = try alloc.dupe(u8, beam);
    defer alloc.free(bad_opcode);
    try std.testing.expectEqual(@as(u8, @intFromEnum(Op.int_code_end)), bad_opcode[code.body_end - 1]);
    try std.testing.expectEqual(@as(u8, @intFromEnum(Op.@"return")), bad_opcode[code.body_end - 2]);
    bad_opcode[code.body_end - 2] = 255;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;
    try tmp.dir.writeFile(io, .{ .sub_path = "bad_atoms.beam", .data = bad_atoms });
    try tmp.dir.writeFile(io, .{ .sub_path = "bad_opcode.beam", .data = bad_opcode });
    const out = try runErl(&tmp, bad_magic,
        \\Dir = filename:dirname(Path),
        \\Verdict = fun(Name, Bin) ->
        \\    Info = case beam_lib:info(Bin) of {error, beam_lib, _} -> refused; L when is_list(L) -> ok end,
        \\    Atoms = case beam_lib:chunks(Bin, [atoms]) of {error, beam_lib, _} -> refused; {ok, _} -> ok end,
        \\    io:format("~s info=~w atoms=~w load=~w~n", [Name, Info, Atoms, code:load_binary(t, "", Bin)])
        \\end,
        \\Verdict("magic", B),
        \\[begin {ok, Bin} = file:read_file(filename:join(Dir, F)), Verdict(F, Bin) end || F <- ["bad_atoms.beam", "bad_opcode.beam"]]
    );
    defer alloc.free(out);
    try expectLine(out, "magic info=refused atoms=refused load={error,badfile}");
    try expectLine(out, "bad_atoms.beam info=refused atoms=refused load={error,badfile}");
    try expectLine(out, "bad_opcode.beam info=ok atoms=ok load={error,badfile}");
}

test "beam_file: the model is refused outside decision 86's subset and on a bad label" {
    const S = struct {
        const newer = [_]Instr{
            Instr.of(.label, &.{Arg.uint(1)}),
            Instr.of(.func_info, &.{ Arg.atomOf("t"), Arg.atomOf("main"), Arg.uint(0) }),
            Instr.of(.label, &.{Arg.uint(2)}),
            Instr.of(.badrecord, &.{Arg.xr(0)}), // OTP 25
        };
        const dangling = [_]Instr{
            Instr.of(.label, &.{Arg.uint(1)}),
            Instr.of(.func_info, &.{ Arg.atomOf("t"), Arg.atomOf("main"), Arg.uint(0) }),
            Instr.of(.label, &.{Arg.uint(2)}),
            Instr.of(.jump, &.{Arg.lbl(9)}),
        };
        const short = [_]Instr{
            Instr.of(.label, &.{Arg.uint(1)}),
            Instr.of(.func_info, &.{ Arg.atomOf("t"), Arg.atomOf("main") }),
            Instr.of(.label, &.{Arg.uint(2)}),
        };
    };
    const cases = [_]struct { code: []const Instr, err: anyerror }{
        .{ .code = &S.newer, .err = error.OpcodeNotEmittable },
        .{ .code = &S.dangling, .err = error.UndefinedLabel },
        .{ .code = &S.short, .err = error.ArityMismatch },
    };
    for (cases) |c| {
        const functions = [_]Function{.{ .name = "main", .arity = 0, .entry = 2, .code = c.code }};
        try std.testing.expectError(c.err, assemble(std.testing.allocator, .{ .name = "t", .functions = &functions }));
    }
    try std.testing.expectError(error.NoFunctions, assemble(std.testing.allocator, .{ .name = "t", .functions = &.{} }));
}
