/// `bpmp list` — show the project's resolved deps + active compiler.
///
///   `bpmp list`             current project's manifest + lockfile rollup.
///   `bpmp list --installed` every package physically present in $BPMP_HOME.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");
const storage = @import("../storage.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var show_installed = false;
    for (args) |a| {
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx,
                \\bpmp list [--installed]
                \\
            );
            return 0;
        } else if (std.mem.eql(u8, a, "--installed")) {
            show_installed = true;
        } else {
            return common.errFmt("list: unknown flag '{s}'", .{a});
        }
    }

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);

    if (show_installed) {
        try listInstalled(ctx, paths);
        return 0;
    }

    try listProject(ctx);
    return 0;
}

fn listProject(ctx: cli.Context) !void {
    if (manifest.read(ctx.gpa, ctx.io, ".")) |maybe_m| {
        var m = maybe_m;
        defer m.deinit();
        common.writeStdout(ctx, "Project\n");
        common.printf(ctx, "  name:    {s}\n", .{m.name() orelse "(unset)"});
        common.printf(ctx, "  version: {s}\n", .{m.version() orelse "(unset)"});

        const deps = try m.dependencies(ctx.gpa);
        defer ctx.gpa.free(deps);
        common.printf(ctx, "\nDependencies ({d})\n", .{deps.len});
        for (deps) |d| {
            const c = m.requirement(d) orelse "*";
            common.printf(ctx, "  • {s: <14}  {s}\n", .{ d, c });
        }
    } else |_| {
        common.warnMsg("no botopink.json in this directory");
    }

    if (lockfile.read(ctx.gpa, ctx.io, ".")) |maybe_lf| {
        var lf = maybe_lf;
        defer lf.deinit();
        common.printf(ctx, "\nLockfile ({d} pinned)\n", .{lf.packages.len});
        for (lf.packages) |p| {
            common.printf(ctx, "  • {s: <14} {s} ({s})\n", .{ p.name, p.version, p.commit[0..@min(7, p.commit.len)] });
        }
        if (lf.botopink) |bp| {
            common.printf(ctx, "\nActive compiler\n  botopink {s} ({s})\n", .{ bp.version, bp.tag });
        }
    } else |_| {}
}

fn listInstalled(ctx: cli.Context, paths: storage.Paths) !void {
    common.writeStdout(ctx, "Installed under $BPMP_HOME\n");
    // packages/<name>/versions/<ver>/
    var pkgs_dir = std.Io.Dir.cwd().openDir(ctx.io, paths.packages, .{ .iterate = true }) catch {
        common.printf(ctx, "  (no packages — {s} does not exist)\n", .{paths.packages});
        return;
    };
    defer pkgs_dir.close(ctx.io);
    var it = pkgs_dir.iterate();
    var any = false;
    while (it.next(ctx.io) catch null) |entry| {
        if (entry.kind != .directory) continue;
        any = true;
        common.printf(ctx, "  • {s}\n", .{entry.name});
    }
    if (!any) common.writeStdout(ctx, "  (none)\n");
}
