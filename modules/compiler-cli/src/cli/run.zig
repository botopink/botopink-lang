/// `botopink run` — build the project then execute the entry-point module.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const libs = @import("./libs.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null,
    module: []const u8 = "main",
    /// Output directory `build` writes and `run` executes from.
    out_dir: []const u8 = "out",
    extra_args: []const []const u8 = &.{},
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

    // Load config to determine target.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget() orelse {
        build_cmd.reportUnsupportedTarget(proj.target);
        return 1;
    };

    // Build first, into the same directory the entry point is read from.
    const build_exit = try build_cmd.run(gpa, io, .{ .target = target, .out_dir = opts.out_dir }, env_map);
    if (build_exit != 0) return build_exit;

    // Resolve the entry-point file path.
    const entry_path = try std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ opts.out_dir, opts.module, build_cmd.artifactExt(target) });

    // BEAM assembly is an artifact — direct execution requires `erlc +from_asm`
    // followed by an `erl` invocation. Tooling integration arrives in Fase 9.
    if (target == .beam) {
        const msg = try std.fmt.allocPrint(
            arena,
            "wrote {s} — BEAM Assembly is an artifact; compile with `erlc +from_asm {s}` to produce a `.beam`.\n",
            .{ entry_path, entry_path },
        );
        reporter.stdout(io, msg);
        return 0;
    }

    // Build argv.
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .erlang => "escript",
        .wasm => "wasmtime",
        .beam => unreachable, // handled above
    };

    var argv = std.ArrayListUnmanaged([]const u8).empty;
    defer argv.deinit(arena);
    try argv.append(arena, runner);
    try argv.append(arena, entry_path);
    for (opts.extra_args) |arg| try argv.append(arena, arg);

    // Spawn and wait — stdio is inherited from the parent process.
    var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
        const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
        reporter.errMsg(msg);
        return 1;
    };
    defer child.kill(io);

    const term = try child.wait(io);
    return switch (term) {
        .exited => |code| code,
        .signal, .stopped, .unknown => 1,
    };
}
