/// Result aggregation — the lib×target matrix and its summary line.
const std = @import("std");
const args = @import("args.zig");

const Target = args.Target;

// ── Cell status ─────────────────────────────────────────────────────────────────

pub const Status = enum {
    /// `botopink test` exited 0 with tests present.
    pass,
    /// A red `.bp` test — the only status that fails the whole run.
    fail,
    /// The lib has no test blocks; nothing was run.
    no_tests,
    /// The target is not yet runnable (beam/wasm today) and `--strict` is off.
    skipped_unsupported,

    pub fn symbol(self: Status) []const u8 {
        return switch (self) {
            .pass => "✓",
            .fail => "✗",
            .no_tests => "–",
            .skipped_unsupported => "~",
        };
    }

    fn color(self: Status) []const u8 {
        return switch (self) {
            .pass => "\x1b[32m", // green
            .fail => "\x1b[31m", // red
            .no_tests => "\x1b[2m", // dim
            .skipped_unsupported => "\x1b[33m", // yellow
        };
    }
};

const reset = "\x1b[0m";
const bold = "\x1b[1m";

// ── Summary counts ──────────────────────────────────────────────────────────────

pub const Summary = struct {
    passed: usize = 0,
    failed: usize = 0,
    no_tests: usize = 0,
    skipped: usize = 0,

    pub fn tally(self: *Summary, s: Status) void {
        switch (s) {
            .pass => self.passed += 1,
            .fail => self.failed += 1,
            .no_tests => self.no_tests += 1,
            .skipped_unsupported => self.skipped += 1,
        }
    }

    /// Process exit code for the whole matrix: non-zero iff a cell failed.
    /// `no_tests` (–) and `skipped_unsupported` (~) do NOT fail the run, so a
    /// mixed pass/skip/no-test matrix still exits 0; one fail flips it to 1.
    pub fn exitCode(self: Summary) u8 {
        return if (self.failed > 0) 1 else 0;
    }
};

// ── Rendering ───────────────────────────────────────────────────────────────────

/// Render the matrix into an owned string. `cells` is row-major: one row per
/// `lib_names` entry, one column per `targets` entry (`cells[r][c]`). The caller
/// owns the returned buffer.
pub fn render(
    arena: std.mem.Allocator,
    lib_names: []const []const u8,
    targets: []const Target,
    cells: []const []const Status,
    summary: Summary,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(arena);
    const w = &aw.writer;

    // The lib column fits the longest lib name (min "lib"); each target column
    // fits its name. Symbols are display-width 1, so we pad by byte count.
    var name_w: usize = 3;
    for (lib_names) |n| name_w = @max(name_w, n.len);

    // Header.
    try w.writeByte('\n');
    try w.writeAll(bold);
    try w.writeAll("lib");
    try w.splatByteAll(' ', name_w - 3);
    try w.writeAll(reset);
    for (targets) |t| {
        try w.writeAll("  ");
        try w.writeAll(bold);
        try w.writeAll(t.toString());
        try w.writeAll(reset);
    }
    try w.writeByte('\n');

    // Rows.
    for (lib_names, 0..) |name, r| {
        try w.writeAll(name);
        try w.splatByteAll(' ', name_w - name.len);
        for (targets, 0..) |t, c| {
            const st = cells[r][c];
            // Centre the (display-width-1) symbol under the target name.
            const col_w = t.toString().len;
            const pad = (col_w - 1) / 2;
            try w.writeAll("  ");
            try w.splatByteAll(' ', pad);
            try w.writeAll(st.color());
            try w.writeAll(st.symbol());
            try w.writeAll(reset);
            try w.splatByteAll(' ', col_w - 1 - pad);
        }
        try w.writeByte('\n');
    }

    // Summary.
    try w.print(
        "\n{s}{d} passed{s}, {s}{d} failed{s}, {d} no-tests, {d} skipped\n",
        .{
            "\x1b[32m",       summary.passed,
            reset,            if (summary.failed > 0) "\x1b[31m" else "\x1b[2m",
            summary.failed,   reset,
            summary.no_tests, summary.skipped,
        },
    );

    return aw.toOwnedSlice();
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "status symbols" {
    try testing.expectEqualStrings("✓", Status.pass.symbol());
    try testing.expectEqualStrings("✗", Status.fail.symbol());
    try testing.expectEqualStrings("–", Status.no_tests.symbol());
    try testing.expectEqualStrings("~", Status.skipped_unsupported.symbol());
}

test "summary tally" {
    var s: Summary = .{};
    s.tally(.pass);
    s.tally(.pass);
    s.tally(.fail);
    s.tally(.no_tests);
    s.tally(.skipped_unsupported);
    try testing.expectEqual(@as(usize, 2), s.passed);
    try testing.expectEqual(@as(usize, 1), s.failed);
    try testing.expectEqual(@as(usize, 1), s.no_tests);
    try testing.expectEqual(@as(usize, 1), s.skipped);
}

test "summary exit code: a mixed pass/skip/no-test matrix exits 0; one fail flips to 1" {
    // Pass + skip + no-test only → still a clean run.
    var ok: Summary = .{};
    ok.tally(.pass);
    ok.tally(.skipped_unsupported);
    ok.tally(.no_tests);
    try testing.expectEqual(@as(u8, 0), ok.exitCode());

    // Add a single failing cell → non-zero.
    var bad = ok;
    bad.tally(.fail);
    try testing.expectEqual(@as(u8, 1), bad.exitCode());

    // An all-empty matrix (no libs/targets) is not a failure.
    const empty: Summary = .{};
    try testing.expectEqual(@as(u8, 0), empty.exitCode());
}

test "render contains lib names, target headers and symbols" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const targets = [_]Target{ .commonJS, .erlang };
    const row0 = [_]Status{ .pass, .fail };
    const row1 = [_]Status{ .no_tests, .skipped_unsupported };
    const cells = [_][]const Status{ &row0, &row1 };
    const names = [_][]const u8{ "erika", "onze" };

    var summary: Summary = .{};
    for (cells) |row| for (row) |st| summary.tally(st);

    const text = try render(a, &names, &targets, &cells, summary);
    try testing.expect(std.mem.indexOf(u8, text, "erika") != null);
    try testing.expect(std.mem.indexOf(u8, text, "onze") != null);
    try testing.expect(std.mem.indexOf(u8, text, "commonJS") != null);
    try testing.expect(std.mem.indexOf(u8, text, "erlang") != null);
    try testing.expect(std.mem.indexOf(u8, text, "✓") != null);
    try testing.expect(std.mem.indexOf(u8, text, "✗") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 passed") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 failed") != null);
}
