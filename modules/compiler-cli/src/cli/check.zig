/// `botopink check [<path>]` — type-check without generating code.
///
/// Loads the same module set `botopink test` compiles — `src/` through the
/// module tree **and** the flat `test/` suite — plus the declared dependencies,
/// so a module `test` reports as broken is one `check` diagnoses. Every failing
/// module is rendered with file, line and excerpt from its comptime outcome —
/// lex and parse errors included (`diagnostics.printSyntaxError`).
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const scanner = @import("./scanner.zig");
const libs = @import("./libs.zig");
const build_cmd = @import("./build.zig");
const diagnostics = @import("./diagnostics.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");

pub const Options = struct {
    /// Project directory to check; null → the current directory.
    path: ?[]const u8 = null,
};

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    if (opts.path) |p| {
        std.process.setCurrentPath(io, p) catch |err| {
            const msg = try std.fmt.allocPrint(arena, "cannot enter '{s}': {s}", .{ p, @errorName(err) });
            reporter.errMsg(msg);
            return 1;
        };
    }

    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = proj.parsedTarget() orelse {
        build_cmd.reportUnsupportedTarget(proj.target);
        return 1;
    };

    // Resolve declared external libs (generic — `libs/<name>/`), same as `build`,
    // so `import … from "<lib>"` type-checks. Dependencies compile first,
    // and load first: a `.bpp` file unfolds onto the package `"bpp"` names
    // (front 116 step 2, `closure_keys.bpp`).
    const entry_target: code_cache.EntryTarget = .{ .target = target, .host = proj.wasmHost() };
    var closure_keys: libs.ClosureKeys = .{ .arena = arena, .target = entry_target };
    const dep_modules = libs.loadDependenciesWith(gpa, io, proj, env_map, &closure_keys) catch |err| {
        build_cmd.reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    var loaded = sources.loadWith(gpa, io, proj, proj.srcDir(), if (closure_keys.bpp) |*b| b else null) catch return 1;
    defer loaded.free(gpa);
    var test_scan = try scanner.scanSourcesWithFiles(gpa, io, "test");
    defer test_scan.free(gpa);
    // Decision 519 — a test module's `@embed` reads the package's files.
    for (test_scan.modules) |*m| m.files = bp.PackageFiles.disk(io, proj.dir);
    const test_modules = test_scan.modules;

    // The flat `test/` directory is not a package, so it never reached the
    // resolver: check its imports here, against the same rule `src/` answers to.
    sources.checkFlatImports(gpa, proj, loaded.modules, test_scan) catch return 1;

    if (loaded.modules.len == 0 and test_modules.len == 0) {
        reporter.errMsg("no source files found in src/ or test/");
        return 1;
    }

    // The code cache's level B (144 B-60): the target's entries, as `build`
    // reads and writes them.
    var level_b: analysis_store.Cache = undefined;
    try level_b.init(gpa, io, analysis_store.root(proj), entry_target, closure_keys.keys);
    defer level_b.deinit();
    // The compiled comptime modules beside it (decision 543).
    try bp.comptime_runtime.useCompiledCache(analysis_store.root(proj), code_cache.cold);

    // A dependency's modules are one set under every command, so one level B
    // entry.
    const all_modules = try std.mem.concat(arena, bp.Module, &.{ dep_modules, loaded.modules, test_modules });

    reporter.checking(all_modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    var failed: std.ArrayListUnmanaged([]const u8) = .empty;

    // The analysis reads no target (decision 798 (4)); the target's own
    // refusals — a std call with no binding for it (STD-001), a
    // `compiler.beamMemory` off the BEAM — are the ones `botopink build`'s
    // emit gives (`codegen.targetCheck`), so `check` reds where `build` would.
    var session = bp.comptime_pipeline.compileWith(
        gpa,
        all_modules,
        io,
        ".botopinkbuild",
        &level_b.store,
    ) catch |err| {
        reporter.errMsg("type-check failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer session.deinit(gpa);
    level_b.commit();
    _ = try bp.codegen.targetCheck.apply(session.arena.allocator(), session.outputs.items, diagnostics.comptimeTargetName(target, proj.wasmHost()));

    const t1 = std.Io.Timestamp.now(io, .awake);

    for (session.outputs.items) |o| {
        if (diagnostics.renderOutcome(gpa, io, arena, o)) try failed.append(arena, o.name);
    }

    diagnostics.reportOrphans(arena, loaded.orphans.len);

    if (failed.items.len > 0) {
        diagnostics.reportFailedModules(arena, failed.items);
        return 1;
    }

    reporter.checked(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}
