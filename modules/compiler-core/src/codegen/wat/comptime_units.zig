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
//! `wat.comptimeUnits` emits the units (`codegen.comptimeUnits`), run by
//! the driver over every analysis (1058 (2)); this file decides which
//! modules are comptime modules, the folder's files, the record of what the
//! lowering refused (`refused_file`, 1058 (3): recorded, not failed, until
//! C4), and the units' cache entries (`Cache`, `keyOf`).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const runtimeUnit = @import("runtime_unit.zig");
const moduleOutput = @import("../moduleOutput.zig");
const comptimeMod = @import("../../comptime.zig");
const analysisEntry = @import("../../comptime/analysis_entry.zig");

/// The folder beside `out/wasm/` (decision 1033 (3)).
pub const folder = "wasm-comptime";

/// The folder's record of the modules the lowering refused: one
/// `<module>\t<gap>` line each (decision 1058 (3)).
pub const refused_file = "refused.txt";

/// A comptime unit's cache key (`keyOf`).
pub const Key = [32]u8;

/// Decisions 1008 (2), 1058 (2) — the store of comptime units by module key:
/// the driver's (`compiler-cli` `build.zig`), which adds the compiler's
/// identity to each key. `get` answers `stored`'s bytes, living as long as
/// the store.
pub const Cache = struct {
    ctx: *anyopaque,
    get: *const fn (ctx: *anyopaque, key: Key) ?[]const u8,
    put: *const fn (ctx: *anyopaque, key: Key, bytes: []const u8) void,
};

/// The key of module `name`'s comptime unit: its analysis as the code
/// cache's level B encodes it (what its lowering reads), and the keys of the
/// program units it reaches, in order.
pub fn keyOf(gpa: std.mem.Allocator, name: []const u8, src_path: []const u8, ok: comptimeMod.ComptimeOutput.OkData, deps: []const Key) !Key {
    var enc = analysisEntry.Encoder(&analysisEntry.default_skips).init(gpa);
    defer enc.deinit();
    const a: analysisEntry.Analysis = .{ .name = name, .srcPath = src_path, .ok = ok };
    try enc.encode(analysisEntry.Analysis, &a);
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink comptime unit 1\x00");
    h.update(name);
    h.update("\x00");
    h.update(enc.out.items);
    for (enc.strings.keys()) |str| {
        h.update(str);
        h.update("\x00");
    }
    for (deps) |d| h.update(&d);
    return h.finalResult();
}

/// What the cache keeps of a module's comptime result: `U` and its unit's
/// bytes, or `R` and the refusal's text; null for anything else.
pub fn stored(ar: std.mem.Allocator, r: moduleOutput.GenerateResult) !?[]const u8 {
    if (r.wasm) |bin| if (!r.failed()) return try std.mem.concat(ar, u8, &.{ "U", bin });
    if (refusalOf(r)) |m| return try std.mem.concat(ar, u8, &.{ "R", m });
    return null;
}

/// `stored`'s bytes as a result again, owned by `gpa`.
pub fn restored(gpa: std.mem.Allocator, bytes: []const u8) !moduleOutput.GenerateResult {
    var out: moduleOutput.GenerateResult = .{ .js = try gpa.dupe(u8, ""), .comptime_script = null };
    errdefer out.deinit(gpa);
    if (bytes.len > 0 and bytes[0] == 'U') {
        out.wasm = try gpa.dupe(u8, bytes[1..]);
    } else {
        out.diagnostic = .{ .type = .{ .message = try gpa.dupe(u8, if (bytes.len > 0) bytes[1..] else ""), .loc = null } };
    }
    return out;
}

/// The text of the refusal `r` carries, or null.
pub fn refusalOf(r: moduleOutput.GenerateResult) ?[]const u8 {
    if (r.diagnostic) |d| return switch (d) {
        .type => |t| t.message,
        .syntax => "the module does not parse",
    };
    if (r.comptime_err != null) return "the module's comptime validation failed";
    return null;
}

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
