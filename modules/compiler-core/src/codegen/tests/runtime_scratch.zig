//! Pin the per-test scratch dir layout — all paths must live under
//! `<cwd>/.botopinkbuild/tmp/<hex>/`, never as `.tmp-exec-*` siblings of
//! the module root. The umbrella `.gitignore` rule (`.botopinkbuild/`)
//! already swallows the path; `clean-tmp` in `build.zig` reaps stale
//! entries older than 1 day.
const std = @import("std");
const runtime = @import("../runtime.zig");

test "makeScratchDir lands under .botopinkbuild/tmp/<hex>/" {
    const io = std.testing.io;
    var buf: [96]u8 = undefined;
    const dir = try runtime.makeScratchDir(io, &buf);
    defer std.Io.Dir.cwd().deleteTree(io, dir) catch {};

    try std.testing.expect(std.mem.startsWith(u8, dir, runtime.TMP_ROOT ++ "/"));
    const suffix = dir[runtime.TMP_ROOT.len + 1 ..];
    try std.testing.expect(suffix.len > 0);
    for (suffix) |c| try std.testing.expect(std.ascii.isHex(c));

    // dir must exist on disk
    var d = try std.Io.Dir.cwd().openDir(io, dir, .{});
    d.close(io);
}

test "executeJavaScript cleans up scratch dir on success" {
    const io = std.testing.io;
    const before = countTmpEntries(io);
    const out = try runtime.executeJavaScript(
        std.testing.allocator,
        "console.log(42);",
        &.{},
        io,
    );
    defer std.testing.allocator.free(out);
    const after = countTmpEntries(io);
    try std.testing.expectEqual(before, after);
}

test "executeJavaScript leaks under .botopinkbuild/tmp/, never as a root sibling" {
    // Even when the script throws (non-zero exit ⇒ helper returns ""),
    // no `.tmp-exec-*` should land at the cwd root.
    const io = std.testing.io;
    const out = try runtime.executeJavaScript(
        std.testing.allocator,
        "throw new Error('boom');",
        &.{},
        io,
    );
    defer std.testing.allocator.free(out);

    var cwd_dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    defer cwd_dir.close(io);
    var it = cwd_dir.iterate();
    while (try it.next(io)) |entry| {
        try std.testing.expect(!std.mem.startsWith(u8, entry.name, ".tmp-exec-"));
    }
}

fn countTmpEntries(io: std.Io) usize {
    var dir = std.Io.Dir.cwd().openDir(io, runtime.TMP_ROOT, .{ .iterate = true }) catch return 0;
    defer dir.close(io);
    var it = dir.iterate();
    var n: usize = 0;
    while (it.next(io) catch return n) |_| n += 1;
    return n;
}
