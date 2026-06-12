/// `bpmp pack` — tar up the current project per its `files` array.
///
/// The packed tarball lives at `dist/<name>-<version>.tar.gz` and carries
/// every file listed under `files` plus `botopink.json`. A `.sha256`
/// sidecar in `sha256sum` shape is written alongside so consumers can
/// verify offline (same convention as `scripts/release-pack.sh`).
///
/// Output is flat — the archive contents have no embedded directory
/// (matches `install.sh`/`bpmp use` expectations + the `extract.Options`
/// default `strip_components = 0`).
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const sha256 = @import("../sha256.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var out_dir: []const u8 = "dist";
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx,
                \\bpmp pack [--out-dir <dir>]
                \\
                \\Packs botopink.json + each entry in `files[]` into
                \\<out-dir>/<name>-<version>.tar.gz with a sha256 sidecar.
                \\
            );
            return 0;
        } else if (std.mem.eql(u8, a, "--out-dir")) {
            i += 1;
            if (i >= args.len) return common.errMsg("--out-dir expects a path");
            out_dir = args[i];
        } else return common.errFmt("pack: unknown flag '{s}'", .{a});
    }

    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found"),
        else => return err,
    };
    defer m.deinit();
    const name = m.name() orelse return common.errMsg("pack: botopink.json missing `name`");
    const version = m.version() orelse return common.errMsg("pack: botopink.json missing `version`");
    const files = try m.files(ctx.gpa);
    defer ctx.gpa.free(files);
    if (files.len == 0) {
        common.warnMsg("pack: `files[]` is empty — only botopink.json will be packaged");
    }

    try std.Io.Dir.cwd().createDirPath(ctx.io, out_dir);
    const archive_name = try std.fmt.allocPrint(ctx.gpa, "{s}-{s}.tar.gz", .{ name, version });
    defer ctx.gpa.free(archive_name);
    const archive_path = try std.fs.path.join(ctx.gpa, &.{ out_dir, archive_name });
    defer ctx.gpa.free(archive_path);

    // Stage into <out>.partial → atomic-rename + content-addressed sha
    // sidecar. Mirrors release-pack.sh.
    const partial = try std.fmt.allocPrint(ctx.gpa, "{s}.partial", .{archive_path});
    defer ctx.gpa.free(partial);

    {
        const out_file = try std.Io.Dir.cwd().createFile(ctx.io, partial, .{});
        defer out_file.close(ctx.io);

        var file_writer_buf: [16 * 1024]u8 = undefined;
        var file_writer = out_file.writer(ctx.io, &file_writer_buf);

        var window_buf: [std.compress.flate.max_window_len]u8 = undefined;
        var compress = try std.compress.flate.Compress.init(
            &file_writer.interface,
            &window_buf,
            .gzip,
            .default,
        );

        var tar_writer: std.tar.Writer = .{ .underlying_writer = &compress.writer };

        // Always include botopink.json — that's what makes the archive a
        // package, not a tarball of source code.
        try writeOne(ctx, &tar_writer, "botopink.json");
        for (files) |f| try writeOne(ctx, &tar_writer, f);
        try tar_writer.finishPedantically();

        try compress.finish();
        try file_writer.interface.flush();
    }

    // Atomic-rename + sha sidecar.
    try std.Io.Dir.cwd().rename(partial, std.Io.Dir.cwd(), archive_path, ctx.io);
    const digest = try sha256.hashFile(ctx.io, ctx.gpa, archive_path);
    const sidecar_path = try std.fmt.allocPrint(ctx.gpa, "{s}.sha256", .{archive_path});
    defer ctx.gpa.free(sidecar_path);
    const sidecar_line = try std.fmt.allocPrint(ctx.gpa, "{s}\n", .{digest});
    defer ctx.gpa.free(sidecar_line);
    try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = sidecar_path, .data = sidecar_line });

    common.printf(ctx, "bpmp pack: {s} ({s})\n", .{ archive_path, digest });
    return 0;
}

fn writeOne(ctx: cli.Context, tw: *std.tar.Writer, sub_path: []const u8) !void {
    var file = std.Io.Dir.cwd().openFile(ctx.io, sub_path, .{}) catch |err| {
        common.warnMsg("pack: missing file (listed in `files[]`)");
        common.printf(ctx, "  path: {s}  reason: {s}\n", .{ sub_path, @errorName(err) });
        return err;
    };
    defer file.close(ctx.io);

    var read_buf: [16 * 1024]u8 = undefined;
    var file_reader = file.reader(ctx.io, &read_buf);
    // mtime=0 so packed tarballs are bit-reproducible across runs.
    try tw.writeFile(sub_path, &file_reader, 0);
}
