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
