/// 144 B-60 S1 — the level B entry's encoding against the emitters: every
/// module's analysis written as an entry (`bp.analysis_entry`), read back,
/// and emitted on every target (erlang, beam, commonJS with its `.d.ts`, wasm
/// on the `wasi` and the `browser` host) — the output from the decoded
/// analysis must be the output from the live one, byte for byte, over std
/// (every module) and the closure invariant's fixture
/// (`tests/closure_invariant/crowded`: `shelf`, `rival` and the consumer).
/// A round trip re-encoded gives the entry's bytes again. One field dropped on
/// purpose (`instance_lowerings`, a test-only skip) changes the output: a
/// field the format forgets fails here.
///
///
/// S2 — the level-B store in a compile (`analysis_store.Cache`, the comptime
/// pass's `level_b`), in process as `botopink build` runs it: built with no
/// store (`--cold`), then through a store that writes, then through one that
/// reads — every emitted file the same bytes on every target, over the closure
/// invariant's consumers (one consumer reading the library entry the other
/// wrote); an unchanged library is read back and not analysed again
/// (`Store.stats`), its file rewritten with the same bytes included; a changed
/// byte of it, a changed checker or entry format source (the compiler key),
/// another target and a truncated entry analyse it again.
///
/// The unit cache beside it (decision 1008 (2), `unit_cache.zig`, which
/// absorbed level B's CODE): a build that writes stores every dependency's
/// units, one that reads emits no dependency module (every one taken from the
/// cache, `UnitCache.Stats.units_read`) — still the same bytes; `check` writes
/// none, the next build or `test` does, once. `test` (`test_mode`) reads and
/// writes units as `build` does (decision 513: a dependency's unit is the same
/// bytes under both): its outputs, test units included, are the same with
/// units read — whether a `test` or a `build` wrote them — as with none.
///
/// Tests only; nothing here runs in a command.
const std = @import("std");
const bp = @import("botopink");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");
const unit_cache = @import("./unit_cache.zig");
const test_scratch = @import("test_scratch");
const source_stamp = @import("source_stamp");

const entry = bp.analysis_entry;
const codegen = bp.codegen;
const Module = bp.Module;
const ComptimeOutput = codegen.ComptimeOutput;

const testing = std.testing;

/// The targets an entry is built for, as `botopink build` configures them.
const Variant = struct {
    label: []const u8,
    target: codegen.TargetSource,
    host: bp.ast.WasmHost = .wasi,
    typescript: bool = false,
};

const variants = [_]Variant{
    .{ .label = "erlang", .target = .erlang },
    .{ .label = "beam", .target = .beam },
    .{ .label = "commonJS", .target = .commonJS, .typescript = true },
    .{ .label = "wasm", .target = .wasm },
    .{ .label = "wasm.browser", .target = .wasm, .host = .browser },
};

/// The entry a module is filed in: std's one per module, every other package
/// one for all its modules (the project's own included here — it is never
/// stored, but its analysis must survive the format too).
fn groupOf(packages: codegen.crossModule.Packages, name: []const u8) []const u8 {
    if (std.mem.startsWith(u8, name, "std/")) return name;
    return packages.idOf(name).package;
}

const Report = struct {
    /// Modules whose analysis went through an entry.
    stored: usize = 0,
    /// Modules whose emitted output differs (the drop-a-field case counts them).
    differing: usize = 0,
};

/// Analyse `modules` for `v`; encode every analysed module into its entry,
/// emit from the live analysis, then from the entries read back; compare.
/// With `drop` the entries are written and read with that field skipped
/// too, and differing outputs are counted instead of failing.
fn run(comptime skips: []const entry.Skip, gpa: std.mem.Allocator, io: std.Io, modules: []const Module, base: codegen.Config, v: Variant, expect_equal: bool) !Report {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    var cfg = base;
    cfg.targetSource = v.target;
    cfg.wasm_host = v.host;
    cfg.typeDefLanguage = if (v.typescript) .typescript else null;

    var session = try codegen.analyse(gpa, modules, io, cfg);
    defer session.deinit(gpa);
    const live = session.outputs.items;

    // Group the analysed modules by entry, in the session's order.
    var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(usize)) = .empty;
    for (live, 0..) |o, i| {
        if (o.outcome != .ok) continue;
        const gop = try groups.getOrPut(arena, groupOf(cfg.packages, o.name));
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.append(arena, i);
    }

    // Encode BEFORE the live emit: an emitter may rewrite the AST in place.
    const key: entry.Key = @splat(0x5a);
    const decoded = try arena.dupe(ComptimeOutput, live);
    var report: Report = .{};
    var blobs: std.ArrayListUnmanaged([]u8) = .empty;
    for (groups.keys(), groups.values()) |g, idx| {
        const outs = try arena.alloc(ComptimeOutput, idx.items.len);
        const names = try arena.alloc([]const u8, idx.items.len);
        for (idx.items, outs, names) |i, *o, *n| {
            o.* = live[i];
            n.* = live[i].name;
        }
        const bytes = try entry.writeWith(skips, gpa, key, .{ .package = g, .target = v.label, .modules = names }, outs, &.{});
        defer gpa.free(bytes);
        try blobs.append(arena, try arena.dupe(u8, bytes));
        report.stored += idx.items.len;
    }
    var live_emit = try codegen.emit(gpa, live, cfg);
    defer {
        for (live_emit.items) |*o| o.result.deinit(gpa);
        live_emit.deinit(gpa);
    }

    for (groups.values(), blobs.items) |idx, bytes| {
        const e = try entry.unpack(arena, bytes, key);
        const back = try entry.readWith(skips, arena, e);
        try testing.expectEqual(idx.items.len, back.outputs.len);
        for (idx.items, back.outputs) |i, o| {
            try testing.expectEqualStrings(live[i].name, o.name);
            decoded[i] = o;
            // The source text is the driver's, never the entry's.
            decoded[i].src = live[i].src;
        }
        // Encoding what was decoded gives the entry's bytes again.
        const again = try entry.writeWith(skips, gpa, key, back.meta, back.outputs, back.journals);
        defer gpa.free(again);
        try testing.expectEqualSlices(u8, bytes, again);
    }

    var decoded_emit = try codegen.emit(gpa, decoded, cfg);
    defer {
        for (decoded_emit.items) |*o| o.result.deinit(gpa);
        decoded_emit.deinit(gpa);
    }

    try testing.expectEqual(live_emit.items.len, decoded_emit.items.len);
    for (live_emit.items, decoded_emit.items) |a, b| {
        try testing.expectEqualStrings(a.name, b.name);
        const same = sameOutput(a.result, b.result);
        if (!same) {
            report.differing += 1;
            if (expect_equal) {
                std.debug.print("analysis entry: {s} on {s} emits otherwise from its decoded analysis\n", .{ a.name, v.label });
                if (!std.mem.eql(u8, a.result.js, b.result.js)) printFirstDifference(a.result.js, b.result.js);
            }
        }
    }
    if (expect_equal) try testing.expectEqual(@as(usize, 0), report.differing);
    return report;
}

fn sameOutput(a: @FieldType(codegen.ModuleOutput, "result"), b: @FieldType(codegen.ModuleOutput, "result")) bool {
    if (a.failed() != b.failed()) return false;
    if (!std.mem.eql(u8, a.js, b.js)) return false;
    if (!eqlOpt(a.typedef, b.typedef) or !eqlOpt(a.wasm, b.wasm) or !eqlOpt(a.comptime_script, b.comptime_script) or !eqlOpt(a.comptime_trace, b.comptime_trace)) return false;
    if (a.units.len != b.units.len) return false;
    for (a.units, b.units) |x, y| {
        if (!std.mem.eql(u8, x.atom, y.atom) or !std.mem.eql(u8, x.code, y.code)) return false;
    }
    if (a.std_funcs.len != b.std_funcs.len) return false;
    for (a.std_funcs, b.std_funcs) |x, y| {
        if (!std.mem.eql(u8, x.symbol, y.symbol) or !std.mem.eql(u8, x.label, y.label)) return false;
    }
    if ((a.test_unit == null) != (b.test_unit == null)) return false;
    if (a.test_unit) |x| {
        const y = b.test_unit.?;
        if (!std.mem.eql(u8, x.atom, y.atom) or !std.mem.eql(u8, x.code, y.code)) return false;
    }
    return true;
}

fn eqlOpt(a: ?[]const u8, b: ?[]const u8) bool {
    if (a == null or b == null) return a == null and b == null;
    return std.mem.eql(u8, a.?, b.?);
}

fn printFirstDifference(a: []const u8, b: []const u8) void {
    var i: usize = 0;
    while (i < a.len and i < b.len and a[i] == b[i]) i += 1;
    const from = i -| 120;
    std.debug.print("  live:    …{s}…\n  decoded: …{s}…\n", .{ a[from..@min(a.len, i + 120)], b[from..@min(b.len, i + 120)] });
}

/// A program importing every std module, so the session analyses all of std.
fn everyStdModule(arena: std.mem.Allocator) ![]const Module {
    var src: std.ArrayListUnmanaged(u8) = .empty;
    for (bp.comptime_pipeline.std_pkg_modules, 0..) |spm, i| {
        const dotted = try arena.dupe(u8, spm.path["std/".len..]);
        std.mem.replaceScalar(u8, dotted, '/', '.');
        try src.print(arena, "import {{{s} as stdModule{d}}} from \"std\";\n", .{ dotted, i });
    }
    try src.appendSlice(arena, "\npub fn main() -> void {}\n");
    const mods = try arena.alloc(Module, 1);
    mods[0] = .{ .path = "", .source = src.items, .srcPath = "src/main.bp" };
    return mods;
}

/// The closure invariant's busy consumer, loaded as `botopink build` loads it.
const Fixture = struct {
    loaded: sources.Loaded,
    deps: []Module,
    all: []const Module,
    cfg: codegen.Config,
    /// The dependencies' closure keys on the target `load` was given.
    keys: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8) = .empty,
    /// Each dependency package's reader log, for the store's INPUTS.
    logs: std.StringHashMapUnmanaged(*bp.ReadLog) = .empty,
    /// Each dependency package's `.bpr` key: the unit cache's keys.
    runtime: std.StringHashMapUnmanaged(unit_cache.Key) = .empty,

    fn load(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io) !Fixture {
        return loadAt(gpa, arena, io, "tests/closure_invariant/crowded", null);
    }

    /// The project at `project` (from the cwd), its dependencies' keys on
    /// `target` when given.
    fn loadAt(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io, project: []const u8, target: ?code_cache.EntryTarget) !Fixture {
        return loadKeyed(gpa, arena, io, project, target, null);
    }

    /// `loadAt`, each package's key holding the INPUTS its last analysis
    /// filed under `cache_root` when given, as `build` computes it.
    fn loadKeyed(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io, project: []const u8, target: ?code_cache.EntryTarget, cache_root: ?[]const u8) !Fixture {
        const dir = try std.Io.Dir.cwd().realPathFileAlloc(io, project, arena);
        const text = try std.Io.Dir.cwd().readFileAlloc(io, try std.fs.path.join(arena, &.{ dir, "botopink.json" }), arena, .unlimited);
        var proj = try config.parse(arena, text);
        proj.dir = dir;
        var loaded = try sources.load(gpa, io, proj, try std.fs.path.join(arena, &.{ dir, proj.srcDir() }));
        errdefer loaded.free(gpa);
        var keys: libs.ClosureKeys = .{ .arena = arena, .target = target orelse .{ .target = .erlang }, .cache_root = cache_root, .want_runtime = true };
        const deps = try libs.loadDependenciesWith(gpa, io, proj, null, if (target != null) &keys else null);
        errdefer libs.freeModules(gpa, deps);
        return .{
            .loaded = loaded,
            .deps = deps,
            .all = try std.mem.concat(arena, Module, &.{ deps, loaded.modules }),
            .cfg = .{ .build_root = ".botopinkbuild", .packages = try libs.packagesOf(arena, proj, deps), .wasm_artifact = true },
            .keys = keys.keys,
            .logs = keys.logs,
            .runtime = keys.runtime,
        };
    }

    fn free(self: *Fixture, gpa: std.mem.Allocator) void {
        self.loaded.free(gpa);
        libs.freeModules(gpa, self.deps);
    }
};

test "analysis entry: std's every module emits from its decoded analysis what it emits live, on every target" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const modules = try everyStdModule(arena_inst.allocator());
    for (variants) |v| {
        const r = try run(&entry.default_skips, testing.allocator, testing.io, modules, .{}, v, true);
        // Every std module the program reaches went through an entry.
        try testing.expect(r.stored >= bp.comptime_pipeline.std_pkg_modules.len / 2);
    }
}

test "analysis entry: the closure invariant's fixture emits from its decoded analysis what it emits live, on every target" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var fx = try Fixture.load(testing.allocator, arena_inst.allocator(), testing.io);
    defer fx.free(testing.allocator);
    for (variants) |v| {
        const r = try run(&entry.default_skips, testing.allocator, testing.io, fx.all, fx.cfg, v, true);
        try testing.expect(r.stored >= fx.all.len);
    }
}

test "analysis entry: a field the format drops changes the emitted output (instance_lowerings, dropped on purpose)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var fx = try Fixture.load(testing.allocator, arena_inst.allocator(), testing.io);
    defer fx.free(testing.allocator);
    const drop = entry.default_skips ++ [_]entry.Skip{.{ .T = ComptimeOutput.OkData, .field = "instance_lowerings" }};
    const r = try run(&drop, testing.allocator, testing.io, fx.all, fx.cfg, .{ .label = "erlang", .target = .erlang }, false);
    try testing.expect(r.differing > 0);
}

// ── S2: the store in a compile ────────────────────────────────────────────────

fn entryTarget(v: Variant) code_cache.EntryTarget {
    return .{ .target = switch (v.target) {
        .commonJS => .commonJS,
        .erlang => .erlang,
        .beam => .beam,
        .wasm => .wasm,
    }, .host = v.host };
}

const Invocation = struct {
    outputs: std.ArrayListUnmanaged(codegen.ModuleOutput),
    stats: bp.level_b.Stats = .{},
    /// Dependency modules taken from the unit cache instead of emitted.
    units_read: usize = 0,
    /// Unit entries the invocation wrote.
    units_written: usize = 0,

    fn deinit(self: *Invocation, gpa: std.mem.Allocator) void {
        for (self.outputs.items) |*o| o.result.deinit(gpa);
        self.outputs.deinit(gpa);
    }
};

/// One `botopink build` of `fx` on `v`, in process: the comptime pass and the
/// emit, through a fresh store under `root` — written once the generate
/// returned — or through none (`--cold` reads nothing).
fn invoke(gpa: std.mem.Allocator, io: std.Io, fx: *const Fixture, v: Variant, root: ?[]const u8, keys: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8)) !Invocation {
    var cfg = fx.cfg;
    cfg.targetSource = v.target;
    cfg.wasm_host = v.host;
    cfg.typeDefLanguage = if (v.typescript) .typescript else null;
    var cache: analysis_store.Cache = undefined;
    var units_arena = std.heap.ArenaAllocator.init(gpa);
    defer units_arena.deinit();
    var units: unit_cache.Cache = undefined;
    if (root) |r| {
        try cache.init(gpa, io, r, entryTarget(v), keys);
        cache.logs = fx.logs;
        cfg.analysis_store = &cache.store;
        try units.init(gpa, units_arena.allocator(), io, r, entryTarget(v), cfg.packages, &fx.runtime, cfg.codeEmit());
        cfg.unit_cache = &units.iface;
    }
    defer if (root != null) cache.deinit();
    const outputs = try codegen.generateWith(gpa, fx.all, io, cfg, .{ .execute = false });
    if (root == null) return .{ .outputs = outputs };
    cache.commit();
    return .{ .outputs = outputs, .stats = cache.store.stats, .units_read = units.iface.stats.units_read, .units_written = units.written };
}

fn expectSameOutputs(label: []const u8, a: []const codegen.ModuleOutput, b: []const codegen.ModuleOutput) !void {
    try testing.expectEqual(a.len, b.len);
    for (a, b) |x, y| {
        try testing.expectEqualStrings(x.name, y.name);
        if (!sameOutput(x.result, y.result)) {
            std.debug.print("level B: {s}: {s} emits otherwise\n", .{ label, x.name });
            if (!std.mem.eql(u8, x.result.js, y.result.js)) printFirstDifference(x.result.js, y.result.js);
            return error.TestUnexpectedResult;
        }
    }
}

/// The modules of `fx` a package `pkg` owns (its group), or std's.
fn countOf(fx: *const Fixture, pkg: []const u8) usize {
    var n: usize = 0;
    for (fx.all) |m| if (std.mem.eql(u8, m.package, pkg)) {
        n += 1;
    };
    return n;
}

/// Copy the closure invariant's fixture to `to`.
fn copyFixture(arena: std.mem.Allocator, io: std.Io, from: []const u8, to: []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, to);
    var d = try cwd.openDir(io, from, .{ .iterate = true });
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| {
        if (e.name[0] == '.' or std.mem.startsWith(u8, e.name, "out")) continue;
        const src = try std.fs.path.join(arena, &.{ from, e.name });
        const dst = try std.fs.path.join(arena, &.{ to, e.name });
        switch (e.kind) {
            .directory => try copyFixture(arena, io, src, dst),
            .file => try cwd.writeFile(io, .{ .sub_path = dst, .data = try cwd.readFileAlloc(io, src, arena, .unlimited) }),
            else => {},
        }
    }
}

test "level B: build cold, build (writes), build (reads) — every file the same bytes on every target; a second consumer reads the library's entry" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    test_scratch.remove(io, "level-b-equivalence");
    defer test_scratch.remove(io, "level-b-equivalence");
    const root = test_scratch.path(io, "level-b-equivalence");

    for (variants) |v| {
        var crowded = try Fixture.loadAt(gpa, arena, io, "tests/closure_invariant/crowded", entryTarget(v));
        defer crowded.free(gpa);
        var plain = try Fixture.loadAt(gpa, arena, io, "tests/closure_invariant/plain", entryTarget(v));
        defer plain.free(gpa);

        // crowded: cold, writes, reads.
        var cold = try invoke(gpa, io, &crowded, v, null, crowded.keys);
        defer cold.deinit(gpa);
        var writes = try invoke(gpa, io, &crowded, v, root, crowded.keys);
        defer writes.deinit(gpa);
        try testing.expectEqual(@as(usize, 0), writes.stats.modules_read);
        // shelf, rival, and each std module crowded reaches — each one's
        // analysis staged, and its units written once the emit returned.
        try testing.expect(writes.stats.entries_staged >= 3);
        try testing.expect(writes.units_written >= 3);
        try testing.expectEqual(@as(usize, 0), writes.units_read);
        var reads = try invoke(gpa, io, &crowded, v, root, crowded.keys);
        defer reads.deinit(gpa);
        // Only crowded's own modules are analysed again, and emitted: every
        // dependency module takes its unit from the unit cache.
        try testing.expectEqual(countOf(&crowded, ""), reads.stats.modules_analysed);
        try testing.expect(reads.stats.modules_read >= countOf(&crowded, "shelf") + countOf(&crowded, "rival"));
        try testing.expect(reads.units_read >= countOf(&crowded, "shelf") + countOf(&crowded, "rival"));
        try testing.expectEqual(@as(usize, 0), reads.stats.entries_staged);
        try testing.expectEqual(@as(usize, 0), reads.units_written);
        try expectSameOutputs(v.label, cold.outputs.items, writes.outputs.items);
        try expectSameOutputs(v.label, cold.outputs.items, reads.outputs.items);

        // plain reads shelf's entry crowded wrote: one library, one entry.
        var plain_cold = try invoke(gpa, io, &plain, v, null, plain.keys);
        defer plain_cold.deinit(gpa);
        var plain_reads = try invoke(gpa, io, &plain, v, root, plain.keys);
        defer plain_reads.deinit(gpa);
        try testing.expect(plain_reads.stats.modules_read >= countOf(&plain, "shelf"));
        try testing.expect(plain_reads.units_read >= countOf(&plain, "shelf"));
        try expectSameOutputs(v.label, plain_cold.outputs.items, plain_reads.outputs.items);
    }
}

/// The comptime pass alone through a store under `root`, committed — the
/// entries `botopink check` writes, and no units.
fn checkInto(gpa: std.mem.Allocator, io: std.Io, fx: *const Fixture, v: Variant, root: []const u8) !void {
    var cfg = fx.cfg;
    cfg.targetSource = v.target;
    cfg.wasm_host = v.host;
    var cache: analysis_store.Cache = undefined;
    try cache.init(gpa, io, root, entryTarget(v), fx.keys);
    defer cache.deinit();
    cfg.analysis_store = &cache.store;
    var session = try codegen.analyse(gpa, fx.all, io, cfg);
    session.deinit(gpa);
    cache.commit();
    try testing.expect(cache.store.stats.entries_staged >= 1);
}

test "unit cache: after `check` (no units) the next build or `test` writes them, once; `test` reads units as `build` does, with the same outputs" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    const dir = try scratchFixture(arena, io, "level-b-code");
    defer test_scratch.remove(io, "level-b-code");
    const built_root = try std.fs.path.join(arena, &.{ dir, "cache-build" });
    const tested_root = try std.fs.path.join(arena, &.{ dir, "cache-test" });

    for (variants) |v| {
        var fx = try Fixture.loadAt(gpa, arena, io, try std.fs.path.join(arena, &.{ dir, "plain" }), entryTarget(v));
        defer fx.free(gpa);
        const shelf_n = countOf(&fx, "shelf");
        // `botopink test` of the same program: `test_mode`, no `.d.ts`.
        var tested_fx = fx;
        tested_fx.cfg.test_mode = true;
        var tv = v;
        tv.typescript = false;

        try checkInto(gpa, io, &fx, v, built_root);
        try checkInto(gpa, io, &fx, v, tested_root);
        var cold = try invoke(gpa, io, &fx, v, null, fx.keys);
        defer cold.deinit(gpa);
        var tested_cold = try invoke(gpa, io, &tested_fx, tv, null, fx.keys);
        defer tested_cold.deinit(gpa);

        // The first build reads the analysis, emits the dependencies and
        // writes their units; the next one emits none.
        var first = try invoke(gpa, io, &fx, v, built_root, fx.keys);
        defer first.deinit(gpa);
        try testing.expectEqual(@as(usize, 0), first.stats.entries_staged);
        try testing.expectEqual(@as(usize, 0), first.units_read);
        try testing.expect(first.units_written >= 1);
        var second = try invoke(gpa, io, &fx, v, built_root, fx.keys);
        defer second.deinit(gpa);
        try testing.expectEqual(@as(usize, 0), second.units_written);
        try testing.expect(second.units_read >= shelf_n);
        try expectSameOutputs(v.label, cold.outputs.items, first.outputs.items);
        try expectSameOutputs(v.label, cold.outputs.items, second.outputs.items);

        // `test` reads the units a build wrote (the `.d.ts` is part of the
        // key: a build asking for one wrote other units): no dependency
        // module emitted, the outputs those of a `test` that read nothing.
        var tested_built = try invoke(gpa, io, &tested_fx, tv, built_root, fx.keys);
        defer tested_built.deinit(gpa);
        if (!v.typescript) {
            try testing.expectEqual(@as(usize, 0), tested_built.units_written);
            try testing.expect(tested_built.units_read >= shelf_n);
        }
        try expectSameOutputs(v.label, tested_cold.outputs.items, tested_built.outputs.items);

        // `test` after `check` writes the units, once; the next `test` and a
        // build read them — the same outputs.
        var tested_first = try invoke(gpa, io, &tested_fx, tv, tested_root, fx.keys);
        defer tested_first.deinit(gpa);
        try testing.expect(tested_first.stats.modules_read >= shelf_n);
        try testing.expectEqual(@as(usize, 0), tested_first.stats.entries_staged);
        try testing.expectEqual(@as(usize, 0), tested_first.units_read);
        try testing.expect(tested_first.units_written >= 1);
        var tested_second = try invoke(gpa, io, &tested_fx, tv, tested_root, fx.keys);
        defer tested_second.deinit(gpa);
        try testing.expectEqual(@as(usize, 0), tested_second.units_written);
        try testing.expect(tested_second.units_read >= shelf_n);
        try expectSameOutputs(v.label, tested_cold.outputs.items, tested_first.outputs.items);
        try expectSameOutputs(v.label, tested_cold.outputs.items, tested_second.outputs.items);
        var built_tested = try invoke(gpa, io, &fx, v, tested_root, fx.keys);
        defer built_tested.deinit(gpa);
        if (!v.typescript) {
            try testing.expectEqual(@as(usize, 0), built_tested.units_written);
            try testing.expect(built_tested.units_read >= shelf_n);
        }
        try expectSameOutputs(v.label, cold.outputs.items, built_tested.outputs.items);
    }
}

/// The closure invariant's fixture copied to a scratch directory, for a test
/// that changes it.
fn scratchFixture(arena: std.mem.Allocator, io: std.Io, comptime name: []const u8) ![]const u8 {
    test_scratch.remove(io, name);
    const dir = test_scratch.path(io, name);
    try copyFixture(arena, io, "tests/closure_invariant", dir);
    return dir;
}

test "level B: an unchanged library is not analysed again, its file rewritten with the same bytes included; a changed byte of it, another target and a truncated entry are" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    const dir = try scratchFixture(arena, io, "level-b-misses");
    defer test_scratch.remove(io, "level-b-misses");
    const plain_dir = try std.fs.path.join(arena, &.{ dir, "plain" });
    const root = try std.fs.path.join(arena, &.{ dir, "cache" });
    const erl: Variant = .{ .label = "erlang", .target = .erlang };

    var fx = try Fixture.loadAt(gpa, arena, io, plain_dir, entryTarget(erl));
    defer fx.free(gpa);
    const shelf_n = countOf(&fx, "shelf");
    try testing.expect(shelf_n > 0);

    var first = try invoke(gpa, io, &fx, erl, root, fx.keys);
    first.deinit(gpa);
    try testing.expectEqual(@as(usize, 0), first.stats.modules_read);
    const shelf_entry = try analysis_store.packagePath(arena, root, entryTarget(erl), "shelf");
    try std.Io.Dir.cwd().access(io, shelf_entry, .{});

    // Unchanged: shelf (and std) read back, plain's own module alone analysed.
    var second = try invoke(gpa, io, &fx, erl, root, fx.keys);
    second.deinit(gpa);
    try testing.expectEqual(countOf(&fx, ""), second.stats.modules_analysed);
    try testing.expect(second.stats.modules_read >= shelf_n);
    const std_read = second.stats.modules_read - shelf_n;

    // Another target: nothing of erlang's is read.
    const cjs: Variant = .{ .label = "commonJS", .target = .commonJS, .typescript = true };
    var other = try Fixture.loadAt(gpa, arena, io, plain_dir, entryTarget(cjs));
    defer other.free(gpa);
    var on_cjs = try invoke(gpa, io, &other, cjs, root, other.keys);
    on_cjs.deinit(gpa);
    try testing.expectEqual(@as(usize, 0), on_cjs.stats.modules_read);

    // A truncated entry: deleted, shelf analysed again, a whole one written.
    const whole = try std.Io.Dir.cwd().readFileAlloc(io, shelf_entry, arena, .unlimited);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = shelf_entry, .data = whole[0 .. whole.len / 2] });
    var truncated = try invoke(gpa, io, &fx, erl, root, fx.keys);
    truncated.deinit(gpa);
    try testing.expectEqual(std_read, truncated.stats.modules_read);
    try testing.expectEqual(countOf(&fx, "") + shelf_n, truncated.stats.modules_analysed);
    try testing.expectEqualSlices(u8, whole, try std.Io.Dir.cwd().readFileAlloc(io, shelf_entry, arena, .unlimited));

    // The same bytes written again (the file's time moves, its content does
    // not): the key is by content — shelf read back, not analysed.
    const tools = try std.fs.path.join(arena, &.{ dir, "shelf", "src", "tools.bp" });
    const text = try std.Io.Dir.cwd().readFileAlloc(io, tools, arena, .unlimited);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tools, .data = text });
    var same_fx = try Fixture.loadAt(gpa, arena, io, plain_dir, entryTarget(erl));
    defer same_fx.free(gpa);
    try testing.expectEqualSlices(u8, &fx.keys.get("shelf").?, &same_fx.keys.get("shelf").?);
    var same = try invoke(gpa, io, &same_fx, erl, root, same_fx.keys);
    same.deinit(gpa);
    try testing.expectEqual(countOf(&fx, ""), same.stats.modules_analysed);
    try testing.expectEqual(std_read + shelf_n, same.stats.modules_read);
    try testing.expectEqual(@as(usize, 0), same.stats.entries_staged);

    // A changed byte of shelf: a new key, shelf analysed again, its entry replaced.
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tools, .data = try std.mem.concat(arena, u8, &.{ text, "\n" }) });
    var changed_fx = try Fixture.loadAt(gpa, arena, io, plain_dir, entryTarget(erl));
    defer changed_fx.free(gpa);
    try testing.expect(!std.mem.eql(u8, &fx.keys.get("shelf").?, &changed_fx.keys.get("shelf").?));
    var changed = try invoke(gpa, io, &changed_fx, erl, root, changed_fx.keys);
    changed.deinit(gpa);
    try testing.expectEqual(std_read, changed.stats.modules_read);
    try testing.expectEqual(@as(usize, 1), changed.stats.entries_staged);
    try testing.expect(!std.mem.eql(u8, whole, try std.Io.Dir.cwd().readFileAlloc(io, shelf_entry, arena, .unlimited)));
}

test "level B: a file a library's `@embed` reads under its `src` is in the library's key — a changed byte of it, a new key, the library analysed again and its new bytes emitted (decision 519)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    const cwd = std.Io.Dir.cwd();
    test_scratch.remove(io, "level-b-embed");
    defer test_scratch.remove(io, "level-b-embed");
    const dir = test_scratch.path(io, "level-b-embed");
    const files = [_][2][]const u8{
        .{ "banner/botopink.json", "{ \"name\": \"banner\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"root.bp\", \"files\": [\"root.bp\", \"banner.bp\"] }" },
        .{ "banner/src/root.bp", "pub mod banner;\n" },
        .{ "banner/src/banner.bp", "pub fn line() -> string {\n    return @embed(\"src/line.txt\").text();\n}\n" },
        .{ "banner/src/line.txt", "first edition" },
        .{ "app/botopink.json", "{ \"name\": \"app\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"main.bp\", \"dependencies\": { \"banner\": { \"path\": \"../banner\" } } }" },
        .{ "app/src/main.bp", "import {banner.line} from \"banner\";\nimport {io.terminal.print} from \"std\";\n\npub fn main() -> void {\n    print(line());\n}\n" },
    };
    for (files) |f| {
        const path = try std.fs.path.join(arena, &.{ dir, f[0] });
        try cwd.createDirPath(io, std.fs.path.dirname(path).?);
        try cwd.writeFile(io, .{ .sub_path = path, .data = f[1] });
    }
    const app_dir = try std.fs.path.join(arena, &.{ dir, "app" });
    const root = try std.fs.path.join(arena, &.{ dir, "cache" });
    const erl: Variant = .{ .label = "erlang", .target = .erlang };
    const emitted = struct {
        fn has(outputs: []const codegen.ModuleOutput, text: []const u8) bool {
            for (outputs) |o| if (std.mem.indexOf(u8, o.name, "banner") != null and std.mem.indexOf(u8, o.result.js, text) != null) return true;
            return false;
        }
    };

    var fx = try Fixture.loadAt(gpa, arena, io, app_dir, entryTarget(erl));
    defer fx.free(gpa);
    var first = try invoke(gpa, io, &fx, erl, root, fx.keys);
    defer first.deinit(gpa);
    try testing.expect(emitted.has(first.outputs.items, "first edition"));
    try testing.expect(first.stats.entries_staged >= 1);

    // The embedded file changes, nothing else of the library does.
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ dir, "banner", "src", "line.txt" }), .data = "second edition" });
    var changed_fx = try Fixture.loadAt(gpa, arena, io, app_dir, entryTarget(erl));
    defer changed_fx.free(gpa);
    try testing.expect(!std.mem.eql(u8, &fx.keys.get("banner").?, &changed_fx.keys.get("banner").?));
    var changed = try invoke(gpa, io, &changed_fx, erl, root, changed_fx.keys);
    defer changed.deinit(gpa);
    try testing.expectEqual(@as(usize, 1), changed.stats.entries_staged);
    try testing.expect(emitted.has(changed.outputs.items, "second edition"));
    try testing.expect(!emitted.has(changed.outputs.items, "first edition"));
}

test "level B: a file a library's `compiler.load` reads outside its `src` is in the library's key — a changed byte of it, the library analysed again and the new answer emitted (decision 519)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    const cwd = std.Io.Dir.cwd();
    test_scratch.remove(io, "level-b-load");
    defer test_scratch.remove(io, "level-b-load");
    const dir = test_scratch.path(io, "level-b-load");
    const files = [_][2][]const u8{
        .{ "probe/botopink.json", "{ \"name\": \"probe\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"root.bp\", \"files\": [\"root.bp\", \"probe.bp\"] }" },
        .{ "probe/src/root.bp", "pub mod probe;\n" },
        .{ "probe/src/probe.bp", "import {compiler} from \"std\";\n\npub fn loads() -> bool {\n    val r = comptime compiler.load(\"cases/checked\");\n    return r.isOk();\n}\n" },
        .{ "probe/cases/checked/botopink.json", "{ \"name\": \"checked\" }" },
        .{ "probe/cases/checked/src/main.bp", "pub fn answer() -> i32 {\n    return 1;\n}\n" },
        .{ "app/botopink.json", "{ \"name\": \"app\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"main.bp\", \"dependencies\": { \"probe\": { \"path\": \"../probe\" } } }" },
        .{ "app/src/main.bp", "import {probe.loads} from \"probe\";\nimport {io.terminal.print} from \"std\";\n\npub fn main() -> void {\n    print(loads());\n}\n" },
    };
    for (files) |f| {
        const path = try std.fs.path.join(arena, &.{ dir, f[0] });
        try cwd.createDirPath(io, std.fs.path.dirname(path).?);
        try cwd.writeFile(io, .{ .sub_path = path, .data = f[1] });
    }
    const app_dir = try std.fs.path.join(arena, &.{ dir, "app" });
    const root = try std.fs.path.join(arena, &.{ dir, "cache" });
    const erl: Variant = .{ .label = "erlang", .target = .erlang };
    const emitted = struct {
        fn of(outputs: []const codegen.ModuleOutput) []const u8 {
            for (outputs) |o| if (std.mem.indexOf(u8, o.name, "probe") != null and std.mem.indexOf(u8, o.result.js, "loads") != null) return o.result.js;
            return "";
        }
    };

    // Two builds: the first records what the library read, the second files
    // the entry under the key that holds it and is read back by the third.
    var builds: [3][]const u8 = undefined;
    for (&builds) |*b| {
        var fx = try Fixture.loadKeyed(gpa, arena, io, app_dir, entryTarget(erl), root);
        defer fx.free(gpa);
        var inv = try invoke(gpa, io, &fx, erl, root, fx.keys);
        defer inv.deinit(gpa);
        b.* = try arena.dupe(u8, emitted.of(inv.outputs.items));
    }
    try testing.expect(builds[0].len > 0);
    try testing.expectEqualStrings(builds[0], builds[2]);

    // The loaded package now refuses (decision 982: its `src/main.bp`, read
    // through the reader under its directory); nothing under the library's
    // `src` changed.
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ dir, "probe", "cases", "checked", "src", "main.bp" }), .data = "pub fn answer() -> i32 {\n    return \"one\";\n}\n" });
    var changed_fx = try Fixture.loadKeyed(gpa, arena, io, app_dir, entryTarget(erl), root);
    defer changed_fx.free(gpa);
    var changed = try invoke(gpa, io, &changed_fx, erl, root, changed_fx.keys);
    defer changed.deinit(gpa);
    try testing.expectEqual(@as(usize, 1), changed.stats.entries_staged);
    try testing.expect(!std.mem.eql(u8, builds[0], emitted.of(changed.outputs.items)));
}

/// The compiler's part of the key on `target` over a checkout at `checkout`:
/// what `build.zig` embeds as `build_stamp.partition_hash_<target>` (decision
/// 249, `code_cache.compilerKey`), computed by the same function.
fn compilerKeyOf(arena: std.mem.Allocator, io: std.Io, checkout: []const u8, target: []const u8) ![]const u8 {
    var d = try std.Io.Dir.cwd().openDir(io, checkout, .{ .iterate = true });
    defer d.close(io);
    return try arena.dupe(u8, &(try source_stamp.partitionHash(testing.allocator, io, d, target)));
}

test "level B: a changed checker source or entry format source gives every entry a new key; the library is analysed again" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const gpa = testing.allocator;
    const dir = try scratchFixture(arena, io, "level-b-compiler-key");
    defer test_scratch.remove(io, "level-b-compiler-key");
    const shelf_dir = try std.fs.path.join(arena, &.{ dir, "shelf" });
    const root = try std.fs.path.join(arena, &.{ dir, "cache" });
    const erl: Variant = .{ .label = "erlang", .target = .erlang };

    // A checkout in miniature: the checker (`comptime/infer.zig`) and the
    // entry's format (`comptime/analysis_entry.zig`) are shared sources of
    // every backend partition. Its compiler key before and after each changes.
    const checkout = try std.fs.path.join(arena, &.{ dir, "checkout" });
    const cwd = std.Io.Dir.cwd();
    const infer = try std.fs.path.join(arena, &.{ checkout, "modules/compiler-core/src/comptime/infer.zig" });
    const format = try std.fs.path.join(arena, &.{ checkout, "modules/compiler-core/src/comptime/analysis_entry.zig" });
    try cwd.createDirPath(io, std.fs.path.dirname(infer).?);
    try cwd.createDirPath(io, try std.fs.path.join(arena, &.{ checkout, std.fs.path.dirname(source_stamp.PARTITION).? }));
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ checkout, "build.zig" }), .data = "build" });
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ checkout, source_stamp.PARTITION }), .data = "erlang modules/compiler-core/src/codegen/erlang.zig\n" });
    try cwd.writeFile(io, .{ .sub_path = infer, .data = "checker" });
    try cwd.writeFile(io, .{ .sub_path = format, .data = "format" });
    const c1 = try compilerKeyOf(arena, io, checkout, "erlang");
    try cwd.writeFile(io, .{ .sub_path = infer, .data = "checker, changed" });
    const c2 = try compilerKeyOf(arena, io, checkout, "erlang");
    try cwd.writeFile(io, .{ .sub_path = format, .data = "format, changed" });
    const c3 = try compilerKeyOf(arena, io, checkout, "erlang");
    try testing.expect(!std.mem.eql(u8, c1, c2) and !std.mem.eql(u8, c2, c3) and !std.mem.eql(u8, c1, c3));

    var fx = try Fixture.loadAt(gpa, arena, io, try std.fs.path.join(arena, &.{ dir, "plain" }), entryTarget(erl));
    defer fx.free(gpa);
    // shelf's key under each compiler (`closureKeyWith`): its files and
    // manifest the same, the compiler's part another.
    const shelf_text = try cwd.readFileAlloc(io, try std.fs.path.join(arena, &.{ shelf_dir, "botopink.json" }), arena, .unlimited);
    var err: ?@import("manifest").Located = null;
    const m = try @import("manifest").parse(arena, shelf_text, "botopink.json", &err);
    var keys: [3]std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8) = .{ .empty, .empty, .empty };
    for (&keys, [_][]const u8{ c1, c2, c3 }) |*k, c| {
        try k.put(arena, "shelf", try code_cache.closureKeyWith(arena, io, shelf_dir, m, &.{}, entryTarget(erl), c));
    }

    var first = try invoke(gpa, io, &fx, erl, root, keys[0]);
    first.deinit(gpa);
    var same_key = try invoke(gpa, io, &fx, erl, root, keys[0]);
    same_key.deinit(gpa);
    const shelf_n = countOf(&fx, "shelf");
    try testing.expect(same_key.stats.modules_read >= shelf_n);
    const std_read = same_key.stats.modules_read - shelf_n;
    // The checker changed, then the format: each time nothing of shelf's
    // entry is read, shelf is analysed again and its entry replaced.
    for (keys[1..]) |k| {
        var other_key = try invoke(gpa, io, &fx, erl, root, k);
        other_key.deinit(gpa);
        try testing.expectEqual(std_read, other_key.stats.modules_read);
        try testing.expectEqual(countOf(&fx, "") + shelf_n, other_key.stats.modules_analysed);
        try testing.expectEqual(@as(usize, 1), other_key.stats.entries_staged);
    }
}
