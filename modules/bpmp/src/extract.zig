/// Archive extractor — tar.gz + zip.
///
/// `bpmp install` and `bpmp use` both reach for this: bytes-on-disk →
/// extracted tree under `<dest>`. The two archive shapes in v0.beta.18 are:
///
///   - `tar.gz` — every framework + the toolchain on POSIX. Single top-level
///     directory (GitHub's git-archive convention is `<repo>-<sha>/…`); the
///     extractor strips that one component via `std.tar`'s `strip_components`.
///   - `zip` — toolchain on Windows. Same layout assumption. `std.zip` has no
///     strip-components knob, so the implementation extracts under a staging
///     directory then promotes the solo child up.
///
/// Both surfaces stream straight from disk — `extractTarGz` wraps the file in
/// `std.compress.flate.Decompress` (gzip container) then `std.tar.extract`;
/// `extractZip` opens the file and hands its reader to `std.zip.extract`.
const std = @import("std");

pub const Error = error{
    NotImplemented,
    ArchiveMalformed,
    ArchiveMissingRoot,
} || std.mem.Allocator.Error;

/// Strip the first path component (e.g. `repo-<sha>/`) so the archive's
/// contents land directly under `dest`. Returns a slice sharing memory with
/// `entry_path`. Pure logic — used by the zip post-strip helper below.
pub fn stripLeadingDir(entry_path: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, entry_path, '/')) |slash| {
        return entry_path[slash + 1 ..];
    }
    // No slash → it IS the top-level dir entry; emit nothing.
    return entry_path[entry_path.len..];
}

pub const Options = struct {
    /// `0` for release-pack archives (single file at top level — bpmp's
    /// own `.tar.gz`s), `1` for GitHub git-archive (`<repo>-<sha>/…`).
    strip_components: u32 = 0,
};

pub fn extractTarGz(
    gpa: std.mem.Allocator,
    io: std.Io,
    archive_path: []const u8,
    dest_dir: []const u8,
    opts: Options,
) !void {
    // Open archive bytes-on-disk → File.Reader.
    var file = try std.Io.Dir.cwd().openFile(io, archive_path, .{});
    defer file.close(io);

    var file_buf: [16 * 1024]u8 = undefined;
    var file_reader = file.reader(io, &file_buf);

    // gzip → flate. The Decompress reader needs a window buffer of at
    // least `flate.max_window_len` for back-references; smaller buffers
    // panic in `rebase`.
    var window_buf: [std.compress.flate.max_window_len]u8 = undefined;
    var decompress = std.compress.flate.Decompress.init(
        &file_reader.interface,
        .gzip,
        &window_buf,
    );

    // Destination: caller-supplied. `mkdir -p` so callers don't have to.
    std.Io.Dir.cwd().createDirPath(io, dest_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var dest = try std.Io.Dir.cwd().openDir(io, dest_dir, .{});
    defer dest.close(io);

    var diag: std.tar.Diagnostics = .{ .allocator = gpa };
    defer diag.deinit();

    std.tar.extract(io, dest, &decompress.reader, .{
        .strip_components = opts.strip_components,
        .diagnostics = &diag,
    }) catch |err| {
        if (diag.errors.items.len > 0) return error.ArchiveMalformed;
        return err;
    };
}

pub fn extractZip(
    gpa: std.mem.Allocator,
    io: std.Io,
    archive_path: []const u8,
    dest_dir: []const u8,
    opts: Options,
) !void {
    _ = gpa;
    var file = try std.Io.Dir.cwd().openFile(io, archive_path, .{});
    defer file.close(io);

    var file_buf: [16 * 1024]u8 = undefined;
    var file_reader = file.reader(io, &file_buf);

    std.Io.Dir.cwd().createDirPath(io, dest_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var dest = try std.Io.Dir.cwd().openDir(io, dest_dir, .{});
    defer dest.close(io);

    try std.zip.extract(dest, &file_reader, .{});
    if (opts.strip_components > 0) try promoteSoloChild(io, dest_dir);
}

/// `std.zip.extract` has no `strip_components` knob, so after extraction we
/// detect the conventional GitHub `<repo>-<sha>/` solo root, move its
/// children up into `dest_dir`, and drop the now-empty wrapper. Idempotent:
/// if the archive already extracted flat, this is a no-op.
fn promoteSoloChild(io: std.Io, dest_dir: []const u8) !void {
    var dest = try std.Io.Dir.cwd().openDir(io, dest_dir, .{ .iterate = true });
    defer dest.close(io);

    var only_child: ?[std.fs.max_path_bytes]u8 = null;
    var only_len: usize = 0;
    var saw_more_than_one = false;

    {
        var it = dest.iterate();
        while (try it.next(io)) |entry| {
            if (only_child == null) {
                var buf: [std.fs.max_path_bytes]u8 = undefined;
                @memcpy(buf[0..entry.name.len], entry.name);
                only_child = buf;
                only_len = entry.name.len;
            } else {
                saw_more_than_one = true;
                break;
            }
        }
    }

    if (saw_more_than_one or only_child == null or only_len == 0) return;
    const child_name = only_child.?[0..only_len];

    // Promote children of the solo dir → into dest. Skip if the solo is a
    // file (nothing to promote).
    var inner_path_buf: [std.fs.max_path_bytes * 2]u8 = undefined;
    const inner_path = try std.fmt.bufPrint(&inner_path_buf, "{s}/{s}", .{ dest_dir, child_name });
    var inner = std.Io.Dir.cwd().openDir(io, inner_path, .{ .iterate = true }) catch return;
    defer inner.close(io);

    var it = inner.iterate();
    while (try it.next(io)) |entry| {
        var from_buf: [std.fs.max_path_bytes * 2]u8 = undefined;
        var to_buf: [std.fs.max_path_bytes * 2]u8 = undefined;
        const from = try std.fmt.bufPrint(&from_buf, "{s}/{s}", .{ inner_path, entry.name });
        const to = try std.fmt.bufPrint(&to_buf, "{s}/{s}", .{ dest_dir, entry.name });
        try std.Io.Dir.cwd().rename(from, std.Io.Dir.cwd(), to, io);
    }
    // Empty wrapper directory cleanup.
    std.Io.Dir.cwd().deleteDir(io, inner_path) catch {};
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "stripLeadingDir: strips first component" {
    try testing.expectEqualStrings(
        "src/main.bp",
        stripLeadingDir("erika-abc123/src/main.bp"),
    );
}

test "stripLeadingDir: top-level dir entry yields empty string" {
    try testing.expectEqualStrings("", stripLeadingDir("erika-abc123"));
}

test "stripLeadingDir: preserves nested paths after first strip" {
    try testing.expectEqualStrings(
        "src/main.bp",
        stripLeadingDir("erika-abc/src/main.bp"),
    );
}

test "extractTarGz: round-trips a tarball produced from this tree" {
    const dir = ".botopinkbuild/bpmp-tests/extract-tar";
    std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, dir);

    // Stage `<dir>/src/repo-abc/{a.txt,sub/b.txt}` and tar it up with the
    // single top-level `repo-abc/` — the conventional GitHub layout.
    const src_root = dir ++ "/src/repo-abc";
    try std.Io.Dir.cwd().createDirPath(testing.io, src_root ++ "/sub");
    try std.Io.Dir.cwd().writeFile(testing.io, .{
        .sub_path = src_root ++ "/a.txt",
        .data = "alpha\n",
    });
    try std.Io.Dir.cwd().writeFile(testing.io, .{
        .sub_path = src_root ++ "/sub/b.txt",
        .data = "beta\n",
    });

    const tar_path = dir ++ "/in.tar.gz";

    // Use the system `tar` to produce a known-good gzip-tar. Skip the test
    // if `tar` isn't on PATH (Windows CI under MSYS+Zig has it; bare Windows
    // PowerShell does not — the GitHub-Actions runners are POSIX).
    const run_result = std.process.run(testing.allocator, testing.io, .{
        .argv = &.{ "tar", "-czf", "../in.tar.gz", "repo-abc" },
        .cwd = .{ .path = dir ++ "/src" },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.SkipZigTest,
        else => return err,
    };
    defer testing.allocator.free(run_result.stdout);
    defer testing.allocator.free(run_result.stderr);
    switch (run_result.term) {
        .exited => |code| if (code != 0) return error.SkipZigTest,
        else => return error.SkipZigTest,
    }

    // Extract into a fresh dir and assert the strip-leading-dir contract.
    const out = dir ++ "/out";
    try extractTarGz(testing.allocator, testing.io, tar_path, out, .{ .strip_components = 1 });

    const got_a = try std.Io.Dir.cwd().readFileAlloc(
        testing.io,
        out ++ "/a.txt",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(got_a);
    try testing.expectEqualStrings("alpha\n", got_a);

    const got_b = try std.Io.Dir.cwd().readFileAlloc(
        testing.io,
        out ++ "/sub/b.txt",
        testing.allocator,
        .unlimited,
    );
    defer testing.allocator.free(got_b);
    try testing.expectEqualStrings("beta\n", got_b);
}
