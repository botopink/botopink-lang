/// `botopink-lib-test` — run every discovered project's test suite on each
/// requested backend and aggregate the results into a lib×target matrix.
///
/// Usage:
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>]… [--filter <s>] [--strict] [--bin <path>]
///                     [--jobs <n>] [--json] [--list] [--cold] [--store-root <dir>]
///
/// It discovers every project carrying a `botopink.json` across the resolved root
/// list (bundled `repository/botopink-lang/libs`, sibling `repository/`, legacy
/// flat `libs/`) — and every **member** of a workspace found there (a manifest
/// declaring `"workspaces"`, decision 75), examples included, one row per
/// member — runs `botopink test --target <t>` with `cwd` set to each lib's own
/// directory, and **exits non-zero iff any cell fails or a restriction is not
/// structural** — the missing CI gate for the lib ecosystem. The manifest
/// decides the matrix: a target a lib's `"targets"` list excludes is not a
/// cell, and the exclusion is audited on every run (`runner.captureAudit`) —
/// no flag runs it or skips the audit. It shells out to the installed
/// `botopink` binary and touches no compiler internals (the std-only
/// `manifest` module is the shared reading of `botopink.json`).
const std = @import("std");
const args = @import("args.zig");
const discovery = @import("discovery.zig");
const matrix = @import("matrix.zig");
const runner = @import("runner.zig");
const doc_quotes = @import("doc_quotes.zig");
const schedule = @import("schedule.zig");
const result_store = @import("result_store.zig");
const source_stamp = @import("source_stamp");
const build_stamp = @import("build_stamp");

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
    \\  --lib <name>          Restrict to the named project across roots; repeatable —
    \\                        every name runs, in the order given, in one report
    \\                        (default: all).
    \\  --filter <s>          Forwarded to `botopink test --filter`.
    \\  --strict              Treat an unsupported target as a failure, not a skip.
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
    \\  --list                Print the plan and run nothing: one tab-separated
    \\                        <lib> <target> <kind> line per pair. The `cell:*`
    \\                        kinds are the cells the manifests declare.
    \\  --cold                Do not read the cell-result store: every cell runs
    \\                        (its passes are still written). Without it a cell
    \\                        whose key (the compiler's build and sources, the
    \\                        toolchain, every library's bytes, the cell) equals a
    \\                        stored pass is answered from the store.
    \\  --store-root <dir>    Keep the result store in <dir> (default: each
    \\                        library's .botopinkbuild/cache/results/lib-test/).
    \\  -h, --help            Show this message.
    \\
    \\A lib's botopink.json "targets" list decides its cells: a target it
    \\excludes is never run. Each excluded target `botopink test` can run is
    \\audited instead — `botopink build --target <t>` must be refused for a
    \\missing host binding (`has no #[@External.<Target>(…)]`). A lib that
    \\builds there, or fails for another reason, fails the run.
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

    // A library run against a stale build measures the previous compiler:
    // refuse to start when the checkout this runner (and the `botopink` built
    // beside it) was built from has changed since (`source_stamp`). A
    // `botopink test` child makes the same check of its own binary.
    if (try source_stamp.checkFresh(gpa, io, build_stamp.source_root, build_stamp.source_hash)) |stale| {
        var msg_buf: [1024]u8 = undefined;
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}", .{source_stamp.render(&msg_buf, stale, "botopink-lib-test")});
        return 1;
    }

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
    const libs = discovery.discover(gpa, io, roots, opts.libs) catch |err| {
        switch (err) {
            error.LibsRootNotFound => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no library root could be read\n", .{}),
            else => return err,
        }
        return 1;
    };
    defer discovery.free(gpa, libs);

    // Every `--lib` names a library, or the run fails naming each one that
    // does not (decision 258: no name is dropped silently).
    var unknown_lib = false;
    for (opts.libs) |name| {
        const found = for (libs) |l| {
            if (std.mem.eql(u8, l.name, name)) break true;
        } else false;
        if (!found) {
            std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no lib named '{s}' found across the library roots\n", .{name});
            unknown_lib = true;
        }
    }
    if (unknown_lib) return 1;
    if (libs.len == 0) {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no libs found across the library roots\n", .{});
        return 1;
    }

    // A workspace document that quotes the tool's member list is checked
    // against the tool (`doc_quotes.zig`): a quote that drifted fails the run.
    // Printed on stderr in both modes; `--json` also carries one
    // `{"event":"doc_quote_mismatch"}` record so the wrapper counts it.
    const doc_problems = try doc_quotes.check(gpa, io, roots);
    defer gpa.free(doc_problems);
    if (doc_problems.len > 0) {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: a document quotes the tool and disagrees with it\n{s}", .{doc_problems});
        if (opts.json) std.Io.File.stdout().writeStreamingAll(io, "{\"event\":\"doc_quote_mismatch\"}\n") catch {};
    }

    // Under `--json`, one `{"event":"lib","lib":…,"dir":…}` record per
    // library first: the directory each lib's cells run in.
    if (opts.json and !opts.list) {
        for (libs) |lib| try runner.emitLibRecord(arena, io, lib.name, lib.dir);
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
            const kind = Cell.Kind.of(lib, target);
            if (kind.spawns()) spawned += 1;
            plan[r * opts.targets.len + c] = .{ .lib = lib, .target = target, .kind = kind };
        }
    }

    // `--list`: the plan is the answer. Nothing is spawned.
    if (opts.list) {
        var out: std.ArrayListUnmanaged(u8) = .empty;
        for (plan) |cell| {
            try out.appendSlice(arena, cell.lib.name);
            try out.append(arena, '\t');
            try out.appendSlice(arena, cell.target.toString());
            try out.append(arena, '\t');
            try out.appendSlice(arena, cell.kind.listName());
            try out.append(arena, '\n');
        }
        std.Io.File.stdout().writeStreamingAll(io, out.items) catch {};
        return if (doc_problems.len > 0) 1 else 0;
    }

    // The order the workers START the spawning cells in (`schedule.zig`): the
    // longest last time first, from the cache roots' duration histories. It moves
    // when a cell runs, never whether it runs or where it is printed.
    const spawning = try arena.alloc(usize, spawned);
    const keys = try arena.alloc([]const u8, spawned);
    {
        var k: usize = 0;
        for (plan, 0..) |cell, i| {
            if (!cell.kind.spawns()) continue;
            spawning[k] = i;
            keys[k] = try schedule.keyText(arena, .{ .lib = cell.lib.name, .target = cell.target.toString(), .kind = cell.kind.listName() });
            k += 1;
        }
    }
    // One history per cache root (`schedule.cacheRoot`), each holding its own
    // libraries' cells; the start order reads them all at once.
    const cell_files = try arena.alloc([]const u8, spawned);
    var files: std.StringArrayHashMapUnmanaged(schedule.History) = .empty;
    var history: schedule.History = .empty;
    for (spawning, 0..) |i, k| {
        cell_files[k] = try schedule.path(arena, schedule.cacheRoot(arena, io, plan[i].lib.dir));
        const gop = try files.getOrPut(arena, cell_files[k]);
        if (!gop.found_existing) {
            gop.value_ptr.* = schedule.load(arena, io, cell_files[k]);
            var it = gop.value_ptr.iterator();
            while (it.next()) |e| try history.put(arena, e.key_ptr.*, e.value_ptr.*);
        }
    }
    const by_time = try schedule.order(arena, keys, &history);
    const start_order = try arena.alloc(usize, spawned);
    for (by_time, 0..) |k, j| start_order[j] = spawning[k];

    // The cell-result store (`result_store.zig`): every spawning cell whose
    // key equals a stored pass is answered from it before the pool starts, and
    // the pool runs the rest. `--cold` never reads it, and every run writes
    // the passes it ran (decision 249).
    var from_store: usize = 0;
    const store_global = try result_store.global(arena, io, build_stamp.source_root, bin, roots);
    const never_stored: ?[]const u8 = store_global.unstorable;
    if (never_stored == null) {
        for (spawning) |i| {
            const cell = &plan[i];
            cell.key = result_store.cellKey(store_global, cellId(cell.*, opts));
            cell.store = try result_store.storeDir(arena, io, opts.store_root, cell.lib.dir);
            if (!opts.cold) {
                if (result_store.load(arena, io, cell.store, cell.key.?)) |cap| {
                    cell.captured = cap;
                    cell.from_store = true;
                    cell.done.set(io);
                    from_store += 1;
                }
            }
        }
    }

    var pool: Pool = .{ .plan = plan, .order = start_order, .io = io, .bin = bin, .opts = opts, .cpus = std.Thread.getCpuCount() catch 1 };
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
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, .fail);
                break :blk .fail;
            },
            .not_runnable => blk: {
                // The lib's `"targets"` list excludes a target `botopink test`
                // cannot run at all (beam/wasm today). No cell could exist
                // there, so the exclusion hides nothing and there is nothing
                // to audit: the pair is reported as the CLI's own limit is —
                // `~`, or a failure under `--strict` — without a spawn.
                const st: matrix.Status = if (opts.strict) .fail else .skipped_unsupported;
                if (opts.strict) std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n\x1b[1m\x1b[31merror\x1b[0m: `botopink test` cannot run the {s} target (--strict)\n", .{ lib.name, tname, tname });
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, st);
                break :blk st;
            },
            .nothing_to_compile => blk: {
                // A manifest with no botopink source: nothing to compile.
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, tname, .no_tests);
                break :blk .no_tests;
            },
            // No `test` block: still compiled per target (`botopink
            // build`), so a test-less lib that does not compile fails
            // its cell; one that compiles is `–`.
            .compile => try runner.emitCompile(arena, io, bin, lib.name, cell.target, opts.json, pool.await(i), cell.from_store),
            .test_run => try runner.emitTest(arena, io, bin, lib.name, cell.target, opts.json, pool.await(i), cell.from_store),
            // Not a cell: the manifest excludes the target. The exclusion is
            // audited — `·` when it is structural, `!` (and a failed run)
            // when it is not.
            .audit => try runner.emitAudit(arena, io, bin, lib.name, cell.target, opts.json, pool.await(i), cell.from_store),
        };
        cells[r][c] = status;
        summary.tally(status);
    }

    // Every spawning cell has run: remember how long each took, for the next
    // run's start order.
    {
        var fit = files.iterator();
        while (fit.next()) |f| {
            var own_keys: std.ArrayListUnmanaged([]const u8) = .empty;
            var own_times: std.ArrayListUnmanaged(u64) = .empty;
            for (spawning, 0..) |i, k| {
                if (!std.mem.eql(u8, cell_files[k], f.key_ptr.*)) continue;
                // A cell answered from the store did not run: its last time stays.
                if (plan[i].from_store) continue;
                try own_keys.append(arena, keys[k]);
                try own_times.append(arena, plan[i].wall_ms);
            }
            schedule.store(arena, io, f.key_ptr.*, f.value_ptr, own_keys.items, own_times.items);
        }
    }

    // Every pass that ran is written to the store — only when nothing the keys
    // read moved while the run was going (the global part computed again).
    var written: usize = 0;
    var moved: usize = 0;
    if (never_stored == null) {
        const after = try result_store.global(arena, io, build_stamp.source_root, bin, roots);
        const same = after.unstorable == null and std.mem.eql(u8, &after.hex, &store_global.hex);
        var stores: std.StringArrayHashMapUnmanaged(void) = .empty;
        for (spawning) |i| {
            const cell = &plan[i];
            if (cell.from_store or cell.key == null or !result_store.storable(cell.captured)) continue;
            try stores.put(arena, cell.store, {});
            if (!same) {
                moved += 1;
                continue;
            }
            if (result_store.save(arena, io, cell.store, cell.key.?, cell.captured)) written += 1;
        }
        for (stores.keys()) |d| result_store.reap(arena, io, d);
    }
    const store_line = try storeLine(arena, spawned, from_store, opts.cold, never_stored, moved);

    if (opts.json) {
        try runner.emitStoreRecord(arena, io, spawned, spawned - from_store, from_store, written, store_line.note);
        // One final aggregate record so a JSON consumer sees exactly one
        // run-terminating record per invocation.
        try runner.emitRunSummary(arena, io, summary);
        return if (doc_problems.len > 0) 1 else summary.exitCode();
    }

    // Render the text matrix (text mode only).
    const cells_const = try arena.alloc([]const matrix.Status, libs.len);
    for (cells, 0..) |row, i| cells_const[i] = row;
    const text = try matrix.render(arena, lib_names, opts.targets, cells_const, summary);
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};
    std.Io.File.stdout().writeStreamingAll(io, store_line.text) catch {};

    // Exit non-zero iff any cell failed (skips / no-tests do not), a
    // restriction audit refused an exclusion, or a document's quote of the
    // tool disagrees with it.
    if (doc_problems.len > 0) return 1;
    return summary.exitCode();
}

/// The cell's identity under the result store's global key.
fn cellId(cell: Cell, opts: args.Options) result_store.CellId {
    return .{
        .lib = cell.lib.name,
        .dir = cell.lib.dir,
        .target = cell.target.toString(),
        .kind = cell.kind.listName(),
        .filter = opts.filter,
        .strict = opts.strict,
        .json = opts.json,
    };
}

/// `result store: <N> jobs — <R> run, <S> from store<note>` — what was
/// executed and what was answered from a stored pass; `scripts/gate.sh` holds
/// run + from store to the plan's spawning pairs.
fn storeLine(arena: std.mem.Allocator, jobs: usize, from_store: usize, cold: bool, never: ?[]const u8, moved: usize) !struct { text: []const u8, note: []const u8 } {
    const note: []const u8 = if (never) |why|
        try std.fmt.allocPrint(arena, "{s}never stored: {s}", .{ if (cold) "--cold: nothing read from the store; " else "", why })
    else if (moved > 0)
        try std.fmt.allocPrint(arena, "{s}{d} not written: their inputs moved during the run", .{ if (cold) "--cold: nothing read from the store; " else "", moved })
    else if (cold)
        "--cold: nothing read from the store"
    else
        "";
    const text = try std.fmt.allocPrint(arena, "result store: {d} jobs — {d} run, {d} from store{s}{s}{s}\n", .{
        jobs,                           jobs - from_store, from_store,
        if (note.len > 0) " (" else "", note,              if (note.len > 0) ")" else "",
    });
    return .{ .text = text, .note = note };
}

/// One (lib, target) pair of the plan. `kind` is decided up front from
/// discovery alone; only `.compile`, `.test_run` and `.audit` spawn a child.
const Cell = struct {
    lib: discovery.Lib,
    target: args.Target,
    kind: Kind,
    /// The result-store key (`result_store.cellKey`); null under `--cold`
    /// or when nothing of this run can be stored.
    key: ?[64]u8 = null,
    /// The store directory this cell's entry lives in.
    store: []const u8 = "",
    /// Answered from a stored pass: never spawned.
    from_store: bool = false,
    /// Filled by the worker that ran the cell; valid once `done` is set.
    captured: runner.Captured = .{},
    /// How long the cell took, for the duration history (`schedule.zig`).
    wall_ms: u64 = 0,
    done: std.Io.Event = .unset,

    const Kind = enum {
        problem,
        not_runnable,
        nothing_to_compile,
        compile,
        test_run,
        audit,

        /// The manifest decides, and nothing overrides it: a target the lib's
        /// `"targets"` list excludes is never a cell. Such a pair is audited
        /// when `botopink test` can run the target (a cell could have existed
        /// there), and is the CLI's own limit when it cannot.
        fn of(lib: discovery.Lib, target: args.Target) Kind {
            if (lib.problem != null) return .problem;
            if (!discovery.libSupportsTarget(lib, target.toString()))
                return if (target.isSupported()) .audit else .not_runnable;
            if (!lib.has_tests and !lib.has_sources) return .nothing_to_compile;
            if (!lib.has_tests) return .compile;
            return .test_run;
        }

        fn spawns(self: Kind) bool {
            return self == .compile or self == .test_run or self == .audit;
        }

        /// The third column of `--list`. `cell:*` is a cell the manifests
        /// declare; `audit` and `not-runnable` are excluded pairs.
        fn listName(self: Kind) []const u8 {
            return switch (self) {
                .problem => "cell:problem",
                .nothing_to_compile => "cell:nothing-to-compile",
                .compile => "cell:compile",
                .test_run => "cell:test",
                .audit => "audit",
                .not_runnable => "not-runnable",
            };
        }
    };
};

/// The worker pool: each worker takes the next spawning cell of `order`
/// (`schedule.zig` — the longest last time first), runs it into its slot, and
/// sets the slot's event. The main thread emits, in plan order.
const Pool = struct {
    plan: []Cell,
    /// Every spawning cell's plan index, once each, in the order to start them.
    order: []const usize,
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
            const k = pool.next.fetchAdd(1, .monotonic);
            if (k >= pool.order.len) return false;
            const cell = &pool.plan[pool.order[k]];
            if (!cell.kind.spawns() or cell.from_store) continue;
            pool.admit();
            const t0 = std.Io.Timestamp.now(pool.io, .awake);
            _ = pool.active.fetchAdd(1, .monotonic);
            defer _ = pool.active.fetchSub(1, .monotonic);
            // Captured output lives until the process exits; a page-backed
            // arena per cell keeps the workers off each other's allocator.
            var cell_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            const a = cell_arena.allocator();
            cell.captured = switch (cell.kind) {
                .compile => runner.captureCompile(a, pool.io, pool.bin, cell.lib.dir, cell.target, pool.opts.strict),
                .test_run => runner.captureTest(a, pool.io, pool.bin, cell.lib.dir, cell.target, pool.opts.filter, pool.opts.strict, pool.opts.json),
                .audit => runner.captureAudit(a, pool.io, pool.bin, cell.lib.dir, cell.target),
                else => unreachable,
            };
            cell.wall_ms = @intCast(@divTrunc(t0.durationTo(std.Io.Timestamp.now(pool.io, .awake)).nanoseconds, std.time.ns_per_ms));
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
    _ = doc_quotes;
    _ = schedule;
    _ = result_store;
}

test "Cell.Kind.of: the manifest decides — an excluded target is never a cell" {
    const only_erlang = [_][]const u8{"erlang"};
    const lib: discovery.Lib = .{ .name = "host-bound", .dir = "/x", .has_tests = true, .targets = &only_erlang };
    // Declared: a cell.
    try std.testing.expectEqual(Cell.Kind.test_run, Cell.Kind.of(lib, .erlang));
    // Excluded, and `botopink test` could have run it: audited, not run.
    try std.testing.expectEqual(Cell.Kind.audit, Cell.Kind.of(lib, .commonJS));
    // Excluded, and no cell can run there at all: the CLI's own limit.
    try std.testing.expectEqual(Cell.Kind.not_runnable, Cell.Kind.of(lib, .beam));
    try std.testing.expectEqual(Cell.Kind.not_runnable, Cell.Kind.of(lib, .wasm));

    // An exclusion is audited whatever the lib holds: no tests, no sources.
    const bare: discovery.Lib = .{ .name = "bare", .dir = "/x", .has_tests = false, .has_sources = false, .targets = &only_erlang };
    try std.testing.expectEqual(Cell.Kind.audit, Cell.Kind.of(bare, .commonJS));
    try std.testing.expectEqual(Cell.Kind.nothing_to_compile, Cell.Kind.of(bare, .erlang));

    // No list: every requested target is a cell.
    const open: discovery.Lib = .{ .name = "open", .dir = "/x", .has_tests = false, .targets = null };
    try std.testing.expectEqual(Cell.Kind.compile, Cell.Kind.of(open, .commonJS));
    try std.testing.expectEqual(Cell.Kind.compile, Cell.Kind.of(open, .beam));

    // A lib that cannot be used fails every requested target, excluded or not.
    const broken: discovery.Lib = .{ .name = "broken", .dir = "/x", .problem = "error: refused\n", .has_tests = true, .targets = &only_erlang };
    try std.testing.expectEqual(Cell.Kind.problem, Cell.Kind.of(broken, .commonJS));
}

test "Cell.Kind: what spawns, and what --list calls a cell" {
    try std.testing.expect(Cell.Kind.audit.spawns());
    try std.testing.expect(Cell.Kind.test_run.spawns());
    try std.testing.expect(Cell.Kind.compile.spawns());
    try std.testing.expect(!Cell.Kind.problem.spawns());
    try std.testing.expect(!Cell.Kind.not_runnable.spawns());
    try std.testing.expect(!Cell.Kind.nothing_to_compile.spawns());
    try std.testing.expectEqualStrings("audit", Cell.Kind.audit.listName());
    try std.testing.expect(std.mem.startsWith(u8, Cell.Kind.test_run.listName(), "cell:"));
    try std.testing.expect(!std.mem.startsWith(u8, Cell.Kind.not_runnable.listName(), "cell:"));
}
