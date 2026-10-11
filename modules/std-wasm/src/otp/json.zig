//! `json:encode/1`, byte-compatible with OTP 27+'s: its escapes, a float as
//! `float_to_binary(F, [short])` (`number.shortFloat`).
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const etf = @import("etf.zig");
const T = term.T;

// ── json:encode ──────────────────────────────────────────────────────────────

fn jsonString(bb: T, s: []const u8) bool {
    if (!std.unicode.utf8ValidateSlice(s)) return false;
    term.bbPush(bb, "\"");
    for (s) |c| switch (c) {
        // Two bytes each, never a string per arm (a table of pointers).
        '"', '\\' => term.bbPush(bb, &.{ '\\', c }),
        '\n' => term.bbPush(bb, &.{ '\\', 'n' }),
        '\r' => term.bbPush(bb, &.{ '\\', 'r' }),
        '\t' => term.bbPush(bb, &.{ '\\', 't' }),
        8 => term.bbPush(bb, &.{ '\\', 'b' }),
        12 => term.bbPush(bb, &.{ '\\', 'f' }),
        0...7, 11, 14...31 => {
            const hex = "0123456789ABCDEF";
            term.bbPush(bb, &.{ '\\', 'u', '0', '0', hex[c >> 4], hex[c & 15] });
        },
        else => term.bbPush(bb, &.{c}),
    };
    term.bbPush(bb, "\"");
    return true;
}

/// `json:encode/1` (OTP 27+): what it raises is `{unsupported_type, T}` and
/// `{invalid_byte, B}` — here `badarg` for an invalid UTF-8 string, which no
/// comptime reply carries.
fn jsonEncode(bb: T, t: T) bool {
    switch (term.tagOf(t)) {
        .int => {
            var buf: [24]u8 = undefined;
            term.bbPush(bb, erlang.intText(term.as(term.Int, t).value, &buf));
        },
        .float => {
            var buf: [64]u8 = undefined;
            term.bbPush(bb, term.shortFloat(term.as(term.Float, t).value, &buf));
        },
        .atom => {
            if (t == term.a_true or t == term.a_false or t == term.a_null) {
                term.bbPush(bb, term.atomBytes(t));
            } else if (!jsonString(bb, term.atomBytes(t))) return badJson(t);
        },
        .binary => if (!jsonString(bb, term.binBytes(t))) return badJson(t),
        .nil => term.bbPush(bb, "[]"),
        .cons => {
            const items = term.listItems(t) orelse return badJson(t);
            term.bbPush(bb, "[");
            for (items, 0..) |it, i| {
                if (i > 0) term.bbPush(bb, ",");
                if (!jsonEncode(bb, it)) return false;
            }
            term.bbPush(bb, "]");
        },
        .map => {
            const m = term.as(term.Map, t);
            term.bbPush(bb, "{");
            for (0..m.count) |i| {
                if (i > 0) term.bbPush(bb, ",");
                const k = m.keys[i];
                switch (term.tagOf(k)) {
                    .binary => if (!jsonString(bb, term.binBytes(k))) return badJson(k),
                    .atom => if (!jsonString(bb, term.atomBytes(k))) return badJson(k),
                    .int => {
                        var buf: [24]u8 = undefined;
                        _ = jsonString(bb, erlang.intText(term.as(term.Int, k).value, &buf));
                    },
                    else => return badJson(k),
                }
                term.bbPush(bb, ":");
                if (!jsonEncode(bb, m.vals[i])) return false;
            }
            term.bbPush(bb, "}");
        },
        else => return badJson(t),
    }
    return true;
}

fn badJson(t: T) bool {
    term.raiseError(term.tuple(&.{ term.a_unsupported_type, t }));
    return false;
}

pub fn rt_json_encode(t: T) callconv(.c) term.T {
    const bb = term.rt_bb_new();
    if (!jsonEncode(bb, t)) return &term.nil_cell;
    return term.rt_bb_end(bb);
}
