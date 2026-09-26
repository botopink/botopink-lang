/// A document that quotes what the tool prints is checked against the tool.
///
/// A workspace root's documents (`*.md` directly in the workspace directory —
/// its `AGENTS.md`, its `docs.md`) quote the refusal `botopink build` prints
/// there, and that refusal enumerates every member. An enumeration kept as
/// prose is merged as prose: emilia front 39's merge took one side's copy of
/// the member list whole and silently dropped the member the other side had
/// added, in a hunk git resolved without a conflict — a quiet auto-merge is
/// more dangerous than a loud conflict. So the list is not trusted: every
/// quote of `…run this command inside one of its members: <list>` must equal
/// the list the tool prints (`manifest.Workspace.memberList`, the one
/// `config.workspaceRefusal` renders), whitespace aside. An elided quote (`…`
/// or `...`) enumerates nothing and is not checked. A mismatch fails the run —
/// no flag, no warning row (decision 67).
const std = @import("std");
const manifest = @import("manifest");

/// The words the refusal puts before its member list.
pub const PHRASE = "run this command inside one of its members:";

/// Every mismatched quote under the workspaces the `roots` reach, rendered one
/// per line (`<file>:<line>: …`); empty when every quote agrees. Owned by `gpa`.
pub fn check(gpa: std.mem.Allocator, io: std.Io, roots: []const []const u8) ![]u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(gpa);

    const entries = try manifest.scanRoots(arena, io, roots);
    for (entries) |e| {
        if (!e.is_workspace or e.problem != null) continue;
        const ws = e.workspace orelse continue;
        const members = try ws.memberList(arena);
        var dir = std.Io.Dir.cwd().openDir(io, e.dir, .{ .iterate = true }) catch continue;
        defer dir.close(io);
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = dir.iterate();
        while (it.next(io) catch null) |entry| {
            if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".md")) continue;
            try names.append(arena, try arena.dupe(u8, entry.name));
        }
        std.mem.sortUnstable([]const u8, names.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        for (names.items) |name| {
            const text = dir.readFileAlloc(io, name, arena, .limited(16 * 1024 * 1024)) catch continue;
            const path = try std.fs.path.join(arena, &.{ e.dir, name });
            try checkText(gpa, &out, arena, path, text, members);
        }
    }
    return out.toOwnedSlice(gpa);
}

/// Check every quote of the refusal in `text` against `members`, appending a
/// line per mismatch to `out`.
pub fn checkText(
    gpa: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    path: []const u8,
    text: []const u8,
    members: []const u8,
) !void {
    var from: usize = 0;
    while (std.mem.indexOfPos(u8, text, from, PHRASE)) |at| {
        const start = at + PHRASE.len;
        // The quote ends at the closing backtick of the code span it sits in.
        const end = std.mem.indexOfScalarPos(u8, text, start, '`') orelse text.len;
        from = end;
        const quoted = try normalize(arena, text[start..end]);
        if (std.mem.eql(u8, quoted, "…") or std.mem.eql(u8, quoted, "...")) continue;
        const want = try normalize(arena, members);
        if (std.mem.eql(u8, quoted, want)) continue;
        const line = std.mem.count(u8, text[0..at], "\n") + 1;
        const msg = try std.fmt.allocPrint(arena,
            \\{s}:{d}: the workspace refusal is quoted with the members `{s}`, but the tool prints `{s}`
            \\  copy the list from `botopink build` run at the workspace root — never merge or retype it
            \\
        , .{ path, line, quoted, want });
        try out.appendSlice(gpa, msg);
    }
}

/// Collapse every run of whitespace (newlines included — a quote may wrap) to
/// one space and trim the ends.
fn normalize(arena: std.mem.Allocator, s: []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    var space = false;
    for (std.mem.trim(u8, s, " \t\r\n")) |c| {
        if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
            space = true;
            continue;
        }
        if (space) try buf.append(arena, ' ');
        space = false;
        try buf.append(arena, c);
    }
    return buf.items;
}

// ── tests ───────────────────────────────────────────────────────────────────

const testing = std.testing;

test "a wrapped quote that lists every member agrees; an elided one is not checked" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(testing.allocator);
    const text =
        "the located refusal `botopink.json is a workspace, not a package — " ++ PHRASE ++ " acme, acme-core,\n" ++
        "acme-web`. And later `" ++ PHRASE ++ " …`.\n";
    try checkText(testing.allocator, &out, arena_inst.allocator(), "AGENTS.md", text, "acme, acme-core, acme-web");
    try testing.expectEqualStrings("", out.items);
}

test "a quote that lost a member in a merge fails, named by file and line" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(testing.allocator);
    const text = "intro\n`" ++ PHRASE ++ " acme, acme-core`\n";
    try checkText(testing.allocator, &out, arena_inst.allocator(), "ws/AGENTS.md", text, "acme, acme-core, acme-web");
    try testing.expect(std.mem.startsWith(u8, out.items, "ws/AGENTS.md:2: the workspace refusal is quoted with the members `acme, acme-core`, but the tool prints `acme, acme-core, acme-web`"));
}
