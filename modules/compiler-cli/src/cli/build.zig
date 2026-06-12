/// `botopink build` — compile the project to the configured target.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");

const Module = bp.Module;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    out_dir: []const u8 = "out",
    typescript: bool = false,
};

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

    // Compile dependency modules ahead of project modules (their types/decorators
    // must resolve before the project that imports them).
    const modules = try gpa.alloc(Module, dep_modules.len + project_modules.len);
    defer gpa.free(modules);
    @memcpy(modules[0..dep_modules.len], dep_modules);
    @memcpy(modules[dep_modules.len..], project_modules);

    reporter.compiling(modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // Build codegen config.
    const cfg = bp.codegen.Config{
        .targetSource = switch (target) {
            .commonJS => .commonJS,
            .erlang => .erlang,
            .beam => .beam,
            .wasm => .wasm,
        },
        .comptimeRuntime = switch (target) {
            .commonJS, .wasm => .node,
            .erlang, .beam => .erlang,
        },
        .typeDefLanguage = if (opts.typescript) .typescript else null,
        .build_root = ".botopinkbuild",
    };

    // Run the compiler.
    var outputs = bp.codegen.generate(gpa, modules, io, cfg) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    const t1 = std.Io.Timestamp.now(io, .awake);

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

    // Write output files.
    try writeOutputs(gpa, io, outputs.items, opts.out_dir, target);

    reporter.compiled(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}

// ── Output writer ─────────────────────────────────────────────────────────────

fn writeOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    target: config.Target,
) !void {
    // Ensure output directory exists.
    std.Io.Dir.cwd().createDirPath(io, out_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext = switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        .beam => ".S",
        .wasm => ".wat",
    };

    for (outputs) |o| {
        // Create subdirectories if the module path contains slashes.
        const sub_path = try std.fmt.allocPrint(gpa, "{s}/{s}{s}", .{ out_dir, o.name, ext });
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
            const dts_path = try std.fmt.allocPrint(gpa, "{s}/{s}.d.ts", .{ out_dir, o.name });
            defer gpa.free(dts_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dts_path, .data = td });
        }
    }

    // Ship runtime `.mjs` sidecars (G2) so a built program resolves every
    // `#[@external]` `require("…/x.mjs")` — including a dependency's, whose
    // emitted module sits a directory deeper than in its own build.
    if (target == .commonJS) {
        libs.shipMjsSidecars(gpa, io, outputs, out_dir, ext) catch {};
    }
}
