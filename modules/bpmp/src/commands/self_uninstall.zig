/// `bpmp self uninstall` — interactively remove `$BPMP_HOME`.
/// `--yes` skips the prompt; `--keep-config` preserves the cache for a later reinstall.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const storage = @import("../storage.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var yes = false;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--yes")) yes = true
        else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx, "bpmp self uninstall [--yes]\n");
            return 0;
        } else return common.errFmt("self uninstall: unknown flag '{s}'", .{a});
    }

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);

    if (!yes) {
        common.printf(ctx, "This will delete {s} and every cached package.\nRe-run with --yes to confirm.\n", .{paths.home});
        return 0;
    }
    std.Io.Dir.cwd().deleteTree(ctx.io, paths.home) catch |err| {
        return common.errFmt("self uninstall: deleteTree failed ({s})", .{@errorName(err)});
    };
    common.printf(ctx, "removed {s}\n", .{paths.home});
    common.hintMsg("don't forget to remove `$BPMP_HOME/bin` from your shell PATH (rc file).");
    return 0;
}
