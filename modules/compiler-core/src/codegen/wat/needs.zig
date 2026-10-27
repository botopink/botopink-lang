//! Decision 518 — the host features a wasm program needs, as the program
//! carries them: the custom section `botopink.needs`, the needs' names
//! (`ast.WasmNeed`: `exceptions`, `http`, `gc`, `filesystem`) one per line, which `wat.zig` writes
//! from the `needs:` of the bindings the program reaches and links. The
//! runners read it back — `needsOf` from the binary (`codegen/runtime.zig`'s
//! RUN LOG), `needsOfText` from a `wasi` build's component text
//! (`botopink run` / `test`) — and hand the host only the
//! matching flags (`wasmtimeArgs`). A program needing none carries no
//! section and runs with no flag; node runs exceptions by default.

const std = @import("std");
const ast = @import("../../ast.zig");

const Need = ast.WasmNeed;
const Needs = ast.WasmNeeds;

/// The most flags `wasmtimeArgs` answers: two per need, `filesystem` four.
pub const max_args = 2 * std.enums.values(Need).len + 2;

/// Decision 1008 (5) — where `wasmtime`'s compilation cache lives when no cache
/// root is known (a harness run in a scratch directory): the working
/// directory's own `.botopinkbuild`, never `~/.cache/wasmtime`.
pub const DEFAULT_CACHE_DIR = ".botopinkbuild/cache/wasmtime";

/// Decision 1008 (5) — the `wasmtime run` flags that put its compilation cache
/// in `dir` (`<cache root>/.botopinkbuild/cache/wasmtime`, relative to the
/// working directory or absolute): `-C cache-config=<dir>/config.toml` over a
/// config naming `<dir>/store`. `cold` deletes the store first. Empty when the
/// directory cannot be made (wasmtime then keeps its own default). The one place
/// the config's text is written: `botopink run` / `test` and the harness's
/// `executeWat` all come here.
pub fn cacheArgs(arena: std.mem.Allocator, io: std.Io, dir: []const u8, cold: bool) std.mem.Allocator.Error![]const []const u8 {
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = std.process.currentPath(io, &cwd_buf) catch return &.{};
    const abs = try std.fs.path.resolve(arena, &.{ cwd_buf[0..n], dir });
    const store = try std.fs.path.join(arena, &.{ abs, "store" });
    const cwd = std.Io.Dir.cwd();
    if (cold) cwd.deleteTree(io, store) catch {};
    cwd.createDirPath(io, abs) catch return &.{};
    const toml = try std.fs.path.join(arena, &.{ abs, "config.toml" });
    const text = try std.fmt.allocPrint(arena, "[cache]\ndirectory = \"{s}\"\n", .{store});
    const held = cwd.readFileAlloc(io, toml, arena, .limited(65536)) catch "";
    if (!std.mem.eql(u8, held, text)) {
        // Staged and renamed: concurrent runs write the same bytes.
        var rand: [8]u8 = undefined;
        io.random(&rand);
        const tmp = try std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ toml, std.mem.readInt(u64, &rand, .little) });
        cwd.writeFile(io, .{ .sub_path = tmp, .data = text }) catch return &.{};
        cwd.rename(tmp, cwd, toml, io) catch {
            cwd.deleteFile(io, tmp) catch {};
            return &.{};
        };
    }
    return arena.dupe([]const u8, &.{ "-C", try std.fmt.allocPrint(arena, "cache-config={s}", .{toml}) });
}

test "cacheArgs names a config under the given directory and writes it" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    const test_scratch = @import("test_scratch");
    test_scratch.remove(io, "cache-args");
    defer test_scratch.remove(io, "cache-args");
    const dir = test_scratch.path(io, "cache-args/.botopinkbuild/cache/wasmtime");
    const args = try cacheArgs(arena, io, dir, false);
    try std.testing.expectEqual(@as(usize, 2), args.len);
    try std.testing.expectEqualStrings("-C", args[0]);
    try std.testing.expect(std.mem.startsWith(u8, args[1], "cache-config=/"));
    try std.testing.expect(std.mem.endsWith(u8, args[1], "/cache-args/.botopinkbuild/cache/wasmtime/config.toml"));
    const toml = args[1]["cache-config=".len..];
    const text = try std.Io.Dir.cwd().readFileAlloc(io, toml, arena, .limited(4096));
    try std.testing.expect(std.mem.indexOf(u8, text, "/cache-args/.botopinkbuild/cache/wasmtime/store\"") != null);
}

/// `wasmtime run`'s flags for `needs`, in a fixed order: `-W exceptions=y`
/// for `exceptions`, `-S http` for `http`, `-W gc=y` for `gc` (WasmGC, front
/// 164 s2 — every program that emits GC types), and for `filesystem`
/// (decision 992) `--dir /::/`, the root, and `--env TMPDIR`, the host's
/// temporary directory when it names one. The working directory is the
/// caller's to add (`cwdDirArg`): it is no static string.
pub fn wasmtimeArgs(needs: Needs, buf: *[max_args][]const u8) []const []const u8 {
    var n: usize = 0;
    if (needs.contains(.exceptions)) {
        buf[n] = "-W";
        buf[n + 1] = "exceptions=y";
        n += 2;
    }
    if (needs.contains(.http)) {
        buf[n] = "-S";
        buf[n + 1] = "http";
        n += 2;
    }
    if (needs.contains(.gc)) {
        buf[n] = "-W";
        buf[n + 1] = "gc=y";
        n += 2;
    }
    if (needs.contains(.filesystem)) {
        buf[n] = "--dir";
        buf[n + 1] = "/::/";
        buf[n + 2] = "--env";
        buf[n + 3] = "TMPDIR";
        n += 4;
    }
    return buf[0..n];
}

/// Decision 992 — the second preopen of a program that needs the `filesystem`:
/// the working directory under its own absolute path (`wasmtime run --dir
/// <cwd>::<cwd>`), so the program learns where a relative path begins from
/// the name of the preopen. Owned by `alloc`.
pub fn cwdDirArg(alloc: std.mem.Allocator, cwd: []const u8) ![]const u8 {
    return std.fmt.allocPrint(alloc, "{s}::{s}", .{ cwd, cwd });
}

/// Decision 518 — the custom section a wasm program names the host features
/// it needs in: their names (`Need`, `exceptions` / `http`), one per
/// line. `needsOf` reads it back from the binary, `needsOfText` from the
/// text a `wasi` build writes.
pub const section = "botopink.needs";

/// The needs a `.wasm` binary's `botopink.needs` section names; empty when it
/// has none (or the bytes are no module).
pub fn needsOf(bytes: []const u8) Needs {
    var set = Needs.initEmpty();
    if (bytes.len < 8 or !std.mem.eql(u8, bytes[0..4], "\x00asm")) return set;
    var i: usize = 8;
    while (i < bytes.len) {
        const id = bytes[i];
        i += 1;
        const size = readUleb(bytes, &i) orelse return set;
        if (i + size > bytes.len) return set;
        const body = bytes[i .. i + size];
        i += size;
        if (id != 0) continue;
        var j: usize = 0;
        const n = readUleb(body, &j) orelse continue;
        if (j + n > body.len) continue;
        if (!std.mem.eql(u8, body[j .. j + n], section)) continue;
        addNeeds(&set, body[j + n ..]);
    }
    return set;
}

/// The needs a wasm text names in its `(@custom "botopink.needs" "…")`
/// annotation (a `wasi` build's component text); empty when it has none.
pub fn needsOfText(text: []const u8) Needs {
    var set = Needs.initEmpty();
    const head = "(@custom \"" ++ section ++ "\" \"";
    const at = std.mem.indexOf(u8, text, head) orelse return set;
    const rest = text[at + head.len ..];
    const end = std.mem.indexOfScalar(u8, rest, '"') orelse return set;
    // The text escapes each newline as `\0a`.
    var buf: [256]u8 = undefined;
    var n: usize = 0;
    var k: usize = 0;
    const raw = rest[0..end];
    while (k < raw.len and n < buf.len) : (n += 1) {
        if (raw[k] == '\\' and k + 2 < raw.len) {
            buf[n] = std.fmt.parseInt(u8, raw[k + 1 .. k + 3], 16) catch return set;
            k += 3;
        } else {
            buf[n] = raw[k];
            k += 1;
        }
    }
    addNeeds(&set, buf[0..n]);
    return set;
}

fn addNeeds(set: *Needs, payload: []const u8) void {
    var lines = std.mem.tokenizeScalar(u8, payload, '\n');
    while (lines.next()) |l| {
        if (std.meta.stringToEnum(Need, l)) |need| set.insert(need);
    }
}

fn readUleb(bytes: []const u8, i: *usize) ?usize {
    var result: usize = 0;
    var shift: u6 = 0;
    while (i.* < bytes.len) {
        const b = bytes[i.*];
        i.* += 1;
        result |= @as(usize, b & 0x7f) << shift;
        if (b & 0x80 == 0) return result;
        if (shift >= 56) return null;
        shift += 7;
    }
    return null;
}

test "needs: the section read back from the binary and from the text" {
    const bin = [_]u8{ 0x00, 'a', 's', 'm', 0x01, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x0e } ++ "botopink.needs".* ++ "exceptions\n".*;
    try std.testing.expect(needsOf(&bin).contains(.exceptions));
    try std.testing.expect(!needsOf(&bin).contains(.http));
    const text = "  (@custom \"botopink.needs\" \"exceptions\\0ahttp\\0a\")\n";
    const got = needsOfText(text);
    try std.testing.expect(got.contains(.exceptions) and got.contains(.http));
    try std.testing.expectEqual(@as(usize, 0), needsOfText("(module)").count());
    var buf: [max_args][]const u8 = undefined;
    try std.testing.expectEqual(@as(usize, 4), wasmtimeArgs(got, &buf).len);
    var all = Needs.initFull();
    const flags = wasmtimeArgs(all, &buf);
    try std.testing.expectEqual(@as(usize, 10), flags.len);
    try std.testing.expectEqualStrings("gc=y", flags[5]);
    try std.testing.expectEqualStrings("--dir", flags[6]);
    try std.testing.expectEqualStrings("/::/", flags[7]);
    try std.testing.expectEqualStrings("TMPDIR", flags[9]);
    all.remove(.gc);
    all.remove(.filesystem);
    try std.testing.expectEqual(@as(usize, 4), wasmtimeArgs(all, &buf).len);
    try std.testing.expectEqual(@as(usize, 0), wasmtimeArgs(Needs.initEmpty(), &buf).len);
}
