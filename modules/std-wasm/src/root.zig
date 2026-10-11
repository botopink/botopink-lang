//! std-wasm — std's host functions in Zig, compiled to wasm (decisions 434
//! (2), 440).
//!
//! One implementation for two consumers (decision 440 (1)):
//!
//! - **the comptime runtime** (wasm3 in-process,
//!   `compiler-core/src/comptime/runtime/wat/`) is compiled with this
//!   package — `rt.zig`, the term library a lowered comptime module links
//!   against, imports it — and serves each entry of `exports` as the runtime
//!   export `rt_std_<symbol>`, plus the text and number algorithms behind the
//!   OTP calls a comptime module's primitive methods make
//!   (`string:uppercase/1`, `string:trim/1,2`, `float_to_binary/2` …);
//! - **a `--target wasm` program**: `wasm.zig` is the package's program
//!   face, compiled to `std_wasm.wasm` (a position-independent side module,
//!   `zig build std-wasm`), whose functions the wasm codegen decodes into the
//!   program's own module (`compiler-core/src/codegen/wat/std_wasm_link.zig`).
//!
//! A std function is served by std-wasm only where its
//! `#[@External.Wasm("std:<module>.<function>")]` cell names one of `exports`
//! (decision 440 (3)); there is no match by name. Everything here is pure —
//! no term layout, no allocation of its own. Each function has a Zig unit
//! test.
const std = @import("std");

pub const hash = @import("hash.zig");
pub const text = @import("text.zig");
pub const number = @import("number.zig");

/// A botopink type an export takes or answers. A `string` crosses as the
/// program's string (the address of its `u32` length, the bytes behind it) in
/// a wasm program, and as a binary term at comptime; an `f64` as itself.
pub const Type = enum {
    string,
    f64,

    /// The type as botopink spells it.
    pub fn spelling(t: Type) []const u8 {
        return @tagName(t);
    }
};

/// One function std-wasm implements, as a `std:` cell names it.
pub const Export = struct {
    /// `<module>.<function>` — the text after `std:`, and the wasm export's
    /// name in `std_wasm.wasm`.
    name: []const u8,
    params: []const Type,
    result: Type,

    /// The symbol a comptime module calls it by, in the Erlang module
    /// `erlang_module`: the name with `.` written `__`
    /// (`hash__contentHash`); the comptime runtime's export that answers it
    /// is `"rt_std_" ++ symbol`. Comptime only (`symbolInto` at run time).
    pub fn symbol(comptime e: Export) []const u8 {
        comptime {
            var out: [e.name.len + 1]u8 = undefined;
            _ = e.symbolInto(&out);
            const final = out;
            return &final;
        }
    }

    /// `symbol` at run time, into `buf`.
    pub fn symbolInto(e: Export, buf: []u8) []const u8 {
        const dot = std.mem.indexOfScalar(u8, e.name, '.').?;
        @memcpy(buf[0..dot], e.name[0..dot]);
        buf[dot] = '_';
        buf[dot + 1] = '_';
        @memcpy(buf[dot + 2 ..][0 .. e.name.len - dot - 1], e.name[dot + 1 ..]);
        return buf[0 .. e.name.len + 1];
    }
};

/// The Erlang module name a comptime module's call to a std-wasm export is
/// written under (`bp_std_wasm:hash__contentHash(S)`); the comptime runtime's
/// lowering maps each to `"rt_std_" ++ symbol`.
pub const erlang_module = "bp_std_wasm";

/// Every function std-wasm implements, by the name a `std:` cell gives it.
/// `wasm.zig` exports each under that name with the matching wasm signature,
/// and `rt.zig` serves each at comptime — both checked at compile time.
pub const exports = [_]Export{
    .{ .name = "hash.contentHash", .params = &.{.string}, .result = .string },
    .{ .name = "text.trim", .params = &.{.string}, .result = .string },
    .{ .name = "text.trimStart", .params = &.{.string}, .result = .string },
    .{ .name = "text.trimEnd", .params = &.{.string}, .result = .string },
    .{ .name = "number.floatToString", .params = &.{.f64}, .result = .string },
};

/// The export a `std:` cell names, or null when std-wasm has none of that
/// name.
pub fn find(name: []const u8) ?Export {
    for (exports) |e| if (std.mem.eql(u8, e.name, name)) return e;
    return null;
}

/// Whether a declaration whose parameters and return botopink spells
/// `params` and `result` (`"string"`, `"f64"`; null for no return) has the
/// types of `e` — what a `std:` cell is checked by (decision 440 (3)).
pub fn matches(e: Export, params: []const []const u8, result: ?[]const u8) bool {
    if (params.len != e.params.len) return false;
    for (params, e.params) |p, t| if (!std.mem.eql(u8, p, t.spelling())) return false;
    const r = result orelse return false;
    return std.mem.eql(u8, r, e.result.spelling());
}

/// `e`'s signature as botopink spells it, `(string) -> string`, into `buf`.
pub fn signatureText(e: Export, buf: []u8) []const u8 {
    var n: usize = 0;
    buf[n] = '(';
    n += 1;
    for (e.params, 0..) |t, i| {
        if (i > 0) {
            @memcpy(buf[n..][0..2], ", ");
            n += 2;
        }
        @memcpy(buf[n..][0..t.spelling().len], t.spelling());
        n += t.spelling().len;
    }
    @memcpy(buf[n..][0..5], ") -> ");
    n += 5;
    @memcpy(buf[n..][0..e.result.spelling().len], e.result.spelling());
    return buf[0 .. n + e.result.spelling().len];
}

/// Every export's name, `, `-separated — what a refusal lists.
pub const names = blk: {
    var out: []const u8 = "";
    for (exports, 0..) |e, i| out = out ++ (if (i > 0) ", " else "") ++ e.name;
    break :blk out;
};

test {
    _ = hash;
    _ = text;
    _ = number;
}

test "find: an export by the name a std: cell gives it" {
    const e = find("hash.contentHash") orelse return error.TestExpectedExport;
    try std.testing.expectEqual(Type.string, e.result);
    try std.testing.expect(find("hash.sha256") == null);
    try std.testing.expect(find("contentHash") == null);
}

test "every symbol is the name with its dot written as two underscores" {
    inline for (exports) |e| {
        var buf: [128]u8 = undefined;
        const sym = comptime e.symbol();
        try std.testing.expectEqualStrings(sym, e.symbolInto(&buf));
        try std.testing.expect(std.mem.indexOfScalar(u8, sym, '.') == null);
    }
    try std.testing.expectEqualStrings("hash__contentHash", comptime exports[0].symbol());
}

test "matches: the spelled types, exactly" {
    const e = find("number.floatToString").?;
    try std.testing.expect(matches(e, &.{"f64"}, "string"));
    try std.testing.expect(!matches(e, &.{"f32"}, "string"));
    try std.testing.expect(!matches(e, &.{"f64"}, null));
    try std.testing.expect(!matches(e, &.{ "f64", "f64" }, "string"));
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("(f64) -> string", signatureText(e, &buf));
}
