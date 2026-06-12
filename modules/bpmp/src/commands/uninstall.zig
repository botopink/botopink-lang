/// `bpmp uninstall <name>` — removes `<name>` from manifest + lockfile.
///
/// The on-disk cache under `$BPMP_HOME/packages/<name>/versions/<v>/` is
/// **kept by default** so a later `bpmp install <name>` short-circuits the
/// download. Pass `--purge` to remove the cached tree too.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");
const storage = @import("../storage.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var name: ?[]const u8 = null;
    var purge = false;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx,
                \\bpmp uninstall <name> [--purge]
                \\
                \\Removes <name> from botopink.json + botopink.lock.json.
                \\With --purge also deletes $BPMP_HOME/packages/<name>.
                \\
            );
            return 0;
        } else if (std.mem.eql(u8, a, "--purge")) {
            purge = true;
        } else if (!std.mem.startsWith(u8, a, "--") and name == null) {
            name = a;
        } else {
            return common.errFmt("uninstall: unexpected argument '{s}'", .{a});
        }
    }
    const dep = name orelse return common.errMsg("uninstall: missing <name>");

    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found"),
        else => return err,
    };
    defer m.deinit();
    try m.removeDependency(dep);
    try manifest.write(ctx.gpa, ctx.io, ".", &m);

    // Lockfile: rewrite without the package (we mutate in-place by reading,
    // filtering, and writing the result).
    if (lockfile.read(ctx.gpa, ctx.io, ".")) |maybe_lf| {
        var lf = maybe_lf;
        defer lf.deinit();
        const a = lf.arena.allocator();
        var keep: std.ArrayListUnmanaged(lockfile.PackagePin) = .empty;
        for (lf.packages) |p| {
            if (!std.mem.eql(u8, p.name, dep)) try keep.append(a, p);
        }
        lf.packages = try keep.toOwnedSlice(a);
        try lockfile.write(ctx.gpa, ctx.io, ".", &lf);
    } else |_| {
        // Missing/invalid lockfile is non-fatal here — uninstall must not
        // require a lockfile to exist.
    }

    if (purge) {
        var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
        defer paths.deinit(ctx.gpa);
        const pkg_dir = try std.fs.path.join(ctx.gpa, &.{ paths.packages, dep });
        defer ctx.gpa.free(pkg_dir);
        std.Io.Dir.cwd().deleteTree(ctx.io, pkg_dir) catch {};
        common.printf(ctx, "bpmp uninstall: removed {s} (manifest + lockfile + on-disk cache)\n", .{dep});
    } else {
        common.printf(ctx, "bpmp uninstall: removed {s} (cache kept; pass --purge to delete it)\n", .{dep});
    }
    return 0;
}
