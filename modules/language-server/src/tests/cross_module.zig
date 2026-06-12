/// Cross-module tests — the project-index driven LSP requests that every other
/// test (single self-contained document) can't reach. Covers
/// `engine.crossModuleReferences` / `engine.crossModuleRename`, which the server
/// uses whenever a workspace root is set (`ProjectIndex.root_uri != null`).
///
/// The index scans real `.bp` files from disk, so each test materializes a tiny
/// project under a unique relative dir (resolved against the test cwd, the
/// language-server module root) and tears it down afterwards.
const std = @import("std");
const h = @import("./helpers.zig");
const engine = @import("../engine.zig");
const index_mod = @import("../project_index.zig");
const proto = @import("../protocol.zig");

fn freeActions(gpa: std.mem.Allocator, actions: []proto.CodeAction) void {
    for (actions) |a| {
        gpa.free(a.title);
        if (a.edit) |edit| {
            if (edit.documentChanges) |dcs| {
                for (dcs) |dc| {
                    for (dc.edits) |e| gpa.free(e.newText);
                    gpa.free(dc.edits);
                }
                gpa.free(dcs);
            }
        }
    }
    gpa.free(actions);
}

const MATH_BP =
    \\pub fn double(x: i32) -> i32 {
    \\    return x * 2;
    \\}
;

test "cross-module: references finds usages in other files via the project index" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const dir = ".botopinkbuild/xmod-refs";
    std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(io, dir);
    defer std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dir ++ "/math.bp", .data = MATH_BP });

    // The "current" (in-memory, editor-open) file references `double` twice.
    const main_src =
        \\val r = double(21);
        \\val s = double(2);
    ;
    const main_uri = "file://" ++ dir ++ "/main.bp";

    var idx = index_mod.ProjectIndex.init(gpa, io);
    defer idx.deinit();
    try idx.setRoot("file://" ++ dir);

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);

    // Cursor on `double` in `val r = double(21);` (line 0, col 8).
    const locs = try engine.crossModuleReferences(gpa, io, main_src, h.pos(0, 8), main_uri, tokens, true, &idx);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // Two usages in the current file + the `pub fn double` declaration in math.bp.
    var math_refs: usize = 0;
    var main_refs: usize = 0;
    for (locs) |l| {
        if (std.mem.indexOf(u8, l.uri, "math.bp") != null) math_refs += 1;
        if (std.mem.indexOf(u8, l.uri, "main.bp") != null) main_refs += 1;
    }
    try std.testing.expect(math_refs >= 1); // the external decl was found
    try std.testing.expectEqual(@as(usize, 2), main_refs);
}

test "cross-module: rename edits the current file and every external file" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const dir = ".botopinkbuild/xmod-rename";
    std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(io, dir);
    defer std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dir ++ "/math.bp", .data = MATH_BP });

    const main_src =
        \\val r = double(21);
    ;
    const main_uri = "file://" ++ dir ++ "/main.bp";

    var idx = index_mod.ProjectIndex.init(gpa, io);
    defer idx.deinit();
    try idx.setRoot("file://" ++ dir);

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);

    const result = try engine.crossModuleRename(gpa, io, main_src, h.pos(0, 8), "doubled", main_uri, tokens, &idx);
    defer {
        for (result.entries) |e| {
            gpa.free(e.uri);
            gpa.free(e.edits);
        }
        gpa.free(result.entries);
    }

    // One WorkspaceEdit entry for the current file, one for math.bp.
    var has_main = false;
    var has_math = false;
    for (result.entries) |e| {
        if (std.mem.indexOf(u8, e.uri, "main.bp") != null) {
            has_main = true;
            try std.testing.expect(e.edits.len >= 1);
        }
        if (std.mem.indexOf(u8, e.uri, "math.bp") != null) {
            has_math = true;
            try std.testing.expect(e.edits.len >= 1);
        }
    }
    try std.testing.expect(has_main);
    try std.testing.expect(has_math);
}

test "cross-module: codeAction imports a missing symbol via the project index" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const dir = ".botopinkbuild/xmod-import";
    std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(io, dir);
    defer std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dir ++ "/math.bp", .data = MATH_BP });

    // `double` is used but not imported — and undefined locally, so bindings are
    // empty; the action resolves it through the project index instead.
    const main_src =
        \\val y = double(1);
    ;
    const main_uri = "file://" ++ dir ++ "/main.bp";

    var idx = index_mod.ProjectIndex.init(gpa, io);
    defer idx.deinit();
    try idx.setRoot("file://" ++ dir);

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);

    const range = h.range(0, 0, 0, 18);
    const actions = try engine.codeActions(gpa, main_uri, main_src, range, tokens, &.{}, &idx);
    defer freeActions(gpa, actions);

    var found = false;
    for (actions) |a| {
        if (std.mem.indexOf(u8, a.title, "Import") != null and
            std.mem.indexOf(u8, a.title, "double") != null) found = true;
    }
    try std.testing.expect(found);
}
