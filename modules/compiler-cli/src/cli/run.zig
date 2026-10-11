/// `botopink run` — build the project then execute the entry-point module.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const libs = @import("./libs.zig");
const arglist = @import("./arglist.zig");
const otp = @import("./otp.zig");

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

    const argv = try programArgv(arena, io, proj, target, opts.out_dir, opts.module) orelse return 1;
    var full = std.ArrayListUnmanaged([]const u8).empty;
    try full.appendSlice(arena, argv);
    for (opts.extra_args) |arg| try full.append(arena, arg);

    // Spawn and wait — stdio is inherited from the parent process.
    return spawnWait(arena, io, full.items);
}

/// The command line that runs the program `build` wrote into `out_dir` on
/// `target`, entry `module` — after the step erlang and BEAM need first
/// (every emitted `.erl` / `.S` compiled into `out_dir`). Null when that step
/// failed; its refusal is printed. `botopink run` appends the program's own
/// arguments and spawns it with inherited stdio; `botopink cell check`
/// (`cell.zig`) spawns it with its stdout and stderr captured.
pub fn programArgv(
    arena: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    target: config.Target,
    out_dir: []const u8,
    module: []const u8,
) !?[]const []const u8 {
    // Resolve the entry-point file path. erlang and BEAM artifacts are named by
    // the module ATOM under `out/<target>/`; commonJS and wasm keep the mirrored
    // module-path tree (`build_cmd.artifactPath`).
    // The entry is the project's own module: its atom starts with the
    // project's package (decision 109).
    const packages: bp.codegen.crossModule.Packages = .{ .root = proj.name };
    // A `browser` wasm build runs through its loader (decision 334).
    const browser = target == .wasm and proj.wasmHost() == .browser;
    const entry_path = try build_cmd.artifactPath(arena, out_dir, target, packages, module, if (browser) ".mjs" else build_cmd.artifactExt(target));

    // erlang and BEAM need two steps, not one. `escript <file>` compiles ONLY
    // the file it is handed, so every cross-module call in a multi-module
    // program is an `undef` at run time even when the emitted code is correct;
    // BEAM assembly is not runnable until `erlc +from_asm` has assembled it.
    // Compile the whole output directory and run it on a code path that can
    // see all of it.
    const entry_atom = try bp.codegen.crossModule.erlAtom(arena, packages.idOf(module));
    if (target == .erlang) return erlangArgv(arena, io, out_dir, entry_atom);
    if (target == .beam) return beamArgv(arena, io, out_dir, entry_atom);

    var argv = std.ArrayListUnmanaged([]const u8).empty;
    // A `wasi` build is a WASI preview 2 component (decision 334): `wasmtime
    // run` with `wasi:http` granted (`-S http`), which a component that
    // imports no `wasi:http` does not read.
    // A `browser` build is `node <module>.mjs`, its loader.
    switch (target) {
        .commonJS => try argv.append(arena, "node"),
        .wasm => if (browser) try argv.append(arena, "node") else try argv.appendSlice(arena, &.{ "wasmtime", "run", "-S", "http" }),
        .erlang, .beam => unreachable, // handled above
    }
    try argv.append(arena, entry_path);
    return argv.items;
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
fn erlangArgv(arena: std.mem.Allocator, io: std.Io, out_dir: []const u8, entry_atom: []const u8) !?[]const []const u8 {
    const dir = try std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, std.mem.trimEnd(u8, build_cmd.targetSubdir(.erlang), "/") });

    // Compile every emitted module, not just the entry: one left uncompiled is
    // an `undef` at run time rather than a compile error. The walk is recursive
    // because a `.erl` tree is flat today but a driver may nest one tomorrow.
    var erls: std.ArrayListUnmanaged([]const u8) = .empty;
    try collectByExt(arena, io, dir, ".erl", &erls);
    if (erls.items.len == 0) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no .erl artifact under {s}/ — nothing to run", .{dir}));
        return null;
    }
    if (try compileAll(arena, io, dir, .erlang, erls.items) != 0) return null;

    const eval = try std.fmt.allocPrint(arena, "{s}:main([]), halt().", .{entry_atom});
    return try otp.erlArgv(arena, &.{ "-noshell", "-pa", dir, "-eval", eval });
}

// ── the BEAM runner ───────────────────────────────────────────────────────────

/// `botopink run --target beam`: assemble every emitted `.S` beside itself
/// (`erlc +from_asm -o <out>/beam`), then run the entry module's `main/1` with
/// `erl` on that directory.
///
/// The `.beam`s go where the `.S` files are, not one level up, because that is
/// the directory the build ships a host `.erl` into (`libs.shipErlSidecars`)
/// and the one the entry's `'__bp_load_siblings'/0` reads: it compiles and
/// loads every `.erl` beside the module it runs in. Nothing here compiles a
/// sidecar — the assembled program does, so it runs the same way outside this
/// command.
///
/// `main([])` for the reason `erlangArgv` gives; on BEAM `main/1` is
/// `'_botopink_main'/0`, which runs the module body and then `main/0`.
fn beamArgv(arena: std.mem.Allocator, io: std.Io, out_dir: []const u8, entry_atom: []const u8) !?[]const []const u8 {
    const dir = try std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, std.mem.trimEnd(u8, build_cmd.targetSubdir(.beam), "/") });

    // Every module, not just the entry: one left unassembled is an `undef` at
    // run time rather than an assembler error.
    var asms: std.ArrayListUnmanaged([]const u8) = .empty;
    try collectByExt(arena, io, dir, ".S", &asms);
    if (asms.items.len == 0) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no .S artifact under {s}/ — nothing to run", .{dir}));
        return null;
    }
    if (try compileAll(arena, io, dir, .beam, asms.items) != 0) return null;

    const eval = try std.fmt.allocPrint(arena, "'{s}':main([]), halt().", .{entry_atom});
    return try otp.erlArgv(arena, &.{ "-noshell", "-pa", dir, "-eval", eval });
}

/// `erlc -o <dir> <files…>` (`+from_asm` for BEAM assembly), without a command
/// line that grows with the program: the files go through a list file
/// (`arglist.write`) and one `erl` compiles each with the options `erlc` gives
/// it — `report` prints every error and warning as `erlc` does, on stderr
/// (the group leader is `standard_error`), so the program's stdout stays its
/// own — into `dir`.
/// `erlc` itself takes its files on the command line only, and one argument
/// per module passed macOS's 1 MiB `ARG_MAX` at ~200 modules with a deep
/// `--out`. Exit 1 when any file does not compile.
fn compileAll(arena: std.mem.Allocator, io: std.Io, dir: []const u8, kind: enum { erlang, beam }, files: []const []const u8) !u8 {
    const list = try arglist.write(arena, io, files);
    defer arglist.remove(io, list);
    const mode: []const u8 = switch (kind) {
        .erlang => "erl",
        .beam => "asm",
    };
    // A job of the command's `erl` session (`otp.zig`), after `build`'s check.
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-eval", COMPILE_EVAL, "-extra", dir, mode, list };
    const result = otp.job(arena, io, COMPILE_EVAL, argv[5..], 1) catch |err| {
        reporter.errMsg(arglist.spawnError(arena, "erl", argv, err));
        return 1;
    };
    if (result.stdout.len > 0) std.Io.File.stdout().writeStreamingAll(io, result.stdout) catch {};
    if (result.code != 0) reporter.errMsg("the OTP compiler refused the emitted program — nothing to run");
    return result.code;
}

const COMPILE_EVAL =
    \\[OutDir, Mode, ListFile] = init:get_plain_arguments(),
++ arglist.READ_LIST("Files", "ListFile") ++
    \\group_leader(whereis(standard_error), self()),
    \\Opts = case Mode of "asm" -> [from_asm, report, {outdir, OutDir}]; _ -> [report, {outdir, OutDir}] end,
    \\Bad = [F || F <- Files, case compile:file(F, Opts) of {ok, _} -> false; {ok, _, _} -> false; _ -> true end],
    \\halt(case Bad of [] -> 0; _ -> 1 end).
;

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
        reporter.errMsg(arglist.spawnError(arena, argv[0], argv, err));
        return 1;
    };
    defer child.kill(io);
    const term = try child.wait(io);
    return switch (term) {
        .exited => |code| code,
        .signal, .stopped, .unknown => 1,
    };
}
