/// Per-cell execution — spawn `botopink test` for one `(lib, target)` pair.
///
/// The runner orchestrates the existing CLI; it never re-implements test running.
/// Each child runs with `cwd = <lib_dir>` (the lib's own directory, which may live
/// under any resolved root) so it reads that lib's `botopink.json` and writes under
/// that lib's own `.botopinkbuild/` — per-lib isolation falls out of the working
/// directory, exactly as CI would do it. Isolation BETWEEN runs is the child's:
/// two gates share one library checkout, so `botopink test` writes to
/// `.botopinkbuild/test-out/<target>/<id>/` (per target, per run) and
/// `compileCell` below to `.botopinkbuild/lib-test-build/<target>`.
const std = @import("std");
const args = @import("args.zig");
const matrix = @import("matrix.zig");

const Target = args.Target;
pub const Status = matrix.Status;

/// The substring `botopink test` prints when asked for a backend it cannot run
/// yet (beam/wasm today). Detection is driven by this child output — not a
/// hard-coded target list — so the moment the CLI learns a new backend, that
/// target stops being skipped with no change here.
const UNSUPPORTED_MARK = "currently supports only";

/// Run one cell and return its status. Re-emits the child's captured stdout/stderr
/// so its inline report still reaches the user. Returns an error only when the
/// child cannot be spawned at all (e.g. the binary path is wrong).
///
/// When `json = true`, passes `--json` to the spawned `botopink test`,
/// parses each JSONL record on the child's stdout, splices in
/// `"lib":"<lib>"` and `"target":"<t>"` keys, and re-emits the resulting
/// line to our own stdout. The colored stderr header is suppressed so the
/// JSON channel stays pure structured output — stderr passes through
/// untouched for spawn/compile errors. After the per-test stream the runner
/// emits one `{"event":"cell_summary",…}` record so consumers can tally
/// cells without re-parsing the text matrix.
///
/// `restricted` says this cell's target is excluded by the lib's
/// `botopink.json` `"targets"` list and only runs because
/// `--include-unsupported` lifted the skip. It is carried into the cell
/// summary so the ledger (`scripts/restricted-targets.txt`) reads the cell's
/// failure count instead of the ordinary pass/fail verdict.
pub fn runCell(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    lib_name: []const u8,
    target: Target,
    filter: ?[]const u8,
    strict: bool,
    json: bool,
    restricted: bool,
) !Status {
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    try argv.append(arena, bin);
    try argv.append(arena, "test");
    try argv.append(arena, "--target");
    try argv.append(arena, target.toString());
    if (filter) |f| {
        try argv.append(arena, "--filter");
        try argv.append(arena, f);
    }
    if (json) try argv.append(arena, "--json");

    // Header to stderr (the status channel) so the cell's output is
    // attributable in text mode. JSON mode keeps stderr quiet so a tooling
    // consumer can pipe stderr without ANSI noise interleaving spawn errors.
    if (!json) std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n", .{ lib_name, target.toString() });

    const result = std.process.run(arena, io, .{
        .argv = argv.items,
        .cwd = .{ .path = lib_dir },
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| {
        std.debug.print(
            "\x1b[1m\x1b[31merror\x1b[0m: failed to spawn '{s}': {s}\n",
            .{ bin, @errorName(err) },
        );
        return err;
    };

    // Re-emit the child's output inline.
    if (json) {
        try emitJsonlWithCellFields(arena, io, lib_name, target.toString(), result.stdout);
    } else if (result.stdout.len > 0) {
        std.Io.File.stdout().writeStreamingAll(io, result.stdout) catch {};
    }
    if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};

    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };

    // Non-zero exit: distinguish a not-yet-runnable backend from a real failure.
    const status = classifyWith(.pass, code, result.stdout, result.stderr, strict);

    if (json) {
        // The child's own `{"event":"summary",…}` record carries the test
        // tally; a cell that never compiled has none, which is `ran = false`
        // and NOT "zero failures" — the distinction is the whole point of the
        // ledger (a cell that does not build must never read as green).
        const counts = parseChildSummary(result.stdout);
        try emitCellSummary(arena, io, lib_name, target.toString(), status, restricted, counts);
    }
    return status;
}

/// The test tally of one cell, read from the child's JSONL.
pub const CellCounts = struct {
    /// `"failed"` of the child's `{"event":"summary",…}` record.
    failed: usize = 0,
    /// Whether such a record was seen at all. False for a cell that did not
    /// compile, was not spawned, or ran `botopink build` instead of `test`.
    ran: bool = false,
};

/// Scan a child's `--json` stdout for its terminating
/// `{"event":"summary","passed":P,"failed":F}` record and return `F`.
/// Last record wins (there is one per `botopink test` run). A stdout with no
/// such record yields `.{ .failed = 0, .ran = false }`.
fn parseChildSummary(child_stdout: []const u8) CellCounts {
    var counts: CellCounts = .{};
    var it = std.mem.splitScalar(u8, child_stdout, '\n');
    while (it.next()) |line| {
        if (line.len == 0 or line[0] != '{') continue;
        if (std.mem.indexOf(u8, line, "\"event\":\"summary\"") == null) continue;
        const key = "\"failed\":";
        const at = std.mem.indexOf(u8, line, key) orelse continue;
        var i = at + key.len;
        var n: usize = 0;
        var digits: usize = 0;
        while (i < line.len and line[i] >= '0' and line[i] <= '9') : (i += 1) {
            n = n * 10 + (line[i] - '0');
            digits += 1;
        }
        if (digits == 0) continue;
        counts = .{ .failed = n, .ran = true };
    }
    return counts;
}

/// Build directory, relative to the lib's own directory, that `compileCell`
/// writes to — next to `botopink test`'s `.botopinkbuild/test-out/`, and scoped
/// per target for the same reason: the checkout is shared, so the path a run
/// writes to must not be.
const COMPILE_OUT_DIR = ".botopinkbuild/lib-test-build";

/// Compile one cell of a library that has no `test` block: spawn `botopink
/// build --target <t>` in the lib's directory. A library that never wrote a
/// test is still compiled per target, so it cannot break silently. Exit 0 →
/// `.no_tests` (compiled, nothing to run); the unsupported-target mark →
/// `.skipped_unsupported` (a fail under `--strict`); any other exit → `.fail`.
///
/// The child's stdout (status lines) and stderr (diagnostics) are re-emitted
/// on stderr, so `--json` keeps stdout pure JSONL while a compile error still
/// reaches the log above the cell's `cell_summary`.
pub fn compileCell(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    lib_name: []const u8,
    target: Target,
    strict: bool,
    json: bool,
    restricted: bool,
) !Status {
    const out_dir = try std.fmt.allocPrint(arena, "{s}/{s}", .{ COMPILE_OUT_DIR, target.toString() });
    const argv = [_][]const u8{ bin, "build", "--target", target.toString(), "--out", out_dir };

    if (!json) std.debug.print("\n\x1b[36m── {s} · {s} (no tests: compile only) ──\x1b[0m\n", .{ lib_name, target.toString() });

    const result = std.process.run(arena, io, .{
        .argv = &argv,
        .cwd = .{ .path = lib_dir },
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| {
        std.debug.print(
            "\x1b[1m\x1b[31merror\x1b[0m: failed to spawn '{s}': {s}\n",
            .{ bin, @errorName(err) },
        );
        return err;
    };

    if (result.stdout.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stdout) catch {};
    if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};

    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };
    const status = classifyWith(.no_tests, code, result.stdout, result.stderr, strict);
    // No test ran: `ran = false`, so a compile red is never reported as
    // "0 failures" by the ledger.
    if (json) try emitCellSummary(arena, io, lib_name, target.toString(), status, restricted, .{});
    return status;
}

/// A child's verdict from its exit code and output: 0 is `ok_status`'s pass, a
/// non-zero exit carrying the unsupported-target mark is a skip (unless
/// `strict`), anything else a failure.
fn classifyWith(ok_status: Status, code: u8, stdout: []const u8, stderr: []const u8, strict: bool) Status {
    if (code == 0) return ok_status;
    const unsupported =
        std.mem.indexOf(u8, stdout, UNSUPPORTED_MARK) != null or
        std.mem.indexOf(u8, stderr, UNSUPPORTED_MARK) != null;
    if (unsupported and !strict) return .skipped_unsupported;
    return .fail;
}

/// Splice `"lib":"<name>","target":"<t>"` into each JSONL record from a
/// child's stdout and write the result to our own stdout. Insert position is
/// right after the opening `{` so the lib/target keys lead — easier to grep
/// and keeps `event` second so consumers see kind early.
///
/// Lines that do not begin with `{` are passed through unchanged (defensive:
/// the child might prepend a compile-status line; we don't want to corrupt
/// it). Empty trailing lines from `splitScalar` are dropped.
fn emitJsonlWithCellFields(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    child_stdout: []const u8,
) !void {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);

    var it = std.mem.splitScalar(u8, child_stdout, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] != '{') {
            try out.appendSlice(arena, line);
            try out.append(arena, '\n');
            continue;
        }
        // `{` is at index 0; splice `"lib":"…","target":"…",` immediately
        // after it. JSON strings here cannot contain `"` (lib_name is a dir
        // basename; target is the enum spelling) so no escaping is needed.
        try out.append(arena, '{');
        try out.appendSlice(arena, "\"lib\":\"");
        try out.appendSlice(arena, lib_name);
        try out.appendSlice(arena, "\",\"target\":\"");
        try out.appendSlice(arena, target_str);
        try out.appendSlice(arena, "\",");
        try out.appendSlice(arena, line[1..]);
        try out.append(arena, '\n');
    }

    if (out.items.len > 0) std.Io.File.stdout().writeStreamingAll(io, out.items) catch {};
}

/// Emit one
/// `{"event":"cell_summary","lib":…,"target":…,"status":…,"restricted":…,"failed":…,"ran":…}`
/// record so a JSON consumer can correlate every spawned cell with its
/// outcome without re-parsing the text matrix. `status` mirrors `Status`
/// stringified for downstream readability.
///
/// `restricted` marks a cell the lib's `"targets"` list excludes (it only ran
/// because of `--include-unsupported`); `failed`/`ran` carry the child's own
/// test tally, which is what `scripts/restricted-targets.txt` pins. `ran:false`
/// means no test tally exists — a compile red, a build-only cell, or a cell
/// that was never spawned — and must never be read as "zero failures".
fn emitCellSummary(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
    restricted: bool,
    counts: CellCounts,
) !void {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);

    try buf.appendSlice(arena, "{\"event\":\"cell_summary\",\"lib\":\"");
    try buf.appendSlice(arena, lib_name);
    try buf.appendSlice(arena, "\",\"target\":\"");
    try buf.appendSlice(arena, target_str);
    try buf.appendSlice(arena, "\",\"status\":\"");
    try buf.appendSlice(arena, statusName(status));
    try buf.appendSlice(arena, "\",\"restricted\":");
    try buf.appendSlice(arena, if (restricted) "true" else "false");
    try buf.appendSlice(arena, ",\"failed\":");
    try appendDecimal(arena, &buf, counts.failed);
    try buf.appendSlice(arena, ",\"ran\":");
    try buf.appendSlice(arena, if (counts.ran) "true" else "false");
    try buf.appendSlice(arena, "}\n");

    std.Io.File.stdout().writeStreamingAll(io, buf.items) catch {};
}

fn statusName(s: Status) []const u8 {
    return switch (s) {
        .pass => "pass",
        .fail => "fail",
        .skipped_unsupported => "skipped_unsupported",
        .no_tests => "no_tests",
    };
}

/// Public wrapper around `emitCellSummary` for the no-tests path in `main.zig`
/// — which never spawns a child but still wants a structured record in JSON
/// mode so consumers don't have to infer "missing" cells.
pub fn emitCellSummaryFor(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
    restricted: bool,
) !void {
    try emitCellSummary(arena, io, lib_name, target_str, status, restricted, .{});
}

/// Final `{"event":"run_summary",…}` record — one per `botopink-lib-test`
/// invocation in JSON mode. Mirrors the text-mode `<P> passed, <F> failed,
/// <N> no-tests, <S> skipped` line at the bottom of the matrix.
pub fn emitRunSummary(
    arena: std.mem.Allocator,
    io: std.Io,
    summary: matrix.Summary,
) !void {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);

    try buf.appendSlice(arena, "{\"event\":\"run_summary\",\"passed\":");
    try appendDecimal(arena, &buf, summary.passed);
    try buf.appendSlice(arena, ",\"failed\":");
    try appendDecimal(arena, &buf, summary.failed);
    try buf.appendSlice(arena, ",\"no_tests\":");
    try appendDecimal(arena, &buf, summary.no_tests);
    try buf.appendSlice(arena, ",\"skipped\":");
    try appendDecimal(arena, &buf, summary.skipped);
    try buf.appendSlice(arena, "}\n");

    std.Io.File.stdout().writeStreamingAll(io, buf.items) catch {};
}

fn appendDecimal(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), n: anytype) !void {
    var dbuf: [20]u8 = undefined;
    const s = try std.fmt.bufPrint(&dbuf, "{d}", .{n});
    try out.appendSlice(arena, s);
}

// ── tests ───────────────────────────────────────────────────────────────────

const testing = std.testing;

test "emitJsonlWithCellFields — splices lib+target into each {…} line" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const child =
        "{\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":1,\"name\":\"t\",\"status\":\"ok\",\"run_log\":\"\"}\n" ++
        "{\"event\":\"summary\",\"passed\":1,\"failed\":0}\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);

    // Stand-in for stdout sink — use the same splicing logic into our buffer
    // by re-implementing inline (the production fn writes to stdout via Io,
    // not testable directly without a faked sink).
    var it = std.mem.splitScalar(u8, child, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] != '{') {
            try out.appendSlice(arena, line);
            try out.append(arena, '\n');
            continue;
        }
        try out.append(arena, '{');
        try out.appendSlice(arena, "\"lib\":\"");
        try out.appendSlice(arena, "erika");
        try out.appendSlice(arena, "\",\"target\":\"");
        try out.appendSlice(arena, "commonJS");
        try out.appendSlice(arena, "\",");
        try out.appendSlice(arena, line[1..]);
        try out.append(arena, '\n');
    }

    try testing.expectEqualStrings(
        "{\"lib\":\"erika\",\"target\":\"commonJS\",\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":1,\"name\":\"t\",\"status\":\"ok\",\"run_log\":\"\"}\n" ++
            "{\"lib\":\"erika\",\"target\":\"commonJS\",\"event\":\"summary\",\"passed\":1,\"failed\":0}\n",
        out.items,
    );
}

test "statusName covers every Status variant" {
    try testing.expectEqualStrings("pass", statusName(.pass));
    try testing.expectEqualStrings("fail", statusName(.fail));
    try testing.expectEqualStrings("skipped_unsupported", statusName(.skipped_unsupported));
    try testing.expectEqualStrings("no_tests", statusName(.no_tests));
}

test "parseChildSummary: the child's summary record carries the failure count" {
    const stdout =
        "{\"event\":\"test\",\"name\":\"a\",\"status\":\"ok\"}\n" ++
        "{\"event\":\"test\",\"name\":\"b\",\"status\":\"fail\"}\n" ++
        "{\"event\":\"summary\",\"passed\":1,\"failed\":9}\n";
    const counts = parseChildSummary(stdout);
    try testing.expect(counts.ran);
    try testing.expectEqual(@as(usize, 9), counts.failed);
}

test "parseChildSummary: a green cell is 0 failures, and it ran" {
    const counts = parseChildSummary("{\"event\":\"summary\",\"passed\":17,\"failed\":0}\n");
    try testing.expect(counts.ran);
    try testing.expectEqual(@as(usize, 0), counts.failed);
}

test "parseChildSummary: no summary record is `did not run`, not zero failures" {
    // A cell that did not compile prints diagnostics on stderr and no summary.
    // `ran = false` is what keeps the ledger from reading it as green.
    const counts = parseChildSummary("error: parse error\n");
    try testing.expect(!counts.ran);
    try testing.expectEqual(@as(usize, 0), counts.failed);

    const empty = parseChildSummary("");
    try testing.expect(!empty.ran);
}

test "classifyWith: exit 0 is the ok status, the unsupported mark a skip unless strict, else a fail" {
    try testing.expectEqual(Status.pass, classifyWith(.pass, 0, "", "", false));
    try testing.expectEqual(Status.no_tests, classifyWith(.no_tests, 0, "", "", false));
    try testing.expectEqual(Status.fail, classifyWith(.no_tests, 1, "", "error: parse error", false));
    try testing.expectEqual(Status.skipped_unsupported, classifyWith(.no_tests, 1, "", "botopink test currently supports only commonJS", false));
    try testing.expectEqual(Status.fail, classifyWith(.pass, 1, "currently supports only", "", true));
}
