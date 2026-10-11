//! The `.beam` container: an IFF file `FOR1 <size> BEAM` of 4-byte-aligned
//! chunks. This reads the ones a translation needs — `AtU8` (atoms), `Code`,
//! `ImpT` (imports), `ExpT` (exports), `LitT` (literals, zlib) — and skips
//! the rest (`StrT`, `Line`, `FunT`, `Attr`, `CInf`, `Dbgi`, `Docs` …).
const std = @import("std");

pub const Error = error{ OutOfMemory, BadBeam };

pub const Import = struct { module: []const u8, function: []const u8, arity: u32 };
pub const Export = struct { function: []const u8, arity: u32, label: u32 };

/// A literal of `LitT`, decoded from its external term format — the shapes a
/// translation can materialise; anything else is `other`, refused where an
/// instruction uses it.
pub const Literal = union(enum) {
    binary: []const u8,
    atom: []const u8,
    int: i64,
    nil,
    /// The ETF tag of a literal outside the decoded shapes.
    other: u8,
};

pub const Beam = struct {
    /// `atoms[0]` is the module's own name (atom index 1).
    atoms: []const []const u8,
    /// The `Code` chunk past its header: the instruction stream.
    code: []const u8,
    label_count: u32,
    function_count: u32,
    imports: []const Import,
    exports: []const Export,
    literals: []const Literal,

    pub fn moduleName(b: Beam) []const u8 {
        return b.atoms[0];
    }

    /// Atom `index` (1-based, as the code refers to it).
    pub fn atom(b: Beam, index: usize) Error![]const u8 {
        if (index == 0 or index > b.atoms.len) return error.BadBeam;
        return b.atoms[index - 1];
    }
};

fn be32(bytes: []const u8, at: usize) Error!u32 {
    if (at + 4 > bytes.len) return error.BadBeam;
    return std.mem.readInt(u32, bytes[at..][0..4], .big);
}

/// Read the chunks of `bytes`. Slices borrow `bytes` except the decompressed
/// literals, which `arena` owns.
pub fn read(arena: std.mem.Allocator, bytes: []const u8) Error!Beam {
    if (bytes.len < 12 or !std.mem.eql(u8, bytes[0..4], "FOR1") or !std.mem.eql(u8, bytes[8..12], "BEAM")) return error.BadBeam;
    const end = @min(bytes.len, 8 + @as(usize, try be32(bytes, 4)));
    var out: Beam = .{ .atoms = &.{}, .code = &.{}, .label_count = 0, .function_count = 0, .imports = &.{}, .exports = &.{}, .literals = &.{} };
    var have_atoms = false;
    var have_code = false;
    var at: usize = 12;
    while (at + 8 <= end) {
        const id = bytes[at..][0..4];
        const size = try be32(bytes, at + 4);
        const body_at = at + 8;
        if (body_at + size > end) return error.BadBeam;
        const body = bytes[body_at..][0..size];
        if (std.mem.eql(u8, id, "AtU8")) {
            out.atoms = try readAtoms(arena, body);
            have_atoms = true;
        } else if (std.mem.eql(u8, id, "Code")) {
            const sub = try be32(body, 0);
            if (4 + sub > body.len or sub < 16) return error.BadBeam;
            out.label_count = try be32(body, 12);
            out.function_count = try be32(body, 16);
            out.code = body[4 + sub ..];
            have_code = true;
        } else if (std.mem.eql(u8, id, "LitT")) {
            out.literals = try readLiterals(arena, body);
        }
        at = body_at + std.mem.alignForward(usize, size, 4);
    }
    if (!have_atoms or !have_code or out.atoms.len == 0) return error.BadBeam;
    // Imports and exports name atoms: read once the atom table is known.
    at = 12;
    while (at + 8 <= end) {
        const id = bytes[at..][0..4];
        const size = try be32(bytes, at + 4);
        const body = bytes[at + 8 ..][0..size];
        if (std.mem.eql(u8, id, "ImpT")) {
            const n = try be32(body, 0);
            const imports = try arena.alloc(Import, n);
            for (imports, 0..) |*imp, i| imp.* = .{
                .module = try out.atom(try be32(body, 4 + i * 12)),
                .function = try out.atom(try be32(body, 8 + i * 12)),
                .arity = try be32(body, 12 + i * 12),
            };
            out.imports = imports;
        } else if (std.mem.eql(u8, id, "ExpT")) {
            const n = try be32(body, 0);
            const exports = try arena.alloc(Export, n);
            for (exports, 0..) |*e, i| e.* = .{
                .function = try out.atom(try be32(body, 4 + i * 12)),
                .arity = try be32(body, 8 + i * 12),
                .label = try be32(body, 12 + i * 12),
            };
            out.exports = exports;
        }
        at = at + 8 + std.mem.alignForward(usize, size, 4);
    }
    return out;
}

fn readAtoms(arena: std.mem.Allocator, body: []const u8) Error![]const []const u8 {
    const n = try be32(body, 0);
    // OTP 28's compact form (a negative count) is not what the compiler's
    // assembler writes; refused as a malformed file rather than misread.
    if (n > body.len) return error.BadBeam;
    const atoms = try arena.alloc([]const u8, n);
    var at: usize = 4;
    for (atoms) |*a| {
        if (at >= body.len) return error.BadBeam;
        const len = body[at];
        at += 1;
        if (at + len > body.len) return error.BadBeam;
        a.* = body[at..][0..len];
        at += len;
    }
    return atoms;
}

fn readLiterals(arena: std.mem.Allocator, body: []const u8) Error![]const Literal {
    const raw_len = try be32(body, 0);
    const raw = try arena.alloc(u8, raw_len);
    var in: std.Io.Reader = .fixed(body[4..]);
    const window = try arena.alloc(u8, std.compress.flate.max_window_len);
    var z = std.compress.flate.Decompress.init(&in, .zlib, window);
    z.reader.readSliceAll(raw) catch return error.BadBeam;
    const n = try be32(raw, 0);
    const lits = try arena.alloc(Literal, n);
    var at: usize = 4;
    for (lits) |*l| {
        const size = try be32(raw, at);
        at += 4;
        if (at + size > raw.len) return error.BadBeam;
        l.* = try decodeLiteral(raw[at..][0..size]);
        at += size;
    }
    return lits;
}

/// One external-term-format literal (version byte 131 first).
fn decodeLiteral(t: []const u8) Error!Literal {
    if (t.len < 2 or t[0] != 131) return error.BadBeam;
    const tag = t[1];
    const b = t[2..];
    return switch (tag) {
        109 => blk: { // BINARY_EXT
            const len = try be32(b, 0);
            if (4 + len > b.len) return error.BadBeam;
            break :blk .{ .binary = b[4..][0..len] };
        },
        119 => blk: { // SMALL_ATOM_UTF8_EXT
            if (b.len < 1 or 1 + b[0] > b.len) return error.BadBeam;
            break :blk .{ .atom = b[1..][0..b[0]] };
        },
        118 => blk: { // ATOM_UTF8_EXT
            if (b.len < 2) return error.BadBeam;
            const len = std.mem.readInt(u16, b[0..2], .big);
            if (2 + len > b.len) return error.BadBeam;
            break :blk .{ .atom = b[2..][0..len] };
        },
        97 => if (b.len < 1) error.BadBeam else .{ .int = b[0] }, // SMALL_INTEGER_EXT
        98 => .{ .int = @as(i32, @bitCast(try be32(b, 0))) }, // INTEGER_EXT
        106 => .nil, // NIL_EXT
        else => .{ .other = tag },
    };
}

test "read: the chunks of a cell the compiler assembled" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const b = try read(arena_state.allocator(), @embedFile("testdata/bp_cell_bang.beam"));
    try std.testing.expectEqualStrings("bp_cell_bang", b.moduleName());
    try std.testing.expectEqual(@as(u32, 1), b.function_count);
    try std.testing.expectEqual(@as(usize, 2), b.imports.len);
    try std.testing.expectEqualStrings("erlang", b.imports[0].module);
    try std.testing.expectEqualStrings("iolist_to_binary", b.imports[0].function);
    try std.testing.expectEqualStrings("error", b.imports[1].function);
    try std.testing.expectEqual(@as(usize, 1), b.exports.len);
    try std.testing.expectEqualStrings("t", b.exports[0].function);
    try std.testing.expectEqual(@as(u32, 2), b.exports[0].label);
    try std.testing.expectEqual(@as(usize, 1), b.literals.len);
    try std.testing.expectEqualStrings("!", b.literals[0].binary);
}

test "read: not a BEAM file" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    try std.testing.expectError(error.BadBeam, read(arena_state.allocator(), "FOR1\x00\x00\x00\x04JUNK"));
}

test "decodeLiteral: the decoded shapes and the rest" {
    try std.testing.expectEqualStrings("ab", (try decodeLiteral("\x83\x6d\x00\x00\x00\x02ab")).binary);
    try std.testing.expectEqualStrings("ok", (try decodeLiteral("\x83\x77\x02ok")).atom);
    try std.testing.expectEqual(@as(i64, 7), (try decodeLiteral("\x83\x61\x07")).int);
    try std.testing.expectEqual(@as(i64, -2), (try decodeLiteral("\x83\x62\xff\xff\xff\xfe")).int);
    try std.testing.expect((try decodeLiteral("\x83\x6a")) == .nil);
    try std.testing.expectEqual(@as(u8, 104), (try decodeLiteral("\x83\x68\x00")).other);
}
