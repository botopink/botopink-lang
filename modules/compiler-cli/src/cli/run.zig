/// `botopink run` — build the project then execute the entry-point module.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const libs = @import("./libs.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null,
    module: []const u8 = "main",
    /// Output directory `build` writes and `run` executes from.
    out_dir: []const u8 = "out",
    extra_args: []const []const u8 = &.{},
};

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

    // Load config to determine target.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget() orelse {
        build_cmd.reportUnsupportedTarget(proj.target);
        return 1;
    };

    // Build first, into the same directory the entry point is read from.
    const build_exit = try build_cmd.run(gpa, io, .{ .target = target, .out_dir = opts.out_dir }, env_map);
    if (build_exit != 0) return build_exit;

    // Resolve the entry-point file path. erlang and BEAM artifacts are named by
    // the module ATOM under `out/<target>/`; commonJS and wasm keep the mirrored
    // module-path tree (`build_cmd.artifactPath`).
    const entry_path = try build_cmd.artifactPath(arena, opts.out_dir, target, opts.module, build_cmd.artifactExt(target));

    // BEAM assembly is an artifact — direct execution requires `erlc +from_asm`
    // followed by an `erl` invocation. Tooling integration arrives in Fase 9.
    if (target == .beam) {
        const msg = try std.fmt.allocPrint(
            arena,
            "wrote {s} — BEAM Assembly is an artifact; compile with `erlc +from_asm {s}` to produce a `.beam`.\n",
            .{ entry_path, entry_path },
        );
        reporter.stdout(io, msg);
        return 0;
    }

    // erlang needs three steps, not one: `escript <file>` compiles ONLY the file
    // it is handed, so every cross-module call in a multi-module program is an
    // `undef` at run time even when the emitted code is correct. Compile the
    // whole output directory with `erlc` and run it on a code path that can see
    // all of it — the shape `tests/language/run.sh` already uses for beam.
    if (target == .erlang) return runErlang(arena, io, opts);

    // Build argv.
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .wasm => "wasmtime",
        .erlang => unreachable, // handled above
        .beam => unreachable, // handled above
    };

    var argv = std.ArrayListUnmanaged([]const u8).empty;
    defer argv.deinit(arena);
    try argv.append(arena, runner);
    try argv.append(arena, entry_path);
    for (opts.extra_args) |arg| try argv.append(arena, arg);

    // Spawn and wait — stdio is inherited from the parent process.
    var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
        const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
        reporter.errMsg(msg);
        return 1;
    };
    defer child.kill(io);

    const term = try child.wait(io);
    return switch (term) {
        .exited => |code| code,
        .signal, .stopped, .unknown => 1,
    };
}

// ── the erlang runner ─────────────────────────────────────────────────────────

/// `botopink run --target erlang`: compile every emitted `.erl` into the output
/// directory, then run the entry module's `main/1` with `erl` on a code path
/// that holds all of them.
///
/// Why not `escript`: it compiles only the file it is handed, so a project with
/// more than one module fails with `undefined function <mod>:<fn>` however
/// correct the emitted code is. `escript -pa <dir>` is rejected outright
/// (`illegal operation on a directory`) and `ERL_FLAGS="-pa <dir>"` changes
/// nothing, because no `.beam` exists yet — the compile step is the missing
/// half, not the code path.
///
/// Why `main([])` and not `main()`: `main/1` is always exported (it is the
/// escript entry point), while `main/0` is emitted only when `main` is `pub`, so
/// a runner calling `main:main()` fails with `undef` on any project whose entry
/// is a plain `fn main()`.
///
/// **Exit status.** A crashing program now exits `1` (`erl`'s status) where
/// `escript` exited `127`. The number was escript's artefact; it is not mapped
/// back, and the command contract in `modules/compiler-cli/AGENTS.md` says so.
fn runErlang(arena: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    const dir = try std.fmt.allocPrint(arena, "{s}/{s}", .{ opts.out_dir, std.mem.trimEnd(u8, build_cmd.targetSubdir(.erlang), "/") });

    // Compile every emitted module, not just the entry: one left uncompiled is
    // an `undef` at run time rather than a compile error. The walk is recursive
    // because a `.erl` tree is flat today but a driver may nest one tomorrow.
    var erls: std.ArrayListUnmanaged([]const u8) = .empty;
    try collectByExt(arena, io, dir, ".erl", &erls);
    if (erls.items.len == 0) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no .erl artifact under {s}/ — nothing to run", .{dir}));
        return 1;
    }
    {
        var argv: std.ArrayListUnmanaged([]const u8) = .empty;
        try argv.append(arena, "erlc");
        try argv.append(arena, "-o");
        try argv.append(arena, dir);
        for (erls.items) |f| try argv.append(arena, f);
        const code = try spawnWait(arena, io, argv.items);
        if (code != 0) return code;
    }

    const eval = try std.fmt.allocPrint(arena, "{s}:main([]), halt().", .{opts.module});
    return spawnWait(arena, io, &.{ "erl", "-noshell", "-pa", dir, "-eval", eval });
}

/// Every file under `dir` whose name ends with `ext`, recursively, as paths
/// relative to the process cwd. Sorted, so a build is reproducible.
fn collectByExt(
    arena: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    ext: []const u8,
    out: *std.ArrayListUnmanaged([]const u8),
) !void {
    var d = std.Io.Dir.cwd().openDir(io, dir, .{ .iterate = true }) catch return;
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |entry| {
        const child = try std.fmt.allocPrint(arena, "{s}/{s}", .{ dir, entry.name });
        switch (entry.kind) {
            .directory => try collectByExt(arena, io, child, ext, out),
            else => if (std.mem.endsWith(u8, entry.name, ext)) try out.append(arena, child),
        }
    }
    std.mem.sort([]const u8, out.items, {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lt);
}

/// Spawn `argv` with inherited stdio and return its exit status.
fn spawnWait(arena: std.mem.Allocator, io: std.Io, argv: []const []const u8) !u8 {
    var child = std.process.spawn(io, .{ .argv = argv }) catch |err| {
        const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ argv[0], @errorName(err) });
        reporter.errMsg(msg);
        return 1;
    };
    defer child.kill(io);
    const term = try child.wait(io);
    return switch (term) {
        .exited => |code| code,
        .signal, .stopped, .unknown => 1,
    };
}
