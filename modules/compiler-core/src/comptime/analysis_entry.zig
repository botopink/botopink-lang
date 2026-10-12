//! The code cache's level B entry (decision 509 (1), 144 B-60): one file per
//! dependency package and target — std's one per module — holding that
//! package's analysis, read back by later invocations.
//!
//! This file is the entry's FORMAT, nothing else: where an entry lives, when it
//! is read and written, and the key it is filed under are the CLI's
//! (`compiler-cli` `analysis_store.zig`, `code_cache.closureKey`). It sits in
//! `compiler-core/src`, so every source of it is inside the compiler key's
//! backend partition (`source_stamp.partitionHashes`, decision 249): any change
//! to what an entry holds, or how, gives every entry a new key. There is no
//! version number.
//!
//! ## The container
//!
//! ```text
//! magic          8 bytes   "BPENTRY\x00"
//! key           32 bytes   the closure key the entry was written under
//! payload_len    u64 LE    the bytes after the checksum
//! checksum      32 bytes   SHA-256 of those bytes
//! payload:
//!   count        u32 LE    sections
//!   table        count × { id u32 LE, offset u64 LE, length u64 LE }
//!                          offsets from the payload's first byte
//!   sections     the bytes the table names
//! ```
//!
//! The section table is inside the checksummed bytes, so nothing of an entry
//! is read before the whole of it is proven (`unpack`). Doubt discards: a short
//! file, another magic, a length that is not the file's, a checksum that
//! differs, another key or a table that points outside the payload is
//! `error.Doubt` — the reader deletes the file and analyses again; an entry is
//! never used in part.
const std = @import("std");

/// The first eight bytes of every entry.
pub const MAGIC = "BPENTRY\x00";

/// The closure key, raw (the CLI hashes it as hex; `keyFromHex`).
pub const Key = [32]u8;

/// The sections an entry may hold: META, STRINGS, then per module its
/// ANALYSIS and its JOURNAL (what the module added to or replaced in the
/// session's registries, the default DSL and the reflection catalogue,
/// replayed in order on load), then — once a build emitted them (S4) — one
/// CODE per module: the module's own unit on the target (`CodeUnit`).
pub const SectionId = enum(u32) {
    meta = 1,
    strings = 2,
    /// One per module, in META's module order.
    analysis = 3,
    journal = 4,
    /// None, or one per module in META's module order, after every ANALYSIS
    /// and JOURNAL. Self-contained (its own strings), so a build adds it to
    /// an entry it read without encoding the rest again.
    code = 5,
    _,
};

pub const Section = struct {
    id: SectionId,
    bytes: []const u8,
};

const HEADER_LEN = MAGIC.len + 32 + 8 + 32;
const TABLE_ROW_LEN = 4 + 8 + 8;

/// The entry `sections` make under `key`, allocated with `gpa`.
pub fn pack(gpa: std.mem.Allocator, key: Key, sections: []const Section) ![]u8 {
    var payload_len: usize = 4 + sections.len * TABLE_ROW_LEN;
    for (sections) |s| payload_len += s.bytes.len;
    const out = try gpa.alloc(u8, HEADER_LEN + payload_len);
    errdefer gpa.free(out);

    @memcpy(out[0..MAGIC.len], MAGIC);
    @memcpy(out[MAGIC.len..][0..32], &key);
    std.mem.writeInt(u64, out[MAGIC.len + 32 ..][0..8], payload_len, .little);

    const payload = out[HEADER_LEN..];
    std.mem.writeInt(u32, payload[0..4], @intCast(sections.len), .little);
    var offset: usize = 4 + sections.len * TABLE_ROW_LEN;
    for (sections, 0..) |s, i| {
        const row = payload[4 + i * TABLE_ROW_LEN ..][0..TABLE_ROW_LEN];
        std.mem.writeInt(u32, row[0..4], @intFromEnum(s.id), .little);
        std.mem.writeInt(u64, row[4..12], offset, .little);
        std.mem.writeInt(u64, row[12..20], s.bytes.len, .little);
        @memcpy(payload[offset..][0..s.bytes.len], s.bytes);
        offset += s.bytes.len;
    }
    std.crypto.hash.sha2.Sha256.hash(payload, out[MAGIC.len + 32 + 8 ..][0..32], .{});
    return out;
}

/// Any reason an entry is not used: the reader deletes it and analyses again.
pub const Doubt = error{Doubt};

/// A proven entry: its sections, slices of the bytes `unpack` was given.
pub const Entry = struct {
    sections: []const Section,

    /// The first section of `id`, or null.
    pub fn get(self: Entry, id: SectionId) ?[]const u8 {
        for (self.sections) |s| if (s.id == id) return s.bytes;
        return null;
    }

    /// Every section of `id`, in the entry's order (ANALYSIS: one per module).
    pub fn all(self: Entry, arena: std.mem.Allocator, id: SectionId) ![]const []const u8 {
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        for (self.sections) |s| if (s.id == id) try out.append(arena, s.bytes);
        return out.items;
    }
};

/// `bytes`, a whole entry file, proven against `key` — else `error.Doubt`.
/// The section table is allocated with `arena`.
pub fn unpack(arena: std.mem.Allocator, bytes: []const u8, key: Key) (Doubt || std.mem.Allocator.Error)!Entry {
    if (bytes.len < HEADER_LEN + 4) return error.Doubt;
    if (!std.mem.eql(u8, bytes[0..MAGIC.len], MAGIC)) return error.Doubt;
    if (!std.mem.eql(u8, bytes[MAGIC.len..][0..32], &key)) return error.Doubt;
    const payload_len = std.mem.readInt(u64, bytes[MAGIC.len + 32 ..][0..8], .little);
    if (payload_len != bytes.len - HEADER_LEN) return error.Doubt;
    const payload = bytes[HEADER_LEN..];
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(payload, &digest, .{});
    if (!std.mem.eql(u8, &digest, bytes[MAGIC.len + 32 + 8 ..][0..32])) return error.Doubt;

    const count = std.mem.readInt(u32, payload[0..4], .little);
    if (count > (payload.len - 4) / TABLE_ROW_LEN) return error.Doubt;
    const sections = try arena.alloc(Section, count);
    for (sections, 0..) |*s, i| {
        const row = payload[4 + i * TABLE_ROW_LEN ..][0..TABLE_ROW_LEN];
        const offset = std.mem.readInt(u64, row[4..12], .little);
        const length = std.mem.readInt(u64, row[12..20], .little);
        if (offset > payload.len or length > payload.len - offset) return error.Doubt;
        s.* = .{ .id = @enumFromInt(std.mem.readInt(u32, row[0..4], .little)), .bytes = payload[@intCast(offset)..][0..@intCast(length)] };
    }
    return .{ .sections = sections };
}

/// The raw key a 64-hex-digit closure key spells.
pub fn keyFromHex(hex: [64]u8) Key {
    var key: Key = undefined;
    _ = std.fmt.hexToBytes(&key, &hex) catch unreachable;
    return key;
}

// ── The encoding (S1) ─────────────────────────────────────────────────────────
//
// Binary and generic over the Zig types (`@typeInfo`): every field of every
// type is written unless `skips` names it, so a field added to a type is
// stored without anyone remembering to; a type the encoder has no rule for is
// a compile error, never skipped.
//
//   bool              one byte, 0 / 1
//   int (≤ 64 bits)   LEB128; a signed one zigzagged first
//   float             its bits, little-endian
//   enum              its integer value, as an int
//   optional          one byte, then the payload when 1
//   tagged union      its tag, then the active payload
//   struct            its fields in declaration order (`skips` left out; a
//                     packed struct as its backing integer)
//   array             its elements
//   string            (a slice of u8) 1 + an index into STRINGS, each content
//                     once — or 0 and (source, offset, length) for a slice of
//                     one of the sources the binary embeds (std's prelude and
//                     modules, `embedded_sources`): it reads back as a slice of
//                     the same bytes, so a reader that asks whether a name
//                     slices into the prelude (`codegen/erlang.zig`
//                     `slicesIntoPrelude`) answers as it did live
//   pointer, slice    through the identity table: 0 (a new one: a slice's
//                     length, then the contents) or 1 + the index of the one
//                     already written at the same (address, length) for the
//                     same element type — shared AST nodes, type variables and
//                     bodies stay shared after a round trip, a cycle closes
//   ArrayList         its items (as a slice); capacity is the length on load
//   HashMap(Unmanaged), AutoHashMap, StringHashMap
//                     the count, then the entries sorted by key (`order`), so
//                     the bytes are deterministic
//   ArrayHashMap(Unmanaged)
//                     the count, then the entries in insertion order (the map
//                     is ordered: its order is data)
//
// A map whose key is a pointer other than a string cannot be sorted by
// content and is a compile error.

const comptimeMod = @import("../comptime.zig");
const infer = @import("./infer.zig");
const prelude = @import("std_prelude");

/// The sources the binary embeds, whose slices an entry writes by place: the
/// prelude's three files, then every std module's. Inside the compiler key,
/// like every other source of the binary.
const embedded_sources = blk: {
    var out: [3 + prelude.pkg_modules.len][]const u8 = undefined;
    out[0] = prelude.primitives;
    out[1] = prelude.builtins;
    out[2] = prelude.builtin_fns;
    for (prelude.pkg_modules, 0..) |m, i| out[3 + i] = m.source;
    break :blk out;
};

const EmbeddedAt = struct { source: usize, offset: usize };

/// Where `s` sits in an embedded source, when it is a slice of one.
fn embeddedAt(s: []const u8) ?EmbeddedAt {
    if (s.len == 0) return null;
    const at = @intFromPtr(s.ptr);
    for (embedded_sources, 0..) |src, i| {
        const start = @intFromPtr(src.ptr);
        if (at >= start and at + s.len <= start + src.len) return .{ .source = i, .offset = at - start };
    }
    return null;
}

/// A field the encoding leaves out: on load it takes its default value
/// (`null`, an empty slice, or the declared default).
pub const Skip = struct {
    T: type,
    field: []const u8,
};

/// The fields an entry never stores (the design's short list):
///   * `TypedBinding.typedExpr` — the typed tree inference built; the
///     transformed AST and the binding's type carry what a consumer reads;
///   * `OkData.custom_ast` — `@ExprCustom` reference trees, the language
///     server's read-only view of a module it is editing (never a dependency's).
pub const default_skips = [_]Skip{
    .{ .T = infer.TypedBinding, .field = "typedExpr" },
    .{ .T = comptimeMod.ComptimeOutput.OkData, .field = "custom_ast" },
};

fn skipped(comptime skips: []const Skip, comptime T: type, comptime field: []const u8) bool {
    inline for (skips) |sk| {
        if (sk.T == T and comptime std.mem.eql(u8, sk.field, field)) return true;
    }
    return false;
}

fn typeHash(comptime T: type) u64 {
    return comptime std.hash.Wyhash.hash(0, @typeName(T));
}

const PtrKey = struct { addr: usize, len: usize, ty: u64 };

const MapKind = enum { none, array_list, hash_unmanaged, hash_managed, array_hash_unmanaged };

fn mapKind(comptime T: type) MapKind {
    if (@typeInfo(T) != .@"struct") return .none;
    if (@hasField(T, "items") and @hasField(T, "capacity") and @hasDecl(T, "Slice")) {
        const E = @typeInfo(T.Slice).pointer.child;
        if (T != std.ArrayListUnmanaged(E)) @compileError("analysis_entry: an ArrayList other than the plain unmanaged one: " ++ @typeName(T));
        return .array_list;
    }
    if (@hasField(T, "metadata") and @hasDecl(T, "Managed") and @hasDecl(T, "KV")) return .hash_unmanaged;
    if (@hasField(T, "unmanaged") and @hasField(T, "allocator") and @hasDecl(T, "Unmanaged")) return .hash_managed;
    if (@hasField(T, "entries") and @hasField(T, "index_header") and @hasDecl(T, "KV")) return .array_hash_unmanaged;
    return .none;
}

fn KeyOf(comptime M: type) type {
    return @FieldType(M.KV, "key");
}
fn ValueOf(comptime M: type) type {
    return @FieldType(M.KV, "value");
}

/// The content order of two map keys — what makes a map's bytes deterministic.
fn order(comptime K: type, a: K, b: K) std.math.Order {
    switch (@typeInfo(K)) {
        .int => return std.math.order(a, b),
        .bool => return std.math.order(@intFromBool(a), @intFromBool(b)),
        .void => return .eq,
        .@"enum" => return std.math.order(@intFromEnum(a), @intFromEnum(b)),
        .optional => |o| {
            if (a == null and b == null) return .eq;
            if (a == null) return .lt;
            if (b == null) return .gt;
            return order(o.child, a.?, b.?);
        },
        .array => |arr| {
            for (0..arr.len) |i| switch (order(arr.child, a[i], b[i])) {
                .eq => {},
                else => |o| return o,
            };
            return .eq;
        },
        .pointer => |p| {
            if (p.size != .slice) @compileError("analysis_entry: a map keyed by a pointer cannot be written in a deterministic order: " ++ @typeName(K));
            if (p.child == u8) return std.mem.order(u8, a, b);
            const n = @min(a.len, b.len);
            for (0..n) |i| switch (order(p.child, a[i], b[i])) {
                .eq => {},
                else => |o| return o,
            };
            return std.math.order(a.len, b.len);
        },
        .@"struct" => |st| {
            if (st.layout == .@"packed") return std.math.order(@as(st.backing_integer.?, @bitCast(a)), @as(st.backing_integer.?, @bitCast(b)));
            inline for (st.fields) |f| switch (order(f.type, @field(a, f.name), @field(b, f.name))) {
                .eq => {},
                else => |o| return o,
            };
            return .eq;
        },
        .@"union" => |u| {
            const Tag = u.tag_type orelse @compileError("analysis_entry: an untagged union key: " ++ @typeName(K));
            const ta: Tag = a;
            const tb: Tag = b;
            if (ta != tb) return std.math.order(@intFromEnum(ta), @intFromEnum(tb));
            switch (a) {
                inline else => |pa, tag| return order(@TypeOf(pa), pa, @field(b, @tagName(tag))),
            }
        },
        else => @compileError("analysis_entry: no order for a map key of type " ++ @typeName(K)),
    }
}

pub const EncodeError = std.mem.Allocator.Error;

/// The encoder of one entry: every section it writes shares its STRINGS and
/// its identity table. `skips` — `default_skips` for an entry; a test drops
/// one field more to prove the emitters read it.
pub fn Encoder(comptime skips: []const Skip) type {
    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,
        out: std.ArrayListUnmanaged(u8) = .empty,
        strings: std.StringArrayHashMapUnmanaged(void) = .empty,
        ptrs: std.AutoHashMapUnmanaged(PtrKey, u32) = .empty,

        pub fn init(gpa: std.mem.Allocator) Self {
            return .{ .gpa = gpa };
        }

        pub fn deinit(self: *Self) void {
            self.out.deinit(self.gpa);
            self.strings.deinit(self.gpa);
            self.ptrs.deinit(self.gpa);
        }

        /// The bytes written since the last call, handed to the caller
        /// (allocated with `gpa`): one section.
        pub fn takeSection(self: *Self) EncodeError![]u8 {
            return self.out.toOwnedSlice(self.gpa);
        }

        /// The STRINGS section: the count, then each string's length and bytes.
        pub fn stringsSection(self: *Self) EncodeError![]u8 {
            var buf: std.ArrayListUnmanaged(u8) = .empty;
            errdefer buf.deinit(self.gpa);
            try writeUleb(self.gpa, &buf, self.strings.count());
            for (self.strings.keys()) |k| {
                try writeUleb(self.gpa, &buf, k.len);
                try buf.appendSlice(self.gpa, k);
            }
            return buf.toOwnedSlice(self.gpa);
        }

        /// Write `value`, a `T`.
        pub fn encode(self: *Self, comptime T: type, value: *const T) EncodeError!void {
            switch (@typeInfo(T)) {
                .void => {},
                .bool => try self.out.append(self.gpa, @intFromBool(value.*)),
                .int => |i| {
                    if (i.bits > 64) @compileError("analysis_entry: an integer wider than 64 bits: " ++ @typeName(T));
                    if (i.signedness == .signed) {
                        const v: i64 = value.*;
                        try writeUleb(self.gpa, &self.out, @bitCast((v << 1) ^ (v >> 63)));
                    } else try writeUleb(self.gpa, &self.out, value.*);
                },
                .float => |f| {
                    const Bits = std.meta.Int(.unsigned, f.bits);
                    var b: [@sizeOf(Bits)]u8 = undefined;
                    std.mem.writeInt(Bits, &b, @bitCast(value.*), .little);
                    try self.out.appendSlice(self.gpa, &b);
                },
                .@"enum" => |e| try self.encode(e.tag_type, &@intFromEnum(value.*)),
                .optional => |o| {
                    if (value.*) |*payload| {
                        try self.out.append(self.gpa, 1);
                        try self.encode(o.child, payload);
                    } else try self.out.append(self.gpa, 0);
                },
                .array => |a| for (value) |*elem| try self.encode(a.child, elem),
                .pointer => |p| switch (p.size) {
                    .one => try self.encodeOne(p.child, value.*),
                    .slice => if (p.child == u8)
                        try self.encodeString(value.*)
                    else
                        try self.encodeSlice(p.child, value.*),
                    else => @compileError("analysis_entry: a pointer that is neither one item nor a slice: " ++ @typeName(T)),
                },
                .@"union" => |u| {
                    const Tag = u.tag_type orelse @compileError("analysis_entry: an untagged union: " ++ @typeName(T));
                    const tag: Tag = value.*;
                    try self.encode(Tag, &tag);
                    switch (value.*) {
                        inline else => |*payload| try self.encode(@TypeOf(payload.*), payload),
                    }
                },
                .@"struct" => |st| switch (comptime mapKind(T)) {
                    .array_list => try self.encode(T.Slice, &value.items),
                    .hash_unmanaged => try self.encodeHashMap(T, value),
                    .hash_managed => try self.encodeHashMap(T.Unmanaged, &value.unmanaged),
                    .array_hash_unmanaged => {
                        try writeUleb(self.gpa, &self.out, value.count());
                        for (value.keys(), value.values()) |*k, *v| {
                            try self.encode(KeyOf(T), k);
                            try self.encode(ValueOf(T), v);
                        }
                    },
                    .none => {
                        if (st.layout == .@"packed") {
                            const bits: st.backing_integer.? = @bitCast(value.*);
                            return self.encode(st.backing_integer.?, &bits);
                        }
                        inline for (st.fields) |f| {
                            if (f.is_comptime) continue;
                            if (comptime skipped(skips, T, f.name)) continue;
                            try self.encode(f.type, &@field(value.*, f.name));
                        }
                    },
                },
                else => @compileError("analysis_entry: no encoding for " ++ @typeName(T)),
            }
        }

        fn encodeString(self: *Self, s: []const u8) EncodeError!void {
            if (embeddedAt(s)) |at| {
                try self.out.append(self.gpa, 0);
                try writeUleb(self.gpa, &self.out, at.source);
                try writeUleb(self.gpa, &self.out, at.offset);
                try writeUleb(self.gpa, &self.out, s.len);
                return;
            }
            const gop = try self.strings.getOrPut(self.gpa, s);
            try writeUleb(self.gpa, &self.out, @as(u64, gop.index) + 1);
        }

        /// 0 and a new entry of the identity table, or 1 + a known one's index.
        fn identity(self: *Self, key: PtrKey) EncodeError!bool {
            const gop = try self.ptrs.getOrPut(self.gpa, key);
            if (gop.found_existing) {
                try writeUleb(self.gpa, &self.out, @as(u64, gop.value_ptr.*) + 1);
                return false;
            }
            gop.value_ptr.* = @intCast(self.ptrs.count() - 1);
            try self.out.append(self.gpa, 0);
            return true;
        }

        fn encodeOne(self: *Self, comptime C: type, ptr: *const C) EncodeError!void {
            if (@sizeOf(C) == 0) return;
            if (try self.identity(.{ .addr = @intFromPtr(ptr), .len = 0, .ty = typeHash(C) })) try self.encode(C, ptr);
        }

        fn encodeSlice(self: *Self, comptime C: type, items: []const C) EncodeError!void {
            if (items.len == 0 or @sizeOf(C) == 0) {
                try self.out.append(self.gpa, 0);
                try writeUleb(self.gpa, &self.out, items.len);
                return;
            }
            if (!try self.identity(.{ .addr = @intFromPtr(items.ptr), .len = items.len, .ty = typeHash(C) })) return;
            try writeUleb(self.gpa, &self.out, items.len);
            for (items) |*elem| try self.encode(C, elem);
        }

        fn encodeHashMap(self: *Self, comptime M: type, map: *const M) EncodeError!void {
            const K = KeyOf(M);
            const V = ValueOf(M);
            const Pair = struct { k: *const K, v: *const V };
            var pairs = try self.gpa.alloc(Pair, map.count());
            defer self.gpa.free(pairs);
            var it = map.iterator();
            var i: usize = 0;
            while (it.next()) |e| : (i += 1) pairs[i] = .{ .k = e.key_ptr, .v = e.value_ptr };
            std.mem.sort(Pair, pairs, {}, struct {
                fn lt(_: void, a: Pair, b: Pair) bool {
                    return order(K, a.k.*, b.k.*) == .lt;
                }
            }.lt);
            try writeUleb(self.gpa, &self.out, pairs.len);
            for (pairs) |pr| {
                try self.encode(K, pr.k);
                try self.encode(V, pr.v);
            }
        }
    };
}

pub const DecodeError = error{Malformed} || std.mem.Allocator.Error;

/// The decoder of one entry's sections, in the order the encoder wrote them:
/// the identity table spans them. What it builds lives in `arena`.
pub fn Decoder(comptime skips: []const Skip) type {
    return struct {
        const Self = @This();

        arena: std.mem.Allocator,
        strings: []const []const u8 = &.{},
        ptrs: std.ArrayListUnmanaged(struct { addr: usize, len: usize }) = .empty,
        in: []const u8 = "",
        pos: usize = 0,

        pub fn init(arena: std.mem.Allocator, strings_section: []const u8) DecodeError!Self {
            var self: Self = .{ .arena = arena, .in = strings_section };
            const n = try self.uleb();
            if (n > strings_section.len) return error.Malformed;
            const out = try arena.alloc([]const u8, @intCast(n));
            for (out) |*s| {
                const len: usize = @intCast(try self.uleb());
                s.* = try arena.dupe(u8, try self.take(len));
            }
            self.strings = out;
            return self;
        }

        /// Read the next section: `decode` reads from it until the caller
        /// sets another.
        pub fn section(self: *Self, bytes: []const u8) void {
            self.in = bytes;
            self.pos = 0;
        }

        /// Whether the current section was read to its end.
        pub fn done(self: *const Self) bool {
            return self.pos == self.in.len;
        }

        fn take(self: *Self, n: usize) DecodeError![]const u8 {
            if (n > self.in.len - self.pos) return error.Malformed;
            defer self.pos += n;
            return self.in[self.pos..][0..n];
        }

        fn byte(self: *Self) DecodeError!u8 {
            return (try self.take(1))[0];
        }

        fn uleb(self: *Self) DecodeError!u64 {
            var result: u64 = 0;
            var shift: u7 = 0;
            while (true) {
                const b = try self.byte();
                if (shift > 63) return error.Malformed;
                result |= @as(u64, b & 0x7f) << @intCast(shift);
                if (b & 0x80 == 0) return result;
                shift += 7;
            }
        }

        /// Read a `T`.
        pub fn decode(self: *Self, comptime T: type) DecodeError!T {
            switch (@typeInfo(T)) {
                .void => return {},
                .bool => return switch (try self.byte()) {
                    0 => false,
                    1 => true,
                    else => error.Malformed,
                },
                .int => |i| {
                    const raw = try self.uleb();
                    if (i.signedness == .signed) {
                        const v: i64 = @as(i64, @bitCast(raw >> 1)) ^ -@as(i64, @bitCast(raw & 1));
                        return std.math.cast(T, v) orelse error.Malformed;
                    }
                    return std.math.cast(T, raw) orelse error.Malformed;
                },
                .float => |f| {
                    const Bits = std.meta.Int(.unsigned, f.bits);
                    const b = try self.take(@sizeOf(Bits));
                    return @bitCast(std.mem.readInt(Bits, b[0..@sizeOf(Bits)], .little));
                },
                .@"enum" => |e| {
                    const raw = try self.decode(e.tag_type);
                    if (e.is_exhaustive) {
                        inline for (e.fields) |f| if (f.value == raw) return @enumFromInt(raw);
                        return error.Malformed;
                    }
                    return @enumFromInt(raw);
                },
                .optional => |o| return switch (try self.byte()) {
                    0 => null,
                    1 => try self.decode(o.child),
                    else => error.Malformed,
                },
                .array => |a| {
                    var out: T = undefined;
                    for (&out) |*elem| elem.* = try self.decode(a.child);
                    return out;
                },
                .pointer => |p| switch (p.size) {
                    .one => return @ptrCast(try self.decodeOne(p.child)),
                    .slice => if (p.child == u8) {
                        const ref: usize = @intCast(try self.uleb());
                        const s = if (ref == 0) embedded: {
                            const src: usize = @intCast(try self.uleb());
                            const offset: usize = @intCast(try self.uleb());
                            const len: usize = @intCast(try self.uleb());
                            if (src >= embedded_sources.len) return error.Malformed;
                            const whole = embedded_sources[src];
                            if (offset > whole.len or len > whole.len - offset) return error.Malformed;
                            break :embedded whole[offset..][0..len];
                        } else stored: {
                            if (ref - 1 >= self.strings.len) return error.Malformed;
                            break :stored self.strings[ref - 1];
                        };
                        if (p.sentinel() != null) return try self.arena.dupeZ(u8, s);
                        if (!p.is_const) return try self.arena.dupe(u8, s);
                        return s;
                    } else {
                        const items = try self.decodeSlice(p.child);
                        return @alignCast(items);
                    },
                    else => @compileError("analysis_entry: a pointer that is neither one item nor a slice: " ++ @typeName(T)),
                },
                .@"union" => |u| {
                    const Tag = u.tag_type orelse @compileError("analysis_entry: an untagged union: " ++ @typeName(T));
                    const tag = try self.decode(Tag);
                    switch (tag) {
                        inline else => |t| {
                            const Payload = @FieldType(T, @tagName(t));
                            return @unionInit(T, @tagName(t), try self.decode(Payload));
                        },
                    }
                },
                .@"struct" => |st| switch (comptime mapKind(T)) {
                    .array_list => {
                        const items = try self.decode(T.Slice);
                        return .{ .items = items, .capacity = items.len };
                    },
                    .hash_unmanaged => return self.decodeHashMap(T),
                    .hash_managed => return .{ .unmanaged = try self.decodeHashMap(T.Unmanaged), .allocator = self.arena, .ctx = undefined },
                    .array_hash_unmanaged => {
                        var map: T = .empty;
                        const n: usize = @intCast(try self.uleb());
                        if (n > self.in.len) return error.Malformed;
                        for (0..n) |_| {
                            const k = try self.decode(KeyOf(T));
                            const v = try self.decode(ValueOf(T));
                            const gop = try map.getOrPut(self.arena, k);
                            if (gop.found_existing) return error.Malformed;
                            gop.value_ptr.* = v;
                        }
                        return map;
                    },
                    .none => {
                        if (st.layout == .@"packed") return @bitCast(try self.decode(st.backing_integer.?));
                        var out: T = undefined;
                        inline for (st.fields) |f| {
                            if (f.is_comptime) continue;
                            if (comptime skipped(skips, T, f.name)) {
                                @field(out, f.name) = self.skippedValue(T, f);
                            } else @field(out, f.name) = try self.decode(f.type);
                        }
                        return out;
                    },
                },
                else => @compileError("analysis_entry: no encoding for " ++ @typeName(T)),
            }
        }

        /// What a skipped field holds on load: its declared default, else
        /// `null` for an optional, an empty slice, or an empty map.
        fn skippedValue(self: *Self, comptime T: type, comptime f: std.builtin.Type.StructField) f.type {
            if (comptime f.defaultValue()) |d| return d;
            switch (@typeInfo(f.type)) {
                .optional => return null,
                .pointer => |p| if (p.size == .slice) return &.{},
                else => {},
            }
            switch (comptime mapKind(f.type)) {
                .array_list, .hash_unmanaged, .array_hash_unmanaged => return .empty,
                .hash_managed => return .{ .unmanaged = .empty, .allocator = self.arena, .ctx = undefined },
                .none => @compileError("analysis_entry: the skipped field " ++ @typeName(T) ++ "." ++ f.name ++ " has no value to load"),
            }
        }

        fn backref(self: *Self, ref: u64) DecodeError!struct { addr: usize, len: usize } {
            if (ref == 0 or ref > self.ptrs.items.len) return error.Malformed;
            const e = self.ptrs.items[@intCast(ref - 1)];
            return .{ .addr = e.addr, .len = e.len };
        }

        fn decodeOne(self: *Self, comptime C: type) DecodeError!*C {
            if (@sizeOf(C) == 0) return try self.arena.create(C);
            const ref = try self.uleb();
            if (ref != 0) {
                const e = try self.backref(ref);
                if (e.len != 0) return error.Malformed;
                return @ptrFromInt(e.addr);
            }
            const p = try self.arena.create(C);
            try self.ptrs.append(self.arena, .{ .addr = @intFromPtr(p), .len = 0 });
            p.* = try self.decode(C);
            return p;
        }

        fn decodeSlice(self: *Self, comptime C: type) DecodeError![]C {
            const ref = try self.uleb();
            if (ref != 0) {
                const e = try self.backref(ref);
                if (e.len == 0) return error.Malformed;
                return @as([*]C, @ptrFromInt(e.addr))[0..e.len];
            }
            const n: usize = @intCast(try self.uleb());
            if (n == 0) return &.{};
            if (@sizeOf(C) == 0) return try self.arena.alloc(C, n);
            if (n > self.in.len) return error.Malformed;
            const items = try self.arena.alloc(C, n);
            try self.ptrs.append(self.arena, .{ .addr = @intFromPtr(items.ptr), .len = n });
            for (items) |*elem| elem.* = try self.decode(C);
            return items;
        }

        fn decodeHashMap(self: *Self, comptime M: type) DecodeError!M {
            var map: M = .empty;
            const n: usize = @intCast(try self.uleb());
            if (n > self.in.len) return error.Malformed;
            try map.ensureTotalCapacity(self.arena, @intCast(n));
            for (0..n) |_| {
                const k = try self.decode(KeyOf(M));
                const v = try self.decode(ValueOf(M));
                const gop = map.getOrPutAssumeCapacity(k);
                if (gop.found_existing) return error.Malformed;
                gop.value_ptr.* = v;
            }
            return map;
        }
    };
}

fn writeUleb(gpa: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), value: u64) EncodeError!void {
    var v = value;
    while (true) {
        const b: u8 = @truncate(v & 0x7f);
        v >>= 7;
        if (v == 0) return out.append(gpa, b);
        try out.append(gpa, b | 0x80);
    }
}

// ── The entry: META, STRINGS, then per module ANALYSIS and JOURNAL ──────────

const ast = @import("../ast.zig");
const Types = @import("./types.zig");
const reflectionMod = @import("./reflection.zig");
const hooksMod = @import("./hooks.zig");
const modTree = @import("./mod_tree.zig");

/// What a module's pre-passes learn by parsing it, kept so a hit parses
/// nothing (`comptime.zig` `expandStdImports`, `orderReaders`,
/// `mod_tree.build`).
pub const ModuleMeta = struct {
    path: []const u8,
    /// Whether the module reads `@TypeInfo.all` (`orderReaders`): a stored
    /// entry's never does — its answer is the whole program's.
    reads_catalogue: bool = false,
    /// The std modules the module itself needs (`std/<path>`), in
    /// `std_pkg_modules` order: its `from "std"` items, `std/context` for a
    /// `@Component`, `std/beam` for a module-level `var` on erlang and beam.
    std_imports: []const []const u8 = &.{},
    /// What the session's module tree holds of it (decision 337): its entry
    /// and the re-exports it declares; null when the tree does not hold it.
    tree: ?modTree.Known = null,
};

/// META: what the entry is of. Encoded like everything else.
pub const Meta = struct {
    /// The package's import name (`std/<module>` for a std module's entry).
    package: []const u8,
    /// `code_cache.EntryTarget.name`: `commonJS`, `erlang`, `beam`, `wasm`,
    /// `wasm.browser`.
    target: []const u8,
    /// The modules, in the order their ANALYSIS sections follow.
    modules: []const []const u8,
    /// One per module, in `modules`' order (empty in S1's test entries).
    module_meta: []const ModuleMeta = &.{},
};

/// One module's ANALYSIS: the `ComptimeOutput` of a module that analysed,
/// its outcome `ok`. The module's source text (`ComptimeOutput.src`) is not
/// in it: the driver holds it and sets it on the output read back, as it
/// sets `name` and `srcPath` (`comptime.zig` `compileOnce`); the bytes are
/// inside the entry's key already.
pub const Analysis = struct {
    name: []const u8,
    srcPath: []const u8,
    ok: comptimeMod.ComptimeOutput.OkData,
};

// ── The JOURNAL ───────────────────────────────────────────────────────────────
//
// What one module's analysis and `registerExports` left in the session beyond
// its own output: a delta per map, computed by comparing the session's state
// before and after the module (`level_b.zig`), and applied to the reading
// session at the module's place in the order. A map's delta is its removed
// keys and its put (added or replaced) entries; a map of maps names each inner
// map it touched — `reset` when the module replaced it whole (or created it),
// with every entry it then held; a list keyed by name only grows (the entries
// appended). Every field of `Reflection` is journaled or named in
// `unjournaled_reflection` — a test holds the two lists to the type.

pub fn Put(comptime V: type) type {
    return struct { key: []const u8, value: V };
}

pub fn MapOps(comptime V: type) type {
    return struct {
        removes: []const []const u8 = &.{},
        puts: []const Put(V) = &.{},

        pub fn isEmpty(self: @This()) bool {
            return self.removes.len == 0 and self.puts.len == 0;
        }
    };
}

pub fn InnerOps(comptime V: type) type {
    return struct { key: []const u8, reset: bool, ops: MapOps(V) };
}

pub fn NestedOps(comptime V: type) type {
    return struct {
        /// Outer keys the module removed.
        removes: []const []const u8 = &.{},
        maps: []const InnerOps(V) = &.{},
    };
}

pub fn Appended(comptime E: type) type {
    return struct { key: []const u8, items: []const E };
}

pub fn ListAppends(comptime E: type) type {
    return struct { lists: []const Appended(E) = &.{} };
}

pub const Journal = struct {
    // The five registries of `compileOnce`.
    registry: NestedOps(*Types.Type) = .{},
    type_decls: NestedOps(ast.DeclKind) = .{},
    templates: MapOps(ast.FnDecl) = .{},
    decorators: MapOps(ast.FnDecl) = .{},
    extensions: NestedOps(ast.ImplementDecl) = .{},
    // The default DSL.
    dsl_mod_names: MapOps([]const u8) = .{},
    dsl_handlers: MapOps(comptimeMod.DefaultDsl.Handler) = .{},
    // The reflection catalogue (`reflection.Reflection`).
    meta: ListAppends(reflectionMod.MetaEntry) = .{},
    typed_meta: ListAppends(reflectionMod.TypedMetaEntry) = .{},
    decorator_meta_types: MapOps([]const reflectionMod.MetaCallType) = .{},
    assoc: ListAppends([]const u8) = .{},
    declared: []const reflectionMod.DeclaredEntry = &.{},
    template_queries: MapOps([]const reflectionMod.TemplateQuery) = .{},
    hook_fns: MapOps(hooksMod.FnInfo) = .{},
    scopes: MapOps(reflectionMod.WrittenName) = .{},
};

/// The fields of `Reflection` no journal carries, and why: `arena` (the
/// session's), `readers` (META's `reads_catalogue`; a reader's package is
/// never stored), `templateReads` (a package whose module expands a template
/// reading the catalogue is never stored), `oracle` and `modTree` (the
/// session's own, built before any module).
pub const unjournaled_reflection = [_][]const u8{ "arena", "readers", "templateReads", "oracle", "modTree" };

/// The `Reflection` fields `Journal` carries, by their names there.
pub const journaled_reflection = [_][]const u8{ "meta", "typedMeta", "decoratorMetaTypes", "assoc", "declared", "templateQueries", "hookFns", "scopes" };

/// The entry of `outputs` (each `.ok`) under `key`, allocated with `gpa`.
/// `journals` is empty, or one per output.
pub fn write(gpa: std.mem.Allocator, key: Key, meta: Meta, outputs: []const comptimeMod.ComptimeOutput, journals: []const Journal) ![]u8 {
    return writeWith(&default_skips, gpa, key, meta, outputs, journals);
}

/// `write` with the skip list given — a test drops a field more.
pub fn writeWith(comptime skips: []const Skip, gpa: std.mem.Allocator, key: Key, meta: Meta, outputs: []const comptimeMod.ComptimeOutput, journals: []const Journal) ![]u8 {
    if (journals.len != 0 and journals.len != outputs.len) return error.JournalCount;
    var enc = Encoder(skips).init(gpa);
    defer enc.deinit();
    var owned: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (owned.items) |b| gpa.free(b);
        owned.deinit(gpa);
    }
    var sections: std.ArrayListUnmanaged(Section) = .empty;
    defer sections.deinit(gpa);

    // The sections follow in the order they are encoded: the identity table
    // spans them, so the reader decodes them in this order too.
    try enc.encode(Meta, &meta);
    try owned.append(gpa, try enc.takeSection());
    try sections.append(gpa, .{ .id = .meta, .bytes = owned.items[owned.items.len - 1] });
    // STRINGS takes its place second; its bytes are known once every section is written.
    try sections.append(gpa, .{ .id = .strings, .bytes = "" });
    for (outputs, 0..) |o, i| {
        const a: Analysis = .{ .name = o.name, .srcPath = o.srcPath, .ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.NotAnalysed,
        } };
        try enc.encode(Analysis, &a);
        try owned.append(gpa, try enc.takeSection());
        try sections.append(gpa, .{ .id = .analysis, .bytes = owned.items[owned.items.len - 1] });
        if (journals.len == 0) continue;
        try enc.encode(Journal, &journals[i]);
        try owned.append(gpa, try enc.takeSection());
        try sections.append(gpa, .{ .id = .journal, .bytes = owned.items[owned.items.len - 1] });
    }
    try owned.append(gpa, try enc.stringsSection());
    sections.items[1].bytes = owned.items[owned.items.len - 1];
    return pack(gpa, key, sections.items);
}

/// What `read` gives back: the META, each module's `ComptimeOutput` (its
/// `src` empty: the driver's) and, when the entry carries them, each
/// module's JOURNAL (else empty).
pub const Decoded = struct {
    meta: Meta,
    outputs: []comptimeMod.ComptimeOutput,
    journals: []Journal,
    /// Each module's CODE section, undecoded (`decodeCode`), when the entry
    /// carries them (else empty).
    code: []const []const u8 = &.{},
};

/// The modules of a proven entry, built in `arena`.
pub fn read(arena: std.mem.Allocator, e: Entry) DecodeError!Decoded {
    return readWith(&default_skips, arena, e);
}

pub fn readWith(comptime skips: []const Skip, arena: std.mem.Allocator, e: Entry) DecodeError!Decoded {
    var dec = try Decoder(skips).init(arena, e.get(.strings) orelse return error.Malformed);
    // META first, then every other section in the table's order — the order
    // they were encoded in.
    if (e.sections.len < 2 or e.sections[0].id != .meta) return error.Malformed;
    dec.section(e.sections[0].bytes);
    const meta = try dec.decode(Meta);
    if (!dec.done()) return error.Malformed;
    if (meta.module_meta.len != 0 and meta.module_meta.len != meta.modules.len) return error.Malformed;
    var outputs: std.ArrayListUnmanaged(comptimeMod.ComptimeOutput) = .empty;
    var journals: std.ArrayListUnmanaged(Journal) = .empty;
    var code: std.ArrayListUnmanaged([]const u8) = .empty;
    for (e.sections[1..]) |s| switch (s.id) {
        .strings => {},
        // Decoded when an emit asks for it (`decodeCode`); after every module.
        .code => try code.append(arena, s.bytes),
        .analysis => {
            if (code.items.len != 0) return error.Malformed;
            if (journals.items.len != 0 and journals.items.len != outputs.items.len) return error.Malformed;
            dec.section(s.bytes);
            const a = try dec.decode(Analysis);
            if (!dec.done()) return error.Malformed;
            try outputs.append(arena, .{ .name = a.name, .src = "", .srcPath = a.srcPath, .outcome = .{ .ok = a.ok } });
        },
        .journal => {
            if (code.items.len != 0) return error.Malformed;
            if (journals.items.len + 1 != outputs.items.len) return error.Malformed;
            dec.section(s.bytes);
            try journals.append(arena, try dec.decode(Journal));
            if (!dec.done()) return error.Malformed;
        },
        else => return error.Malformed,
    };
    if (outputs.items.len != meta.modules.len) return error.Malformed;
    if (journals.items.len != 0 and journals.items.len != outputs.items.len) return error.Malformed;
    if (code.items.len != 0 and code.items.len != outputs.items.len) return error.Malformed;
    for (meta.modules, outputs.items) |m, o| if (!std.mem.eql(u8, m, o.name)) return error.Malformed;
    return .{ .meta = meta, .outputs = outputs.items, .journals = journals.items, .code = code.items };
}

// ── CODE (S4) ─────────────────────────────────────────────────────────────────
//
// A module's own unit on the target, as the emitter produced it in a build
// (`codegen.generateWith`, `botopink test` too — decision 513): every
// field of `GenerateResult` but what describes a failure or a run, encoded
// generically like the rest — a field added to `GenerateResult` is stored
// without anyone remembering to. On commonJS the `.d.ts` is always there
// (the build that wrote it emitted it whether or not it asked for one).
// What a consumer instantiates never is: a dependency's unit is the same
// under every consumer (the closure invariant, `test-closure-invariant`), and
// a consumer's instantiations live in the consumer's own unit.
//
// A CODE section is self-contained — `STRINGS-length` (LEB128), its strings,
// then the `CodeUnit` — so it is added to an entry read back (one written by
// `check`, which emits no code) without encoding the rest again.

const moduleOutput = @import("../codegen/moduleOutput.zig");

/// The fields of `GenerateResult` CODE never stores: a failure (a unit is
/// stored only when every module of its entry emitted), the warnings (the
/// analysis carries them, `OkData.warnings`), a run's output and a test unit
/// (a dependency has none, and a test unit is never cached — decision 513 (3)).
pub const code_skips = [_]Skip{
    .{ .T = moduleOutput.GenerateResult, .field = "diagnostic" },
    .{ .T = moduleOutput.GenerateResult, .field = "comptime_err" },
    .{ .T = moduleOutput.GenerateResult, .field = "warnings" },
    .{ .T = moduleOutput.GenerateResult, .field = "run_output" },
    .{ .T = moduleOutput.GenerateResult, .field = "test_unit" },
};

/// One CODE section: the unit and what of the emit's configuration its bytes
/// depend on beyond the entry's key (the target and the host are in it).
pub const CodeUnit = struct {
    /// `codegen.Config.wasm_artifact`: whether wasm's text is the build's
    /// artifact (a component, the browser's module) or a bare module.
    wasm_artifact: bool,
    result: moduleOutput.GenerateResult,
};

/// The CODE section of `unit`, allocated with `gpa`.
pub fn encodeCode(gpa: std.mem.Allocator, unit: *const CodeUnit) EncodeError![]u8 {
    var enc = Encoder(&code_skips).init(gpa);
    defer enc.deinit();
    try enc.encode(CodeUnit, unit);
    const body = try enc.takeSection();
    defer gpa.free(body);
    const strings = try enc.stringsSection();
    defer gpa.free(strings);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(gpa);
    try writeUleb(gpa, &out, strings.len);
    try out.appendSlice(gpa, strings);
    try out.appendSlice(gpa, body);
    return out.toOwnedSlice(gpa);
}

/// The `CodeUnit` a CODE section holds, built in `arena` (its slices are the
/// arena's: a caller that owns a `GenerateResult` copies them).
pub fn decodeCode(arena: std.mem.Allocator, bytes: []const u8) DecodeError!CodeUnit {
    var head = try Decoder(&code_skips).init(arena, "\x00");
    head.section(bytes);
    const strings_len: usize = std.math.cast(usize, try head.uleb()) orelse return error.Malformed;
    if (strings_len > bytes.len - head.pos) return error.Malformed;
    const strings = bytes[head.pos..][0..strings_len];
    var dec = try Decoder(&code_skips).init(arena, strings);
    dec.section(bytes[head.pos + strings_len ..]);
    const unit = try dec.decode(CodeUnit);
    if (!dec.done()) return error.Malformed;
    return unit;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "pack / unpack: the sections come back in order under their key" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const key: Key = @splat(7);
    const bytes = try pack(testing.allocator, key, &.{
        .{ .id = .meta, .bytes = "meta" },
        .{ .id = .strings, .bytes = "" },
        .{ .id = .analysis, .bytes = "one" },
        .{ .id = .analysis, .bytes = "two" },
    });
    defer testing.allocator.free(bytes);
    try testing.expectEqualStrings(MAGIC, bytes[0..8]);
    const e = try unpack(arena.allocator(), bytes, key);
    try testing.expectEqual(@as(usize, 4), e.sections.len);
    try testing.expectEqualStrings("meta", e.get(.meta).?);
    try testing.expectEqualStrings("", e.get(.strings).?);
    try testing.expect(e.get(.journal) == null);
    const mods = try e.all(arena.allocator(), .analysis);
    try testing.expectEqual(@as(usize, 2), mods.len);
    try testing.expectEqualStrings("one", mods[0]);
    try testing.expectEqualStrings("two", mods[1]);
}

test "unpack: doubt discards — short, magic, key, length, checksum, table" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const key: Key = @splat(1);
    const good = try pack(a, key, &.{.{ .id = .analysis, .bytes = "payload bytes" }});
    _ = try unpack(a, good, key);

    // Short: every truncation.
    for (0..good.len) |n| try testing.expectError(error.Doubt, unpack(a, good[0..n], key));
    // Another key.
    try testing.expectError(error.Doubt, unpack(a, good, @splat(2)));
    // Magic, a payload byte (checksum), the length, a trailing byte.
    for ([_]usize{ 0, good.len - 1, MAGIC.len + 32 }) |at| {
        const bad = try a.dupe(u8, good);
        bad[at] ^= 0xff;
        try testing.expectError(error.Doubt, unpack(a, bad, key));
    }
    const longer = try std.mem.concat(a, u8, &.{ good, "x" });
    try testing.expectError(error.Doubt, unpack(a, longer, key));

    // A table row pointing past the payload, with a checksum that matches it.
    const forged = try a.dupe(u8, good);
    const payload = forged[HEADER_LEN..];
    std.mem.writeInt(u64, payload[4 + 12 ..][0..8], 1 << 40, .little);
    std.crypto.hash.sha2.Sha256.hash(payload, forged[MAGIC.len + 32 + 8 ..][0..32], .{});
    try testing.expectError(error.Doubt, unpack(a, forged, key));
}

test "keyFromHex: the raw bytes of a hex key" {
    var hex: [64]u8 = @splat('0');
    hex[0] = 'f';
    hex[63] = '1';
    const k = keyFromHex(hex);
    try testing.expectEqual(@as(u8, 0xf0), k[0]);
    try testing.expectEqual(@as(u8, 0x01), k[31]);
}

const Toy = struct {
    const Node = struct {
        name: []const u8,
        kids: []const *Node = &.{},
        weight: f64 = 0,
        tag: union(enum) { leaf: i32, inner: bool, none } = .none,
        mode: enum(u8) { a, b, c } = .a,
        flags: packed struct { x: bool = false, y: u3 = 0 } = .{},
    };
    root: *Node,
    shared: *Node,
    list: std.ArrayListUnmanaged(*Node),
    by_name: std.StringHashMapUnmanaged(*Node),
    by_loc: std.AutoHashMap(struct { line: usize, col: usize }, i64),
    ordered: std.StringArrayHashMapUnmanaged(u16),
    text: ?[]u8,
    zed: [:0]const u8,
    skip_me: ?i32 = null,
    keep: [3]u8,
};

test "encode / decode: a round trip keeps values, sharing, map contents; re-encoding gives the same bytes" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();

    const leaf = try a.create(Toy.Node);
    leaf.* = .{ .name = "leaf", .weight = -1.5, .tag = .{ .leaf = -7 }, .mode = .c, .flags = .{ .x = true, .y = 5 } };
    const kids = try a.alloc(*Toy.Node, 2);
    kids[0] = leaf;
    kids[1] = leaf;
    const root = try a.create(Toy.Node);
    root.* = .{ .name = "root", .kids = kids, .tag = .{ .inner = true } };
    var toy: Toy = .{
        .root = root,
        .shared = leaf,
        .list = .empty,
        .by_name = .empty,
        .by_loc = .init(a),
        .ordered = .empty,
        .text = try a.dupe(u8, "mutable"),
        .zed = "zero",
        .skip_me = 42,
        .keep = .{ 1, 2, 3 },
    };
    try toy.list.append(a, leaf);
    try toy.list.append(a, root);
    for ([_][]const u8{ "zeta", "alpha", "mid" }) |n| try toy.by_name.put(a, n, leaf);
    try toy.by_loc.put(.{ .line = 9, .col = 1 }, -3);
    try toy.by_loc.put(.{ .line = 1, .col = 2 }, 1 << 40);
    try toy.ordered.put(a, "second", 2);
    try toy.ordered.put(a, "first", 1);

    const skips = [_]Skip{.{ .T = Toy, .field = "skip_me" }};
    var enc = Encoder(&skips).init(testing.allocator);
    defer enc.deinit();
    try enc.encode(Toy, &toy);
    const body = try enc.takeSection();
    defer testing.allocator.free(body);
    const strs = try enc.stringsSection();
    defer testing.allocator.free(strs);

    var dec = try Decoder(&skips).init(a, strs);
    dec.section(body);
    const back = try dec.decode(Toy);
    try testing.expect(dec.done());

    try testing.expectEqualStrings("root", back.root.name);
    try testing.expectEqual(@as(usize, 2), back.root.kids.len);
    // Sharing survives: the two kids, the `shared` field and the list item are one node.
    try testing.expect(back.root.kids[0] == back.root.kids[1]);
    try testing.expect(back.shared == back.root.kids[0]);
    try testing.expect(back.list.items[0] == back.shared);
    try testing.expect(back.list.items[1] == back.root);
    try testing.expectEqual(@as(f64, -1.5), back.shared.weight);
    try testing.expectEqual(@as(i32, -7), back.shared.tag.leaf);
    try testing.expect(back.root.tag.inner);
    try testing.expect(back.shared.mode == .c);
    try testing.expect(back.shared.flags.x and back.shared.flags.y == 5);
    try testing.expect(back.by_name.get("alpha").? == back.shared);
    try testing.expectEqual(@as(i64, 1 << 40), back.by_loc.get(.{ .line = 1, .col = 2 }).?);
    try testing.expectEqual(@as(i64, -3), back.by_loc.get(.{ .line = 9, .col = 1 }).?);
    // An array hash map keeps its insertion order.
    try testing.expectEqualStrings("second", back.ordered.keys()[0]);
    try testing.expectEqualStrings("mutable", back.text.?);
    try testing.expectEqualStrings("zero", back.zed);
    try testing.expectEqual(@as(u8, 0), back.zed.ptr[back.zed.len]);
    try testing.expect(back.skip_me == null);
    try testing.expectEqualSlices(u8, &.{ 1, 2, 3 }, &back.keep);

    // Encoding what was decoded gives the same bytes.
    var enc2 = Encoder(&skips).init(testing.allocator);
    defer enc2.deinit();
    try enc2.encode(Toy, &back);
    const body2 = try enc2.takeSection();
    defer testing.allocator.free(body2);
    const strs2 = try enc2.stringsSection();
    defer testing.allocator.free(strs2);
    try testing.expectEqualSlices(u8, body, body2);
    try testing.expectEqualSlices(u8, strs, strs2);

    // Truncated input is malformed, never a crash.
    for (0..body.len) |n| {
        var d = try Decoder(&skips).init(a, strs);
        d.section(body[0..n]);
        try testing.expectError(error.Malformed, d.decode(Toy));
    }
}

test "the entry's analysis type is encodable (every field has a rule)" {
    // Instantiates the encoder and decoder over the whole of `Analysis`: a
    // type with no rule fails this file's compilation.
    _ = &write;
    _ = &read;
    var enc = Encoder(&default_skips).init(testing.allocator);
    defer enc.deinit();
    const meta: Meta = .{ .package = "p", .target = "erlang", .modules = &.{"p/a"} };
    try enc.encode(Meta, &meta);
    const j: Journal = .{};
    try enc.encode(Journal, &j);
}

test "a slice of an embedded source reads back as a slice of the same bytes; any other string as a copy" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const Pair = struct { prelude_name: []const u8, std_text: []const u8, own: []const u8 };
    const std_src = prelude.pkg_modules[0].source;
    const value: Pair = .{
        .prelude_name = prelude.primitives[10..20],
        .std_text = std_src[0..@min(8, std_src.len)],
        .own = try a.dupe(u8, prelude.primitives[10..20]),
    };
    var enc = Encoder(&.{}).init(testing.allocator);
    defer enc.deinit();
    try enc.encode(Pair, &value);
    const body = try enc.takeSection();
    defer testing.allocator.free(body);
    const strs = try enc.stringsSection();
    defer testing.allocator.free(strs);
    var dec = try Decoder(&.{}).init(a, strs);
    dec.section(body);
    const back = try dec.decode(Pair);
    // The emitter asks whether a name slices into the prelude
    // (`codegen/erlang.zig` `slicesIntoPrelude`): the answer survives.
    try testing.expectEqual(@intFromPtr(value.prelude_name.ptr), @intFromPtr(back.prelude_name.ptr));
    try testing.expectEqual(@intFromPtr(value.std_text.ptr), @intFromPtr(back.std_text.ptr));
    try testing.expectEqualStrings(value.own, back.own);
    try testing.expect(embeddedAt(back.own) == null);
}

test "the journal names every field of Reflection: journaled, or left out with its reason" {
    inline for (@typeInfo(reflectionMod.Reflection).@"struct".fields) |f| {
        const known = for (journaled_reflection ++ unjournaled_reflection) |n| {
            if (std.mem.eql(u8, n, f.name)) break true;
        } else false;
        if (!known) std.debug.print("Reflection.{s} is neither journaled nor left out (analysis_entry.zig)\n", .{f.name});
        try testing.expect(known);
    }
}

test "CODE: a unit round-trips whole; an entry with CODE for some modules only is malformed" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var units = [_]moduleOutput.Unit{.{ .atom = try a.dupe(u8, "lib@m@@T"), .code = try a.dupe(u8, "-module('lib@m@@T').") }};
    var funcs = [_]moduleOutput.StdFunc{.{ .symbol = "s", .label = "std:list.map", .hash = "0123456789ab".* }};
    const unit: CodeUnit = .{ .wasm_artifact = true, .result = .{
        .js = try a.dupe(u8, "-module('lib@m')."),
        .typedef = try a.dupe(u8, "export {};"),
        .units = &units,
        .comptime_script = null,
        .wasm = try a.dupe(u8, "\x00asm"),
        .std_funcs = &funcs,
        .comptime_trace = try a.dupe(u8, "trace"),
        .run_output = try a.dupe(u8, "never stored"),
    } };
    const bytes = try encodeCode(testing.allocator, &unit);
    defer testing.allocator.free(bytes);
    const back = try decodeCode(a, bytes);
    try testing.expect(back.wasm_artifact);
    try testing.expectEqualStrings(unit.result.js, back.result.js);
    try testing.expectEqualStrings(unit.result.typedef.?, back.result.typedef.?);
    try testing.expectEqualStrings(unit.result.wasm.?, back.result.wasm.?);
    try testing.expectEqualStrings(unit.result.comptime_trace.?, back.result.comptime_trace.?);
    try testing.expect(back.result.comptime_script == null);
    try testing.expect(back.result.run_output == null);
    try testing.expectEqual(@as(usize, 1), back.result.units.len);
    try testing.expectEqualStrings("lib@m@@T", back.result.units[0].atom);
    try testing.expectEqualStrings(units[0].code, back.result.units[0].code);
    try testing.expectEqualStrings("std:list.map", back.result.std_funcs[0].label);
    try testing.expectEqualSlices(u8, &funcs[0].hash, &back.result.std_funcs[0].hash);
    for (0..bytes.len) |n| _ = decodeCode(a, bytes[0..n]) catch continue;

    // Two modules, one CODE: never used in part.
    const key: Key = @splat(3);
    const meta: Meta = .{ .package = "lib", .target = "erlang", .modules = &.{} };
    var enc = Encoder(&default_skips).init(testing.allocator);
    defer enc.deinit();
    try enc.encode(Meta, &meta);
    const meta_bytes = try enc.takeSection();
    defer testing.allocator.free(meta_bytes);
    const strings = try enc.stringsSection();
    defer testing.allocator.free(strings);
    const packed_bytes = try pack(testing.allocator, key, &.{
        .{ .id = .meta, .bytes = meta_bytes },
        .{ .id = .strings, .bytes = strings },
        .{ .id = .code, .bytes = bytes },
    });
    defer testing.allocator.free(packed_bytes);
    try testing.expectError(error.Malformed, read(a, try unpack(a, packed_bytes, key)));
}
