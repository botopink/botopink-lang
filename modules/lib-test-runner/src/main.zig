/// `botopink-lib-test` — run every discovered project's test suite on each
/// requested backend and aggregate the results into a lib×target matrix.
///
/// Usage:
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///
/// It discovers every project carrying a `botopink.json` across the resolved root
/// list (bundled `repository/botopink-lang/libs`, sibling `repository/`, legacy
/// flat `libs/`), runs `botopink test --target <t>` with `cwd` set to each lib's
/// own directory, and **exits non-zero iff any cell fails** — the missing CI gate
/// for the lib ecosystem. It shells out to the installed `botopink` binary and
/// touches no compiler internals.
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
    \\(repository/botopink-lang/libs, repository/, or a legacy flat libs/).
    \\
    \\Options:
    \\  --target <t>[,<t>…]   Targets to run; repeatable. Accepts commonJS|erlang|
    \\                        beam|wasm plus the alias node→commonJS, and --target=<t>.
    \\                        `all` expands to every supported target.
    \\                        Default: commonJS,erlang.
    \\  --lib <name>          Restrict to one project by name across roots (default: all).
    \\  --filter <s>          Forwarded to `botopink test --filter`.
    \\  --strict              Treat an unsupported target as a failure, not a skip.
    \\  --bin <path>          Path to the `botopink` binary (env: BOTOPINK_BIN;
    \\                        default: ./zig-out/bin/botopink, else PATH).
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

    const roots = try resolveRoots(arena, io, cwd);
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
            const status: matrix.Status = if (!lib.has_tests)
                .no_tests
            else
                try runner.runCell(arena, io, bin, lib.dir, lib.name, target, opts.filter, opts.strict);
            cells[r][c] = status;
            summary.tally(status);
        }
    }

    // Render the matrix.
    const cells_const = try arena.alloc([]const matrix.Status, libs.len);
    for (cells, 0..) |row, i| cells_const[i] = row;
    const text = try matrix.render(arena, lib_names, opts.targets, cells_const, summary);
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};

    // Exit non-zero iff any cell failed (skips / no-tests do not).
    return summary.exitCode();
}

/// Resolve the ordered list of library roots — directories that directly hold a
/// `<name>/botopink.json` — mirroring the CLI driver's `resolveLibRoots` (kept a
/// local copy so this orchestrator carries no compiler-core import). Walking up
/// from `start`, for each ancestor `D` (nearest-first) these roots are added when
/// present: `D/repository/botopink-lang/libs` (bundled), `D/repository` (sibling
/// projects), `D/libs` (legacy flat tree). De-duped, nearest-first; on the flat
/// tree the list is exactly `[<ancestor>/libs]`. Arena-owned.
fn resolveRoots(arena: std.mem.Allocator, io: std.Io, start: []const u8) ![]const []const u8 {
    var dir: []const u8 = start;
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    while (true) {
        try addRootIfExists(arena, io, &roots, &.{ dir, "repository", "botopink-lang", "libs" });
        try addRootIfExists(arena, io, &roots, &.{ dir, "repository" });
        try addRootIfExists(arena, io, &roots, &.{ dir, "libs" });
        const parent = std.fs.path.dirname(dir) orelse break;
        if (std.mem.eql(u8, parent, dir)) break;
        dir = parent;
    }
    return roots.toOwnedSlice(arena);
}

fn addRootIfExists(
    arena: std.mem.Allocator,
    io: std.Io,
    roots: *std.ArrayListUnmanaged([]const u8),
    parts: []const []const u8,
) !void {
    const candidate = try std.fs.path.join(arena, parts);
    var d = std.Io.Dir.cwd().openDir(io, candidate, .{}) catch return;
    d.close(io);
    for (roots.items) |r| {
        if (std.mem.eql(u8, r, candidate)) return; // de-dup, nearest-first wins
    }
    try roots.append(arena, candidate);
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
