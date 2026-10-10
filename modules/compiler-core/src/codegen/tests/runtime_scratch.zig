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

// A run that did not end by its own exit — killed by a signal, or an `erl`
// interrupted into its break handler — says nothing about the program, so the
// runtime cache never stores it: a stored one is replayed by every later run
// until the cache is deleted.

/// Fails (and removes the entry) when the runtime cache holds `code`'s run.
fn expectNotCached(target: []const u8, module_name: []const u8, code: []const u8) !void {
    var key: [64]u8 = undefined;
    runtime.cacheKey(&key, target, module_name, code, &.{});
    if (runtime.cacheRead(std.testing.allocator, std.testing.io, &key)) |hit| {
        std.testing.allocator.free(hit);
        var path_buf: [128]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ runtime.CACHE_ROOT, &key });
        std.Io.Dir.cwd().deleteFile(std.testing.io, path) catch {};
        return error.InterruptedRunCached;
    }
}

test "executeJavaScript: a run killed by a signal is never cached" {
    const alloc = std.testing.allocator;
    // The nonce keeps the key fresh, so an entry an older harness wrote
    // cannot answer for this run.
    var nonce: [8]u8 = undefined;
    std.testing.io.random(&nonce);
    const js = try std.fmt.allocPrint(alloc,
        \\// {x}
        \\console.log("partial");
        \\process.kill(process.pid, "SIGKILL");
        \\
    , .{std.mem.readInt(u64, &nonce, .little)});
    defer alloc.free(js);
    const log = try runtime.executeJavaScript(alloc, js, &.{}, std.testing.io);
    defer alloc.free(log);
    try expectNotCached("node+check", "", js);
}

test "executeErlang: an erl interrupted into its break handler is never cached" {
    const alloc = std.testing.allocator;
    var nonce: [8]u8 = undefined;
    std.testing.io.random(&nonce);
    // SIGINT sends erl to its break handler (`BREAK: (a)bort …`); with stdin
    // at EOF the handler halts the emulator with exit status 0, so the exit
    // status alone reads it as a pass.
    const erl = try std.fmt.allocPrint(alloc,
        \\-module(test@main).
        \\-export(['_botopink_main'/0]).
        \\%% {x}
        \\'_botopink_main'() ->
        \\    io:format("before~n", []),
        \\    os:cmd("kill -INT " ++ os:getpid()),
        \\    timer:sleep(5000),
        \\    io:format("after~n", []).
        \\
    , .{std.mem.readInt(u64, &nonce, .little)});
    defer alloc.free(erl);
    const log = try runtime.executeErlang(alloc, erl, "main", &.{}, std.testing.io);
    defer alloc.free(log);
    try std.testing.expect(std.mem.indexOf(u8, log, "after") == null);
    try expectNotCached("erlang", "main", erl);
}
