/// `botopink build` — compile the project to the configured target.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const scanner = @import("./scanner.zig");

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

    // Scan source files.
    const modules = try scanner.scanSources(gpa, io, "src");
    defer scanner.freeModules(gpa, modules);

    if (modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    reporter.compiling(modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // Build codegen config.
    const cfg = bp.codegen.Config{
        .targetSource = switch (target) {
            .commonJS => .commonJS,
            .erlang => .erlang,
        },
        .comptimeRuntime = switch (target) {
            .commonJS => .node,
            .erlang => .erlang,
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
}
