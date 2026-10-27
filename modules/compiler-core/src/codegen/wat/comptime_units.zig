//! Decisions 1033 (3), 1035 (1), (3), 1038 (4) — piece C1: the comptime
//! units and their folder.
//!
//! Comptime goes through the program's WasmGC generator one unit per module:
//! a module that declares comptime code — a decorator, a template, a
//! `comptime` expression or block — has a unit `<pkg>@<path>` of its own in
//! `out/wasm-comptime/`, holding only that module's code, compiled by the
//! same generator as `out/wasm/`'s units with no linear memory (1033 (1)):
//! a module the GC lowering refuses is a refusal, never a linear module.
//! The folder also holds every program unit those import, the runtime core
//! and each std unit any of them imports — the core and std units the same
//! bytes as `out/wasm/`'s, so one precompiled artifact serves both (1035 (3)).
//! An evaluation instantiates units and compiles nothing (1035 (1)).
//!
//! `wat.comptimeUnits` emits the units (`codegen.Options.comptime_units`);
//! this file decides which modules are comptime modules and which files the
//! folder holds. Behind `switch_env` until the evaluators switch (C4): the
//! Erlang path evaluates meanwhile.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const runtimeUnit = @import("runtime_unit.zig");

/// The folder beside `out/wasm/` (decision 1033 (3)).
pub const folder = "wasm-comptime";

/// The switch of the stage while the Erlang path is live (until C4): the
/// CLI's build emits the comptime units when this variable is `1`.
pub const switch_env = "BOTOPINK_COMPTIME_UNITS";

/// Whether the module source `src` declares comptime code: it writes
/// `comptime` (an expression, a block, a `comptime` parameter) or a `syntax`
/// parameter (a decorator's, a template's, a function expanded at its call).
/// A source that does not lex declares none.
pub fn declaresComptime(ar: std.mem.Allocator, src: []const u8) !bool {
    var lx = lexerMod.Lexer.init(src);
    const tokens = lx.scanAll(ar) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return false,
    };
    for (tokens, 0..) |t, i| {
        if (t.kind == .@"comptime") return true;
        if (t.kind == .identifier and std.mem.eql(u8, t.lexeme, "syntax") and i + 2 < tokens.len and
            tokens[i + 1].kind == .identifier and tokens[i + 2].kind == .colon) return true;
    }
    return false;
}

/// One file of the folder: `<name>.wasm` and its bytes.
pub const File = struct { name: []const u8, bytes: []const u8 };

/// A module's comptime unit: its stem (`<pkg>@<path>`, the last line of its
/// `botopink.units`) and its binary.
pub const Unit = struct { stem: []const u8, bytes: []const u8 };

/// Every file of `out/wasm-comptime/` for `units`: the runtime core, each std
/// unit any of them imports (and theirs), in dependency order, then each
/// unit as given — the core's and std's bytes the runtime's own, the ones
/// `out/wasm/` holds.
pub fn files(ar: std.mem.Allocator, units: []const Unit) ![]const File {
    const rt = try runtimeUnit.get();
    var out: std.ArrayListUnmanaged(File) = .empty;
    try out.append(ar, .{ .name = runtimeUnit.file_name, .bytes = rt.core_bytes });
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    for (units) |u| try roots.appendSlice(ar, (try runtimeUnit.importsOf(ar, u.bytes)).units);
    for (try rt.closure(ar, roots.items)) |su| try out.append(ar, .{ .name = su.file_name, .bytes = su.bytes });
    for (units) |u| try out.append(ar, .{ .name = try std.fmt.allocPrint(ar, "{s}.wasm", .{u.stem}), .bytes = u.bytes });
    return out.items;
}

test "comptime units: a module declares comptime code when it writes comptime or a syntax parameter" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    try std.testing.expect(try declaresComptime(ar, "fn entity(syntax decl: unknown) -> void {}"));
    try std.testing.expect(try declaresComptime(ar, "val x = comptime f(2);"));
    try std.testing.expect(try declaresComptime(ar, "comptime { print(1); }"));
    try std.testing.expect(!try declaresComptime(ar, "fn f(syntax: i32) -> i32 { return syntax; }"));
    try std.testing.expect(!try declaresComptime(ar, "pub fn main() -> void { print(\"comptime\"); }"));
}
