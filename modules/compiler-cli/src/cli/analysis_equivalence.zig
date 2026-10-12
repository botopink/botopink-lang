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
/// Tests only; nothing here runs in a command.
const std = @import("std");
const bp = @import("botopink");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");

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
        const bytes = try entry.writeWith(skips, gpa, key, .{ .package = g, .target = v.label, .modules = names }, outs);
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
        }
        // Encoding what was decoded gives the entry's bytes again.
        const again = try entry.writeWith(skips, gpa, key, back.meta, back.outputs);
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
    try src.appendSlice(arena, "\npub fn main() {}\n");
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

    fn load(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io) !Fixture {
        const dir = try std.Io.Dir.cwd().realPathFileAlloc(io, "tests/closure_invariant/crowded", arena);
        const text = try std.Io.Dir.cwd().readFileAlloc(io, try std.fs.path.join(arena, &.{ dir, "botopink.json" }), arena, .unlimited);
        var proj = try config.parse(arena, text);
        proj.dir = dir;
        var loaded = try sources.load(gpa, io, proj, try std.fs.path.join(arena, &.{ dir, proj.srcDir() }));
        errdefer loaded.free(gpa);
        const deps = try libs.loadDependencies(gpa, io, proj, null);
        errdefer libs.freeModules(gpa, deps);
        return .{
            .loaded = loaded,
            .deps = deps,
            .all = try std.mem.concat(arena, Module, &.{ deps, loaded.modules }),
            .cfg = .{ .build_root = ".botopinkbuild", .packages = try libs.packagesOf(arena, proj, deps), .wasm_artifact = true },
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
