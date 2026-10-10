//! `codegen/beam/term.zig` values as Erlang's external term format.
//!
//! A comptime body's capture — or a decorator's `@Decl` handle — used to be
//! baked into the generated module as a literal map: 230 of the 295 lines of the
//! smallest realistic module, and the only part of it that differs between two
//! call sites of the same template. Encoded here instead, it travels beside the
//! call as bytes the node hands to `binary_to_term/1`, and the module is left
//! with nothing that depends on the call site — so one module serves every call
//! site of a declaration.
//!
//! **Not source text re-parsed in the node.** That shape existed (the beam
//! backend's retired `'__bp_erl_eval'/2`) and measured ≈ 50× a direct call
//! (`codegen/beam/AGENTS.md`); `binary_to_term/1` is a decode, not a compile.
//!
//! Only the variants `Term` has are written, in the minimal encoding for each:
//!
//! | `Term` | tag | shape |
//! |---|---|---|
//! | `atom` | 119 / 118 | `SMALL_ATOM_UTF8_EXT` up to 255 bytes, else `ATOM_UTF8_EXT` |
//! | `binary` | 109 | `BINARY_EXT`, `u32` length |
//! | `integer` | 97 / 98 / 110 | `SMALL_INTEGER_EXT` for `0..255`, `INTEGER_EXT` for an `i32`, else `SMALL_BIG_EXT` |
//! | `float` | 70 | `NEW_FLOAT_EXT`, IEEE-754 big-endian |
//! | `boolean` | 119 | the atom `true` / `false` |
//! | `nil`, empty `list` | 106 | `NIL_EXT` |
//! | `list` | 108 | `LIST_EXT`, `u32` count, `NIL_EXT` tail |
//! | `tuple` | 104 / 105 | `SMALL_TUPLE_EXT` up to arity 255, else `LARGE_TUPLE_EXT` |
//! | `map` | 116 | `MAP_EXT`, `u32` arity, key/value pairs |
//!
//! A list of small integers is written as `LIST_EXT`, never as the `STRING_EXT`
//! shorthand OTP's own `term_to_binary/1` prefers: both decode to the same list,
//! and one encoding for one `Term` variant is one thing to get right.
const std = @import("std");
const Term = @import("../../codegen/beam/term.zig").Term;

/// The leading byte of every external term.
pub const version_magic: u8 = 131;

pub const Error = std.mem.Allocator.Error;

/// `term` as a complete external term (version byte included), allocated in
/// `arena` and owned by the caller.
pub fn encode(arena: std.mem.Allocator, term: Term) Error![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.append(arena, version_magic);
    try write(arena, &out, term);
    return out.toOwnedSlice(arena);
}

fn write(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), term: Term) Error!void {
    switch (term) {
        .atom => |name| try writeAtom(arena, out, name),
        .boolean => |b| try writeAtom(arena, out, if (b) "true" else "false"),
        .binary => |bytes| {
            try out.append(arena, 109);
            try writeU32(arena, out, @intCast(bytes.len));
            try out.appendSlice(arena, bytes);
        },
        .integer => |n| try writeInt(arena, out, n),
        .float => |f| {
            try out.append(arena, 70);
            var buf: [8]u8 = undefined;
            std.mem.writeInt(u64, &buf, @bitCast(f), .big);
            try out.appendSlice(arena, &buf);
        },
        .nil => try out.append(arena, 106),
        .list => |items| {
            if (items.len == 0) {
                try out.append(arena, 106);
                return;
            }
            try out.append(arena, 108);
            try writeU32(arena, out, @intCast(items.len));
            for (items) |item| try write(arena, out, item);
            // An improper list is not representable in `Term`, so the tail is
            // always `[]`.
            try out.append(arena, 106);
        },
        .tuple => |items| {
            if (items.len <= 255) {
                try out.append(arena, 104);
                try out.append(arena, @intCast(items.len));
            } else {
                try out.append(arena, 105);
                try writeU32(arena, out, @intCast(items.len));
            }
            for (items) |item| try write(arena, out, item);
        },
        .map => |entries| {
            try out.append(arena, 116);
            try writeU32(arena, out, @intCast(entries.len));
            for (entries) |e| {
                try write(arena, out, e.key);
                try write(arena, out, e.value);
            }
        },
    }
}

fn writeAtom(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), name: []const u8) Error!void {
    if (name.len <= 255) {
        try out.append(arena, 119);
        try out.append(arena, @intCast(name.len));
    } else {
        try out.append(arena, 118);
        try out.append(arena, @intCast(name.len >> 8));
        try out.append(arena, @truncate(name.len));
    }
    try out.appendSlice(arena, name);
}

fn writeInt(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), n: i64) Error!void {
    if (n >= 0 and n <= 255) {
        try out.appendSlice(arena, &.{ 97, @intCast(n) });
        return;
    }
    if (n >= std.math.minInt(i32) and n <= std.math.maxInt(i32)) {
        try out.append(arena, 98);
        var buf: [4]u8 = undefined;
        std.mem.writeInt(i32, &buf, @intCast(n), .big);
        try out.appendSlice(arena, &buf);
        return;
    }
    // SMALL_BIG_EXT: byte count, sign byte, then the magnitude little-endian.
    // `-minInt(i64)` overflows an i64, so the magnitude is taken in u64.
    const negative = n < 0;
    const magnitude: u64 = if (negative) @as(u64, @intCast(-(n + 1))) + 1 else @intCast(n);
    var digits: [8]u8 = undefined;
    std.mem.writeInt(u64, &digits, magnitude, .little);
    var len: usize = digits.len;
    while (len > 1 and digits[len - 1] == 0) len -= 1;
    try out.appendSlice(arena, &.{ 110, @intCast(len), @intFromBool(negative) });
    try out.appendSlice(arena, digits[0..len]);
}

fn writeU32(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), n: u32) Error!void {
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, n, .big);
    try out.appendSlice(arena, &buf);
}

// ── tests ─────────────────────────────────────────────────────────────────────

/// Every expectation below is `binary_to_list(term_to_binary(T))` read off
/// OTP 29, so the encoder is pinned to the format rather than to itself.
fn expectEncoding(expected: []const u8, term: Term) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const got = try encode(arena_state.allocator(), term);
    try std.testing.expectEqualSlices(u8, expected, got);
}

test "etf: scalars match term_to_binary/1" {
    try expectEncoding(&.{ 131, 119, 2, 'o', 'k' }, Term.atomOf("ok"));
    try expectEncoding(&.{ 131, 109, 0, 0, 0, 2, 'h', 'i' }, Term.str("hi"));
    try expectEncoding(&.{ 131, 97, 7 }, Term.int(7));
    try expectEncoding(&.{ 131, 98, 0, 0, 1, 44 }, Term.int(300));
    try expectEncoding(&.{ 131, 98, 255, 255, 255, 255 }, Term.int(-1));
    try expectEncoding(&.{ 131, 110, 5, 0, 0, 0, 0, 0, 1 }, Term.int(4294967296));
    try expectEncoding(&.{ 131, 70, 63, 248, 0, 0, 0, 0, 0, 0 }, .{ .float = 1.5 });
    try expectEncoding(&.{ 131, 119, 4, 't', 'r', 'u', 'e' }, .{ .boolean = true });
    try expectEncoding(&.{ 131, 119, 5, 'f', 'a', 'l', 's', 'e' }, .{ .boolean = false });
    try expectEncoding(&.{ 131, 106 }, .nil);
}

test "etf: a negative big integer keeps its magnitude" {
    // -4294967296 = {110, 5, sign 1, magnitude little-endian}.
    try expectEncoding(&.{ 131, 110, 5, 1, 0, 0, 0, 0, 1 }, Term.int(-4294967296));
    // The i64 floor, whose magnitude does not fit an i64.
    try expectEncoding(
        &.{ 131, 110, 8, 1, 0, 0, 0, 0, 0, 0, 0, 128 },
        Term.int(std.math.minInt(i64)),
    );
}

test "etf: containers match term_to_binary/1" {
    try expectEncoding(&.{ 131, 106 }, Term.listOf(&.{}));
    // `[1, 2]` as LIST_EXT, where OTP would choose the STRING_EXT shorthand;
    // both decode to the same list.
    try expectEncoding(
        &.{ 131, 108, 0, 0, 0, 2, 97, 1, 97, 2, 106 },
        Term.listOf(&.{ Term.int(1), Term.int(2) }),
    );
    try expectEncoding(
        &.{ 131, 104, 2, 97, 1, 109, 0, 0, 0, 1, 'a' },
        Term.tupleOf(&.{ Term.int(1), Term.str("a") }),
    );
    try expectEncoding(&.{ 131, 116, 0, 0, 0, 0 }, Term.mapOf(&.{}));
    try expectEncoding(
        &.{
            131, 116, 0, 0, 0, 2,   119, 4,   'k', 'i', 'n', 'd',
            109, 0,   0, 0, 4, 'T', 'e', 'x', 't', 119, 1,   'n',
            97,  2,
        },
        Term.mapOf(&.{
            Term.field("kind", Term.str("Text")),
            Term.field("n", Term.int(2)),
        }),
    );
}

test "etf: a capture-shaped term nests without surprises" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const span = Term.mapOf(&.{
        Term.field("start", Term.int(0)),
        Term.field("end", Term.int(5)),
        Term.field("line", Term.int(1)),
    });
    const part = Term.mapOf(&.{
        Term.field("kind", Term.str("Text")),
        Term.field("text", Term.str("cfg-0")),
        Term.field("span", span),
    });
    const capture = Term.mapOf(&.{
        .{ .key = Term.atomOf("__bp_capture"), .value = Term.str("q") },
        Term.field("parts", Term.listOf(&.{part})),
        Term.field("multiline", .{ .boolean = false }),
    });

    const bytes = try encode(arena, capture);
    try std.testing.expectEqual(version_magic, bytes[0]);
    try std.testing.expectEqual(@as(u8, 116), bytes[1]);
    try std.testing.expectEqual(@as(u32, 3), std.mem.readInt(u32, bytes[2..6], .big));
    // The quoted atom keeps its unquoted name — quoting is a source-syntax
    // concern and the external format has none.
    try std.testing.expect(std.mem.indexOf(u8, bytes, "__bp_capture") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "'") == null);
}
