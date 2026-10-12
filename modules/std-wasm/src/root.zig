//! std-wasm — botopink's wasm runtime in Zig (decisions 434 (2), 440, 449,
//! 450, 454): std's host functions, and the Erlang terms with the OTP
//! functions over them.
//!
//! Two value representations, each in its own file (decision 450 (4)):
//!
//! - **the wasm codegen's typed layout** — a string is the address of its
//!   `u32` length with the bytes behind it, an array its slot words:
//!   `wasm.zig`, the program face, over the pure algorithms (`text`,
//!   `number`, `array`, `bigint`, `hash`, `random`);
//! - **the Erlang terms** — `term.zig` (atoms, tuples, lists, maps,
//!   binaries, funs, the exceptions), the OTP functions and BIFs over them
//!   (`otp.zig`: `otp/*.zig` and the `module:name/arity` table), and each
//!   `exports` entry's comptime face (`term_faces.zig`).
//!
//! Both are compiled into one module, `std_wasm.wasm` (a position-independent
//! side module, `zig build std-wasm`), whose functions are decoded into their
//! caller (`compiler-core/src/codegen/wat/std_wasm_link.zig`):
//!
//! - **a `--target wasm` program** links the `std:` exports it calls;
//! - **the comptime runtime** (wasm3 in-process,
//!   `compiler-core/src/comptime/runtime/wat/runtime_module.zig`) links every
//!   `rt_*` export — the terms, the OTP functions, the comptime faces — once
//!   per process; a comptime module's calls resolve to them.
//!
//! A std function is served by std-wasm only where its
//! `#[@External.Wasm(std: "<module>.<function>")]` cell names one of `exports`
//! (decision 440 (3)); there is no match by name. Allocation is always the
//! caller's (`env.bp_alloc`, decision 450 (5)). Each function has a Zig unit
//! test.
const std = @import("std");

pub const hash = @import("hash.zig");
pub const text = @import("text.zig");
pub const number = @import("number.zig");
pub const array = @import("array.zig");
pub const bigint = @import("bigint.zig");
pub const case_tables = @import("case_tables.zig");
pub const term = @import("term.zig");
pub const term_faces = @import("term_faces.zig");
pub const otp = @import("otp.zig");
pub const random = @import("random.zig");

/// A botopink type an export takes or answers. A `string` crosses as the
/// program's string (the address of its `u32` length, the bytes behind it) in
/// a wasm program, and as a binary term at comptime; an `f64`, an `i32` and an
/// `i64` as themselves; a `bool` as an `i32` `0` / `1` (the atoms at
/// comptime); a `string[]` as the program's array (`[n][s0][s1]…`, a list at
/// comptime); a `?string` as the string or `0` (`undefined` at comptime); a
/// `void` result as none.
pub const Type = enum {
    string,
    f64,
    i32,
    i64,
    bool,
    void,
    string_array,
    opt_string,

    /// The type as botopink spells it.
    pub fn spelling(t: Type) []const u8 {
        return switch (t) {
            .string_array => "string[]",
            .opt_string => "?string",
            else => @tagName(t),
        };
    }
};

/// One function std-wasm implements, as a `std:` cell names it.
pub const Export = struct {
    /// `<module>.<function>` — the text after `std:`, and the wasm export's
    /// name in `std_wasm.wasm`.
    name: []const u8,
    params: []const Type,
    result: Type,
    /// The std function that binds it — what a program calls instead
    /// (decision 445: a `std:` cell is std's alone, its export names internal
    /// to std): `hash.contentHash`, `String.trim`.
    api: []const u8,

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
/// and `term_faces.zig` serves each at comptime (`rt_std_<symbol>`) — both
/// checked at compile time.
pub const exports = [_]Export{
    .{ .name = "hash.contentHash", .params = &.{.string}, .result = .string, .api = "hash.contentHash" },
    .{ .name = "text.trim", .params = &.{.string}, .result = .string, .api = "String.trim" },
    .{ .name = "text.trimStart", .params = &.{.string}, .result = .string, .api = "String.trimStart" },
    .{ .name = "text.trimEnd", .params = &.{.string}, .result = .string, .api = "String.trimEnd" },
    .{ .name = "number.floatToString", .params = &.{.f64}, .result = .string, .api = "Float.toString" },
    .{ .name = "text.length", .params = &.{.string}, .result = .i32, .api = "String.length" },
    .{ .name = "text.split", .params = &.{ .string, .string }, .result = .string_array, .api = "String.split" },
    .{ .name = "text.chars", .params = &.{.string}, .result = .string_array, .api = "String.chars" },
    .{ .name = "text.lines", .params = &.{.string}, .result = .string_array, .api = "String.lines" },
    .{ .name = "text.words", .params = &.{.string}, .result = .string_array, .api = "String.words" },
    .{ .name = "text.contains", .params = &.{ .string, .string }, .result = .bool, .api = "String.contains" },
    .{ .name = "text.startsWith", .params = &.{ .string, .string }, .result = .bool, .api = "String.startsWith" },
    .{ .name = "text.endsWith", .params = &.{ .string, .string }, .result = .bool, .api = "String.endsWith" },
    .{ .name = "text.indexOf", .params = &.{ .string, .string }, .result = .i32, .api = "String.indexOf" },
    .{ .name = "text.lastIndexOf", .params = &.{ .string, .string }, .result = .i32, .api = "String.lastIndexOf" },
    .{ .name = "text.at", .params = &.{ .string, .i32 }, .result = .opt_string, .api = "String.at" },
    .{ .name = "text.charCodeAt", .params = &.{ .string, .i32 }, .result = .i32, .api = "String.charCodeAt" },
    .{ .name = "text.padStart", .params = &.{ .string, .i32, .string }, .result = .string, .api = "String.padStart" },
    .{ .name = "text.padEnd", .params = &.{ .string, .i32, .string }, .result = .string, .api = "String.padEnd" },
    .{ .name = "text.repeat", .params = &.{ .string, .i32 }, .result = .string, .api = "String.repeat" },
    .{ .name = "text.replace", .params = &.{ .string, .string, .string }, .result = .string, .api = "String.replace" },
    .{ .name = "text.replaceAll", .params = &.{ .string, .string, .string }, .result = .string, .api = "String.replaceAll" },
    .{ .name = "text.fromCodepoint", .params = &.{.i32}, .result = .string, .api = "String.fromCodepoint" },
    .{ .name = "text.toUpper", .params = &.{.string}, .result = .string, .api = "String.toUpper" },
    .{ .name = "text.toLower", .params = &.{.string}, .result = .string, .api = "String.toLower" },
    .{ .name = "random.float", .params = &.{}, .result = .f64, .api = "io.random.float" },
    .{ .name = "random.seed", .params = &.{.i32}, .result = .void, .api = "io.random.seed" },
    .{ .name = "random.seededFloat", .params = &.{}, .result = .f64, .api = "io.random.seededFloat" },
};

/// A wasm value type a program function takes or answers.
pub const Val = enum { i32, i64, f64 };

/// One function only the wasm codegen calls (decision 442 (2)): no
/// declaration of std carries its name, because its arguments are the
/// codegen's own — a string's code point bounds, an array's slot words
/// whatever its element type, an integer by its carrier. A `std:` cell names
/// none of them (`find` answers only `exports`) and the comptime runtime
/// serves none: a comptime module calls std's methods through their own
/// cells.
pub const Program = struct {
    /// `<module>.<function>`, exported as `std:<name>` as `exports` are.
    name: []const u8,
    params: []const Val,
    result: ?Val,
};

/// Every function std-wasm's program face exports for the wasm codegen alone.
pub const program = [_]Program{
    .{ .name = "text.slice", .params = &.{ .i32, .i32, .i32 }, .result = .i32 },
    .{ .name = "number.i32ToString", .params = &.{.i32}, .result = .i32 },
    .{ .name = "number.i64ToString", .params = &.{.i64}, .result = .i32 },
    .{ .name = "number.u64ToString", .params = &.{.i64}, .result = .i32 },
    .{ .name = "number.i64Text", .params = &.{.i64}, .result = .i32 },
    .{ .name = "number.u64Text", .params = &.{.i64}, .result = .i32 },
    .{ .name = "array.reverse", .params = &.{.i32}, .result = .i32 },
    .{ .name = "array.slice", .params = &.{ .i32, .i32, .i32 }, .result = .i32 },
    .{ .name = "array.prepend", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.concat", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.zip", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.fill", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.joinStrings", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.joinInts", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.joinFloats", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.indexOfWord", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.indexOfString", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.indexOfFloat", .params = &.{ .i32, .f64 }, .result = .i32 },
    .{ .name = "array.lastIndexOfWord", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.lastIndexOfString", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.lastIndexOfFloat", .params = &.{ .i32, .f64 }, .result = .i32 },
    .{ .name = "array.unique", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.flatten", .params = &.{.i32}, .result = .i32 },
    .{ .name = "array.chunked", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "array.sliding", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.add", .params = &.{ .i32, .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.negate", .params = &.{.i32}, .result = .i32 },
    .{ .name = "bigint.multiply", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.divmod", .params = &.{ .i32, .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.compare", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.equalOptional", .params = &.{ .i32, .i32 }, .result = .i32 },
    .{ .name = "bigint.ofI64", .params = &.{.i64}, .result = .i32 },
    .{ .name = "bigint.toI64", .params = &.{.i32}, .result = .i64 },
    .{ .name = "bigint.toF64", .params = &.{.i32}, .result = .f64 },
    .{ .name = "bigint.toString", .params = &.{.i32}, .result = .i32 },
    .{ .name = "bigint.parse", .params = &.{.i32}, .result = .i32 },
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
    return std.mem.eql(u8, result orelse "void", e.result.spelling());
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
    _ = term;
    _ = term_faces;
    _ = otp;
    _ = hash;
    _ = text;
    _ = number;
    _ = array;
    _ = bigint;
    _ = random;
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
