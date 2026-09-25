/// `botopink-lib-test` — run every discovered project's test suite on each
/// requested backend and aggregate the results into a lib×target matrix.
///
/// Usage:
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///                     [--include-unsupported] [--jobs <n>]
///
/// It discovers every project carrying a `botopink.json` across the resolved root
/// list (bundled `repository/botopink-lang/libs`, sibling `repository/`, legacy
/// flat `libs/`) — and every **member** of a workspace found there (a manifest
/// declaring `"workspaces"`, decision 75), examples included, one row per
/// member — runs `botopink test --target <t>` with `cwd` set to each lib's own
/// directory, and **exits non-zero iff any cell fails** — the missing CI gate
/// for the lib ecosystem. It shells out to the installed `botopink` binary and
/// touches no compiler internals (the std-only `manifest` module is the shared
/// reading of `botopink.json`).
const std = @import("std");
const args = @import("args.zig");
const discovery = @import("discovery.zig");
const matrix = @import("matrix.zig");
const runner = @import("runner.zig");

const HELP =
    \\botopink-lib-test — run every discovered project's tests per backend
    \\
    \\Usage:
    \\  botopink-lib-test [options]
    \\
    \\Discovers every project carrying a botopink.json across the resolved roots
    \\(repository/botopink-lang/libs, repository/, or a legacy flat libs/), and
    \\every member of a workspace found there ("workspaces" in botopink.json).
    \\
    \\Options:
    \\  --target <t>[,<t>…]   Targets to run; repeatable. Accepts commonJS|erlang|
    \\                        beam|wasm plus the alias node→commonJS, and --target=<t>.
    \\                        `all` expands to every supported target.
    \\                        Default: commonJS,erlang.
    \\  --lib <name>          Restrict to one project by name across roots (default: all).
    \\  --filter <s>          Forwarded to `botopink test --filter`.
    \\  --strict              Treat an unsupported target as a failure, not a skip.
    \\  --include-unsupported Run a cell the lib's botopink.json "targets" list
    \\                        excludes, instead of skipping it, and mark it
    \\                        "restricted":true in --json. Measures what a
    \\                        restriction hides; scripts/test-libs.sh pins the
    \\                        result in scripts/restricted-targets.txt.
    \\  --bin <path>          Path to the `botopink` binary (env: BOTOPINK_BIN;
    \\                        default: ./zig-out/bin/botopink, else PATH).
    \\  --lib-root <dir>      Extra root to scan; repeatable. Appended after env
    \\                        roots (BOTOPINK_LIB_ROOTS) and walk-up roots.
    \\  --jobs <n>            Cells run at once (default: one per CPU, bounded by
    \\                        available memory). Output is emitted in discovery
    \\                        order either way, identical to --jobs 1.
    \\  --json                Forward --json to each `botopink test`, splice
    \\                        "lib"+"target" into every JSONL record, and emit
    \\                        per-cell + run summary JSON objects. Skips the
    \\                        text matrix. Schema in AGENTS.md (§T).
    \\  -h, --help            Show this message.
    \\
;

pub fn main(init: std.process.Init) void {
    const exit_code = run(init) catch |err| blk: {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{@errorName(err)});
        break :blk 1;
    };
    if (exit_code != 0) std.process.exit(exit_code);
}

fn run(init: std.process.Init) !u8 {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    const argv = try init.minimal.args.toSlice(arena);
    const rest = if (argv.len > 1) argv[1..] else argv[0..0];

    for (rest) |a| {
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            std.Io.File.stdout().writeStreamingAll(io, HELP) catch {};
            return 0;
        }
    }

    const opts = args.parse(arena, rest) catch |err| {
        switch (err) {
            error.MissingArgument => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: a flag is missing its argument\n", .{}),
            error.InvalidTarget => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown --target (use commonJS|erlang|beam|wasm|node|all)\n", .{}),
            error.UnknownFlag => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown flag (run with --help)\n", .{}),
            error.InvalidJobs => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: --jobs takes a positive number of cells to run at once\n", .{}),
            else => return err,
        }
        return 2;
    };

    // Resolve the cwd, the library roots, and the botopink binary — all as
    // absolute paths so each child's `cwd = <lib_dir>` stays consistent.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_len = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_len];

    const roots = try discovery.resolveRoots(arena, io, init.environ_map, opts.lib_roots, cwd);
    if (roots.len == 0) {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no library root (repository/ or libs/) found in this or any parent directory\n", .{});
        return 1;
    }

    const bin = try resolveBin(arena, io, cwd, opts.bin, init.environ_map.get("BOTOPINK_BIN"));

    // Discover libs across every root.
    const libs = discovery.discover(gpa, io, roots, opts.lib) catch |err| {
        switch (err) {
            error.LibsRootNotFound => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no library root could be read\n", .{}),
            else => return err,
        }
        return 1;
    };
    defer discovery.free(gpa, libs);

    if (libs.len == 0) {
        if (opts.lib) |name| {
            std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no lib named '{s}' found across the library roots\n", .{name});
            return 1;
        }
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no libs found across the library roots\n", .{});
        return 1;
    }

    // Plan every (lib, target) cell in discovery order, then run the ones that
    // spawn a child on a bounded worker pool and emit every cell IN THAT ORDER
    // as soon as it and all the cells before it are done. Concurrency changes
    // when a cell runs, never what it runs or what is printed: each child's
    // output is captured whole (it always was) and written by this thread
    // alone, so the stream is byte for byte the one `--jobs 1` prints.
    var lib_names = try arena.alloc([]const u8, libs.len);
    var cells = try arena.alloc([]matrix.Status, libs.len);
    var summary: matrix.Summary = .{};

    const plan = try arena.alloc(Cell, libs.len * opts.targets.len);
    var spawned: usize = 0;
    for (libs, 0..) |lib, r| {
        lib_names[r] = lib.name;
        cells[r] = try arena.alloc(matrix.Status, opts.targets.len);
        for (opts.targets, 0..) |target, c| {
            // The lib's own `"targets"` whitelist excludes this target. The
            // verdict is computed either way: it decides the skip below, and
            // it is carried into every cell summary so a consumer can tell a
            // restricted cell from an ordinary one (`scripts/test-libs.sh`
            // reads those against `scripts/restricted-targets.txt`).
            const restricted = !discovery.libSupportsTarget(lib, target.toString());
            const kind: Cell.Kind = if (lib.problem != null)
                .problem
            else if (!discovery.libRunsTarget(lib, target.toString(), opts.include_unsupported))
                .skipped
            else if (!lib.has_tests and !lib.has_sources)
                .nothing_to_compile
            else if (!lib.has_tests)
                .compile
            else
                .test_run;
            if (kind == .compile or kind == .test_run) spawned += 1;
            plan[r * opts.targets.len + c] = .{ .lib = lib, .target = target, .kind = kind, .restricted = restricted };
        }
    }

    var pool: Pool = .{ .plan = plan, .io = io, .bin = bin, .opts = opts, .cpus = std.Thread.getCpuCount() catch 1 };
    const jobs = @min(opts.jobs orelse defaultJobs(io), @max(spawned, 1));
    const workers = try arena.alloc(?std.Io.Future(void), jobs);
    var started: usize = 0;
    for (workers) |*w| {
        // A worker that cannot get its own unit of concurrency is not an
        // error: the cells it would have taken are run by the others — or,
        // when none started, by this thread as it emits (the serial runner).
        w.* = io.concurrent(Pool.work, .{&pool}) catch null;
        if (w.* != null) started += 1;
    }
    pool.inline_run = started == 0;
    defer for (workers) |*w| if (w.*) |*f| f.cancel(io);

    for (plan, 0..) |*cell, i| {
        const r = i / opts.targets.len;
        const c = i % opts.targets.len;
        const lib = cell.lib;
        const tname = cell.target.toString();
        const status: matrix.Status = switch (cell.kind) {
            .problem => blk: {
                // The lib cannot be used at all — a refused manifest, a name
                // declared twice, a library member that ships nothing. Every
                // cell is a fail, printed once per cell with its location;
                // nothing is spawned. Stderr in both modes, so `--json` stdout
                // stays pure JSONL.
                std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n{s}", .{ lib.name, tname, lib.problem.? });
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, .fail, cell.restricted);
                break :blk .fail;
            },
            .skipped => blk: {
                // Lib's botopink.json `"targets": [...]` whitelist excludes
                // this target — skip without spawning. Marks `~` in the matrix,
                // never fails the run (even under --strict; the lib opted out
                // explicitly, unlike a CLI-side unsupported target).
                // `--include-unsupported` takes this arm away: the cell runs
                // and is measured instead.
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, .skipped_unsupported, cell.restricted);
                break :blk .skipped_unsupported;
            },
            .nothing_to_compile => blk: {
                // A manifest with no botopink source: nothing to compile.
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, .no_tests, cell.restricted);
                break :blk .no_tests;
            },
            // No `test` block: still compiled per target (`botopink
            // build`), so a test-less lib that does not compile fails
            // its cell; one that compiles is `–`.
            .compile => try runner.emitCompile(arena, io, bin, lib.name, cell.target, opts.json, cell.restricted, pool.await(i)),
            .test_run => try runner.emitTest(arena, io, bin, lib.name, cell.target, opts.json, cell.restricted, pool.await(i)),
        };
        cells[r][c] = status;
        summary.tally(status);
    }

    if (opts.json) {
        // One final aggregate record so a JSON consumer sees exactly one
        // run-terminating record per invocation.
        try runner.emitRunSummary(arena, io, summary);
        return summary.exitCode();
    }

    // Render the text matrix (text mode only).
    const cells_const = try arena.alloc([]const matrix.Status, libs.len);
    for (cells, 0..) |row, i| cells_const[i] = row;
    const text = try matrix.render(arena, lib_names, opts.targets, cells_const, summary);
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};

    // Exit non-zero iff any cell failed (skips / no-tests do not).
    return summary.exitCode();
}

/// One (lib, target) cell of the plan. `kind` is decided up front from
/// discovery alone; only `.compile` and `.test_run` spawn a child.
const Cell = struct {
    lib: discovery.Lib,
    target: args.Target,
    kind: Kind,
    restricted: bool,
    /// Filled by the worker that ran the cell; valid once `done` is set.
    captured: runner.Captured = .{},
    done: std.Io.Event = .unset,

    const Kind = enum { problem, skipped, nothing_to_compile, compile, test_run };
};

/// The worker pool: each worker takes the next spawning cell in plan order,
/// runs it into its slot, and sets the slot's event. The main thread emits.
const Pool = struct {
    plan: []Cell,
    io: std.Io,
    bin: []const u8,
    opts: args.Options,
    next: std.atomic.Value(usize) = .init(0),
    /// No worker started: the main thread runs each cell as it reaches it.
    inline_run: bool = false,
    /// Cells of this run whose child is alive right now.
    active: std.atomic.Value(usize) = .init(0),
    /// Online CPUs — the admission bound (`admit`).
    cpus: usize = 1,

    /// Claim and run cells until none is left.
    fn work(pool: *Pool) void {
        while (pool.runNext()) {}
    }

    fn runNext(pool: *Pool) bool {
        while (true) {
            const i = pool.next.fetchAdd(1, .monotonic);
            if (i >= pool.plan.len) return false;
            const cell = &pool.plan[i];
            if (cell.kind != .compile and cell.kind != .test_run) continue;
            pool.admit();
            _ = pool.active.fetchAdd(1, .monotonic);
            defer _ = pool.active.fetchSub(1, .monotonic);
            // Captured output lives until the process exits; a page-backed
            // arena per cell keeps the workers off each other's allocator.
            var cell_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            const a = cell_arena.allocator();
            cell.captured = switch (cell.kind) {
                .compile => runner.captureCompile(a, pool.io, pool.bin, cell.lib.dir, cell.target, pool.opts.strict),
                .test_run => runner.captureTest(a, pool.io, pool.bin, cell.lib.dir, cell.target, pool.opts.filter, pool.opts.strict, pool.opts.json),
                else => unreachable,
            };
            cell.done.set(pool.io);
            return true;
        }
    }

    /// Wait, before starting a cell, until the machine has a CPU for it:
    /// `procs_running` (the 4th field of `/proc/loadavg`, the runnable
    /// threads right now — not the lagging 1-minute average) at most the CPU
    /// count. Several gates run side by side on one machine; a pool that only
    /// counted its own workers put the load at ~140 on 16 CPUs, and a test that
    /// measures its own wall clock (`std/async`'s "settleOf runs its tasks
    /// concurrently", three 60 ms tasks under 120 ms) went red. A run with no
    /// cell in flight is always admitted, so it never waits on other gates
    /// forever; where `/proc/loadavg` does not exist nothing waits.
    fn admit(pool: *Pool) void {
        while (pool.active.load(.monotonic) > 0) {
            const running = procsRunning(pool.io) orelse return;
            if (running <= pool.cpus) return;
            pool.io.sleep(.fromMilliseconds(200), .awake) catch return;
        }
    }

    /// The captured result of cell `i`, once a worker has run it (or, with no
    /// worker, after running the cells up to it on this thread).
    fn await(pool: *Pool, i: usize) runner.Captured {
        const cell = &pool.plan[i];
        if (pool.inline_run) {
            while (!cell.done.isSet() and pool.runNext()) {}
        }
        cell.done.waitUncancelable(pool.io);
        return cell.captured;
    }
};

/// Default worker count: one per CPU, bounded by memory — a `botopink test`
/// child peaks at ~400 MB (measured on rakun, erlang) plus its `erl`/`node`,
/// and several gates run side by side on one machine, so a pool sized to CPUs
/// alone could exhaust RAM. `MemAvailable / 768 MiB`, when `/proc/meminfo`
/// answers; at least 1.
fn defaultJobs(io: std.Io) usize {
    const cpus = std.Thread.getCpuCount() catch 1;
    const per_job: u64 = 768 * 1024 * 1024;
    const avail = memAvailable(io) orelse return @max(cpus, 1);
    const by_mem: usize = @intCast(@max(avail / per_job, 1));
    return @max(@min(cpus, by_mem), 1);
}

/// Runnable threads right now: `<r>` of the `<r>/<total>` 4th field of
/// `/proc/loadavg`; null where there is none.
fn procsRunning(io: std.Io) ?usize {
    var buf: [256]u8 = undefined;
    const text = std.Io.Dir.cwd().readFile(io, "/proc/loadavg", &buf) catch return null;
    var it = std.mem.tokenizeAny(u8, text, " \n");
    var field: usize = 0;
    while (it.next()) |tok| : (field += 1) {
        if (field != 3) continue;
        const slash = std.mem.indexOfScalar(u8, tok, '/') orelse return null;
        return std.fmt.parseUnsigned(usize, tok[0..slash], 10) catch null;
    }
    return null;
}

/// `MemAvailable` from `/proc/meminfo`, in bytes; null where there is none.
fn memAvailable(io: std.Io) ?u64 {
    var buf: [4096]u8 = undefined;
    const text = std.Io.Dir.cwd().readFile(io, "/proc/meminfo", &buf) catch return null;
    const key = "MemAvailable:";
    const at = std.mem.indexOf(u8, text, key) orelse return null;
    var it = std.mem.tokenizeAny(u8, text[at + key.len ..], " \t\n");
    const kb = std.fmt.parseUnsigned(u64, it.next() orelse return null, 10) catch return null;
    return kb * 1024;
}

/// Resolve the `botopink` binary path. Precedence: `--bin` flag, then
/// `BOTOPINK_BIN`, then `<cwd>/zig-out/bin/botopink` if it exists, else the bare
/// name `botopink` (resolved via PATH). Any path containing a separator is made
/// absolute against `cwd` so it survives the child's `cwd = libs/<lib>` chdir.
fn resolveBin(
    arena: std.mem.Allocator,
    io: std.Io,
    cwd: []const u8,
    flag: ?[]const u8,
    env: ?[]const u8,
) ![]const u8 {
    if (flag orelse env) |override| {
        return absolutize(arena, cwd, override);
    }

    const local = try std.fs.path.join(arena, &.{ cwd, "zig-out", "bin", "botopink" });
    std.Io.Dir.cwd().access(io, local, .{}) catch {
        // Not built locally — fall back to PATH lookup of the bare name.
        return "botopink";
    };
    return local;
}

/// Make `path` absolute against `base`, unless it is a bare name (no separator),
/// which must stay bare so the child resolves it via PATH.
fn absolutize(arena: std.mem.Allocator, base: []const u8, path: []const u8) ![]const u8 {
    if (std.fs.path.isAbsolute(path)) return path;
    if (std.mem.indexOfScalar(u8, path, '/') == null) return path; // bare name → PATH
    return std.fs.path.join(arena, &.{ base, path });
}

test {
    // Pull every file's unit tests into this root's test binary.
    _ = args;
    _ = discovery;
    _ = matrix;
    _ = runner;
}
