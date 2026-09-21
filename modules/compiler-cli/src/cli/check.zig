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

    var loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer loaded.free(gpa);
    var test_scan = try scanner.scanSourcesWithFiles(gpa, io, "test");
    defer test_scan.free(gpa);
    const test_modules = test_scan.modules;

    // The flat `test/` directory is not a package, so it never reached the
    // resolver: check its imports here, against the same rule `src/` answers to.
    sources.checkFlatImports(gpa, proj, loaded.modules, test_scan) catch return 1;

    if (loaded.modules.len == 0 and test_modules.len == 0) {
        reporter.errMsg("no source files found in src/ or test/");
        return 1;
    }

    // Resolve declared external libs (generic — `libs/<name>/`), same as `build`,
    // so `import … from "<lib>"` type-checks. Dependencies compile first.
    const dep_modules = libs.loadDependencies(gpa, io, proj, env_map) catch |err| {
        build_cmd.reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Keep only real `.bp` dependency modules. Declaration-only (`.d.bp`) modules
    // use declaration-file syntax the regular pipeline doesn't parse for external
    // libs yet (the declaration-parse path is std-only), so they are skipped
    // rather than failed — they carry host-bound / gated surface, not code.
    var real_deps: std.ArrayListUnmanaged(bp.Module) = .empty;
    for (dep_modules) |d| {
        if (!d.declaration) try real_deps.append(arena, d);
    }

    const all_modules = try std.mem.concat(arena, bp.Module, &.{ real_deps.items, loaded.modules, test_modules });

    reporter.checking(all_modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    var failed: std.ArrayListUnmanaged([]const u8) = .empty;

    // STD-001 — same target-name vocabulary `codegen.generate` threads in,
    // so `botopink check` reds on the same `from "std"` imports `botopink build`
    // would have aborted on.
    var session = bp.comptime_pipeline.compile(
        gpa,
        all_modules,
        io,
        ".botopinkbuild",
        diagnostics.comptimeTargetName(target),
    ) catch |err| {
        reporter.errMsg("type-check failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer session.deinit(gpa);

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
