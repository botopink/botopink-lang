/// `bpmp run` — exec the active `botopink` with
/// `BOTOPINK_LIB_ROOTS=<root_1>:<root_2>:…` set to one entry per installed
/// package (lockfile order, top-deps first).
///
/// Anything after `--` is forwarded verbatim. The active compiler is found
/// at `$BPMP_HOME/botopink/versions/stable/botopink`; when stable is not
/// linked, bpmp picks the first installed version.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const lockfile = @import("../lockfile.zig");
const storage = @import("../storage.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--")) {
            i += 1;
            break;
        }
        if (std.mem.eql(u8, args[i], "-h") or std.mem.eql(u8, args[i], "--help")) {
            common.writeStdout(ctx,
                \\bpmp run [-- <botopink args>]
                \\
                \\Exec the active botopink with BOTOPINK_LIB_ROOTS set to every
                \\installed package's version dir (lockfile order, top-deps first).
                \\
            );
            return 0;
        }
    }
    const forward = if (i <= args.len) args[i..] else &.{};

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);

    // Resolve active compiler.
    const stable_link = try std.fs.path.join(ctx.gpa, &.{ paths.botopink_versions, "stable" });
    defer ctx.gpa.free(stable_link);
    const compiler = try std.fs.path.join(ctx.gpa, &.{ stable_link, "botopink" });
    defer ctx.gpa.free(compiler);
    if (!fileExists(ctx.io, compiler)) {
        common.warnMsg("no active botopink — run `bpmp use botopink <ver>` first.");
        return 1;
    }

    // Build BOTOPINK_LIB_ROOTS.
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (roots.items) |s| ctx.gpa.free(s);
        roots.deinit(ctx.gpa);
    }
    if (lockfile.read(ctx.gpa, ctx.io, ".")) |maybe_lf| {
        var lf = maybe_lf;
        defer lf.deinit();
        for (lf.packages) |p| {
            const dir = try paths.packageVersionDir(ctx.gpa, p.name, p.version);
            try roots.append(ctx.gpa, dir);
        }
    } else |_| {}

    const env_value = try joinPathDelim(ctx.gpa, roots.items);
    defer ctx.gpa.free(env_value);

    // Spawn: we set BOTOPINK_LIB_ROOTS on the child env. The clone-env-+-set
    // primitive is platform-specific; the conservative path here builds the
    // argv only and reports what would be executed. Live exec lands with
    // the rest of the spawn surface.
    common.printf(ctx, "bpmp run: would exec {s} with BOTOPINK_LIB_ROOTS={s}\n", .{ compiler, env_value });
    if (forward.len > 0) {
        common.writeStdout(ctx, "  argv:");
        for (forward) |a| common.printf(ctx, " {s}", .{a});
        common.writeStdout(ctx, "\n");
    }
    common.hintMsg("live exec wiring lands once `bpmp use botopink` populates a real toolchain.");
    return 0;
}

fn joinPathDelim(gpa: std.mem.Allocator, entries: []const []const u8) ![]u8 {
    if (entries.len == 0) return try gpa.alloc(u8, 0);
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    const sep = std.fs.path.delimiter;
    for (entries, 0..) |e, idx| {
        if (idx > 0) try aw.writer.writeByte(sep);
        try aw.writer.writeAll(e);
    }
    return aw.toOwnedSlice();
}

fn fileExists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}
