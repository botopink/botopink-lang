/// The language server's cache (decision 233): under
/// `<cache root>/.botopinkbuild/cache/lsp/` of the opened project — the
/// workspace root of a member, else the project root (`manifest.findCacheRoot`,
/// the root the CLI keeps its build caches under) — and nowhere for a document
/// outside every project. `$HOME` is never written: each test hands the server
/// a `HOME` on a scratch directory and asserts it stays empty.
const std = @import("std");
const manifest = @import("manifest");
const test_scratch = @import("test_scratch");
const engine = @import("../engine.zig");
const server_mod = @import("../server.zig");

const MOD: engine.StdModule = .{ .name = "list", .source = "pub fn one() -> i32 { return 1; }\n" };

fn write(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

fn exists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

/// True when `dir` holds no file at any depth (a missing `dir` is empty).
fn emptyTree(io: std.Io, gpa: std.mem.Allocator, dir: []const u8) !bool {
    var d = std.Io.Dir.cwd().openDir(io, dir, .{ .iterate = true }) catch return true;
    defer d.close(io);
    var walker = try d.walk(gpa);
    defer walker.deinit();
    while (try walker.next(io)) |e| if (e.kind != .directory) return false;
    return true;
}

test "lsp cache: a member's cache lives under its workspace root, and a deleted .botopinkbuild starts empty" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-cache-ws");
    defer test_scratch.remove(io, "lsp-cache-ws");

    try write(io, test_scratch.path(io, "lsp-cache-ws/acme/botopink.json"),
        \\{ "name": "acme", "workspaces": ["modules/*"] }
    );
    try write(io, test_scratch.path(io, "lsp-cache-ws/acme/modules/app/botopink.json"),
        \\{ "name": "app", "files": ["main.bp"] }
    );
    try write(io, test_scratch.path(io, "lsp-cache-ws/acme/modules/app/src/main.bp"), "pub fn main() {}\n");
    try std.Io.Dir.cwd().createDirPath(io, test_scratch.path(io, "lsp-cache-ws/home"));

    var env = std.process.Environ.Map.init(gpa);
    defer env.deinit();
    try env.put("HOME", test_scratch.path(io, "lsp-cache-ws/home"));

    var server = server_mod.Server.init(gpa, io, &env);
    defer server.deinit();
    const uri = test_scratch.uri(io, "lsp-cache-ws/acme/modules/app/src/main.bp");

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const ws_build = try std.fs.path.join(a, &.{ test_scratch.path(io, "lsp-cache-ws/acme"), manifest.CACHE_DIR });
    const lsp_store = try std.fs.path.join(a, &.{ ws_build, server_mod.LSP_STORE });
    const want = try std.fs.path.join(a, &.{ lsp_store, "std", "list.bp" });

    // The template evaluator's scratch is the same store's `template/`.
    try std.testing.expectEqualStrings(
        try std.fs.path.join(a, &.{ lsp_store, "template" }),
        server.lspCacheDir(a, uri, "template").?,
    );

    const first = server.materializeStdModule(uri, MOD).?;
    defer gpa.free(first);
    try std.testing.expectEqualStrings(want, first);
    try std.testing.expect(exists(io, want));
    // The member keeps nothing of its own; the user's home stays empty.
    try std.testing.expect(!exists(io, test_scratch.path(io, "lsp-cache-ws/acme/modules/app/.botopinkbuild")));
    try std.testing.expect(try emptyTree(io, gpa, test_scratch.path(io, "lsp-cache-ws/home")));

    // `rm -rf <root>/.botopinkbuild`: the next write recreates the store empty
    // but for what it writes — no state survives the delete.
    test_scratch.remove(io, "lsp-cache-ws/acme/.botopinkbuild");
    try std.testing.expect(!exists(io, want));
    const second = server.materializeStdModule(uri, .{ .name = "map", .source = MOD.source }).?;
    defer gpa.free(second);
    try std.testing.expect(exists(io, second));
    try std.testing.expect(!exists(io, want));
}

test "lsp cache: a package outside a workspace keeps its cache under itself" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-cache-pkg");
    defer test_scratch.remove(io, "lsp-cache-pkg");

    try write(io, test_scratch.path(io, "lsp-cache-pkg/app/botopink.json"),
        \\{ "name": "app" }
    );
    try write(io, test_scratch.path(io, "lsp-cache-pkg/app/src/main.bp"), "pub fn main() {}\n");

    var server = server_mod.Server.init(gpa, io, null);
    defer server.deinit();
    const path = server.materializeStdModule(test_scratch.uri(io, "lsp-cache-pkg/app/src/main.bp"), MOD).?;
    defer gpa.free(path);

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try std.testing.expectEqualStrings(
        try std.fs.path.join(a, &.{ test_scratch.path(io, "lsp-cache-pkg/app"), manifest.CACHE_DIR, server_mod.LSP_STORE, "std", "list.bp" }),
        path,
    );
}

test "lsp cache: a file outside every project writes nothing, not even under HOME" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-cache-loose");
    defer test_scratch.remove(io, "lsp-cache-loose");

    try write(io, test_scratch.path(io, "lsp-cache-loose/src/x.bp"), "val x = 1;\n");
    try std.Io.Dir.cwd().createDirPath(io, test_scratch.path(io, "lsp-cache-loose/home"));

    var env = std.process.Environ.Map.init(gpa);
    defer env.deinit();
    try env.put("HOME", test_scratch.path(io, "lsp-cache-loose/home"));

    var server = server_mod.Server.init(gpa, io, &env);
    defer server.deinit();
    const uri = test_scratch.uri(io, "lsp-cache-loose/src/x.bp");

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    try std.testing.expect(server.lspCacheDir(arena_inst.allocator(), uri, "template") == null);
    try std.testing.expect(server.materializeStdModule(uri, MOD) == null);
    try std.testing.expect(try emptyTree(io, gpa, test_scratch.path(io, "lsp-cache-loose/home")));
    try std.testing.expect(!exists(io, test_scratch.path(io, "lsp-cache-loose/.botopinkbuild")));
    try std.testing.expect(!exists(io, test_scratch.path(io, "lsp-cache-loose/src/.botopinkbuild")));
}
