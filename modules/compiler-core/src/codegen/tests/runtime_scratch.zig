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

// Both tests pass an aux module: with none, `executeJavaScript` takes the
// `node -e` path and never creates a scratch dir, so nothing would be checked.
// A random nonce in the script defeats the runtime output cache, which would
// otherwise return before the scratch dir is made.

fn nonceComment(io: anytype, buf: *[32]u8) []const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    return std.fmt.bufPrint(buf, "// {x}", .{std.mem.readInt(u64, &rand_bytes, .little)}) catch unreachable;
}

test "executeJavaScript deletes its scratch dir after an aux-module run" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var nonce_buf: [32]u8 = undefined;
    const script = try std.fmt.allocPrint(alloc, "console.log(__dirname); {s}", .{nonceComment(io, &nonce_buf)});
    defer alloc.free(script);

    const out = try runtime.executeJavaScript(alloc, script, &.{.{ .name = "aux", .code = "module.exports = 1;" }}, io);
    defer alloc.free(out);

    // `__dirname` is the absolute scratch dir; it must sit under TMP_ROOT and
    // be gone once the call returns.
    const printed = std.mem.trim(u8, out, " \r\n");
    const at = std.mem.indexOf(u8, printed, runtime.TMP_ROOT ++ "/") orelse {
        std.debug.print("\nscratch dir not under {s}: '{s}'\n", .{ runtime.TMP_ROOT, printed });
        return error.ScratchDirOutsideTmpRoot;
    };
    const rel = printed[at..];
    if (std.Io.Dir.cwd().openDir(io, rel, .{})) |d| {
        d.close(io);
        std.debug.print("\nscratch dir survived the run: {s}\n", .{rel});
        return error.ScratchDirNotDeleted;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
}

test "executeJavaScript on a throwing aux-module run leaves no .tmp-exec-* root sibling" {
    // The script throws (non-zero exit ⇒ the helper returns ""); no
    // `.tmp-exec-*` may land at the cwd root on that path either.
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var nonce_buf: [32]u8 = undefined;
    const script = try std.fmt.allocPrint(alloc, "throw new Error('boom'); {s}", .{nonceComment(io, &nonce_buf)});
    defer alloc.free(script);

    const out = try runtime.executeJavaScript(alloc, script, &.{.{ .name = "aux", .code = "module.exports = 1;" }}, io);
    defer alloc.free(out);
    try std.testing.expectEqualStrings("", out);

    var cwd_dir = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    defer cwd_dir.close(io);
    var it = cwd_dir.iterate();
    while (try it.next(io)) |entry| {
        try std.testing.expect(!std.mem.startsWith(u8, entry.name, ".tmp-exec-"));
    }
}
