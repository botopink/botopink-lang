/// `botopink check` — type-check without generating code.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");

pub fn run(gpa: std.mem.Allocator, io: std.Io, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    var loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer loaded.free(gpa);
    const project_modules = loaded.modules;

    if (project_modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        return 1;
    }

    // Resolve declared external libs (generic — `libs/<name>/`), same as `build`,
    // so `import … from "<lib>"` type-checks. Dependencies compile first.
    const dep_modules = libs.loadDependencies(gpa, io, proj.dependencies, env_map) catch |err| {
        switch (err) {
            error.LibsRootNotFound => {
                reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory");
                reporter.hintMsg("if your botopink.json uses the new object form ({\"<name>\": {\"git\": ...}}), run `bpmp install` to fetch deps into $BPMP_HOME first");
            },
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
    // rather than failed — they carry host-bound / gated surface, not code.
    var real_deps: std.ArrayListUnmanaged(bp.Module) = .empty;
    for (dep_modules) |d| {
        if (!d.declaration) try real_deps.append(arena, d);
    }

    const modules = try std.mem.concat(arena, bp.Module, &.{ real_deps.items, project_modules });

    reporter.checking(modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // STD-001 — same target-name vocabulary `codegen.generate` threads in,
    // so `botopink check` reds on the same `from "std"` imports `botopink build`
    // would have aborted on.
    const target_name: []const u8 = switch (proj.parsedTarget()) {
        .commonJS => "node",
        .erlang, .beam => "erlang",
        .wasm => "wasm",
    };

    var session = bp.comptime_pipeline.compile(
        gpa,
        modules,
        io,
        ".botopinkbuild",
        target_name,
    ) catch |err| {
        reporter.errMsg("type-check failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer session.deinit(gpa);

    const t1 = std.Io.Timestamp.now(io, .awake);

    var had_error = false;
    for (session.outputs.items) |o| {
        switch (o.outcome) {
            .ok => {},
            .parseError => {
                had_error = true;
                std.debug.print("error: parse error in {s}\n", .{o.name});
            },
            .validationError => |ce| {
                had_error = true;
                const rendered = ce.renderAlloc(gpa, o.src) catch continue;
                defer gpa.free(rendered);
                std.debug.print("{s}", .{rendered});
            },
            .typeError => |te| {
                had_error = true;
                const msg = te.message(gpa) catch continue;
                defer gpa.free(msg);
                if (te.loc) |loc| {
                    std.debug.print("error: {s} at {s}:{d}:{d}\n", .{ msg, o.name, loc.line, loc.col });
                } else {
                    std.debug.print("error: {s} in {s}\n", .{ msg, o.name });
                }
            },
        }
    }

    if (had_error) return 1;

    reporter.checked(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}
