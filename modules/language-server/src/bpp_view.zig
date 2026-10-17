/// An open `.bpp` document as the language server reads it (front 116 step
/// 4): the module it unfolds to — the text the compile and the engine read —
/// and the two ways between a position of the file and one of that text. The
/// unfold keeps every line where it is written and moves only a few columns
/// (`bpp_unfold.Shift`) and the header's last-line decorator (`Moved`), so a
/// hover, a definition and a diagnostic in the header, the style section or
/// the markup land on the file's own line and column. A `.bp` document, or a
/// `.bpp` outside a project that names a `"bpp"` package, is its own view.
const std = @import("std");
const manifest = @import("manifest");
const cli_resolver = @import("cli_resolver");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");

const bpp_unfold = cli_resolver.bpp_unfold_mod;

pub const View = struct {
    /// What the compile and the engine read.
    text: []const u8,
    /// How the text was unfolded; null when it is the document itself.
    origin: ?bpp_unfold.Origin = null,
    /// The file's refusal (its grammar), when the unfold refused it.
    refusal: ?bpp_unfold.Refusal = null,

    /// The view's position for the file's `pos` (both 0-based).
    pub fn toView(self: View, pos: proto.Position) proto.Position {
        const o = self.origin orelse return pos;
        const line: usize = pos.line + 1;
        var col: usize = pos.character + 1;
        for (o.moved) |m| {
            if (m.file_line == line and col >= m.file_col and col < m.file_col + m.len)
                return .{ .line = @intCast(m.line - 1), .character = @intCast(m.col - 1 + (col - m.file_col)) };
        }
        for (o.shifts) |s| {
            if (s.line == line and col >= s.from) col += s.by;
        }
        return .{ .line = pos.line, .character = @intCast(col - 1) };
    }

    /// The file's position for the view's `pos` (both 0-based).
    pub fn toFile(self: View, pos: proto.Position) proto.Position {
        const o = self.origin orelse return pos;
        const at = o.position(pos.line + 1, pos.character + 1);
        return .{ .line = @intCast(at.line -| 1), .character = @intCast(at.col -| 1) };
    }

    pub fn rangeToFile(self: View, r: proto.Range) proto.Range {
        return .{ .start = self.toFile(r.start), .end = self.toFile(r.end) };
    }
};

/// The view of document `uri` (text `source`) unfolded onto `spec` when it is
/// a `.bpp` file and the project names a `"bpp"` package. `arena` owns it.
pub fn of(arena: std.mem.Allocator, uri: []const u8, source: []const u8, spec: ?*const bpp_unfold.Spec) !View {
    const path = lsp_types.uriToPath(uri);
    if (!manifest.isBppFile(path)) return .{ .text = source };
    const s = spec orelse return .{ .text = source };
    return switch (try bpp_unfold.unfold(arena, source, s.*)) {
        .ok => |u| .{ .text = u.source, .origin = .{ .text = source, .shifts = u.shifts, .moved = u.moved } },
        .refused => |r| .{ .text = source, .refusal = r },
    };
}

/// The unfold the project graph remembered for the `.bpp` file at `path`.
pub fn originOf(path: []const u8) ?bpp_unfold.Origin {
    return bpp_unfold.origin(path);
}

/// A diagnostic for the file's refusal (its grammar), at its line.
pub fn refusalDiagnostic(gpa: std.mem.Allocator, r: bpp_unfold.Refusal) !proto.Diagnostic {
    const start: proto.Position = .{ .line = @intCast(r.line -| 1), .character = @intCast(r.col -| 1) };
    return .{
        .range = .{ .start = start, .end = .{ .line = start.line, .character = start.character + 1 } },
        .severity = proto.DiagnosticSeverity.Error,
        .message = try gpa.dupe(u8, r.message),
        .source = "botopink",
    };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const test_spec: bpp_unfold.Spec = .{ .html = .{ .package = "markup", .path = "markup", .name = "markup" }, .ret = "i32" };

test "bpp view: a header line keeps its positions; the markup's first line and a moved decorator map both ways" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const src = "import {named} from \"markup\";\n\nval size = 2;\n#[named]\n---\n<p>card!</p>\n";
    const v = try of(a, "file:///p/src/Card.bpp", src, &test_spec);
    try std.testing.expect(v.origin != null);
    // `size` on line 2 (0-based): the same position in the view.
    const size: proto.Position = .{ .line = 2, .character = 4 };
    try std.testing.expectEqual(size, v.toView(size));
    try std.testing.expectEqual(size, v.toFile(size));
    // The `!` of the markup's first line (0-based line 5, character 7).
    const bang: proto.Position = .{ .line = 5, .character = 7 };
    const in_view = v.toView(bang);
    try std.testing.expectEqual(@as(u32, 5), in_view.line);
    try std.testing.expectEqual(@as(u8, '!'), lineAt(v.text, in_view.line)[in_view.character]);
    try std.testing.expectEqual(bang, v.toFile(in_view));
    // `named` in the decorator (0-based line 3, character 2), moved to line 0.
    const named: proto.Position = .{ .line = 3, .character = 2 };
    const moved = v.toView(named);
    try std.testing.expectEqual(@as(u32, 0), moved.line);
    try std.testing.expect(std.mem.startsWith(u8, lineAt(v.text, 0)[moved.character..], "named]"));
    try std.testing.expectEqual(named, v.toFile(moved));
    // A `.bp` document is its own view.
    const plain = try of(a, "file:///p/src/main.bp", "val x = 1;", &test_spec);
    try std.testing.expect(plain.origin == null);
    // A refused file carries its refusal.
    const refused = try of(a, "file:///p/src/Bad.bpp", "---\n<p/>\n", &test_spec);
    try std.testing.expectEqual(@as(usize, 1), refused.refusal.?.line);
}

fn lineAt(text: []const u8, n: u32) []const u8 {
    var it = std.mem.splitScalar(u8, text, '\n');
    var k: u32 = 0;
    while (it.next()) |l| : (k += 1) if (k == n) return l;
    return "";
}
