/// `bpmp` — Boto Pink Package Manager + toolchain manager.
///
/// `bpmp <command> [flags]`. The subcommand table drives dispatch; flags are
/// parsed per-command. Help / version short-circuit before any command runs.
const std = @import("std");
const cli = @import("./cli.zig");
const version_mod = @import("./version.zig");

const cmd_init = @import("./commands/init.zig");
const cmd_install = @import("./commands/install.zig");
const cmd_uninstall = @import("./commands/uninstall.zig");
const cmd_use = @import("./commands/use.zig");
const cmd_list = @import("./commands/list.zig");
const cmd_pack = @import("./commands/pack.zig");
const cmd_sync = @import("./commands/sync.zig");
const cmd_run = @import("./commands/run.zig");
const cmd_self_update = @import("./commands/self_update.zig");
const cmd_self_uninstall = @import("./commands/self_uninstall.zig");
const cmd_version = @import("./commands/version.zig");
const cmd_env = @import("./commands/env.zig");

const TABLE = [_]cli.Command{
    .{ .name = "init", .summary = "Initialise botopink.json + lockfile in cwd", .run = cmd_init.run },
    .{ .name = "install", .summary = "Install / replay project dependencies", .run = cmd_install.run },
    .{ .name = "uninstall", .summary = "Remove a dep from manifest + lockfile", .run = cmd_uninstall.run },
    .{ .name = "use", .summary = "Switch active toolchain (`use botopink <ver>`)", .run = cmd_use.run },
    .{ .name = "list", .summary = "Show project deps / installed packages", .run = cmd_list.run },
    .{ .name = "pack", .summary = "Pack current project to dist/<name>-<ver>.tar.gz", .run = cmd_pack.run },
    .{ .name = "sync", .summary = "Re-resolve manifest constraints; report drift", .run = cmd_sync.run },
    .{ .name = "run", .summary = "Exec active compiler with BOTOPINK_LIB_ROOTS set", .run = cmd_run.run },
    .{ .name = "self", .summary = "Self-management subgroup: `self update|uninstall`", .run = runSelf },
    .{ .name = "version", .summary = "Print bpmp + active botopink versions", .run = cmd_version.run },
    .{ .name = "env", .summary = "Print PATH snippet for your shell", .run = cmd_env.run },
};

pub fn main(init: std.process.Init) void {
    const exit_code = dispatch(init) catch |err| blk: {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{@errorName(err)});
        break :blk 1;
    };
    if (exit_code != 0) std.process.exit(exit_code);
}

fn dispatch(init: std.process.Init) !u8 {
    const arena = init.arena.allocator();
    const argv_z = try init.minimal.args.toSlice(arena);

    var argv = try arena.alloc([]const u8, argv_z.len);
    for (argv_z, 0..) |s, i| argv[i] = s;

    const ctx: cli.Context = .{
        .gpa = init.gpa,
        .io = init.io,
        .env_map = init.environ_map,
    };

    if (argv.len < 2 or std.mem.eql(u8, argv[1], "help") or std.mem.eql(u8, argv[1], "--help") or std.mem.eql(u8, argv[1], "-h")) {
        const help = try cli.renderHelp(init.gpa, &TABLE);
        defer init.gpa.free(help);
        std.Io.File.stdout().writeStreamingAll(init.io, help) catch {};
        return 0;
    }
    if (std.mem.eql(u8, argv[1], "--version") or std.mem.eql(u8, argv[1], "-v")) {
        const text = try std.fmt.allocPrint(init.gpa, "bpmp {s}\n", .{version_mod.BPMP_VERSION});
        defer init.gpa.free(text);
        std.Io.File.stdout().writeStreamingAll(init.io, text) catch {};
        return 0;
    }

    const name = argv[1];
    const command = cli.findCommand(&TABLE, name) orelse {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown command '{s}'\n", .{name});
        std.debug.print("hint: run `bpmp help`\n", .{});
        return 1;
    };

    const sub_args = if (argv.len > 2) argv[2..] else &.{};
    return command.run(ctx, sub_args);
}

/// `bpmp self <update|uninstall>` — subgroup dispatch.
fn runSelf(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    if (args.len == 0) {
        std.debug.print("usage: bpmp self <update|uninstall> [flags]\n", .{});
        return 1;
    }
    if (std.mem.eql(u8, args[0], "update")) return cmd_self_update.run(ctx, args[1..]);
    if (std.mem.eql(u8, args[0], "uninstall")) return cmd_self_uninstall.run(ctx, args[1..]);
    std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown self subcommand '{s}'\n", .{args[0]});
    return 1;
}

// ── Test root ────────────────────────────────────────────────────────────────

test {
    std.testing.refAllDecls(@This());
    _ = @import("./cli.zig");
    _ = @import("./manifest.zig");
    _ = @import("./lockfile.zig");
    _ = @import("./semver.zig");
    _ = @import("./storage.zig");
    _ = @import("./sha256.zig");
    _ = @import("./registry.zig");
    _ = @import("./download.zig");
    _ = @import("./extract.zig");
    _ = @import("./resolver.zig");
    _ = @import("./release.zig");
}
