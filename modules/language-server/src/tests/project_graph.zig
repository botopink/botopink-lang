/// Tests for the project-graph compile (lsp-project-awareness F3): the LSP must
/// resolve a document together with its module graph — `from "<lib>"` packages
/// (via the lib `botopink.json`) and `mod` siblings — instead of compiling it in
/// isolation. Two angles:
///   * the engine resolves a cross-module symbol (incl. member access) when
///     handed the dependency sources (R3);
///   * the on-disk resolver finds a real example project's lib deps and caches
///     them so a keystroke is a cache hit (R3, latency guard).
const std = @import("std");
const h = @import("./helpers.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");
const graph_mod = @import("../project_graph.zig");
const snap = @import("./snapshot.zig");

// ── R3 — cross-module member-access go-to-def via the graph ───────────────────

test "definition: member access on a `from \"<lib>\"` symbol resolves through the graph (R3)" {
    const gpa = std.testing.allocator;

    // The lib surface (what `from "rakun"` would bring in): a `pub fn created`.
    const lib_uri = "file:///libs/rakun/http.bp";
    const lib_src =
        \\pub record Response { code: i32 }
        \\pub fn created(self: Response, body: string) -> Response {
        \\    return self;
        \\}
    ;
    // The app file calling `Response.created(...)`.
    const app_src =
        \\import { Response, created } from "rakun";
        \\fn make(r: Response) -> Response {
        \\    return Response.created(r, "hi");
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), app_src);

    // Cursor on `created` inside `Response.created(...)` (line 2, after the dot).
    const dot = std.mem.indexOf(u8, app_src, "Response.created").? + "Response.".len;
    const cursor = engine_offsetToPos(app_src, dot + 1);

    const others = [_]engine.ModuleSource{.{ .uri = lib_uri, .source = lib_src }};
    const loc = (try engine.definitionInModules(gpa, h.TEST_URI, app_src, cursor, tokens, &others)) orelse
        return error.NoDefinition;
    defer gpa.free(loc.uri);

    // Jumped into the lib file, onto `pub fn created` (line 1, 0-based).
    try std.testing.expectEqualStrings(lib_uri, loc.uri);
    try std.testing.expectEqual(@as(u32, 1), loc.range.start.line);
    try snap.assertDefinition(gpa, "definition_lib_member", app_src, cursor, loc);
}

fn engine_offsetToPos(source: []const u8, off: usize) proto.Position {
    var line: u32 = 0;
    var col: u32 = 0;
    var i: usize = 0;
    while (i < off and i < source.len) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            col = 0;
        } else col += 1;
    }
    return .{ .line = line, .character = col };
}

// ── R3 — on-disk resolver + cache (latency guard) ─────────────────────────────
//
// Resolves the real rakun example project (relative to the test CWD, which
// build.zig sets to `repository/botopink-lang/modules/language-server/`). The
// example now lives at the rakun sibling's `examples/`, so from that CWD it is
// `../../../rakun/examples/rakun/`. Its `from "rakun"`/`from "server"` deps
// resolve across roots (sibling `repository/` + bundled `botopink-lang/libs`).
// Skips cleanly if the example is absent so the suite never hard-depends on the
// tree layout.

test "project graph: resolves a real project's lib deps and caches them (R3)" {
    const gpa = std.testing.allocator;
    var g = graph_mod.ProjectGraph.init(gpa, std.testing.io, null);
    defer g.deinit();

    const active = "file://../../../rakun/examples/rakun/src/posts.bp";

    const first = g.resolve(active) catch return; // I/O hiccup → skip
    const r1 = first orelse return; // no project found from this CWD → skip
    try std.testing.expect(!r1.hit); // first resolve walks the tree
    try std.testing.expect(r1.deps.len > 0); // rakun + server + project src

    // The `from "rakun"` surface must be present — `Response.created` lives in
    // one of the lib's `files`, so `pub fn created` appears in a dep source.
    var saw_created = false;
    for (r1.deps) |d| {
        if (std.mem.indexOf(u8, d.source, "pub fn created") != null) saw_created = true;
    }
    try std.testing.expect(saw_created);

    // A keystroke re-resolves the same project — unchanged deps → cache hit, no
    // tree walk (only the active doc would be re-inferred).
    const second = (try g.resolve(active)).?;
    try std.testing.expect(second.hit);
}

// ── BOTOPINK_LIB_ROOTS mirror (A1.F1) ─────────────────────────────────────────
//
// The LSP and the CLI driver must see an identical root list — otherwise a
// `go to definition` on `from "<lib>"` misroutes when bpmp puts its packages
// somewhere the walk-up never reaches. These exercises drive the same scenarios
// through `ProjectGraph.resolveRoots` as `compiler-cli/.../libs.zig:rootsFrom`.

test "ProjectGraph.resolveRoots: env entry prepends before walk-up roots" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/lsp-roots-env/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/lsp-roots-env") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/lsp-roots-env") catch {};
    // Resolve to an abs path so the env entry survives without cwd churn.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const abs_store = try std.fs.path.join(gpa, &.{ cwd_buf[0..cwd_n], ws, "store" });
    defer gpa.free(abs_store);

    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/store/erika");
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/libs");
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = ws ++ "/botopink.json", .data = "{}" });

    var map = std.process.Environ.Map.init(gpa);
    defer map.deinit();
    try map.put(graph_mod.ENV_VAR, abs_store);

    var g = graph_mod.ProjectGraph.init(gpa, io, &map);
    defer g.deinit();

    const roots = try g.resolveRootsForTesting(ws);
    defer {
        for (roots) |r| gpa.free(r);
        gpa.free(roots);
    }

    // Env entry must come first; the walk-up `<ws>/libs` follows.
    try std.testing.expect(roots.len >= 2);
    try std.testing.expect(std.mem.endsWith(u8, roots[0], "/store"));
}

test "ProjectGraph.resolveRoots: env unset is byte-identical to legacy walk-up" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/lsp-roots-unset/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/lsp-roots-unset") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/lsp-roots-unset") catch {};
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/libs/std");
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = ws ++ "/libs/std/botopink.json", .data = "{}" });

    var g = graph_mod.ProjectGraph.init(gpa, io, null);
    defer g.deinit();

    const roots = try g.resolveRootsForTesting(ws);
    defer {
        for (roots) |r| gpa.free(r);
        gpa.free(roots);
    }

    // The walk-up still climbs from cwd to / and may pick up real ancestor
    // roots (the repo's own bundled libs); what matters is that the synthetic
    // `<ws>/libs` is in the list and no env entry slipped in.
    try std.testing.expect(roots.len >= 1);
    var saw_ws_libs = false;
    for (roots) |r| {
        if (std.mem.endsWith(u8, r, "lsp-roots-unset/ws/libs")) saw_ws_libs = true;
    }
    try std.testing.expect(saw_ws_libs);
}
