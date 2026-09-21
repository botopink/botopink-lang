/// `botopink-lib-test` — run every discovered project's test suite on each
/// requested backend and aggregate the results into a lib×target matrix.
///
/// Usage:
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///                     [--include-unsupported]
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

    // Run each (lib, target) cell.
    var lib_names = try arena.alloc([]const u8, libs.len);
    var cells = try arena.alloc([]matrix.Status, libs.len);
    var summary: matrix.Summary = .{};

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
            const status: matrix.Status = if (lib.problem) |problem| blk: {
                // The lib cannot be used at all — a refused manifest, a name
                // declared twice, a library member that ships nothing. Every
                // cell is a fail, printed once per cell with its location;
                // nothing is spawned. Stderr in both modes, so `--json` stdout
                // stays pure JSONL.
                std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n{s}", .{ lib.name, target.toString(), problem });
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, target.toString(), .fail, restricted);
                break :blk .fail;
            } else if (!discovery.libRunsTarget(lib, target.toString(), opts.include_unsupported)) blk: {
                // Lib's botopink.json `"targets": [...]` whitelist excludes
                // this target — skip without spawning. Marks `~` in the matrix,
                // never fails the run (even under --strict; the lib opted out
                // explicitly, unlike a CLI-side unsupported target).
                // `--include-unsupported` takes this arm away: the cell runs
                // and is measured instead.
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, target.toString(), .skipped_unsupported, restricted);
                break :blk .skipped_unsupported;
            } else if (!lib.has_tests and !lib.has_sources) blk: {
                // A manifest with no botopink source: nothing to compile.
                if (opts.json) try runner.emitCellSummaryFor(arena, io, lib.name, target.toString(), .no_tests, restricted);
                break :blk .no_tests;
            } else if (!lib.has_tests)
                // No `test` block: still compiled per target (`botopink
                // build`), so a test-less lib that does not compile fails
                // its cell; one that compiles is `–`.
                try runner.compileCell(arena, io, bin, lib.dir, lib.name, target, opts.strict, opts.json, restricted)
            else
                try runner.runCell(arena, io, bin, lib.dir, lib.name, target, opts.filter, opts.strict, opts.json, restricted);
            cells[r][c] = status;
            summary.tally(status);
        }
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
