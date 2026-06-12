/// `botopink test` — compile in test mode then run every test block.
///
/// Compiles the project with `test_mode = true` (test blocks emit as
/// functions + a registry + runner entry; `fn main/0` is not auto-invoked),
/// writes artifacts under `.botopinkbuild/test-out/`, then executes each
/// module that contains tests and aggregates the exit codes.
///
/// Currently only the `commonJS` target runs tests (node); other targets
/// are pending phases of the `test-blocks` spec.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const scanner = @import("./scanner.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    /// `--filter <substr>` — only run tests whose name contains the substring.
    filter: ?[]const u8 = null,
};

const TEST_OUT_DIR = ".botopinkbuild/test-out";

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget();
    if (target != .commonJS and target != .erlang) {
        reporter.errMsg("`botopink test` currently supports only the commonJS and erlang targets");
        reporter.hintMsg("run with `--target commonJS` or set \"target\": \"commonJS\" in botopink.json");
        return 1;
    }

    // Scan source files: `src/` (inline test blocks) plus `test/` (separate
    // `*_test.bp` suites). Test modules come last so `src/` exports are
    // already registered when they compile.
    // `src/` resolves through the explicit module tree; the flat `test/` suite
    // dir is not a package, so it keeps the plain directory scan.
    var src_loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer src_loaded.free(gpa);
    const src_modules = src_loaded.modules;
    const test_modules = try scanner.scanSources(gpa, io, "test");
    defer scanner.freeModules(gpa, test_modules);

    if (src_modules.len == 0 and test_modules.len == 0) {
        reporter.errMsg("no source files found in src/ or test/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    // Resolve declared external libs (generic — `libs/<name>/`), same as `build`,
    // so a consumer's tests can `import … from "<lib>"`. Dependency modules are
    // compiled first (their types/exports must resolve before the project), but
    // their OWN `test {}` blocks are not run — only the project's are.
    const dep_modules = libs.loadDependencies(gpa, io, proj.dependencies) catch |err| {
        switch (err) {
            error.LibsRootNotFound => reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory"),
            error.LibNotFound => reporter.errMsg("a declared dependency was not found under the libs root"),
            error.LibManifestInvalid => reporter.errMsg("a dependency's botopink.json is invalid"),
            else => reporter.errMsg("failed to load project dependencies"),
        }
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Keep only real `.bp` dependency modules. Declaration-only (`.d.bp`) modules
    // use declaration-file syntax the regular pipeline doesn't parse for external
    // libs yet (the declaration-parse path is std-only), so they are skipped
    // rather than failed — they carry host-bound / gated surface, not runnable
    // code. `build` effectively drops them the same way.
    var real_deps: std.ArrayListUnmanaged(bp.Module) = .empty;
    for (dep_modules) |d| {
        if (!d.declaration) try real_deps.append(arena, d);
    }

    const modules = try std.mem.concat(arena, bp.Module, &.{ real_deps.items, src_modules, test_modules });

    reporter.compiling(modules.len);

    // Build codegen config in test mode.
    const cfg = bp.codegen.Config{
        .targetSource = switch (target) {
            .commonJS => .commonJS,
            .erlang => .erlang,
            else => unreachable, // guarded above
        },
        .comptimeRuntime = switch (target) {
            .commonJS => .node,
            .erlang => .erlang,
            else => unreachable,
        },
        .build_root = ".botopinkbuild",
        .test_mode = true,
    };

    var outputs = bp.codegen.generate(gpa, modules, io, cfg) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    // Check for comptime errors in outputs.
    var had_error = false;
    for (outputs.items) |o| {
        if (o.result.comptime_err) |ce| {
            had_error = true;
            const rendered = ce.renderAlloc(gpa, o.src) catch continue;
            defer gpa.free(rendered);
            std.debug.print("{s}", .{rendered});
        }
    }
    if (had_error) return 1;

    // Modules with parse/type errors produce no output at all — surface that
    // instead of silently skipping their tests.
    if (outputs.items.len < modules.len) {
        const msg = try std.fmt.allocPrint(
            arena,
            "{d} module(s) failed to compile — run `botopink check` for diagnostics",
            .{modules.len - outputs.items.len},
        );
        reporter.errMsg(msg);
        return 1;
    }

    // Write every module's test-mode artifact (test modules `require` their
    // sibling modules on commonJS), then run each module that contains tests.
    std.Io.Dir.cwd().createDirPath(io, TEST_OUT_DIR) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext: []const u8 = switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        else => unreachable,
    };
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .erlang => "escript",
        else => unreachable,
    };

    for (outputs.items) |o| {
        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });
    }

    // Ship runtime `.mjs` sidecars (G2): a dependency's `#[@external]` modules
    // sit a directory deeper here than in their own build, so their relative
    // `require("../../src/x.mjs")` would miss the source — copy each into place.
    if (target == .commonJS) {
        libs.shipMjsSidecars(gpa, io, outputs.items, TEST_OUT_DIR, ext) catch {};
    }

    // commonJS: root-source imports (`import {x};`) emit `require("./module")`
    // — write a `module.js` aggregator that merges every module's exports.
    // Runners only execute as the entry module (`require.main === module`),
    // so requiring a sibling never re-runs its tests.
    if (target == .commonJS) {
        var agg = std.ArrayListUnmanaged(u8).empty;
        defer agg.deinit(arena);
        try agg.appendSlice(arena, "module.exports = Object.assign({}");
        for (outputs.items) |o| {
            // "std" package modules are only reachable via `from "std"` —
            // bare imports (project root) must never see them.
            if (std.mem.startsWith(u8, o.name, "std/")) continue;
            // Test modules export nothing other modules import, and a test module
            // may run module-load side effects (e.g. decorator `@emit`s) that
            // depend on its own bare imports resolving through this aggregator.
            // Requiring one test module from another's run would re-execute it
            // mid-aggregator-build — the circular `require("./module")` would then
            // see an empty object and its side effects would crash. Exclude them.
            if (isTestModule(o.name, test_modules)) continue;
            try agg.appendSlice(arena, ", require(\"./");
            try agg.appendSlice(arena, o.name);
            try agg.appendSlice(arena, ".js\")");
        }
        try agg.appendSlice(arena, ");\n");
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = TEST_OUT_DIR ++ "/module.js", .data = agg.items });

        // Nested modules (a dependency's `jhonstart/hooks.js`) emit a flat
        // `require("./module")` for their bare sibling imports, which would
        // resolve next to themselves (`jhonstart/module.js`), not at the root
        // aggregator. Drop a shim `module.js` in each such directory that points
        // back up to the root one.
        var seen_dirs = std.StringHashMap(void).init(arena);
        for (outputs.items) |o| {
            if (std.mem.startsWith(u8, o.name, "std/")) continue;
            const dir = std.fs.path.dirname(o.name) orelse continue; // null → top level
            if (seen_dirs.contains(dir)) continue;
            try seen_dirs.put(dir, {});

            // One `../` per path segment in `dir` (segments = '/' count + 1).
            const depth = std.mem.count(u8, dir, "/") + 1;
            var shim = std.ArrayListUnmanaged(u8).empty;
            defer shim.deinit(arena);
            try shim.appendSlice(arena, "module.exports = require(\"");
            for (0..depth) |_| try shim.appendSlice(arena, "../");
            try shim.appendSlice(arena, "module\");\n");

            const shim_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}/module.js", .{dir});
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = shim_path, .data = shim.items });
        }
    }

    var any_tests = false;
    var exit_code: u8 = 0;
    for (outputs.items) |o| {
        // Dependency modules are compiled for their exports, not tested here —
        // run only the project's own `test {}` blocks.
        if (isDepModule(o.name, real_deps.items)) continue;
        // Modules without test blocks have no runner — skip them.
        if (std.mem.indexOf(u8, o.result.js, "__bp_run_tests") == null) continue;
        any_tests = true;

        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });

        var argv = std.ArrayListUnmanaged([]const u8).empty;
        defer argv.deinit(arena);
        try argv.append(arena, runner);
        try argv.append(arena, sub_path);
        if (opts.filter) |f| try argv.append(arena, f);

        // Spawn and wait — stdio is inherited so the runner reports directly.
        var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
            const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
            reporter.errMsg(msg);
            return 1;
        };
        defer child.kill(io);

        const term = try child.wait(io);
        const code: u8 = switch (term) {
            .exited => |c| c,
            .signal, .stopped, .unknown => 1,
        };
        if (code != 0) exit_code = code;
    }

    if (!any_tests) {
        reporter.stdout(io, "no test blocks found\n");
        return 0;
    }

    return exit_code;
}

/// True when an output module name belongs to a loaded dependency (so its own
/// `test {}` blocks should not be run by the consumer's `botopink test`).
fn isDepModule(name: []const u8, dep_modules: []const bp.Module) bool {
    for (dep_modules) |d| {
        if (std.mem.eql(u8, d.path, name)) return true;
    }
    return false;
}

/// True when an output module name belongs to a `test/` suite module. These are
/// excluded from the root `module.js` aggregator: they export nothing other
/// modules consume, and cross-loading one (with module-load side effects) from
/// another test's run would hit a half-built aggregator.
fn isTestModule(name: []const u8, test_modules: []const bp.Module) bool {
    for (test_modules) |t| {
        if (std.mem.eql(u8, t.path, name)) return true;
    }
    return false;
}
