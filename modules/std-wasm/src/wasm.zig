//! std-wasm's program face: `zig build std-wasm` → `zig-out/lib/std_wasm.wasm`,
//! a position-independent side module (wasm32-freestanding, MVP + bulk
//! memory, `dylink.0`) whose functions the wasm codegen decodes into a
//! `--target wasm` program (`compiler-core/src/codegen/wat/std_wasm_link.zig`,
//! decision 440 (2)). The comptime runtime does not link this file — it
//! compiles the package into its own term library (`root.zig`).
//!
//! Each entry of `root.exports` is exported under its cell's text,
//! `std:<module>.<function>` (`std:hash.contentHash`) — never the bare
//! `hash.contentHash`, which is the name Zig gives `hash.zig`'s own
//! `contentHash`: an export of that name resolves to itself, and the
//! optimizer, seeing the recursion, compiles the export to `unreachable`. Its
//! values are the program's own: a `string` is the
//! address of its `u32` length with the bytes behind it — the layout every
//! string of a wasm program has — and an answer is a fresh string allocated
//! through the program's bump allocator, imported as `env.bp_alloc` (the
//! decoder binds it to `$__alloc`). The module's data, its function table and
//! its stack are placed by the program (`__memory_base`, `__table_base`,
//! `__stack_pointer`).
const std = @import("std");
const root = @import("root.zig");

/// The program's allocator: `n` fresh bytes, 4-aligned; it grows the memory
/// or traps.
extern "env" fn bp_alloc(n: u32) u32;

/// The bytes of the program string at `s`.
fn arg(s: u32) []const u8 {
    const len = @as(*const u32, @ptrFromInt(s)).*;
    return @as([*]const u8, @ptrFromInt(s + 4))[0..len];
}

/// `bytes` as a fresh program string.
fn fresh(bytes: []const u8) u32 {
    const p = bp_alloc(@intCast(bytes.len + 4));
    @as(*u32, @ptrFromInt(p)).* = @intCast(bytes.len);
    @memcpy(@as([*]u8, @ptrFromInt(p + 4))[0..bytes.len], bytes);
    return p;
}

/// `hash.contentHash`. A program string is valid UTF-8, so the refusal is
/// unreachable from a program; it traps rather than answer.
fn contentHash(s: u32) callconv(.c) u32 {
    var buf: [8]u8 = undefined;
    const h = root.hash.contentHash(&buf, arg(s)) catch @trap();
    return fresh(h);
}

fn trimmed(s: u32, dir: root.text.TrimDir) u32 {
    const a = arg(s);
    const t = root.text.trim(a, dir);
    // Nothing trimmed: the string itself (strings are immutable).
    if (t.len == a.len) return s;
    return fresh(t);
}

/// `String.trim`.
fn trim(s: u32) callconv(.c) u32 {
    return trimmed(s, .both);
}

/// `String.trimStart`.
fn trimStart(s: u32) callconv(.c) u32 {
    return trimmed(s, .leading);
}

/// `String.trimEnd`.
fn trimEnd(s: u32) callconv(.c) u32 {
    return trimmed(s, .trailing);
}

/// `Float.toString`, and the text a wasm program writes for a float
/// anywhere (decision 441).
fn floatToString(f: f64) callconv(.c) u32 {
    var buf: [64]u8 = undefined;
    return fresh(root.number.shortFloat(f, &buf));
}

/// Each export by its `std:` name — the table the check below reads; the
/// `@export`s after it spell the same pairs.
const faces = .{
    .{ "hash.contentHash", contentHash },
    .{ "text.trim", trim },
    .{ "text.trimStart", trimStart },
    .{ "text.trimEnd", trimEnd },
    .{ "number.floatToString", floatToString },
};

/// The wasm type a `root.Type` crosses as.
fn wasmType(t: root.Type) type {
    return switch (t) {
        .string => u32,
        .f64 => f64,
    };
}

comptime {
    // Every export of `root.exports` is here, under its name, with the
    // signature its types cross as — and nothing else is.
    if (faces.len != root.exports.len) @compileError("wasm.zig exports a different set than root.exports");
    for (root.exports) |e| {
        var found = false;
        for (faces) |face| if (std.mem.eql(u8, face[0], e.name)) {
            found = true;
            const info = @typeInfo(@TypeOf(face[1])).@"fn";
            if (info.params.len != e.params.len) @compileError(e.name ++ ": wrong arity");
            for (info.params, e.params) |p, t| if (p.type.? != wasmType(t)) @compileError(e.name ++ ": wrong parameter type");
            if (info.return_type.? != wasmType(e.result)) @compileError(e.name ++ ": wrong result type");
        };
        if (!found) @compileError("std-wasm implements " ++ e.name ++ " but wasm.zig does not export it");
    }
    @export(&contentHash, .{ .name = "std:hash.contentHash" });
    @export(&trim, .{ .name = "std:text.trim" });
    @export(&trimStart, .{ .name = "std:text.trimStart" });
    @export(&trimEnd, .{ .name = "std:text.trimEnd" });
    @export(&floatToString, .{ .name = "std:number.floatToString" });
}
