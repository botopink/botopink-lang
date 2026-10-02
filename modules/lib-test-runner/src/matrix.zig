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
    /// The lib has no test blocks; `botopink build` compiled it, nothing ran.
    no_tests,
    /// The target is not yet runnable (beam/wasm today) and `--strict` is off.
    skipped_unsupported,
    /// Not a cell: the lib's `"targets"` list excludes the target, and the
    /// restriction audit proved the exclusion structural (`botopink build` on
    /// the excluded target is refused for a missing host binding).
    excluded,
    /// Not a cell either, and the audit refused the exclusion: the lib builds
    /// on the excluded target, or its build fails for another reason. Fails
    /// the run — a restriction may not hide a cell that could run, or a red.
    not_structural,

    pub fn symbol(self: Status) []const u8 {
        return switch (self) {
            .pass => "✓",
            .fail => "✗",
            .no_tests => "–",
            .skipped_unsupported => "~",
            .excluded => "·",
            .not_structural => "!",
        };
    }

    fn color(self: Status) []const u8 {
        return switch (self) {
            .pass => "\x1b[32m", // green
            .fail => "\x1b[31m", // red
            .no_tests => "\x1b[2m", // dim
            .skipped_unsupported => "\x1b[33m", // yellow
            .excluded => "\x1b[2m", // dim
            .not_structural => "\x1b[1;31m", // bold red
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
    /// Restriction audits that proved an exclusion structural. Not cells.
    audited: usize = 0,
    /// Restriction audits that refused an exclusion. Not cells; each fails the run.
    not_structural: usize = 0,

    pub fn tally(self: *Summary, s: Status) void {
        switch (s) {
            .pass => self.passed += 1,
            .fail => self.failed += 1,
            .no_tests => self.no_tests += 1,
            .skipped_unsupported => self.skipped += 1,
            .excluded => self.audited += 1,
            .not_structural => self.not_structural += 1,
        }
    }

    /// Process exit code for the whole matrix: non-zero iff a cell failed or a
    /// restriction audit refused an exclusion. `no_tests` (–),
    /// `skipped_unsupported` (~) and an audited exclusion (·) do NOT fail the
    /// run; one fail or one `not_structural` flips it to 1.
    pub fn exitCode(self: Summary) u8 {
        return if (self.failed > 0 or self.not_structural > 0) 1 else 0;
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
        "\n{s}{d} passed{s}, {s}{d} failed{s}, {d} no-tests, {d} skipped, {d} restrictions audited, {s}{d} not structural{s}\n",
        .{
            "\x1b[32m",             summary.passed,
            reset,                  if (summary.failed > 0) "\x1b[31m" else "\x1b[2m",
            summary.failed,         reset,
            summary.no_tests,       summary.skipped,
            summary.audited,        if (summary.not_structural > 0) "\x1b[31m" else "\x1b[2m",
            summary.not_structural, reset,
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
    try testing.expectEqualStrings("·", Status.excluded.symbol());
    try testing.expectEqualStrings("!", Status.not_structural.symbol());
}

test "summary tally" {
    var s: Summary = .{};
    s.tally(.pass);
    s.tally(.pass);
    s.tally(.fail);
    s.tally(.no_tests);
    s.tally(.skipped_unsupported);
    s.tally(.excluded);
    s.tally(.excluded);
    s.tally(.not_structural);
    try testing.expectEqual(@as(usize, 2), s.passed);
    try testing.expectEqual(@as(usize, 1), s.failed);
    try testing.expectEqual(@as(usize, 1), s.no_tests);
    try testing.expectEqual(@as(usize, 1), s.skipped);
    try testing.expectEqual(@as(usize, 2), s.audited);
    try testing.expectEqual(@as(usize, 1), s.not_structural);
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

test "summary exit code: an audited exclusion exits 0; one the audit refused exits 1 with no cell red" {
    var ok: Summary = .{};
    ok.tally(.pass);
    ok.tally(.excluded);
    try testing.expectEqual(@as(u8, 0), ok.exitCode());

    var bad = ok;
    bad.tally(.not_structural);
    try testing.expectEqual(@as(usize, 0), bad.failed);
    try testing.expectEqual(@as(u8, 1), bad.exitCode());
}

test "render contains lib names, target headers and symbols" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const targets = [_]Target{ .commonJS, .erlang };
    const row0 = [_]Status{ .pass, .fail };
    const row1 = [_]Status{ .no_tests, .skipped_unsupported };
    const row2 = [_]Status{ .excluded, .not_structural };
    const cells = [_][]const Status{ &row0, &row1, &row2 };
    const names = [_][]const u8{ "alpha", "beta", "gamma" };

    var summary: Summary = .{};
    for (cells) |row| for (row) |st| summary.tally(st);

    const text = try render(a, &names, &targets, &cells, summary);
    try testing.expect(std.mem.indexOf(u8, text, "alpha") != null);
    try testing.expect(std.mem.indexOf(u8, text, "beta") != null);
    try testing.expect(std.mem.indexOf(u8, text, "gamma") != null);
    try testing.expect(std.mem.indexOf(u8, text, "commonJS") != null);
    try testing.expect(std.mem.indexOf(u8, text, "erlang") != null);
    try testing.expect(std.mem.indexOf(u8, text, "✓") != null);
    try testing.expect(std.mem.indexOf(u8, text, "✗") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 passed") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 failed") != null);
    try testing.expect(std.mem.indexOf(u8, text, "·") != null);
    try testing.expect(std.mem.indexOf(u8, text, "!") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 restrictions audited") != null);
    try testing.expect(std.mem.indexOf(u8, text, "1 not structural") != null);
}
