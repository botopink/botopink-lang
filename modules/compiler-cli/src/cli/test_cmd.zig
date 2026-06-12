/// `botopink test` — compile in test mode then run every test block.
///
/// Compiles the project with `test_mode = true` (test blocks emit as
/// functions + a registry + runner entry; `fn main/0` is not auto-invoked),
/// writes artifacts under `.botopinkbuild/test-out/`, then executes each
/// module that contains tests and aggregates the exit codes.
///
/// Currently only the `commonJS` target runs tests (node); other targets
/// are pending phases of the `test-blocks` spec.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const scanner = @import("./scanner.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    /// `--filter <substr>` — only run tests whose name contains the substring.
    filter: ?[]const u8 = null,
    /// `--json` — emit JSONL (one JSON object per test) to stdout instead of
    /// the §T text envelope. The runner captures each child's stdout, parses
    /// the `TEST … / ----- RUN LOG ----- / ok|FAIL` blocks emitted by the
    /// codegen-side runner (commonJS + erlang today), and re-emits as
    /// `{file, line, name, status, run_log, error_message?, error_file?,
    /// error_line?}` per test plus a final `{event:"summary", passed, failed}`.
    /// Schema documented in `modules/compiler-cli/AGENTS.md` "§T".
    json: bool = false,
};

const TEST_OUT_DIR = ".botopinkbuild/test-out";

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    env_map: libs.EnvMap,
) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget();
    if (target != .commonJS and target != .erlang) {
        reporter.errMsg("`botopink test` currently supports only the commonJS and erlang targets");
        reporter.hintMsg("run with `--target commonJS` or set \"target\": \"commonJS\" in botopink.json");
        return 1;
    }

    // Scan source files: `src/` (inline test blocks) plus `test/` (separate
    // `*_test.bp` suites). Test modules come last so `src/` exports are
    // already registered when they compile.
    // `src/` resolves through the explicit module tree; the flat `test/` suite
    // dir is not a package, so it keeps the plain directory scan.
    var src_loaded = sources.load(gpa, io, proj, "src") catch return 1;
    defer src_loaded.free(gpa);
    const src_modules = src_loaded.modules;
    const test_modules = try scanner.scanSources(gpa, io, "test");
    defer scanner.freeModules(gpa, test_modules);

    if (src_modules.len == 0 and test_modules.len == 0) {
        reporter.errMsg("no source files found in src/ or test/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    // Resolve declared external libs (generic — `libs/<name>/`), same as `build`,
    // so a consumer's tests can `import … from "<lib>"`. Dependency modules are
    // compiled first (their types/exports must resolve before the project), but
    // their OWN `test {}` blocks are not run — only the project's are.
    const dep_modules = libs.loadDependencies(gpa, io, proj.dependencies, env_map) catch |err| {
        switch (err) {
            error.LibsRootNotFound => {
                reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory");
                reporter.hintMsg("if your botopink.json uses the new object form ({\"<name>\": {\"git\": ...}}), run `bpmp install` to fetch deps into $BPMP_HOME first");
            },
            error.LibNotFound => reporter.errMsg("a declared dependency was not found under the libs root"),
            error.LibManifestInvalid => reporter.errMsg("a dependency's botopink.json is invalid"),
            else => reporter.errMsg("failed to load project dependencies"),
        }
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Keep only real `.bp` dependency modules. Declaration-only (`.d.bp`) modules
    // use declaration-file syntax the regular pipeline doesn't parse for external
    // libs yet (the declaration-parse path is std-only), so they are skipped
    // rather than failed — they carry host-bound / gated surface, not runnable
    // code. `build` effectively drops them the same way.
    var real_deps: std.ArrayListUnmanaged(bp.Module) = .empty;
    for (dep_modules) |d| {
        if (!d.declaration) try real_deps.append(arena, d);
    }

    const modules = try std.mem.concat(arena, bp.Module, &.{ real_deps.items, src_modules, test_modules });

    reporter.compiling(modules.len);

    // Build codegen config in test mode.
    const cfg = bp.codegen.Config{
        .targetSource = switch (target) {
            .commonJS => .commonJS,
            .erlang => .erlang,
            else => unreachable, // guarded above
        },
        .build_root = ".botopinkbuild",
        .test_mode = true,
    };

    var outputs = bp.codegen.generate(gpa, modules, io, cfg) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    // Check for comptime errors in outputs.
    var had_error = false;
    for (outputs.items) |o| {
        if (o.result.comptime_err) |ce| {
            had_error = true;
            const rendered = ce.renderAlloc(gpa, o.src) catch continue;
            defer gpa.free(rendered);
            std.debug.print("{s}", .{rendered});
        }
    }
    if (had_error) return 1;

    // Modules with parse/type errors produce no output at all — surface that
    // instead of silently skipping their tests.
    if (outputs.items.len < modules.len) {
        const msg = try std.fmt.allocPrint(
            arena,
            "{d} module(s) failed to compile — run `botopink check` for diagnostics",
            .{modules.len - outputs.items.len},
        );
        reporter.errMsg(msg);
        return 1;
    }

    // Write every module's test-mode artifact (test modules `require` their
    // sibling modules on commonJS), then run each module that contains tests.
    std.Io.Dir.cwd().createDirPath(io, TEST_OUT_DIR) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext: []const u8 = switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        else => unreachable,
    };
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .erlang => "escript",
        else => unreachable,
    };

    for (outputs.items) |o| {
        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });
    }

    // Ship runtime `.mjs` sidecars (G2): a dependency's `#[@External.<targert>(...)]` modules
    // sit a directory deeper here than in their own build, so their relative
    // `require("../../src/x.mjs")` would miss the source — copy each into place.
    if (target == .commonJS) {
        libs.shipMjsSidecars(gpa, io, outputs.items, TEST_OUT_DIR, ext, env_map) catch {};
    }

    // commonJS: root-source imports (`import {x};`) emit `require("./module")`
    // — write a `module.js` aggregator that merges every module's exports.
    // Runners only execute as the entry module (`require.main === module`),
    // so requiring a sibling never re-runs its tests.
    if (target == .commonJS) {
        var agg = std.ArrayListUnmanaged(u8).empty;
        defer agg.deinit(arena);
        try agg.appendSlice(arena, "module.exports = Object.assign({}");
        for (outputs.items) |o| {
            // "std" package modules are only reachable via `from "std"` —
            // bare imports (project root) must never see them.
            if (std.mem.startsWith(u8, o.name, "std/")) continue;
            // Test modules export nothing other modules import, and a test module
            // may run module-load side effects (e.g. decorator `@emit`s) that
            // depend on its own bare imports resolving through this aggregator.
            // Requiring one test module from another's run would re-execute it
            // mid-aggregator-build — the circular `require("./module")` would then
            // see an empty object and its side effects would crash. Exclude them.
            if (isTestModule(o.name, test_modules)) continue;
            try agg.appendSlice(arena, ", require(\"./");
            try agg.appendSlice(arena, o.name);
            try agg.appendSlice(arena, ".js\")");
        }
        try agg.appendSlice(arena, ");\n");
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = TEST_OUT_DIR ++ "/module.js", .data = agg.items });

        // Nested modules (a dependency's `jhonstart/hooks.js`) emit a flat
        // `require("./module")` for their bare sibling imports, which would
        // resolve next to themselves (`jhonstart/module.js`), not at the root
        // aggregator. Drop a shim `module.js` in each such directory that points
        // back up to the root one.
        var seen_dirs = std.StringHashMap(void).init(arena);
        for (outputs.items) |o| {
            if (std.mem.startsWith(u8, o.name, "std/")) continue;
            const dir = std.fs.path.dirname(o.name) orelse continue; // null → top level
            if (seen_dirs.contains(dir)) continue;
            try seen_dirs.put(dir, {});

            // One `../` per path segment in `dir` (segments = '/' count + 1).
            const depth = std.mem.count(u8, dir, "/") + 1;
            var shim = std.ArrayListUnmanaged(u8).empty;
            defer shim.deinit(arena);
            try shim.appendSlice(arena, "module.exports = require(\"");
            for (0..depth) |_| try shim.appendSlice(arena, "../");
            try shim.appendSlice(arena, "module\");\n");

            const shim_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}/module.js", .{dir});
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = shim_path, .data = shim.items });
        }
    }

    var any_tests = false;
    var exit_code: u8 = 0;
    // JSON mode accumulates `passed`/`failed` across modules so the final
    // `summary` JSON object reflects the whole run, not the last module only.
    var json_passed_total: usize = 0;
    var json_failed_total: usize = 0;
    for (outputs.items) |o| {
        // Dependency modules are compiled for their exports, not tested here —
        // run only the project's own `test {}` blocks.
        if (isDepModule(o.name, real_deps.items)) continue;
        // Modules without test blocks have no runner — skip them.
        if (std.mem.indexOf(u8, o.result.js, "__bp_run_tests") == null) continue;
        any_tests = true;

        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });

        var argv = std.ArrayListUnmanaged([]const u8).empty;
        defer argv.deinit(arena);
        try argv.append(arena, runner);
        try argv.append(arena, sub_path);
        if (opts.filter) |f| try argv.append(arena, f);

        if (opts.json) {
            // JSON mode: capture child stdout, parse the §T envelope, re-emit
            // as JSONL. Stderr is forwarded untouched (compile-time spam from
            // node/escript still surfaces). The text-mode path stays
            // inherit-stdio so live streaming is unchanged when --json is off.
            const result = std.process.run(arena, io, .{
                .argv = argv.items,
                .stdout_limit = .limited(16 * 1024 * 1024),
                .stderr_limit = .limited(16 * 1024 * 1024),
            }) catch |err| {
                const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
                reporter.errMsg(msg);
                return 1;
            };

            if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};

            const counts = emitJsonl(arena, io, o.name, result.stdout) catch |err| {
                const msg = try std.fmt.allocPrint(arena, "failed to format JSONL for '{s}': {s}", .{ o.name, @errorName(err) });
                reporter.errMsg(msg);
                return 1;
            };
            json_passed_total += counts.passed;
            json_failed_total += counts.failed;

            const code: u8 = switch (result.term) {
                .exited => |c| c,
                .signal, .stopped, .unknown => 1,
            };
            if (code != 0) exit_code = code;
            continue;
        }

        // Spawn and wait — stdio is inherited so the runner reports directly.
        var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
            const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
            reporter.errMsg(msg);
            return 1;
        };
        defer child.kill(io);

        const term = try child.wait(io);
        const code: u8 = switch (term) {
            .exited => |c| c,
            .signal, .stopped, .unknown => 1,
        };
        if (code != 0) exit_code = code;
    }

    if (opts.json and any_tests) {
        // Final aggregated summary so a JSONL consumer sees one terminal
        // record per `botopink test` invocation rather than per child.
        var buf = std.ArrayListUnmanaged(u8).empty;
        defer buf.deinit(arena);
        try buf.appendSlice(arena, "{\"event\":\"summary\",\"passed\":");
        try appendDecimal(arena, &buf, json_passed_total);
        try buf.appendSlice(arena, ",\"failed\":");
        try appendDecimal(arena, &buf, json_failed_total);
        try buf.appendSlice(arena, "}\n");
        std.Io.File.stdout().writeStreamingAll(io, buf.items) catch {};
    }

    if (!any_tests) {
        reporter.stdout(io, "no test blocks found\n");
        return 0;
    }

    return exit_code;
}

const JsonCounts = struct { passed: usize, failed: usize };

/// Parse the §T text envelope emitted by the commonJS / erlang runners and
/// re-emit each test result as a single-line JSON object on stdout. Returns
/// per-module passed/failed counts so the caller can aggregate a final
/// `{event:"summary", …}` record across all modules.
///
/// Envelope (per test):
///   TEST <file>:<line> <name>
///   ----- RUN LOG -----
///   \`\`\`logs
///   <captured stdout — zero or more lines>
///   \`\`\`
///     ok   <name>                              | (or)
///     FAIL <name>  (<err>)  at <file>:<line>
///
/// Trailing summary line (`<P> passed, <F> failed`) is parsed out — it is
/// not re-emitted here; the caller aggregates module-level counts into the
/// single end-of-run summary record.
///
/// Unknown lines are skipped (forward-compatible with future envelope
/// extensions like timing).
fn emitJsonl(
    arena: std.mem.Allocator,
    io: std.Io,
    module_name: []const u8,
    stdout_buf: []const u8,
) !JsonCounts {
    var counts = JsonCounts{ .passed = 0, .failed = 0 };

    const State = enum { idle, awaiting_run_log, awaiting_fence_open, in_logs, awaiting_result };
    var state: State = .idle;

    var cur_file: []const u8 = "";
    var cur_line: []const u8 = "";
    var cur_name: []const u8 = "";
    var cur_duration_ms: ?u32 = null;
    var cur_logs: std.ArrayListUnmanaged(u8) = .empty;
    defer cur_logs.deinit(arena);

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);

    var it = std.mem.splitScalar(u8, stdout_buf, '\n');
    while (it.next()) |line| {
        switch (state) {
            .idle, .awaiting_result => {
                if (std.mem.startsWith(u8, line, "TEST ")) {
                    const rest = line["TEST ".len..];
                    const sp = std.mem.indexOfScalar(u8, rest, ' ') orelse continue;
                    const loc = rest[0..sp];
                    cur_name = rest[sp + 1 ..];
                    if (std.mem.lastIndexOfScalar(u8, loc, ':')) |colon| {
                        cur_file = loc[0..colon];
                        cur_line = loc[colon + 1 ..];
                    } else {
                        cur_file = loc;
                        cur_line = "0";
                    }
                    cur_logs.clearRetainingCapacity();
                    cur_duration_ms = null;
                    state = .awaiting_run_log;
                } else if (std.mem.startsWith(u8, line, "  duration ")) {
                    // T2-followup: `  duration <ms>ms` between fence-close and
                    // the ok/FAIL line. Captured for the upcoming test record.
                    cur_duration_ms = parseDurationMs(line);
                } else if (std.mem.startsWith(u8, line, "  ok   ")) {
                    // Standalone ok line (after a finished envelope) —
                    // current name still holds the test that just finished.
                    try writeTestRecord(arena, &out, module_name, cur_file, cur_line, cur_name, true, cur_logs.items, null, null, null, cur_duration_ms);
                    counts.passed += 1;
                    cur_duration_ms = null;
                    state = .idle;
                } else if (std.mem.startsWith(u8, line, "  FAIL ")) {
                    const parsed = parseFailLine(line) orelse FailParse{
                        .name = cur_name,
                        .err = "",
                        .err_file = cur_file,
                        .err_line = cur_line,
                    };
                    try writeTestRecord(arena, &out, module_name, cur_file, cur_line, parsed.name, false, cur_logs.items, parsed.err, parsed.err_file, parsed.err_line, cur_duration_ms);
                    counts.failed += 1;
                    cur_duration_ms = null;
                    state = .idle;
                }
                // Other lines (summary, blank trailing, etc.) are skipped.
            },
            .awaiting_run_log => {
                if (std.mem.eql(u8, line, "----- RUN LOG -----")) {
                    state = .awaiting_fence_open;
                }
            },
            .awaiting_fence_open => {
                if (std.mem.eql(u8, line, "```logs")) {
                    state = .in_logs;
                }
            },
            .in_logs => {
                if (std.mem.eql(u8, line, "```")) {
                    state = .awaiting_result;
                } else {
                    if (cur_logs.items.len > 0) try cur_logs.append(arena, '\n');
                    try cur_logs.appendSlice(arena, line);
                }
            },
        }
    }

    if (out.items.len > 0) std.Io.File.stdout().writeStreamingAll(io, out.items) catch {};
    return counts;
}

/// Parse `  duration <int>ms` to its integer ms value. Returns null when the
/// line is malformed (defensive — the runner controls this format, but a
/// downstream tool re-emitting envelopes should not crash the parser).
fn parseDurationMs(line: []const u8) ?u32 {
    if (!std.mem.startsWith(u8, line, "  duration ")) return null;
    var rest = line["  duration ".len..];
    if (!std.mem.endsWith(u8, rest, "ms")) return null;
    rest = rest[0 .. rest.len - "ms".len];
    return std.fmt.parseInt(u32, rest, 10) catch null;
}

const FailParse = struct { name: []const u8, err: []const u8, err_file: []const u8, err_line: []const u8 };

/// Pick apart `  FAIL <name>  (<err>)  at <file>:<line>`. The error message
/// may contain arbitrary punctuation (parentheses included) so the parser
/// anchors on the final `  at ` substring instead of splitting on `)`. Returns
/// null when the shape does not match (caller falls back to a record with
/// empty error / current header location).
fn parseFailLine(line: []const u8) ?FailParse {
    if (!std.mem.startsWith(u8, line, "  FAIL ")) return null;
    const body = line["  FAIL ".len..];

    // Anchor on the LAST `  at ` so an error message containing the substring
    // does not split mid-message.
    const at_idx = std.mem.lastIndexOf(u8, body, "  at ") orelse return null;
    const name_and_err = body[0..at_idx];
    const loc = body[at_idx + "  at ".len ..];

    // `<name>  (<err>)` — split on the last `  (` so a name with parens is
    // tolerated, then strip the closing `)` from the err side.
    const sep = std.mem.lastIndexOf(u8, name_and_err, "  (") orelse return null;
    const name = name_and_err[0..sep];
    var err = name_and_err[sep + "  (".len ..];
    if (err.len > 0 and err[err.len - 1] == ')') err = err[0 .. err.len - 1];

    var err_file: []const u8 = loc;
    var err_line: []const u8 = "0";
    if (std.mem.lastIndexOfScalar(u8, loc, ':')) |c| {
        err_file = loc[0..c];
        err_line = loc[c + 1 ..];
    }

    return .{ .name = name, .err = err, .err_file = err_file, .err_line = err_line };
}

/// Append one JSONL test record to `out`. Strings are JSON-escaped via
/// `writeJsonString` to keep the line well-formed even when the captured
/// run-log carries quotes / backslashes / control bytes. `duration_ms` is
/// emitted only when present (older `botopink` builds may not surface it on
/// the envelope yet — back-compat for downstream consumers reading mixed
/// versions of the §T stream).
fn writeTestRecord(
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(u8),
    module: []const u8,
    file: []const u8,
    line_str: []const u8,
    name: []const u8,
    is_ok: bool,
    run_log: []const u8,
    err: ?[]const u8,
    err_file: ?[]const u8,
    err_line_str: ?[]const u8,
    duration_ms: ?u32,
) !void {
    try out.appendSlice(arena, "{\"event\":\"test\",\"module\":");
    try writeJsonString(arena, out, module);
    try out.appendSlice(arena, ",\"file\":");
    try writeJsonString(arena, out, file);
    try out.appendSlice(arena, ",\"line\":");
    const ln = std.fmt.parseInt(u32, line_str, 10) catch 0;
    try appendDecimal(arena, out, ln);
    try out.appendSlice(arena, ",\"name\":");
    try writeJsonString(arena, out, name);
    try out.appendSlice(arena, ",\"status\":\"");
    try out.appendSlice(arena, if (is_ok) "ok" else "fail");
    try out.appendSlice(arena, "\",\"run_log\":");
    try writeJsonString(arena, out, run_log);
    if (duration_ms) |dm| {
        try out.appendSlice(arena, ",\"duration_ms\":");
        try appendDecimal(arena, out, dm);
    }
    if (err) |e| {
        try out.appendSlice(arena, ",\"error_message\":");
        try writeJsonString(arena, out, e);
    }
    if (err_file) |ef| {
        try out.appendSlice(arena, ",\"error_file\":");
        try writeJsonString(arena, out, ef);
    }
    if (err_line_str) |els| {
        const eln = std.fmt.parseInt(u32, els, 10) catch 0;
        try out.appendSlice(arena, ",\"error_line\":");
        try appendDecimal(arena, out, eln);
    }
    try out.appendSlice(arena, "}\n");
}

/// Append `n` as base-10 ASCII to `out`. Stack buffer sized for u64. Used by
/// the JSONL emitter to avoid pulling in stream-formatting machinery for one
/// integer-per-record.
fn appendDecimal(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), n: anytype) !void {
    var buf: [20]u8 = undefined;
    const s = try std.fmt.bufPrint(&buf, "{d}", .{n});
    try out.appendSlice(arena, s);
}

// ── tests: §T envelope → JSONL conversion (T2 / T4) ──────────────────────────

/// In-test variant of `emitJsonl` that writes records into a buffer instead of
/// stdout, so unit tests can diff the resulting JSONL string. Mirrors the
/// state machine in `emitJsonl` byte-for-byte; the only difference is the
/// terminal sink.
fn emitJsonlToBuf(
    arena: std.mem.Allocator,
    module_name: []const u8,
    stdout_buf: []const u8,
    out: *std.ArrayListUnmanaged(u8),
) !JsonCounts {
    var counts = JsonCounts{ .passed = 0, .failed = 0 };

    const State = enum { idle, awaiting_run_log, awaiting_fence_open, in_logs, awaiting_result };
    var state: State = .idle;

    var cur_file: []const u8 = "";
    var cur_line: []const u8 = "";
    var cur_name: []const u8 = "";
    var cur_duration_ms: ?u32 = null;
    var cur_logs: std.ArrayListUnmanaged(u8) = .empty;
    defer cur_logs.deinit(arena);

    var it = std.mem.splitScalar(u8, stdout_buf, '\n');
    while (it.next()) |line| {
        switch (state) {
            .idle, .awaiting_result => {
                if (std.mem.startsWith(u8, line, "TEST ")) {
                    const rest = line["TEST ".len..];
                    const sp = std.mem.indexOfScalar(u8, rest, ' ') orelse continue;
                    const loc = rest[0..sp];
                    cur_name = rest[sp + 1 ..];
                    if (std.mem.lastIndexOfScalar(u8, loc, ':')) |colon| {
                        cur_file = loc[0..colon];
                        cur_line = loc[colon + 1 ..];
                    } else {
                        cur_file = loc;
                        cur_line = "0";
                    }
                    cur_logs.clearRetainingCapacity();
                    cur_duration_ms = null;
                    state = .awaiting_run_log;
                } else if (std.mem.startsWith(u8, line, "  duration ")) {
                    cur_duration_ms = parseDurationMs(line);
                } else if (std.mem.startsWith(u8, line, "  ok   ")) {
                    try writeTestRecord(arena, out, module_name, cur_file, cur_line, cur_name, true, cur_logs.items, null, null, null, cur_duration_ms);
                    counts.passed += 1;
                    cur_duration_ms = null;
                    state = .idle;
                } else if (std.mem.startsWith(u8, line, "  FAIL ")) {
                    const parsed = parseFailLine(line) orelse FailParse{
                        .name = cur_name,
                        .err = "",
                        .err_file = cur_file,
                        .err_line = cur_line,
                    };
                    try writeTestRecord(arena, out, module_name, cur_file, cur_line, parsed.name, false, cur_logs.items, parsed.err, parsed.err_file, parsed.err_line, cur_duration_ms);
                    counts.failed += 1;
                    cur_duration_ms = null;
                    state = .idle;
                }
            },
            .awaiting_run_log => if (std.mem.eql(u8, line, "----- RUN LOG -----")) {
                state = .awaiting_fence_open;
            },
            .awaiting_fence_open => if (std.mem.eql(u8, line, "```logs")) {
                state = .in_logs;
            },
            .in_logs => if (std.mem.eql(u8, line, "```")) {
                state = .awaiting_result;
            } else {
                if (cur_logs.items.len > 0) try cur_logs.append(arena, '\n');
                try cur_logs.appendSlice(arena, line);
            },
        }
    }
    return counts;
}

test "emitJsonl — single passing test, empty run log" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST main.bp:9 math doubles two\n" ++
        "----- RUN LOG -----\n" ++
        "```logs\n" ++
        "```\n" ++
        "  ok   math doubles two\n" ++
        "1 passed, 0 failed\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    const counts = try emitJsonlToBuf(arena, "main", input, &out);

    try std.testing.expectEqual(@as(usize, 1), counts.passed);
    try std.testing.expectEqual(@as(usize, 0), counts.failed);
    try std.testing.expectEqualStrings(
        "{\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":9,\"name\":\"math doubles two\",\"status\":\"ok\",\"run_log\":\"\"}\n",
        out.items,
    );
}

test "emitJsonl — failing test surfaces error_message + error_file + error_line" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST main.bp:15 this one fails with a custom message\n" ++
        "----- RUN LOG -----\n" ++
        "```logs\n" ++
        "```\n" ++
        "  FAIL this one fails with a custom message  (double(2) should be five)  at main.bp:16\n" ++
        "0 passed, 1 failed\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    const counts = try emitJsonlToBuf(arena, "main", input, &out);

    try std.testing.expectEqual(@as(usize, 0), counts.passed);
    try std.testing.expectEqual(@as(usize, 1), counts.failed);
    try std.testing.expectEqualStrings(
        "{\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":15,\"name\":\"this one fails with a custom message\",\"status\":\"fail\",\"run_log\":\"\",\"error_message\":\"double(2) should be five\",\"error_file\":\"main.bp\",\"error_line\":16}\n",
        out.items,
    );
}

test "emitJsonl — captured run log lines flow into run_log with newlines escaped" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST f.bp:1 t\n" ++
        "----- RUN LOG -----\n" ++
        "```logs\n" ++
        "hello\n" ++
        "world\n" ++
        "```\n" ++
        "  ok   t\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    _ = try emitJsonlToBuf(arena, "mod", input, &out);

    // Two log lines join with an embedded \n that is JSON-escaped to \\n.
    try std.testing.expectEqualStrings(
        "{\"event\":\"test\",\"module\":\"mod\",\"file\":\"f.bp\",\"line\":1,\"name\":\"t\",\"status\":\"ok\",\"run_log\":\"hello\\nworld\"}\n",
        out.items,
    );
}

test "emitJsonl — multiple tests in one module accumulate" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST f.bp:1 a\n----- RUN LOG -----\n```logs\n```\n  ok   a\n" ++
        "TEST f.bp:2 b\n----- RUN LOG -----\n```logs\n```\n  FAIL b  (nope)  at f.bp:3\n" ++
        "1 passed, 1 failed\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    const counts = try emitJsonlToBuf(arena, "m", input, &out);

    try std.testing.expectEqual(@as(usize, 1), counts.passed);
    try std.testing.expectEqual(@as(usize, 1), counts.failed);

    // Two JSON lines, second carries error fields.
    var lines = std.mem.splitScalar(u8, out.items, '\n');
    const l1 = lines.next() orelse "";
    const l2 = lines.next() orelse "";
    try std.testing.expect(std.mem.indexOf(u8, l1, "\"name\":\"a\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, l1, "\"status\":\"ok\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, l2, "\"name\":\"b\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, l2, "\"status\":\"fail\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, l2, "\"error_message\":\"nope\"") != null);
}

test "parseFailLine — error message containing parentheses still parses" {
    const line = "  FAIL t  (oops (inner) bad)  at f.bp:9";
    const p = parseFailLine(line).?;
    try std.testing.expectEqualStrings("t", p.name);
    try std.testing.expectEqualStrings("oops (inner) bad", p.err);
    try std.testing.expectEqualStrings("f.bp", p.err_file);
    try std.testing.expectEqualStrings("9", p.err_line);
}

test "parseFailLine — non-fail line returns null" {
    try std.testing.expect(parseFailLine("  ok   t") == null);
    try std.testing.expect(parseFailLine("TEST f.bp:1 t") == null);
}

test "emitJsonl — `  duration <ms>ms` between fence-close and ok lands as duration_ms" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST main.bp:9 t\n" ++
        "----- RUN LOG -----\n" ++
        "```logs\n" ++
        "```\n" ++
        "  duration 42ms\n" ++
        "  ok   t\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    _ = try emitJsonlToBuf(arena, "main", input, &out);

    try std.testing.expectEqualStrings(
        "{\"event\":\"test\",\"module\":\"main\",\"file\":\"main.bp\",\"line\":9,\"name\":\"t\",\"status\":\"ok\",\"run_log\":\"\",\"duration_ms\":42}\n",
        out.items,
    );
}

test "emitJsonl — duration_ms still flows on a failing test (before the FAIL line)" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const input =
        "TEST f.bp:1 t\n" ++
        "----- RUN LOG -----\n" ++
        "```logs\n" ++
        "```\n" ++
        "  duration 7ms\n" ++
        "  FAIL t  (nope)  at f.bp:2\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    _ = try emitJsonlToBuf(arena, "m", input, &out);

    // duration_ms comes after run_log and before the error_* trio so a
    // consumer pretty-printing record fields sees a stable column order.
    try std.testing.expect(std.mem.indexOf(u8, out.items, "\"duration_ms\":7") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.items, "\"error_message\":\"nope\"") != null);
    const dur_pos = std.mem.indexOf(u8, out.items, "\"duration_ms\":7").?;
    const err_pos = std.mem.indexOf(u8, out.items, "\"error_message\":\"nope\"").?;
    try std.testing.expect(dur_pos < err_pos);
}

test "emitJsonl — duration_ms is per-test (does not leak across tests)" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Two tests: only the first carries a duration line. The second must
    // emit WITHOUT a duration_ms key (cur_duration_ms is reset between
    // tests; back-compat with older runners that omit the line).
    const input =
        "TEST f.bp:1 a\n----- RUN LOG -----\n```logs\n```\n  duration 11ms\n  ok   a\n" ++
        "TEST f.bp:2 b\n----- RUN LOG -----\n```logs\n```\n  ok   b\n";

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    _ = try emitJsonlToBuf(arena, "m", input, &out);

    var lines = std.mem.splitScalar(u8, out.items, '\n');
    const l1 = lines.next() orelse "";
    const l2 = lines.next() orelse "";
    try std.testing.expect(std.mem.indexOf(u8, l1, "\"duration_ms\":11") != null);
    try std.testing.expect(std.mem.indexOf(u8, l2, "\"duration_ms\"") == null);
}

test "parseDurationMs — well-formed + malformed inputs" {
    try std.testing.expectEqual(@as(?u32, 0), parseDurationMs("  duration 0ms"));
    try std.testing.expectEqual(@as(?u32, 42), parseDurationMs("  duration 42ms"));
    try std.testing.expectEqual(@as(?u32, 1234567), parseDurationMs("  duration 1234567ms"));
    // Missing `ms` suffix.
    try std.testing.expectEqual(@as(?u32, null), parseDurationMs("  duration 42"));
    // Non-numeric body.
    try std.testing.expectEqual(@as(?u32, null), parseDurationMs("  duration abcms"));
    // Wrong prefix → returns null without reading any digits.
    try std.testing.expectEqual(@as(?u32, null), parseDurationMs("  duraton 42ms"));
}

test "writeJsonString — control bytes + quotes + backslash get escaped" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(arena);
    try writeJsonString(arena, &out, "a\"b\\c\n\td\x01e");
    try std.testing.expectEqualStrings("\"a\\\"b\\\\c\\n\\td\\u0001e\"", out.items);
}

/// Minimal JSON string writer — RFC 8259 §7. Escapes the seven required
/// sequences (`"`/`\`/control bytes < 0x20) and passes everything else
/// through verbatim. UTF-8 sequences need no escaping; surrogate pairs are
/// not generated because input is already UTF-8 source/stdout.
fn writeJsonString(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), s: []const u8) !void {
    try out.append(arena, '"');
    for (s) |c| {
        switch (c) {
            '"' => try out.appendSlice(arena, "\\\""),
            '\\' => try out.appendSlice(arena, "\\\\"),
            '\n' => try out.appendSlice(arena, "\\n"),
            '\r' => try out.appendSlice(arena, "\\r"),
            '\t' => try out.appendSlice(arena, "\\t"),
            0x08 => try out.appendSlice(arena, "\\b"),
            0x0C => try out.appendSlice(arena, "\\f"),
            else => {
                if (c < 0x20) {
                    var buf: [6]u8 = undefined;
                    _ = std.fmt.bufPrint(&buf, "\\u{x:0>4}", .{c}) catch unreachable;
                    try out.appendSlice(arena, buf[0..6]);
                } else {
                    try out.append(arena, c);
                }
            },
        }
    }
    try out.append(arena, '"');
}

/// True when an output module name belongs to a loaded dependency (so its own
/// `test {}` blocks should not be run by the consumer's `botopink test`).
fn isDepModule(name: []const u8, dep_modules: []const bp.Module) bool {
    for (dep_modules) |d| {
        if (std.mem.eql(u8, d.path, name)) return true;
    }
    return false;
}

/// True when an output module name belongs to a `test/` suite module. These are
/// excluded from the root `module.js` aggregator: they export nothing other
/// modules consume, and cross-loading one (with module-load side effects) from
/// another test's run would hit a half-built aggregator.
fn isTestModule(name: []const u8, test_modules: []const bp.Module) bool {
    for (test_modules) |t| {
        if (std.mem.eql(u8, t.path, name)) return true;
    }
    return false;
}
