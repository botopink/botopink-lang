/// `botopink build` — compile the project to the configured target.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");
const diagnostics = @import("./diagnostics.zig");

const Module = bp.Module;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    out_dir: []const u8 = "out",
    typescript: bool = false,
};

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    env_map: libs.EnvMap,
) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget() orelse {
        reportUnsupportedTarget(proj.target);
        return 1;
    };

    // Resolve project source files through the explicit module tree.
    // (`sources.load` reports resolution errors itself.)
    var loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer loaded.free(gpa);
    const project_modules = loaded.modules;

    if (project_modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    // Resolve declared external libs from disk (generic — `libs/<name>/`). The
    // core never names a lib; it only sees these as ordinary `Module[]` and
    // resolves `from "<lib>"` through the shared import registry. `std` is the
    // embedded exception and is not loaded here.
    const dep_modules = libs.loadDependencies(gpa, io, proj, env_map) catch |err| {
        reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Compile dependency modules ahead of project modules (their types/decorators
    // must resolve before the project that imports them).
    const all_modules = try std.mem.concat(arena, Module, &.{ dep_modules, project_modules });

    reporter.compiling(all_modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // A module that does not lex, parse or type-check is reported with its
    // location (below); the rest still compile.
    const modules = all_modules;

    // Build codegen config.
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (opts.typescript) .typescript else null,
        .build_root = ".botopinkbuild",
    };

    // Run the compiler. `build` emits only: the program is not executed.
    var outputs = bp.codegen.generateWith(gpa, modules, io, cfg, .{ .execute = false }) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    const t1 = std.Io.Timestamp.now(io, .awake);

    // Every module comes back from the compiler; one that did not lex, parse,
    // type-check or pass comptime validation carries its diagnostic instead of
    // an artifact, rendered here.
    const failed = try diagnostics.failedOutputs(gpa, io, arena, modules, outputs.items);

    // Write what compiled; remove any previous artifact of a module that did not,
    // so nothing stale is left claiming to be current.
    try writeOutputs(gpa, io, outputs.items, opts.out_dir, target, env_map);
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target);

    diagnostics.reportOrphans(arena, loaded.orphans.len);

    if (failed.len > 0) {
        diagnostics.reportFailedModules(arena, failed);
        return 1;
    }

    reporter.compiled(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}

/// `botopink.json` names a target the compiler does not support.
pub fn reportUnsupportedTarget(name: []const u8) void {
    var buf: [256]u8 = undefined;
    reporter.errMsg(std.fmt.bufPrint(&buf, "botopink.json declares an unsupported target '{s}'", .{name}) catch "botopink.json declares an unsupported target");
    reporter.hintMsg("use one of commonJS, erlang, beam or wasm");
}

/// Shared message for a `libs.loadDependencies` failure.
pub fn reportDependencyError(err: anyerror) void {
    switch (err) {
        error.LibsRootNotFound => {
            reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory");
            reporter.hintMsg("if your botopink.json uses the new object form ({\"<name>\": {\"git\": ...}}), run `bpmp install` to fetch deps into $BPMP_HOME first");
        },
        error.LibNotFound => reporter.hintMsg("libraries resolve from BOTOPINK_LIB_ROOTS, then <ancestor>/repository/botopink-lang/libs, <ancestor>/repository and <ancestor>/libs, then .botopinkbuild/deps (`bpmp install`)"),
        // Already rendered, located in the manifest that is wrong.
        error.LibManifestInvalid => {},
        // Already rendered with the path and the manifest line.
        error.LibFileNotFound => {},
        else => reporter.errMsg("failed to load project dependencies"),
    }
}

pub fn artifactExt(target: config.Target) []const u8 {
    return switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        .beam => ".S",
        .wasm => ".wat",
    };
}

/// The codegen target a CLI target emits.
pub fn targetSource(target: config.Target) bp.codegen.TargetSource {
    return switch (target) {
        .commonJS => .commonJS,
        .erlang => .erlang,
        .beam => .beam,
        .wasm => .wasm,
    };
}

/// Where a target's artifacts live under `out/`.
///
/// `erlc` refuses a `-module` atom that differs from its file's basename, so an
/// erlang or BEAM artifact is named by the module ATOM (`std/math` →
/// `std@math.erl`) and the tree is FLAT — one directory per target, which is
/// also the only shape `erl -pa <one directory>` can load a multi-module program
/// from. commonJS, its `.d.ts` and wasm keep the mirrored module-path tree
/// directly under `out/`: a `require` target and a wasm import segment ARE the
/// module path, so flattening them would break every multi-module JS program.
pub fn targetSubdir(target: config.Target) []const u8 {
    return switch (target) {
        .erlang => "erl/",
        .beam => "beam/",
        .commonJS, .wasm => "",
    };
}

/// `<out_dir>/<subdir><stem><ext>` for one module — the stem is the module atom
/// for erlang and BEAM, the module path for commonJS and wasm. Caller owns it.
pub fn artifactPath(
    alloc: std.mem.Allocator,
    out_dir: []const u8,
    target: config.Target,
    module_name: []const u8,
    ext: []const u8,
) ![]u8 {
    const stem = try bp.codegen.crossModule.outputStem(targetSource(target), alloc, .of(module_name));
    defer alloc.free(stem);
    return std.fmt.allocPrint(alloc, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), stem, ext });
}

/// Delete the artifact (and `.d.ts`) of every module that failed.
fn removeStaleArtifacts(arena: std.mem.Allocator, io: std.Io, failed: []const []const u8, out_dir: []const u8, target: config.Target) void {
    for (failed) |name| {
        const exts = [_][]const u8{ artifactExt(target), ".d.ts" };
        for (exts) |ext| {
            const p = artifactPath(arena, out_dir, target, name, ext) catch continue;
            std.Io.Dir.cwd().deleteFile(io, p) catch {};
        }
    }
}

// ── Output writer ─────────────────────────────────────────────────────────────

fn writeOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    target: config.Target,
    env_map: libs.EnvMap,
) !void {
    // Ensure output directory exists.
    std.Io.Dir.cwd().createDirPath(io, out_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext = artifactExt(target);

    for (outputs) |o| {
        // A validation error carries no artifact.
        if (o.result.failed()) continue;
        // erlang/BEAM: `out/<target>/<atom><ext>`, flat. commonJS/wasm:
        // `out/<module path><ext>`, so subdirectories may have to be created.
        const sub_path = try artifactPath(gpa, out_dir, target, o.name, ext);
        defer gpa.free(sub_path);

        // Ensure parent directory exists.
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }

        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });

        // Optional TypeScript typedef.
        if (o.result.typedef) |td| {
            const dts_path = try artifactPath(gpa, out_dir, target, o.name, ".d.ts");
            defer gpa.free(dts_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dts_path, .data = td });
        }
    }

    // Ship runtime `.mjs` sidecars (G2) so a built program resolves every
    // `#[@External.<targert>(...)]` `require("…/x.mjs")` — including a dependency's, whose
    // emitted module sits a directory deeper than in its own build.
    if (target == .commonJS) {
        libs.shipMjsSidecars(gpa, io, outputs, out_dir, ext, env_map) catch {};
    }
}
