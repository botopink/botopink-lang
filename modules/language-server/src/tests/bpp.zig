/// Front 116 step 4 — a `.bpp` file in the language server: the project graph
/// reads it as the module it unfolds to (the roles of the package `"bpp"`
/// names, as `botopink build` reads them), and an open `.bpp` document is
/// compiled as that module, its diagnostics, hover and definitions at the
/// file's own line and column.
const std = @import("std");
const h = @import("./helpers.zig");
const proto = @import("../protocol.zig");
const engine = @import("../engine.zig");
const snap = @import("./snapshot.zig");
const test_scratch = @import("test_scratch");
const server_mod = @import("../server.zig");
const graph_mod = @import("../project_graph.zig");

const MARKUP =
    \\//// The markup's unfold target: answers the literal's length, and refuses a
    \\//// `!` in it at the `!`.
    \\
    \\import {bpp} from "std";
    \\
    \\#[bpp.html]
    \\pub default fn markup(expr t: string) -> i32 {
    \\    val text = compiler.text(t);
    \\    val at = text.indexOf("!");
    \\    if (at >= 0) {
    \\        compiler.fail("markup: `!` is not markup", at: t, span: Span(at, at + 1, 1));
    \\    }
    \\    val root = CustomNode(kind: "markup", span: Span(0, 0, 1), label: "", ref: null, children: []);
    \\    compiler.custom(root);
    \\    return compiler.build(text.length().toString());
    \\}
    \\
    \\import {compiler, compiler.Span, compiler.CustomNode} from "std";
;

const CARD =
    \\type Props(title: string)
    \\pub fn twice(x: i32) -> i32 {
    \\    return x * 2;
    \\}
    \\
    \\val size = props.title.length();
    \\val p: Props = props;
    \\---
    \\<h1>{props.title}</h1>
    \\
;

const BROKEN =
    \\type Props(title: string)
    \\
    \\val size: string = props.title.length();
    \\---
    \\<h1>{props.title}</h1>
    \\
;

const BANG =
    \\val size = 1;
    \\---
    \\<p>bang!</p>
    \\
;

/// A project naming the fixture package `markup` in `"bpp"`, with `.bpp`
/// files under `src/components/`.
fn writeProject(io: std.Io, comptime case: []const u8) !void {
    const files = comptime [_]struct { rel: []const u8, data: []const u8 }{
        .{ .rel = "botopink.json", .data = "{ \"name\": \"app\", \"dependencies\": { \"markup\": { \"path\": \"deps/markup\" } }, \"bpp\": \"markup\" }" },
        .{ .rel = "deps/markup/botopink.json", .data = "{\"name\": \"markup\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"root.bp\", \"files\": [\"root.bp\", \"markup.bp\"]}" },
        .{ .rel = "deps/markup/src/root.bp", .data = "pub default mod markup;\n" },
        .{ .rel = "deps/markup/src/markup.bp", .data = MARKUP },
        .{ .rel = "src/main.bp", .data = "pub mod components;\nimport {components.Card};\n\npub fn main() {}\n" },
        .{ .rel = "src/components/mod.bp", .data = "pub mod Card;\npub mod Broken;\npub mod Bang;\n" },
        .{ .rel = "src/components/Card.bpp", .data = CARD },
        .{ .rel = "src/components/Broken.bpp", .data = BROKEN },
        .{ .rel = "src/components/Bang.bpp", .data = BANG },
    };
    inline for (files) |f| {
        const path = test_scratch.path(io, case ++ "/" ++ f.rel);
        if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = f.data });
    }
}

fn uriOf(io: std.Io, comptime case: []const u8, comptime rel: []const u8) ![]const u8 {
    return test_scratch.uri(io, case ++ "/" ++ rel);
}

test "bpp: the project graph reads a .bpp file as the module it unfolds to" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-bpp-graph");
    defer test_scratch.remove(io, "lsp-bpp-graph");
    try writeProject(io, "lsp-bpp-graph");

    var g = graph_mod.ProjectGraph.init(gpa, io, null);
    defer g.deinit();
    const r = (try g.resolve(try uriOf(io, "lsp-bpp-graph", "src/main.bp"))).?;
    try std.testing.expect(r.bpp != null);
    try std.testing.expectEqualStrings("markup", r.bpp.?.html.package);
    var saw = false;
    for (r.deps) |d| {
        if (!std.mem.endsWith(u8, d.uri, "/Card.bpp")) continue;
        saw = true;
        try std.testing.expect(std.mem.indexOf(u8, d.source, "pub default fn (props: Props) -> i32 {") != null);
    }
    try std.testing.expect(saw);
}

test "bpp: an open .bpp document's diagnostics are at the file's line and column" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-bpp-diag");
    defer test_scratch.remove(io, "lsp-bpp-diag");
    try writeProject(io, "lsp-bpp-diag");

    var server = server_mod.Server.init(gpa, io, null);
    defer server.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const broken = try server.documentDiagnostics(arena.allocator(), try uriOf(io, "lsp-bpp-diag", "src/components/Broken.bpp"), BROKEN);
    try snap.assertDiagnostics(gpa, "bpp_header_type_error", BROKEN, broken);
    const bang = try server.documentDiagnostics(arena.allocator(), try uriOf(io, "lsp-bpp-diag", "src/components/Bang.bpp"), BANG);
    try snap.assertDiagnostics(gpa, "bpp_markup_fail_at", BANG, bang);
    const refused = try server.documentDiagnostics(arena.allocator(), try uriOf(io, "lsp-bpp-diag", "src/components/Card.bpp"), "---\n<p/>\n");
    try snap.assertDiagnostics(gpa, "bpp_first_line_separator", "---\n<p/>\n", refused);
}

test "bpp: hover and definition in a .bpp header answer at the file's positions" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-bpp-hover");
    defer test_scratch.remove(io, "lsp-bpp-hover");
    try writeProject(io, "lsp-bpp-hover");

    var server = server_mod.Server.init(gpa, io, null);
    defer server.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();
    const uri = try uriOf(io, "lsp-bpp-hover", "src/components/Card.bpp");

    const view = try server.viewOf(a, uri, CARD);
    try std.testing.expect(view.origin != null);
    var result = try server.compileWithGraph(uri, CARD);
    defer result.deinit(gpa);
    const bindings = result.bindingsFor(uri);

    // Hover on `twice` (line 1, char 7), a declaration of the header.
    const at: proto.Position = .{ .line = 1, .character = 7 };
    const hov = try engine.hover(gpa, view.text, view.toView(at), bindings);
    defer if (hov) |x| gpa.free(x.contents.value);
    try std.testing.expect(hov != null);
    try snap.assertHover(gpa, "bpp_header_hover", CARD, at, hov);

    // Definition of `Props` in `val p: Props = props;` (line 6, char 7): the
    // header's `type Props` on line 0.
    const use: proto.Position = .{ .line = 6, .character = 7 };
    const tokens = try h.tokenize(a, view.text);
    const found = (try engine.definition(gpa, uri, view.text, view.toView(use), tokens)) orelse return error.NoDefinition;
    defer gpa.free(found.uri);
    const loc: proto.Location = .{ .uri = found.uri, .range = view.rangeToFile(found.range) };
    try std.testing.expectEqual(@as(u32, 0), loc.range.start.line);
    // The snapshot names the file by a fixed URI: the scratch path is the process's.
    const shown: proto.Location = .{ .uri = "file:///Card.bpp", .range = loc.range };
    try snap.assertDefinitionIn(gpa, "bpp_header_definition", CARD, use, shown, &.{.{ .uri = "file:///Card.bpp", .source = CARD }});
}
