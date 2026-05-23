/// `botopink run` — build the project then execute the entry-point module.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null,
    module: []const u8 = "main",
    extra_args: []const []const u8 = &.{},
};

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
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

    const target = opts.target orelse proj.parsedTarget();

    // Build first.
    const build_exit = try build_cmd.run(gpa, io, .{ .target = target });
    if (build_exit != 0) return build_exit;

    // Resolve the entry-point file path.
    const entry_path = switch (target) {
        .commonJS => try std.fmt.allocPrint(arena, "out/{s}.js", .{opts.module}),
        .erlang => try std.fmt.allocPrint(arena, "out/{s}.erl", .{opts.module}),
        .beam => try std.fmt.allocPrint(arena, "out/{s}.S", .{opts.module}),
        .wasm => try std.fmt.allocPrint(arena, "out/{s}.wat", .{opts.module}),
    };

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
