/// Per-cell execution — spawn `botopink test` for one `(lib, target)` pair.
///
/// The runner orchestrates the existing CLI; it never re-implements test running.
/// Each child runs with `cwd = <lib_dir>` (the lib's own directory, which may live
/// under any resolved root) so it reads that lib's `botopink.json` and writes under
/// that lib's own `.botopinkbuild/` — per-lib isolation falls out of the working
/// directory, exactly as CI would do it. Isolation BETWEEN runs is the child's:
/// two gates share one library checkout, so `botopink test` writes to
/// `.botopinkbuild/test-out/<target>/<id>/` (per target, per run) and
/// `compileCell` below to `.botopinkbuild/lib-test-build/<target>/<id>/`.
///
/// A (lib, target) pair the lib's manifest excludes (`"targets"`) is not a
/// cell and is never run. It is AUDITED instead (`captureAudit`): `botopink
/// build --target <excluded>` must be refused for a missing host binding, or
/// the exclusion itself fails the run.
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

/// What one spawned cell left behind: the child's captured output and its
/// verdict. `capture*` fills it (safe to call from a worker — it writes
/// nothing to the runner's own stdout/stderr); `emit*` writes it out. The
/// split is what lets `main.zig` run cells concurrently and still print every
/// cell in discovery order, byte for byte what a serial run prints.
pub const Captured = struct {
    /// The child could not be spawned (e.g. the binary path is wrong). Re-raised
    /// by `emit*` after the same message the serial runner printed.
    spawn_err: ?anyerror = null,
    stdout: []const u8 = "",
    stderr: []const u8 = "",
    status: Status = .fail,
    counts: CellCounts = .{},
    /// Set by `captureAudit` only: why the audit answered what it did.
    audit: Audit = .{},
};

/// Run one `botopink test` cell and return its status: `captureTest` then
/// `emitTest`. Re-emits the child's captured stdout/stderr so its inline
/// report still reaches the user. Returns an error only when the child cannot
/// be spawned at all (e.g. the binary path is wrong).
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
    const cap = captureTest(arena, io, bin, lib_dir, target, filter, strict, json);
    return emitTest(arena, io, bin, lib_name, target, json, cap);
}

/// Spawn `botopink test --target <t>` in `lib_dir` and capture its output and
/// verdict. Writes nothing to this process's stdout/stderr. `gpa` must be safe
/// to use from the calling thread (a worker passes its own arena).
pub fn captureTest(
    gpa: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    target: Target,
    filter: ?[]const u8,
    strict: bool,
    json: bool,
) Captured {
    var argv_buf: [7][]const u8 = undefined;
    var n: usize = 0;
    argv_buf[n] = bin;
    n += 1;
    argv_buf[n] = "test";
    n += 1;
    argv_buf[n] = "--target";
    n += 1;
    argv_buf[n] = target.toString();
    n += 1;
    if (filter) |f| {
        argv_buf[n] = "--filter";
        n += 1;
        argv_buf[n] = f;
        n += 1;
    }
    if (json) {
        argv_buf[n] = "--json";
        n += 1;
    }
    return spawnCaptured(gpa, io, argv_buf[0..n], lib_dir, .pass, strict, json);
}

/// Write a captured `botopink test` cell out — exactly what the serial runner
/// wrote around the spawn: the text-mode header, the child's stdout (spliced
/// JSONL under `--json`), its stderr, and the `cell_summary` record.
pub fn emitTest(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_name: []const u8,
    target: Target,
    json: bool,
    cap: Captured,
) !Status {
    // Header to stderr (the status channel) so the cell's output is
    // attributable in text mode. JSON mode keeps stderr quiet so a tooling
    // consumer can pipe stderr without ANSI noise interleaving spawn errors.
    if (!json) std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n", .{ lib_name, target.toString() });
    if (cap.spawn_err) |err| return reportSpawnError(bin, err);

    // Re-emit the child's output inline.
    if (json) {
        try emitJsonlWithCellFields(arena, io, lib_name, target.toString(), cap.stdout);
    } else if (cap.stdout.len > 0) {
        std.Io.File.stdout().writeStreamingAll(io, cap.stdout) catch {};
    }
    if (cap.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, cap.stderr) catch {};

    if (json) {
        // The child's own `{"event":"summary",…}` record carries the test
        // tally; a cell that never compiled has none, which is `ran = false`
        // and NOT "zero failures" (a cell that does not build must never read
        // as green).
        try emitCellSummary(arena, io, lib_name, target.toString(), cap.status, cap.counts);
    }
    return cap.status;
}

/// Spawn `argv` in `cwd`, capture both streams, and classify the exit:
/// 0 is `ok_status`, the unsupported-target mark a skip (unless `strict`),
/// anything else a failure (non-zero exit: distinguish a not-yet-runnable
/// backend from a real failure). `json` also reads the child's test tally.
fn spawnCaptured(
    gpa: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    cwd: []const u8,
    ok_status: Status,
    strict: bool,
    json: bool,
) Captured {
    const result = std.process.run(gpa, io, .{
        .argv = argv,
        .cwd = .{ .path = cwd },
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| return .{ .spawn_err = err };

    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };
    var status = classifyWith(ok_status, code, result.stdout, result.stderr, strict);
    // A test cell reads its count from the child's run total — the JSONL
    // `summary` record, or the text-mode `total:` line — never from a
    // module's own summary. A test cell that exited 0 with no total is not a
    // pass: nothing says how many tests ran.
    const counts = if (ok_status == .pass) parseChildSummary(result.stdout, json) else CellCounts{};
    var stderr = result.stderr;
    if (ok_status == .pass and status == .pass and !counts.ran) {
        status = .fail;
        stderr = std.fmt.allocPrint(gpa, "{s}error: `botopink test` exited 0 but printed no run total, so no count of this cell's tests exists\n", .{result.stderr}) catch result.stderr;
    }
    return .{
        .stdout = result.stdout,
        .stderr = stderr,
        .status = status,
        .counts = counts,
    };
}

fn reportSpawnError(bin: []const u8, err: anyerror) anyerror {
    std.debug.print(
        "\x1b[1m\x1b[31merror\x1b[0m: failed to spawn '{s}': {s}\n",
        .{ bin, @errorName(err) },
    );
    return err;
}

/// The test tally of one cell, read from the child's JSONL.
pub const CellCounts = struct {
    /// `"failed"` of the child's `{"event":"summary",…}` record.
    failed: usize = 0,
    /// Whether such a record was seen at all. False for a cell that did not
    /// compile, was not spawned, or ran `botopink build` instead of `test`.
    ran: bool = false,
};

/// The first bytes of `botopink test`'s text-mode run total, its last line:
/// `total: <P> passed, <F> failed in <N> module(s)` (`TOTAL_PREFIX` in
/// `compiler-cli/src/cli/test_cmd.zig`). Every module before it printed its
/// own `<P> passed, <F> failed`; only this line is the cell's count.
const TEXT_TOTAL_PREFIX = "total: ";

/// Scan a child's stdout for its run total and return its `F`: under `--json`
/// the terminating `{"event":"summary","passed":P,"failed":F}` record, in text
/// mode the `total: P passed, F failed in N module(s)` line. Last one wins
/// (there is one per `botopink test` run). A stdout with neither yields
/// `.{ .failed = 0, .ran = false }`.
fn parseChildSummary(child_stdout: []const u8, json: bool) CellCounts {
    if (!json) return parseTextTotal(child_stdout);
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

/// The text-mode half of `parseChildSummary`.
fn parseTextTotal(child_stdout: []const u8) CellCounts {
    var counts: CellCounts = .{};
    var it = std.mem.splitScalar(u8, child_stdout, '\n');
    while (it.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        if (!std.mem.startsWith(u8, line, TEXT_TOTAL_PREFIX)) continue;
        const rest = line[TEXT_TOTAL_PREFIX.len..];
        const mid = " passed, ";
        const at = std.mem.indexOf(u8, rest, mid) orelse continue;
        _ = std.fmt.parseUnsigned(usize, rest[0..at], 10) catch continue;
        const after = rest[at + mid.len ..];
        const sp = std.mem.indexOf(u8, after, " failed in ") orelse continue;
        const failed = std.fmt.parseUnsigned(usize, after[0..sp], 10) catch continue;
        counts = .{ .failed = failed, .ran = true };
    }
    return counts;
}

/// Build directory, relative to the lib's own directory, that `compileCell`
/// writes under — next to `botopink test`'s `.botopinkbuild/test-out/`, and
/// scoped per target and per run (`<root>/<target>/<id>`, removed when the
/// cell ends) for the same reason: the checkout is shared, so the path a run
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
) !Status {
    const cap = captureCompile(arena, io, bin, lib_dir, target, strict);
    return emitCompile(arena, io, bin, lib_name, target, json, cap);
}

/// Spawn `botopink build --target <t> --out <COMPILE_OUT_DIR>/<t>/<id>` in
/// `lib_dir`, capture its output and verdict, and remove the output. Writes
/// nothing to this process's stdout/stderr.
pub fn captureCompile(
    gpa: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    target: Target,
    strict: bool,
) Captured {
    const out_dir = scratchOutDir(gpa, io, target) catch |err| return .{ .spawn_err = err };
    const argv = [_][]const u8{ bin, "build", "--target", target.toString(), "--out", out_dir };
    const cap = spawnCaptured(gpa, io, &argv, lib_dir, .no_tests, strict, false);
    removeScratchOut(gpa, io, lib_dir, out_dir);
    return cap;
}

/// The `--out` of one `botopink build` this runner spawns, relative to the
/// lib's directory. Per target AND per run: two gates over one library
/// checkout reach the same (lib, target) pair, and a per-target directory
/// alone was one both wrote — the half-written module set of one read as the
/// other's red. The id is 64 random bits, `botopink test`'s own
/// `test-out/<target>/<id>`.
fn scratchOutDir(gpa: std.mem.Allocator, io: std.Io, target: Target) ![]const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    return std.fmt.allocPrint(gpa, "{s}/{s}/{x:0>16}", .{ COMPILE_OUT_DIR, target.toString(), id });
}

/// The build's output belongs to this run and nothing reads it afterwards:
/// the verdict is the exit status and the captured diagnostics.
fn removeScratchOut(gpa: std.mem.Allocator, io: std.Io, lib_dir: []const u8, out_dir: []const u8) void {
    if (std.fs.path.join(gpa, &.{ lib_dir, out_dir })) |abs| {
        std.Io.Dir.cwd().deleteTree(io, abs) catch {};
    } else |_| {}
}

/// Write a captured compile-only cell out, as the serial runner did.
pub fn emitCompile(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_name: []const u8,
    target: Target,
    json: bool,
    cap: Captured,
) !Status {
    if (!json) std.debug.print("\n\x1b[36m── {s} · {s} (no tests: compile only) ──\x1b[0m\n", .{ lib_name, target.toString() });
    if (cap.spawn_err) |err| return reportSpawnError(bin, err);

    if (cap.stdout.len > 0) std.Io.File.stderr().writeStreamingAll(io, cap.stdout) catch {};
    if (cap.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, cap.stderr) catch {};

    // No test ran: `ran = false`, so a compile red is never reported as
    // "0 failures".
    if (json) try emitCellSummary(arena, io, lib_name, target.toString(), cap.status, .{});
    return cap.status;
}

// ── The restriction audit ───────────────────────────────────────────────────

/// The fixed part of the compiler's refusal for a host cell that has no
/// binding on the build's target (`MissingExternal.diagnostic`,
/// `compiler-core/src/codegen/moduleOutput.zig`). Both of its spellings carry
/// it — "`f` has no `#[@External.<Target>(…)]` for the node backend" and
/// "`f` calls `g`, which has no `#[@External.<Target>(…)]` for the wasm
/// backend". The refusal carries no error id, so its fixed text is what
/// identifies it; if the compiler rewords it every audit answers
/// `not_structural` and the run fails — the audit can stop accepting, it
/// cannot start accepting something else. `compiler-cli/tests/test_tooling.sh`
/// holds the two together with a real build.
const HOST_BINDING_MARK = "has no `#[@External.<Target>(…)]` for the ";
const HOST_BINDING_TAIL = " backend";

/// What one restriction audit found. A lib's `"targets"` list may exclude a
/// target only when the lib structurally cannot run there: `botopink build
/// --target <excluded>` is refused, and its FIRST error is the missing
/// host-binding refusal. Anything else — the build succeeds, or it fails for
/// another reason — means the exclusion hides a cell that could run or a red
/// that is somebody's to fix, and the exclusion itself is refused.
pub const Audit = struct {
    why: Why = .no_error_line,
    /// The build's first `error` line, ANSI escapes removed. Empty when the
    /// build succeeded or printed no error line.
    line: []const u8 = "",
    /// The `--> <file>:<line>:<col>` location under that line, when printed.
    at: []const u8 = "",

    pub const Why = enum {
        /// Refused for a missing host binding: the exclusion is structural.
        structural,
        /// `botopink build` succeeded on the excluded target.
        builds,
        /// The build's first error is not a missing host binding.
        other_error,
        /// The build failed and printed no `error` line.
        no_error_line,
    };

    pub fn status(self: Audit) Status {
        return if (self.why == .structural) .excluded else .not_structural;
    }
};

/// Audit one (lib, excluded target) pair: spawn `botopink build --target <t>
/// --out <COMPILE_OUT_DIR>/<t>/<id>` in `lib_dir`, classify the outcome, and
/// remove the output. Writes nothing to this process's stdout/stderr.
pub fn captureAudit(
    gpa: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    target: Target,
) Captured {
    const out_dir = scratchOutDir(gpa, io, target) catch |err| return .{ .spawn_err = err };
    const argv = [_][]const u8{ bin, "build", "--target", target.toString(), "--out", out_dir };
    const result = std.process.run(gpa, io, .{
        .argv = &argv,
        .cwd = .{ .path = lib_dir },
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| return .{ .spawn_err = err };
    removeScratchOut(gpa, io, lib_dir, out_dir);

    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };
    const audit = classifyAudit(gpa, code, result.stdout, result.stderr);
    return .{
        .stdout = result.stdout,
        .stderr = result.stderr,
        .status = audit.status(),
        .audit = audit,
    };
}

/// The audit's verdict from the build's exit code and output. Allocates the
/// returned lines in `gpa`.
pub fn classifyAudit(gpa: std.mem.Allocator, code: u8, stdout: []const u8, stderr: []const u8) Audit {
    if (code == 0) return .{ .why = .builds };
    // Diagnostics are the build's stderr; stdout is read only when stderr
    // holds no error line at all.
    const first = firstErrorLine(gpa, stderr) orelse firstErrorLine(gpa, stdout) orelse
        return .{ .why = .no_error_line };
    return .{
        .why = if (isHostBindingRefusal(first.line)) .structural else .other_error,
        .line = first.line,
        .at = first.at,
    };
}

/// True when `line` is the compiler's missing-host-binding refusal.
fn isHostBindingRefusal(line: []const u8) bool {
    const at = std.mem.indexOf(u8, line, HOST_BINDING_MARK) orelse return false;
    const rest = line[at + HOST_BINDING_MARK.len ..];
    // `<backend> backend`, one word, and nothing after it.
    if (!std.mem.endsWith(u8, rest, HOST_BINDING_TAIL)) return false;
    const backend = rest[0 .. rest.len - HOST_BINDING_TAIL.len];
    if (backend.len == 0) return false;
    for (backend) |c| {
        if (!std.ascii.isAlphanumeric(c)) return false;
    }
    return true;
}

const ErrorLine = struct { line: []const u8, at: []const u8 };

/// The first line of `text` that is a diagnostic's `error: …` / `error[<id>]: …`
/// head, with ANSI escapes removed, and the `--> <location>` of the line
/// after it when there is one. Null when `text` holds no such line.
fn firstErrorLine(gpa: std.mem.Allocator, text: []const u8) ?ErrorLine {
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw| {
        const line = stripAnsi(gpa, std.mem.trimEnd(u8, raw, "\r")) orelse continue;
        if (!std.mem.startsWith(u8, line, "error:") and !std.mem.startsWith(u8, line, "error[")) continue;
        var at: []const u8 = "";
        if (it.peek()) |next_raw| {
            if (stripAnsi(gpa, std.mem.trimEnd(u8, next_raw, "\r"))) |next| {
                const trimmed = std.mem.trimStart(u8, next, " ");
                if (std.mem.startsWith(u8, trimmed, "--> ")) at = trimmed["--> ".len..];
            }
        }
        return .{ .line = line, .at = at };
    }
    return null;
}

/// `line` without its ANSI CSI sequences (`ESC [ … <letter>`), allocated in
/// `gpa`. Null only when the allocation fails.
fn stripAnsi(gpa: std.mem.Allocator, line: []const u8) ?[]const u8 {
    const out = gpa.alloc(u8, line.len) catch return null;
    var n: usize = 0;
    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == 0x1b and i + 1 < line.len and line[i + 1] == '[') {
            i += 2;
            while (i < line.len and !std.ascii.isAlphabetic(line[i])) i += 1;
            if (i < line.len) i += 1; // the final letter
            continue;
        }
        out[n] = line[i];
        n += 1;
        i += 1;
    }
    return out[0..n];
}

/// Write a captured audit out. A structural exclusion is one line: the
/// refusal that proves it. One the audit refused prints the build's own
/// output (when it failed) and the refusal of the exclusion, on stderr in both
/// modes; `--json` adds one `{"event":"restriction_audit",…}` record either way.
pub fn emitAudit(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_name: []const u8,
    target: Target,
    json: bool,
    cap: Captured,
) !Status {
    const tname = target.toString();
    if (!json) std.debug.print("\n\x1b[36m── {s} · {s} (excluded by \"targets\": restriction audit) ──\x1b[0m\n", .{ lib_name, tname });
    if (cap.spawn_err) |err| return reportSpawnError(bin, err);

    const audit = cap.audit;
    // What the record's `line` says, and — for a refused exclusion — the
    // second half of the sentence printed on stderr.
    var line: []const u8 = audit.line;
    var found: []const u8 = "";
    switch (audit.why) {
        .structural => {
            if (!json) {
                if (audit.at.len > 0) {
                    std.debug.print("restriction audit: ok — {s} ({s})\n", .{ audit.line, audit.at });
                } else {
                    std.debug.print("restriction audit: ok — {s}\n", .{audit.line});
                }
            }
        },
        .builds => {
            line = try std.fmt.allocPrint(arena, "`botopink build --target {s}` succeeds", .{tname});
            found = try std.fmt.allocPrint(arena, "`botopink build --target {s}` succeeds there", .{tname});
        },
        .other_error => {
            found = try std.fmt.allocPrint(arena, "the first error of its build there is not a missing host binding: {s}", .{audit.line});
        },
        .no_error_line => {
            line = "the build failed and printed no error line";
            found = "its build there fails without printing an error line";
        },
    }
    if (audit.why != .structural) {
        // The build's own output first (a failed build's diagnostics are what
        // the reader needs), then the refusal of the exclusion.
        if (audit.why != .builds) {
            if (cap.stdout.len > 0) std.Io.File.stderr().writeStreamingAll(io, cap.stdout) catch {};
            if (cap.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, cap.stderr) catch {};
        }
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: the restriction is not structural — `{s}` excludes `{s}` in its \"targets\", and {s}\n", .{ lib_name, tname, found });
        std.debug.print("  → delete the \"targets\" line, or file the compiler row that makes the build refuse it\n", .{});
    }
    if (json) try emitAuditRecord(arena, io, lib_name, tname, audit.status(), line, audit.at);
    return audit.status();
}

/// `{"event":"restriction_audit","lib":…,"target":…,"status":"ok|not_structural","line":…,"at":…}`
/// — one per (lib, excluded target) pair the run audited. `line` is the
/// refusal that proves the exclusion structural, or what the audit found
/// instead; `at` its `<file>:<line>:<col>`, empty when there is none.
fn emitAuditRecord(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
    line: []const u8,
    at: []const u8,
) !void {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);
    try appendAuditRecord(arena, &buf, lib_name, target_str, status, line, at);
    std.Io.File.stdout().writeStreamingAll(io, buf.items) catch {};
}

fn appendAuditRecord(
    arena: std.mem.Allocator,
    buf: *std.ArrayListUnmanaged(u8),
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
    line: []const u8,
    at: []const u8,
) !void {
    try buf.appendSlice(arena, "{\"event\":\"restriction_audit\",\"lib\":\"");
    try buf.appendSlice(arena, lib_name);
    try buf.appendSlice(arena, "\",\"target\":\"");
    try buf.appendSlice(arena, target_str);
    try buf.appendSlice(arena, "\",\"status\":\"");
    try buf.appendSlice(arena, if (status == .excluded) "ok" else "not_structural");
    try buf.appendSlice(arena, "\",\"line\":\"");
    try appendJsonEscaped(arena, buf, line);
    try buf.appendSlice(arena, "\",\"at\":\"");
    try appendJsonEscaped(arena, buf, at);
    try buf.appendSlice(arena, "\"}\n");
}

/// `text` as the inside of a JSON string: `"` and `\` escaped, control
/// bytes as `\u00XX`. Non-ASCII bytes pass through (the stream is UTF-8).
fn appendJsonEscaped(arena: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), text: []const u8) !void {
    for (text) |c| {
        if (c == '"' or c == '\\') {
            try buf.append(arena, '\\');
            try buf.append(arena, c);
        } else if (c < 0x20) {
            var esc: [6]u8 = undefined;
            _ = std.fmt.bufPrint(&esc, "\\u{x:0>4}", .{c}) catch unreachable;
            try buf.appendSlice(arena, &esc);
        } else {
            try buf.append(arena, c);
        }
    }
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
/// `{"event":"cell_summary","lib":…,"target":…,"status":…,"failed":…,"ran":…}`
/// record so a JSON consumer can correlate every cell with its outcome
/// without re-parsing the text matrix. `status` mirrors `Status` stringified
/// for downstream readability.
///
/// `failed`/`ran` carry the child's own test tally. `ran:false` means no test
/// tally exists — a compile red, a build-only cell, or a cell that was never
/// spawned — and must never be read as "zero failures".
fn emitCellSummary(
    arena: std.mem.Allocator,
    io: std.Io,
    lib_name: []const u8,
    target_str: []const u8,
    status: Status,
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
    try buf.appendSlice(arena, "\",\"failed\":");
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
        .excluded => "excluded",
        .not_structural => "not_structural",
    };
}

/// `{"event":"lib","lib":…,"dir":…}` — one per discovered library, before any
/// cell, under `--json`. `dir` is the directory the lib's cells run in.
pub fn emitLibRecord(arena: std.mem.Allocator, io: std.Io, lib_name: []const u8, dir: []const u8) !void {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);
    try buf.appendSlice(arena, "{\"event\":\"lib\",\"lib\":\"");
    try buf.appendSlice(arena, lib_name);
    try buf.appendSlice(arena, "\",\"dir\":\"");
    for (dir) |c| {
        if (c == '"' or c == '\\') try buf.append(arena, '\\');
        try buf.append(arena, c);
    }
    try buf.appendSlice(arena, "\"}\n");
    std.Io.File.stdout().writeStreamingAll(io, buf.items) catch {};
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
    try emitCellSummary(arena, io, lib_name, target_str, status, .{});
}

/// Final `{"event":"run_summary",…}` record — one per `botopink-lib-test`
/// invocation in JSON mode. Mirrors the text-mode `<P> passed, <F> failed,
/// <N> no-tests, <S> skipped, <A> restrictions audited, <X> not structural`
/// line at the bottom of the matrix.
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
    try buf.appendSlice(arena, ",\"audited\":");
    try appendDecimal(arena, &buf, summary.audited);
    try buf.appendSlice(arena, ",\"not_structural\":");
    try appendDecimal(arena, &buf, summary.not_structural);
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
        try out.appendSlice(arena, "acme");
        try out.appendSlice(arena, "\",\"target\":\"");
        try out.appendSlice(arena, "commonJS");
        try out.appendSlice(arena, "\",");
        try out.appendSlice(arena, line[1..]);
        try out.append(arena, '\n');
    }

    try testing.expectEqualStrings(
        "{\"lib\":\"acme\",\"target\":\"commonJS\",\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":1,\"name\":\"t\",\"status\":\"ok\",\"run_log\":\"\"}\n" ++
            "{\"lib\":\"acme\",\"target\":\"commonJS\",\"event\":\"summary\",\"passed\":1,\"failed\":0}\n",
        out.items,
    );
}

test "statusName covers every Status variant" {
    try testing.expectEqualStrings("pass", statusName(.pass));
    try testing.expectEqualStrings("fail", statusName(.fail));
    try testing.expectEqualStrings("skipped_unsupported", statusName(.skipped_unsupported));
    try testing.expectEqualStrings("no_tests", statusName(.no_tests));
    try testing.expectEqualStrings("excluded", statusName(.excluded));
    try testing.expectEqualStrings("not_structural", statusName(.not_structural));
}

test "parseChildSummary: the child's summary record carries the failure count" {
    const stdout =
        "{\"event\":\"test\",\"name\":\"a\",\"status\":\"ok\"}\n" ++
        "{\"event\":\"test\",\"name\":\"b\",\"status\":\"fail\"}\n" ++
        "{\"event\":\"summary\",\"passed\":1,\"failed\":9}\n";
    const counts = parseChildSummary(stdout, true);
    try testing.expect(counts.ran);
    try testing.expectEqual(@as(usize, 9), counts.failed);
}

test "parseChildSummary: a green cell is 0 failures, and it ran" {
    const counts = parseChildSummary("{\"event\":\"summary\",\"passed\":17,\"failed\":0}\n", true);
    try testing.expect(counts.ran);
    try testing.expectEqual(@as(usize, 0), counts.failed);
}

test "parseChildSummary: no summary record is `did not run`, not zero failures" {
    // A cell that did not compile prints diagnostics on stderr and no summary.
    // `ran = false` is what keeps a consumer from reading it as green.
    const counts = parseChildSummary("error: parse error\n", true);
    try testing.expect(!counts.ran);
    try testing.expectEqual(@as(usize, 0), counts.failed);

    const empty = parseChildSummary("", true);
    try testing.expect(!empty.ran);
}

test "parseChildSummary: in text mode the count is the run total, never a module's own line" {
    const text =
        "----- TESTS OF a -----\n" ++
        "0 passed, 3 failed\n" ++
        "----- TESTS OF b -----\n" ++
        "5 passed, 0 failed\n" ++
        "total: 5 passed, 3 failed in 2 module(s)\n";
    const counts = parseChildSummary(text, false);
    try testing.expect(counts.ran);
    try testing.expectEqual(@as(usize, 3), counts.failed);

    // Module summaries alone are no total: the run did not finish its report.
    const partial = parseChildSummary("5 passed, 0 failed\n", false);
    try testing.expect(!partial.ran);
}

test "classifyWith: exit 0 is the ok status, the unsupported mark a skip unless strict, else a fail" {
    try testing.expectEqual(Status.pass, classifyWith(.pass, 0, "", "", false));
    try testing.expectEqual(Status.no_tests, classifyWith(.no_tests, 0, "", "", false));
    try testing.expectEqual(Status.fail, classifyWith(.no_tests, 1, "", "error: parse error", false));
    try testing.expectEqual(Status.skipped_unsupported, classifyWith(.no_tests, 1, "", "botopink test currently supports only commonJS", false));
    try testing.expectEqual(Status.fail, classifyWith(.pass, 1, "currently supports only", "", true));
}

// ── restriction audit ───────────────────────────────────────────────────────

/// What `botopink build --target erlang` prints for a member whose one host
/// cell has a Node binding only (captured from a real build). The escape
/// bytes of the compiler's closing summary are spelled with `++`: a `\\\\`
/// line cannot carry them.
const AUDIT_REFUSED_STDOUT = "  \x1b[36mCompiling\x1b[0m 33 module(s)...\n";
const AUDIT_REFUSED_STDERR =
    \\error: `callGlobal` has no `#[@External.<Target>(…)]` for the erlang backend
    \\  --> src/root.bp:37:12
    \\   |
    \\37 |     return callGlobal(name, id);
    \\   |            ^
    \\
    \\
++ "\x1b[1m\x1b[31merror\x1b[0m: 1 module(s) failed to compile: root\n";

test "classifyAudit: a build refused for a missing host binding is a structural exclusion" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const audit = classifyAudit(arena_inst.allocator(), 1, AUDIT_REFUSED_STDOUT, AUDIT_REFUSED_STDERR);
    try testing.expectEqual(Audit.Why.structural, audit.why);
    try testing.expectEqual(Status.excluded, audit.status());
    try testing.expectEqualStrings("error: `callGlobal` has no `#[@External.<Target>(…)]` for the erlang backend", audit.line);
    try testing.expectEqualStrings("src/root.bp:37:12", audit.at);
}

test "classifyAudit: the refusal reached through a bodied function is structural too" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const stderr =
        \\error: `render` calls `now`, which has no `#[@External.<Target>(…)]` for the wasm backend
        \\   --> src/clock.bp:9:5
        \\
    ;
    const audit = classifyAudit(arena_inst.allocator(), 1, "", stderr);
    try testing.expectEqual(Audit.Why.structural, audit.why);
    try testing.expectEqualStrings("src/clock.bp:9:5", audit.at);
}

test "classifyAudit: a build that succeeds on the excluded target refuses the exclusion" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const audit = classifyAudit(arena_inst.allocator(), 0, "  Compiling 3 module(s)...\n  Compiled in 12ms\n", "");
    try testing.expectEqual(Audit.Why.builds, audit.why);
    try testing.expectEqual(Status.not_structural, audit.status());
    // Exit 0 decides: an `error` line in the output of a build that succeeded
    // proves nothing.
    const noisy = classifyAudit(arena_inst.allocator(), 0, "", AUDIT_REFUSED_STDERR);
    try testing.expectEqual(Audit.Why.builds, noisy.why);
}

test "classifyAudit: a build whose FIRST error is anything else refuses the exclusion, even when a host-binding refusal follows" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const stderr =
        \\error[if-operand]: `if` cannot be an operand
        \\  --> src/a.bp:3:9
        \\
        \\error: `host` has no `#[@External.<Target>(…)]` for the node backend
        \\  --> src/b.bp:1:1
        \\
    ;
    const audit = classifyAudit(arena_inst.allocator(), 1, "", stderr);
    try testing.expectEqual(Audit.Why.other_error, audit.why);
    try testing.expectEqual(Status.not_structural, audit.status());
    try testing.expectEqualStrings("error[if-operand]: `if` cannot be an operand", audit.line);
    try testing.expectEqualStrings("src/a.bp:3:9", audit.at);
}

test "classifyAudit: only the trailing summary, or no error line at all, refuses the exclusion" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const summary_only = classifyAudit(arena_inst.allocator(), 1, "", "\x1b[1m\x1b[31merror\x1b[0m: 1 module(s) failed to compile: root\n");
    try testing.expectEqual(Audit.Why.other_error, summary_only.why);
    try testing.expectEqualStrings("error: 1 module(s) failed to compile: root", summary_only.line);

    const silent = classifyAudit(arena_inst.allocator(), 1, "", "Segmentation fault\n");
    try testing.expectEqual(Audit.Why.no_error_line, silent.why);
    try testing.expectEqual(Status.not_structural, silent.status());
}

test "isHostBindingRefusal: the fixed text, one backend word, nothing after it" {
    try testing.expect(isHostBindingRefusal("error: `f` has no `#[@External.<Target>(…)]` for the node backend"));
    try testing.expect(isHostBindingRefusal("error: `f` calls `g`, which has no `#[@External.<Target>(…)]` for the erlang backend"));
    // The beam template refusal is a different diagnostic: the binding exists.
    try testing.expect(!isHostBindingRefusal("error: `f`'s `#[@External.Erlang(…)]` template does not compile for the beam backend: a fun"));
    try testing.expect(!isHostBindingRefusal("error: `f` has no `#[@External.<Target>(…)]` for the  backend"));
    try testing.expect(!isHostBindingRefusal("error: `f` has no `#[@External.<Target>(…)]` for the node backend, and more"));
    try testing.expect(!isHostBindingRefusal("error: unbound variable `f`"));
}

test "firstErrorLine: ANSI is stripped, a note or a warning is not an error head" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const text = "warning: unused\n  errors below\n\x1b[1m\x1b[31merror\x1b[0m[x-y]: first\nerror: second\n";
    const first = firstErrorLine(arena_inst.allocator(), text).?;
    try testing.expectEqualStrings("error[x-y]: first", first.line);
    try testing.expectEqualStrings("", first.at);
    try testing.expect(firstErrorLine(arena_inst.allocator(), "errors: none\nok\n") == null);
}

test "appendAuditRecord: one JSON line, the refusal escaped" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try appendAuditRecord(arena, &buf, "acme", "commonJS", .excluded, "error: `f` has no `#[@External.<Target>(…)]` for the node backend", "src/a.bp:1:2");
    try testing.expectEqualStrings(
        "{\"event\":\"restriction_audit\",\"lib\":\"acme\",\"target\":\"commonJS\",\"status\":\"ok\",\"line\":\"error: `f` has no `#[@External.<Target>(…)]` for the node backend\",\"at\":\"src/a.bp:1:2\"}\n",
        buf.items,
    );
    buf.clearRetainingCapacity();
    try appendAuditRecord(arena, &buf, "acme", "erlang", .not_structural, "error: expected \"x\"\ty \\ z", "");
    try testing.expectEqualStrings(
        "{\"event\":\"restriction_audit\",\"lib\":\"acme\",\"target\":\"erlang\",\"status\":\"not_structural\",\"line\":\"error: expected \\\"x\\\"\\u0009y \\\\ z\",\"at\":\"\"}\n",
        buf.items,
    );
}
