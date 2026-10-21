//! The refusals in what a build printed (decisions 475 (2), 532, 798 (6)): the
//! text of a build's stderr read back as `cell_snap.Refusal` records. Shared by
//! `botopink cell check` (which files them under their module) and
//! `botopink build --json` (which writes each as a `refused` event).
const std = @import("std");
const snap = @import("./cell_snap.zig");
const Snap = snap.Snap;

/// `text` without its ANSI colour sequences (`ESC [ … m`).
pub fn stripAnsi(a: std.mem.Allocator, text: []const u8) ![]const u8 {
    if (std.mem.indexOfScalar(u8, text, 0x1b) == null) return text;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == 0x1b and i + 1 < text.len and text[i + 1] == '[') {
            var j = i + 2;
            while (j < text.len and (std.ascii.isDigit(text[j]) or text[j] == ';')) j += 1;
            if (j < text.len and text[j] == 'm') {
                i = j + 1;
                continue;
            }
        }
        try out.append(a, text[i]);
        i += 1;
    }
    return out.items;
}

pub fn isErrorLine(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "error:") or std.mem.startsWith(u8, line, "error[");
}

/// `error: N module(s) failed to compile: …` — the build's summary, which
/// names modules, not a refusal.
pub fn isSummary(line: []const u8) bool {
    return std.mem.indexOf(u8, line, " module(s) failed to compile: ") != null;
}

pub fn firstErrorLine(text: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (isErrorLine(line) and !isSummary(line)) return line;
    }
    return null;
}

/// The refusals in what a build printed, by module: each `error…` line (the
/// summary aside) and the first `--> <file>:<line>:<col>` under it, filed
/// under the module that file is (`src/shapes/circle.bp` → `shapes/circle`);
/// an unlocated refusal is `main`'s.
pub fn refusalsOf(a: std.mem.Allocator, text: []const u8) !std.StringArrayHashMapUnmanaged(Snap) {
    var flat: std.ArrayListUnmanaged(snap.Refusal) = .empty;
    var open = false;
    // The caret line of the open refusal is read once, right after its `-->`.
    var caret_read = false;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (isErrorLine(line)) {
            open = !isSummary(line);
            caret_read = false;
            if (open) try flat.append(a, .{ .message = line });
        } else if (std.mem.startsWith(u8, line, "warning")) {
            open = false;
        } else if (open and std.mem.startsWith(u8, std.mem.trimStart(u8, line, " "), "= called from ")) {
            // Decision 532 — a `called from` line of the open refusal.
            const t = std.mem.trimStart(u8, line, " ");
            const last = &flat.items[flat.items.len - 1];
            var grown: std.ArrayListUnmanaged([]const u8) = .empty;
            try grown.appendSlice(a, last.from);
            try grown.append(a, t["= called from ".len..]);
            last.from = grown.items;
        } else if (open and flat.items[flat.items.len - 1].at == null) {
            const t = std.mem.trimStart(u8, line, " ");
            if (std.mem.startsWith(u8, t, "--> ")) flat.items[flat.items.len - 1].at = t["--> ".len..];
        } else if (open and !caret_read) {
            if (caretLabel(line)) |l| {
                caret_read = true;
                if (l.len > 0) flat.items[flat.items.len - 1].label = l;
            }
        }
    }
    var grouped: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(snap.Refusal)) = .empty;
    for (flat.items) |r| {
        const module = if (r.at) |at| moduleOf(at) else "main";
        const gop = try grouped.getOrPut(a, module);
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.append(a, r);
    }
    var out: std.StringArrayHashMapUnmanaged(Snap) = .empty;
    for (grouped.keys(), grouped.values()) |k, v| try out.put(a, k, .{ .refusals = v.items });
    return out;
}

/// The text beside the caret of a source-snippet line (`  |   ^^^ the label`):
/// "" when the carets stand alone, null when the line is no caret line.
fn caretLabel(line: []const u8) ?[]const u8 {
    const bar = std.mem.indexOfScalar(u8, line, '|') orelse return null;
    if (std.mem.trim(u8, line[0..bar], " 0123456789").len != 0) return null;
    const after = std.mem.trimStart(u8, line[bar + 1 ..], " ");
    if (after.len == 0 or after[0] != '^') return null;
    const rest = std.mem.trimStart(u8, after, "^");
    return std.mem.trim(u8, rest, " ");
}

/// `src/shapes/circle.bp:3:7` → `shapes/circle`.
pub fn moduleOf(at: []const u8) []const u8 {
    var path = at;
    inline for (0..2) |_| {
        if (std.mem.lastIndexOfScalar(u8, path, ':')) |c| {
            const tail = path[c + 1 ..];
            if (tail.len > 0 and for (tail) |ch| {
                if (!std.ascii.isDigit(ch)) break false;
            } else true) path = path[0..c];
        }
    }
    if (std.mem.startsWith(u8, path, "src/")) path = path["src/".len..];
    if (std.mem.endsWith(u8, path, ".bp")) path = path[0 .. path.len - ".bp".len];
    return path;
}

// ── Tests ──

const testing = std.testing;

test "refusalsOf files each located refusal under its module and skips the summary" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\  Compiling 2 module(s)...
        \\warning: `out` is born with no element type
        \\ --> src/main.bp:2:9
        \\
        \\error[namespace-type-self]: a namespace type has no value
        \\ --> src/main.bp:7:15
        \\  |
        \\7 |     fn double(self: Self) -> i32 { return 2; }
        \\  |               ^^^^
        \\
        \\error: `f` has no implementation for the wasm backend
        \\  --> src/shapes/circle.bp:21:12
        \\
        \\error: dependency 'x' was not found under any library root
        \\error: 2 module(s) failed to compile: main, shapes/circle
        \\
    ;
    const got = try refusalsOf(a, text);
    try testing.expectEqual(@as(usize, 2), got.count());
    const main = got.get("main").?;
    try testing.expectEqual(@as(usize, 2), main.refusals.len);
    try testing.expectEqualStrings("error[namespace-type-self]: a namespace type has no value", main.refusals[0].message);
    try testing.expectEqualStrings("src/main.bp:7:15", main.refusals[0].at.?);
    try testing.expectEqualStrings("error: dependency 'x' was not found under any library root", main.refusals[1].message);
    try testing.expect(main.refusals[1].at == null);
    const circle = got.get("shapes/circle").?;
    try testing.expectEqualStrings("src/shapes/circle.bp:21:12", circle.refusals[0].at.?);
}

test "refusalsOf reads the label beside the caret, and none when the caret stands alone" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\error[case-bare-name-arm]: a name alone is not a pattern
        \\ --> src/main.bp:7:9
        \\  |
        \\7 |         n { "other" }
        \\  |         ^ use _ { n -> … } to bind the matched value
        \\  |
        \\  = hint: An arm names a type.
        \\
        \\error[x]: bare caret
        \\ --> src/main.bp:9:1
        \\  |
        \\9 | foo
        \\  | ^^^
        \\
    ;
    const got = (try refusalsOf(a, text)).get("main").?;
    try testing.expectEqualStrings("use _ { n -> … } to bind the matched value", got.refusals[0].label.?);
    try testing.expect(got.refusals[1].label == null);
}

test "refusalsOf reads the called-from lines of a raise at build under the refusal (decision 532)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\error: {error,{panic,<<"boom">>}}
        \\ --> src/deco.bp:3:5
        \\  |
        \\3 |     panic("boom");
        \\  |     ^
        \\  |
        \\  = hint: the decorator's body raised
        \\  = called from src/main.bp:9:3
        \\  = called from src/main.bp:12:1
        \\
    ;
    const got = try refusalsOf(a, text);
    try testing.expect(got.get("main") == null);
    const deco = got.get("deco").?;
    try testing.expectEqualStrings("src/deco.bp:3:5", deco.refusals[0].at.?);
    try testing.expectEqual(@as(usize, 2), deco.refusals[0].from.len);
    try testing.expectEqualStrings("src/main.bp:9:3", deco.refusals[0].from[0]);
    try testing.expectEqualStrings("src/main.bp:12:1", deco.refusals[0].from[1]);
}

test "moduleOf reads the module off a location" {
    try testing.expectEqualStrings("main", moduleOf("src/main.bp:7:15"));
    try testing.expectEqualStrings("shapes/circle", moduleOf("src/shapes/circle.bp:3:1"));
    try testing.expectEqualStrings("lib/util", moduleOf("lib/util.bp:1:1"));
}

test "stripAnsi drops colour sequences only" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectEqualStrings("error: x [1]", try stripAnsi(arena.allocator(), "\x1b[1m\x1b[31merror\x1b[0m: x [1]"));
}
