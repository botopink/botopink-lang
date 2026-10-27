//! The unit cache an emit reads (decision 1008 (2)): a dependency module's
//! unit on the target — its text, its `.d.ts`, its `.wasm`, its type units —
//! taken from a store instead of emitted again. Where the units live, their
//! keys and what is written back are the caller's (`compiler-cli`
//! `unit_cache.zig`); this file is the emitter's side: the interface an
//! emitter asks (`Config.cachedUnit`) and a unit's bytes (`encode`, `take`),
//! the `CodeUnit` encoding of `analysis_entry.zig`.
//!
//! An emitter asks right where it would emit the module, after the program's
//! own refusals (an atom fault, an ambiguous import, a host-fn binding) —
//! those are the program's, never the cache's. A module that reads
//! `@TypeInfo.all` or expands a template querying the catalogue (`readers`,
//! the session's `readers`) answers for the whole program: the store is
//! never asked for it.
const std = @import("std");
const moduleOutput = @import("./moduleOutput.zig");
const entry = @import("../comptime/analysis_entry.zig");

const Allocator = std.mem.Allocator;

pub const UnitCache = struct {
    ctx: *anyopaque,
    vtable: *const VTable,
    /// The modules whose answer is the whole program's: never taken.
    /// `codegen.generateWith` sets the session's; a caller emitting a
    /// program read back sets its own.
    readers: []const []const u8 = &.{},
    /// What the last emit did, for the store's owner to read (a test) —
    /// never a flag or a variable (decision 67).
    stats: Stats = .{},

    pub const VTable = struct {
        /// The encoded unit of module `name` (`encode`), or null: emit it.
        /// Its bytes live as long as the store.
        get: *const fn (ctx: *anyopaque, name: []const u8) ?[]const u8,
        /// The emit returned `outputs` (`readers` still set): the store keeps
        /// what it will of them. `codegen.generateWith` calls it; a caller
        /// emitting through `codegen.emit` calls it itself.
        record: *const fn (ctx: *anyopaque, outputs: []const moduleOutput.ModuleOutput) void,
    };

    pub fn record(self: *UnitCache, outputs: []const moduleOutput.ModuleOutput) void {
        self.vtable.record(self.ctx, outputs);
    }

    pub const Stats = struct {
        /// Modules the emit took from the store instead of emitting.
        units_read: usize = 0,
    };

    /// Whether module `name` answers for the whole program.
    pub fn isReader(self: *const UnitCache, name: []const u8) bool {
        for (self.readers) |r| if (std.mem.eql(u8, r, name)) return true;
        return false;
    }

    /// Module `name`'s unit read back, owned by `gpa`, or null: emit it. A
    /// unit that does not decode, or was emitted otherwise, is not used.
    pub fn take(self: *UnitCache, gpa: Allocator, name: []const u8, how: Emit) !?moduleOutput.GenerateResult {
        if (self.isReader(name)) return null;
        const bytes = self.vtable.get(self.ctx, name) orelse return null;
        var scratch = std.heap.ArenaAllocator.init(gpa);
        defer scratch.deinit();
        const unit = entry.decodeCode(scratch.allocator(), bytes) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.Malformed => return null,
        };
        if (unit.wasm_artifact != how.wasm_artifact) return null;
        if ((unit.result.typedef != null) != how.typedef) return null;
        const owned = try ownResult(gpa, unit.result);
        self.stats.units_read += 1;
        return owned;
    }
};

/// What of the emit's configuration a unit's bytes depend on beyond the
/// module, the target and the host — part of every unit's key.
pub const Emit = struct {
    wasm_artifact: bool,
    /// The build asked for a `.d.ts` (commonJS).
    typedef: bool,
};

/// The bytes of `result`'s unit (a `CodeUnit`), allocated with `gpa`: what
/// a store keeps for one module.
pub fn encode(gpa: Allocator, result: moduleOutput.GenerateResult, how: Emit) ![]u8 {
    const unit: entry.CodeUnit = .{ .wasm_artifact = how.wasm_artifact, .result = result };
    return entry.encodeCode(gpa, &unit);
}

/// The fields of `GenerateResult` `ownResult` copies, `entry.code_skips`
/// aside — a test holds the two lists to the type, so a field added there
/// is copied here too.
const owned_result_fields = [_][]const u8{ "js", "typedef", "units", "comptime_script", "wasm", "std_funcs", "comptime_trace" };

/// `r` (a decoded unit, in a scratch arena) copied into `gpa`, as an
/// emitter's own result is.
fn ownResult(gpa: Allocator, r: moduleOutput.GenerateResult) !moduleOutput.GenerateResult {
    var out: moduleOutput.GenerateResult = .{ .js = try gpa.dupe(u8, r.js), .comptime_script = null };
    errdefer out.deinit(gpa);
    if (r.typedef) |t| out.typedef = try gpa.dupe(u8, t);
    if (r.comptime_script) |t| out.comptime_script = try gpa.dupe(u8, t);
    if (r.wasm) |t| out.wasm = try gpa.dupe(u8, t);
    if (r.comptime_trace) |t| out.comptime_trace = try gpa.dupe(u8, t);
    if (r.units.len > 0) {
        const units = try gpa.alloc(moduleOutput.Unit, r.units.len);
        var filled: usize = 0;
        errdefer {
            for (units[0..filled]) |u| {
                gpa.free(u.atom);
                gpa.free(u.code);
            }
            gpa.free(units);
        }
        for (r.units, units) |u, *d| {
            const atom = try gpa.dupe(u8, u.atom);
            errdefer gpa.free(atom);
            d.* = .{ .atom = atom, .code = try gpa.dupe(u8, u.code) };
            filled += 1;
        }
        out.units = units;
    }
    if (r.std_funcs.len > 0) {
        const funcs = try gpa.alloc(moduleOutput.StdFunc, r.std_funcs.len);
        var filled: usize = 0;
        errdefer {
            for (funcs[0..filled]) |f| {
                gpa.free(f.symbol);
                gpa.free(f.label);
            }
            gpa.free(funcs);
        }
        for (r.std_funcs, funcs) |f, *d| {
            const symbol = try gpa.dupe(u8, f.symbol);
            errdefer gpa.free(symbol);
            d.* = .{ .symbol = symbol, .label = try gpa.dupe(u8, f.label), .hash = f.hash };
            filled += 1;
        }
        out.std_funcs = funcs;
    }
    return out;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "unit cache: every field of GenerateResult is stored and copied back, or named in code_skips" {
    const fields = @typeInfo(moduleOutput.GenerateResult).@"struct".fields;
    try testing.expectEqual(fields.len, owned_result_fields.len + entry.code_skips.len);
    inline for (fields) |f| {
        var found = false;
        for (owned_result_fields) |n| found = found or std.mem.eql(u8, n, f.name);
        inline for (entry.code_skips) |sk| found = found or comptime std.mem.eql(u8, sk.field, f.name);
        try testing.expect(found);
    }
}

test "unit cache: a unit round-trips; another emit's, a reader's or an unknown module's is not taken" {
    const Store = struct {
        bytes: []const u8,
        fn get(ctx: *anyopaque, name: []const u8) ?[]const u8 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            return if (std.mem.eql(u8, name, "lib/a")) self.bytes else null;
        }
        fn record(_: *anyopaque, _: []const moduleOutput.ModuleOutput) void {}
    };
    const how: Emit = .{ .wasm_artifact = true, .typedef = false };
    const bytes = try encode(testing.allocator, .{ .js = @constCast("code"), .comptime_script = null }, how);
    defer testing.allocator.free(bytes);
    var store: Store = .{ .bytes = bytes };
    var cache: UnitCache = .{ .ctx = &store, .vtable = &.{ .get = Store.get, .record = Store.record } };

    var got = (try cache.take(testing.allocator, "lib/a", how)).?;
    defer got.deinit(testing.allocator);
    try testing.expectEqualStrings("code", got.js);
    try testing.expectEqual(@as(usize, 1), cache.stats.units_read);
    try testing.expect(try cache.take(testing.allocator, "lib/b", how) == null);
    try testing.expect(try cache.take(testing.allocator, "lib/a", .{ .wasm_artifact = false, .typedef = false }) == null);
    try testing.expect(try cache.take(testing.allocator, "lib/a", .{ .wasm_artifact = true, .typedef = true }) == null);
    cache.readers = &.{"lib/a"};
    try testing.expect(try cache.take(testing.allocator, "lib/a", how) == null);
    try testing.expectEqual(@as(usize, 1), cache.stats.units_read);
}
