/// `bpmp version` — prints `bpmp <ver>` + the active `botopink <ver>`
/// (or `(no active toolchain)` when nothing's been `bpmp use`d yet).
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const version_mod = @import("../version.zig");
const lockfile = @import("../lockfile.zig");
const storage = @import("../storage.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    _ = args;
    common.printf(ctx, "bpmp {s}\n", .{version_mod.BPMP_VERSION});

    if (lockfile.read(ctx.gpa, ctx.io, ".")) |maybe_lf| {
        var lf = maybe_lf;
        defer lf.deinit();
        if (lf.botopink) |bp| {
            common.printf(ctx, "botopink {s} (lockfile pin)\n", .{bp.version});
            return 0;
        }
    } else |_| {}

    // Fall back to the on-disk active version under $BPMP_HOME.
    var paths = storage.resolvePaths(ctx.gpa, ctx.env_map) catch {
        common.writeStdout(ctx, "botopink (no active toolchain)\n");
        return 0;
    };
    defer paths.deinit(ctx.gpa);
    const stable_link = try std.fs.path.join(ctx.gpa, &.{ paths.botopink_versions, "stable" });
    defer ctx.gpa.free(stable_link);
    if (std.Io.Dir.cwd().access(ctx.io, stable_link, .{})) |_| {
        common.printf(ctx, "botopink (linked at {s})\n", .{stable_link});
    } else |_| {
        common.writeStdout(ctx, "botopink (no active toolchain — run `bpmp use botopink <ver>`)\n");
    }
    return 0;
}
