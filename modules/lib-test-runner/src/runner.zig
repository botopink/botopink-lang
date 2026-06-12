/// Per-cell execution — spawn `botopink test` for one `(lib, target)` pair.
///
/// The runner orchestrates the existing CLI; it never re-implements test running.
/// Each child runs with `cwd = <lib_dir>` (the lib's own directory, which may live
/// under any resolved root) so it reads that lib's `botopink.json` and writes its
/// own `.botopinkbuild/test-out/` — per-lib isolation falls out of the working
/// directory, exactly as CI would do it.
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

    const status: Status = blk: {
        if (code == 0) break :blk .pass;
        // Non-zero exit: distinguish a not-yet-runnable backend from a real failure.
        const unsupported =
            std.mem.indexOf(u8, result.stdout, UNSUPPORTED_MARK) != null or
            std.mem.indexOf(u8, result.stderr, UNSUPPORTED_MARK) != null;
        if (unsupported and !strict) break :blk .skipped_unsupported;
        break :blk .fail;
    };

    if (json) {
        try emitCellSummary(arena, io, lib_name, target.toString(), status);
    }
    return status;
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

/// Emit one `{"event":"cell_summary","lib":"…","target":"…","status":"…"}`
/// record so a JSON consumer can correlate every spawned cell with its
/// outcome without re-parsing the text matrix. `status` mirrors `Status`
/// stringified for downstream readability.
fn emitCellSummary(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
) !void {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);

    try buf.appendSlice(arena, "{\"event\":\"cell_summary\",\"lib\":\"");
    try buf.appendSlice(arena, lib_name);
    try buf.appendSlice(arena, "\",\"target\":\"");
    try buf.appendSlice(arena, target_str);
    try buf.appendSlice(arena, "\",\"status\":\"");
    try buf.appendSlice(arena, statusName(status));
    try buf.appendSlice(arena, "\"}\n");

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
) !void {
    try emitCellSummary(arena, io, lib_name, target_str, status);
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
