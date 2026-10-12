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

/// The sections an entry may hold. META, STRINGS and ANALYSIS are S1's;
/// JOURNAL (what a module added to the session's registries, replayed on
/// load) and CODE (a module's own unit on the target) are reserved for the
/// later stages and written by none yet.
pub const SectionId = enum(u32) {
    meta = 1,
    strings = 2,
    /// One per module, in META's module order.
    analysis = 3,
    journal = 4,
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
//   string            (a slice of u8) an index into STRINGS, each content once
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
            const gop = try self.strings.getOrPut(self.gpa, s);
            try writeUleb(self.gpa, &self.out, gop.index);
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
                        const idx: usize = @intCast(try self.uleb());
                        if (idx >= self.strings.len) return error.Malformed;
                        const s = self.strings[idx];
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

// ── The entry (S1: META, STRINGS, ANALYSIS) ───────────────────────────────────

/// META: what the entry is of. Encoded like everything else.
pub const Meta = struct {
    /// The package's import name (`std` for a std module's entry).
    package: []const u8,
    /// `code_cache.EntryTarget.name`: `commonJS`, `erlang`, `beam`, `wasm`,
    /// `wasm.browser`.
    target: []const u8,
    /// The modules, in the order their ANALYSIS sections follow.
    modules: []const []const u8,
};

/// One module's ANALYSIS: the `ComptimeOutput` of a module that analysed,
/// its outcome `ok`.
pub const Analysis = struct {
    name: []const u8,
    src: []const u8,
    srcPath: []const u8,
    ok: comptimeMod.ComptimeOutput.OkData,
};

/// The entry of `outputs` (each `.ok`) under `key`, allocated with `gpa`.
pub fn write(gpa: std.mem.Allocator, key: Key, meta: Meta, outputs: []const comptimeMod.ComptimeOutput) ![]u8 {
    return writeWith(&default_skips, gpa, key, meta, outputs);
}

/// `write` with the skip list given — a test drops a field more.
pub fn writeWith(comptime skips: []const Skip, gpa: std.mem.Allocator, key: Key, meta: Meta, outputs: []const comptimeMod.ComptimeOutput) ![]u8 {
    var enc = Encoder(skips).init(gpa);
    defer enc.deinit();
    var owned: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (owned.items) |b| gpa.free(b);
        owned.deinit(gpa);
    }
    var sections: std.ArrayListUnmanaged(Section) = .empty;
    defer sections.deinit(gpa);

    try enc.encode(Meta, &meta);
    try owned.append(gpa, try enc.takeSection());
    try sections.append(gpa, .{ .id = .meta, .bytes = owned.items[owned.items.len - 1] });
    // STRINGS takes its place second; its bytes are known once every section is written.
    try sections.append(gpa, .{ .id = .strings, .bytes = "" });
    for (outputs) |o| {
        const a: Analysis = .{ .name = o.name, .src = o.src, .srcPath = o.srcPath, .ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.NotAnalysed,
        } };
        try enc.encode(Analysis, &a);
        try owned.append(gpa, try enc.takeSection());
        try sections.append(gpa, .{ .id = .analysis, .bytes = owned.items[owned.items.len - 1] });
    }
    try owned.append(gpa, try enc.stringsSection());
    sections.items[1].bytes = owned.items[owned.items.len - 1];
    return pack(gpa, key, sections.items);
}

/// What `read` gives back: the META and each module's `ComptimeOutput`.
pub const Decoded = struct {
    meta: Meta,
    outputs: []comptimeMod.ComptimeOutput,
};

/// The modules of a proven entry, built in `arena`.
pub fn read(arena: std.mem.Allocator, e: Entry) DecodeError!Decoded {
    return readWith(&default_skips, arena, e);
}

pub fn readWith(comptime skips: []const Skip, arena: std.mem.Allocator, e: Entry) DecodeError!Decoded {
    var dec = try Decoder(skips).init(arena, e.get(.strings) orelse return error.Malformed);
    dec.section(e.get(.meta) orelse return error.Malformed);
    const meta = try dec.decode(Meta);
    if (!dec.done()) return error.Malformed;
    const sections = try e.all(arena, .analysis);
    if (sections.len != meta.modules.len) return error.Malformed;
    const outputs = try arena.alloc(comptimeMod.ComptimeOutput, sections.len);
    for (sections, outputs) |bytes, *out| {
        dec.section(bytes);
        const a = try dec.decode(Analysis);
        if (!dec.done()) return error.Malformed;
        out.* = .{ .name = a.name, .src = a.src, .srcPath = a.srcPath, .outcome = .{ .ok = a.ok } };
    }
    return .{ .meta = meta, .outputs = outputs };
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
}
