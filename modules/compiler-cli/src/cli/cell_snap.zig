//! The `.snap` text of a language cell (decisions 457, 464): the one place
//! the format is written, read and compared. `cell.zig` runs a cell and asks
//! this file whether each answer is the accepted one.
//!
//! A `.snap` is one module's answer on one or every target, a record per line:
//!
//!     botopink-cell 1                 the format and its version, always line 1
//!     refused <message line>          the compiler refuses the module: its
//!     at <file>:<line>:<col>            `error…` line, and where (when located)
//!     out <text>                      one line the program printed (`out`
//!                                       alone for an empty line)
//!     no-final-newline                the last `out` line ended without `\n`
//!     abort                           the program exits non-zero (the number
//!                                       is never pinned)
//!     stderr <text>                   with `abort`: the program's stderr
//!                                       contains this text
//!
//! The records come in that order — refusals, then the output, then `abort`,
//! then the `stderr` claims — and a file has exactly one spelling: it parses
//! only when rendering what it parsed gives back its bytes. A refusal and an
//! output never share a file (a refused module does not run). An empty answer
//! — the header alone — is a module that compiles and, for `main`, a program
//! that prints nothing and exits 0; a missing file answers the same.
//!
//! Everything but `stderr` is compared exactly. A `stderr` line is a claim
//! that the abort names its cause: the stderr must contain it, because the
//! rest of a runtime's stderr (a stack trace, a crash dump notice, absolute
//! paths) is not the language's answer. `cell check` never writes a `stderr`
//! line of its own — a person adds the words that name the abort.
const std = @import("std");

/// Line 1 of every `.snap`: the format and its version.
pub const HEADER = "botopink-cell 1";

/// A candidate's suffix, beside the accepted file it would replace.
pub const NEW_SUFFIX = ".new";

/// One refusal of a module: the compiler's `error…` line, and its location
/// (`src/<file>.bp:<line>:<col>`) when the diagnostic carries one.
pub const Refusal = struct {
    message: []const u8,
    at: ?[]const u8 = null,
};

/// One module's answer.
pub const Snap = struct {
    refusals: []const Refusal = &.{},
    /// What the program printed, byte for byte.
    stdout: []const u8 = "",
    abort: bool = false,
    /// Texts the program's stderr must contain (only with `abort`).
    stderr: []const []const u8 = &.{},

    pub fn isEmpty(self: Snap) bool {
        return self.refusals.len == 0 and self.stdout.len == 0 and !self.abort and self.stderr.len == 0;
    }
};

/// Why a `.snap` did not parse: its 1-based line and the reason.
pub const Malformed = struct {
    line: usize = 0,
    reason: []const u8 = "",
};

pub const ParseError = error{ Malformed, OutOfMemory };

/// Parse a `.snap`. On `error.Malformed`, `why` names the line and the reason.
pub fn parse(arena: std.mem.Allocator, text: []const u8, why: *Malformed) ParseError!Snap {
    if (text.len == 0 or text[text.len - 1] != '\n') {
        why.* = .{ .line = std.mem.count(u8, text, "\n") + 1, .reason = "every record ends with a newline" };
        return error.Malformed;
    }
    var refusals: std.ArrayListUnmanaged(Refusal) = .empty;
    var stdout: std.ArrayListUnmanaged(u8) = .empty;
    var stderr: std.ArrayListUnmanaged([]const u8) = .empty;
    var abort = false;
    // 0 refusals · 1 output · 2 after `no-final-newline` · 3 after `abort` · 4 stderr
    var phase: u8 = 0;
    var last_out_empty = false;
    var lines = std.mem.splitScalar(u8, text[0 .. text.len - 1], '\n');
    var n: usize = 0;
    while (lines.next()) |line| {
        n += 1;
        if (n == 1) {
            if (!std.mem.eql(u8, line, HEADER)) return fail(why, n, "line 1 must be `" ++ HEADER ++ "`");
            continue;
        }
        const space = std.mem.indexOfScalar(u8, line, ' ');
        const word = if (space) |s| line[0..s] else line;
        const rest: ?[]const u8 = if (space) |s| line[s + 1 ..] else null;
        if (rest) |r| if (r.len == 0) return fail(why, n, "a record's text is never empty (an empty output line is `out` alone)");

        if (std.mem.eql(u8, word, "refused")) {
            if (phase != 0) return fail(why, n, "`refused` comes before any output");
            try refusals.append(arena, .{ .message = rest orelse return fail(why, n, "`refused` names the compiler's message") });
        } else if (std.mem.eql(u8, word, "at")) {
            const r = rest orelse return fail(why, n, "`at` names `<file>:<line>:<col>`");
            if (phase != 0 or refusals.items.len == 0 or refusals.items[refusals.items.len - 1].at != null)
                return fail(why, n, "`at` follows its `refused` line");
            refusals.items[refusals.items.len - 1].at = r;
        } else if (std.mem.eql(u8, word, "out")) {
            if (refusals.items.len > 0) return fail(why, n, "a refused module prints nothing");
            if (phase > 1) return fail(why, n, "`out` comes before `no-final-newline`, `abort` and `stderr`");
            phase = 1;
            if (rest) |r| try stdout.appendSlice(arena, r);
            try stdout.append(arena, '\n');
            last_out_empty = rest == null;
        } else if (std.mem.eql(u8, word, "no-final-newline")) {
            if (rest != null) return fail(why, n, "`no-final-newline` takes no text");
            if (phase != 1) return fail(why, n, "`no-final-newline` follows the last `out` line");
            if (last_out_empty) return fail(why, n, "`no-final-newline` after an empty `out` line has one spelling: drop both");
            stdout.items.len -= 1;
            phase = 2;
        } else if (std.mem.eql(u8, word, "abort")) {
            if (rest != null) return fail(why, n, "`abort` takes no text — the exit status is never pinned");
            if (refusals.items.len > 0) return fail(why, n, "a refused module does not run");
            if (phase > 2) return fail(why, n, "`abort` is written once, after the output");
            abort = true;
            phase = 3;
        } else if (std.mem.eql(u8, word, "stderr")) {
            const r = rest orelse return fail(why, n, "`stderr` names the text the abort's stderr contains");
            if (!abort) return fail(why, n, "`stderr` names an abort: it follows `abort`");
            phase = 4;
            try stderr.append(arena, r);
        } else return fail(why, n, "unknown record (refused, at, out, no-final-newline, abort, stderr)");
    }
    const snap: Snap = .{ .refusals = refusals.items, .stdout = stdout.items, .abort = abort, .stderr = stderr.items };
    // One spelling: whatever the rules above let through must render back.
    const again = try render(arena, snap);
    if (!std.mem.eql(u8, again, text)) return fail(why, n, "not the canonical spelling of its records");
    return snap;
}

fn fail(why: *Malformed, line: usize, reason: []const u8) error{Malformed} {
    why.* = .{ .line = line, .reason = reason };
    return error.Malformed;
}

/// The one spelling of `snap`.
pub fn render(arena: std.mem.Allocator, snap: Snap) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.appendSlice(arena, HEADER ++ "\n");
    for (snap.refusals) |r| {
        try out.print(arena, "refused {s}\n", .{r.message});
        if (r.at) |at| try out.print(arena, "at {s}\n", .{at});
    }
    if (snap.stdout.len > 0) {
        const ends = snap.stdout[snap.stdout.len - 1] == '\n';
        const body = if (ends) snap.stdout[0 .. snap.stdout.len - 1] else snap.stdout;
        var lines = std.mem.splitScalar(u8, body, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) try out.appendSlice(arena, "out\n") else try out.print(arena, "out {s}\n", .{line});
        }
        if (!ends) try out.appendSlice(arena, "no-final-newline\n");
    }
    if (snap.abort) try out.appendSlice(arena, "abort\n");
    for (snap.stderr) |s| try out.print(arena, "stderr {s}\n", .{s});
    return out.items;
}

/// Whether the observed answer is the accepted one: the refusals, the output
/// and the abort equal, and every `stderr` claim contained in `observed_stderr`.
pub fn matches(expected: Snap, observed: Snap, observed_stderr: []const u8) bool {
    if (expected.refusals.len != observed.refusals.len) return false;
    for (expected.refusals, observed.refusals) |e, o| {
        if (!std.mem.eql(u8, e.message, o.message)) return false;
        if ((e.at == null) != (o.at == null)) return false;
        if (e.at) |at| if (!std.mem.eql(u8, at, o.at.?)) return false;
    }
    if (!std.mem.eql(u8, expected.stdout, observed.stdout)) return false;
    if (expected.abort != observed.abort) return false;
    for (expected.stderr) |s| {
        if (std.mem.indexOf(u8, observed_stderr, s) == null) return false;
    }
    return true;
}

/// The candidate for an observed answer: what it was, plus the accepted file's
/// `stderr` claims that still hold (a candidate never invents one).
pub fn candidate(arena: std.mem.Allocator, expected: ?Snap, observed: Snap, observed_stderr: []const u8) !Snap {
    var c = observed;
    c.stderr = &.{};
    const e = expected orelse return c;
    if (!observed.abort) return c;
    var kept: std.ArrayListUnmanaged([]const u8) = .empty;
    for (e.stderr) |s| {
        if (std.mem.indexOf(u8, observed_stderr, s) != null) try kept.append(arena, s);
    }
    c.stderr = kept.items;
    return c;
}

/// A line diff of `before` against `after`: `- ` a line only `before` has,
/// `+ ` a line only `after` has, `  ` a line both keep (longest common
/// subsequence — a `.snap` is a few lines).
pub fn diff(arena: std.mem.Allocator, before: []const u8, after: []const u8) ![]u8 {
    const a = try splitLines(arena, before);
    const b = try splitLines(arena, after);
    // lcs[i][j]: the common length of a[i..] and b[j..].
    const w = b.len + 1;
    const lcs = try arena.alloc(usize, (a.len + 1) * w);
    @memset(lcs, 0);
    var i: usize = a.len;
    while (i > 0) {
        i -= 1;
        var j: usize = b.len;
        while (j > 0) {
            j -= 1;
            lcs[i * w + j] = if (std.mem.eql(u8, a[i], b[j])) lcs[(i + 1) * w + j + 1] + 1 else @max(lcs[(i + 1) * w + j], lcs[i * w + j + 1]);
        }
    }
    var out: std.ArrayListUnmanaged(u8) = .empty;
    i = 0;
    var j: usize = 0;
    while (i < a.len or j < b.len) {
        if (i < a.len and j < b.len and std.mem.eql(u8, a[i], b[j])) {
            try out.print(arena, "  {s}\n", .{a[i]});
            i += 1;
            j += 1;
        } else if (i < a.len and (j == b.len or lcs[(i + 1) * w + j] >= lcs[i * w + j + 1])) {
            try out.print(arena, "- {s}\n", .{a[i]});
            i += 1;
        } else {
            try out.print(arena, "+ {s}\n", .{b[j]});
            j += 1;
        }
    }
    return out.items;
}

fn splitLines(arena: std.mem.Allocator, text: []const u8) ![]const []const u8 {
    var lines: std.ArrayListUnmanaged([]const u8) = .empty;
    if (text.len == 0) return lines.items;
    const body = if (text[text.len - 1] == '\n') text[0 .. text.len - 1] else text;
    var it = std.mem.splitScalar(u8, body, '\n');
    while (it.next()) |l| try lines.append(arena, l);
    return lines.items;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

fn roundTrip(arena: std.mem.Allocator, snap: Snap) !Snap {
    const text = try render(arena, snap);
    var why: Malformed = .{};
    return parse(arena, text, &why);
}

test "a program's output renders one `out` line per printed line" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const text = try render(a.allocator(), .{ .stdout = "55\n\nok\n" });
    try testing.expectEqualStrings("botopink-cell 1\nout 55\nout\nout ok\n", text);
}

test "a last line without its newline is written, and read back, as such" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const text = try render(a.allocator(), .{ .stdout = "a\nb" });
    try testing.expectEqualStrings("botopink-cell 1\nout a\nout b\nno-final-newline\n", text);
    const back = try roundTrip(a.allocator(), .{ .stdout = "a\nb" });
    try testing.expectEqualStrings("a\nb", back.stdout);
}

test "an abort and its stderr claims, and a located refusal, round-trip" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const ar = a.allocator();
    const aborted = try roundTrip(ar, .{ .stdout = "1\n", .abort = true, .stderr = &.{"integer overflow: + on i32 at src/main.bp:7:14"} });
    try testing.expect(aborted.abort);
    try testing.expectEqualStrings("integer overflow: + on i32 at src/main.bp:7:14", aborted.stderr[0]);
    const refused = try roundTrip(ar, .{ .refusals = &.{ .{ .message = "error[x]: no", .at = "src/main.bp:7:15" }, .{ .message = "error: unlocated" } } });
    try testing.expectEqual(@as(usize, 2), refused.refusals.len);
    try testing.expectEqualStrings("src/main.bp:7:15", refused.refusals[0].at.?);
    try testing.expect(refused.refusals[1].at == null);
}

test "the header alone is the empty answer" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    var why: Malformed = .{};
    const snap = try parse(a.allocator(), "botopink-cell 1\n", &why);
    try testing.expect(snap.isEmpty());
}

test "a malformed .snap names its line" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const ar = a.allocator();
    const cases = [_]struct { text: []const u8, line: usize }{
        .{ .text = "botopink-snap 1\n", .line = 1 },
        .{ .text = "botopink-cell 1\nout a", .line = 2 },
        .{ .text = "botopink-cell 1\nout a\nrefused error: x\n", .line = 3 },
        .{ .text = "botopink-cell 1\nout a\nstderr boom\n", .line = 3 },
        .{ .text = "botopink-cell 1\nabort\nout a\n", .line = 3 },
        .{ .text = "botopink-cell 1\nat src/main.bp:1:1\n", .line = 2 },
        .{ .text = "botopink-cell 1\nrefused error: x\nat a:1:1\nat b:1:1\n", .line = 4 },
        .{ .text = "botopink-cell 1\nout \n", .line = 2 },
        .{ .text = "botopink-cell 1\nout\nno-final-newline\n", .line = 3 },
        .{ .text = "botopink-cell 1\nabort 1\n", .line = 2 },
        .{ .text = "botopink-cell 1\nexit 0\n", .line = 2 },
        .{ .text = "botopink-cell 1\nabort\nabort\n", .line = 3 },
    };
    for (cases) |c| {
        var why: Malformed = .{};
        try testing.expectError(error.Malformed, parse(ar, c.text, &why));
        try testing.expectEqual(c.line, why.line);
    }
}

test "matches compares output, abort and refusals exactly, stderr by containment" {
    const accepted: Snap = .{ .stdout = "1\n", .abort = true, .stderr = &.{"overflow"} };
    try testing.expect(matches(accepted, .{ .stdout = "1\n", .abort = true }, "Error: integer overflow at x"));
    try testing.expect(!matches(accepted, .{ .stdout = "1\n", .abort = true }, "wasm trap"));
    try testing.expect(!matches(accepted, .{ .stdout = "1\n", .abort = false }, "overflow"));
    try testing.expect(!matches(accepted, .{ .stdout = "1", .abort = true }, "overflow"));
    const refused: Snap = .{ .refusals = &.{.{ .message = "error: no", .at = "src/main.bp:1:2" }} };
    try testing.expect(matches(refused, .{ .refusals = &.{.{ .message = "error: no", .at = "src/main.bp:1:2" }} }, ""));
    try testing.expect(!matches(refused, .{ .refusals = &.{.{ .message = "error: no", .at = "src/main.bp:1:3" }} }, ""));
    try testing.expect(!matches(refused, .{ .refusals = &.{.{ .message = "error: no" }} }, ""));
    try testing.expect(matches(.{}, .{}, "noise on stderr"));
}

test "a candidate keeps the stderr claims that still hold and invents none" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const accepted: Snap = .{ .stdout = "1\n", .abort = true, .stderr = &.{ "overflow", "gone" } };
    const c = try candidate(a.allocator(), accepted, .{ .stdout = "2\n", .abort = true }, "integer overflow");
    try testing.expectEqual(@as(usize, 1), c.stderr.len);
    try testing.expectEqualStrings("overflow", c.stderr[0]);
    const fresh = try candidate(a.allocator(), null, .{ .stdout = "2\n", .abort = true }, "integer overflow");
    try testing.expectEqual(@as(usize, 0), fresh.stderr.len);
}

test "diff marks the lines each side alone has" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();
    const d = try diff(a.allocator(), "botopink-cell 1\nout 1\nout 2\n", "botopink-cell 1\nout 1\nout 3\nabort\n");
    try testing.expectEqualStrings("  botopink-cell 1\n  out 1\n- out 2\n+ out 3\n+ abort\n", d);
}
