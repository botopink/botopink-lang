/// `botopink run` — build the project then execute the entry-point module.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const libs = @import("./libs.zig");
const arglist = @import("./arglist.zig");
const otp = @import("./otp.zig");
const code_cache = @import("./code_cache.zig");
const beam_record = @import("./beam_record.zig");
const workspace_out = @import("./workspace_out.zig");
const analysis_store = @import("./analysis_store.zig");
const manifest = @import("manifest");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null,
    module: []const u8 = "main",
    /// Output directory `build` writes and `run` executes from.
    out_dir: []const u8 = "out",
    extra_args: []const []const u8 = &.{},
    /// `--cold`: the code cache is not read, and what ran is written
    /// (decision 509 (5)).
    cold: bool = false,
    /// `--cache-root <dir>`: the cache root of levels A and B (as `build`'s).
    cache_root: ?[]const u8 = null,
    /// `--workspace-out <dir>`: the member's run from its workspace's one
    /// output folder (decision 1015 (4), `build.Options.workspace_out`).
    workspace_out: ?[]const u8 = null,
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
    if (opts.cache_root) |r| code_cache.root_override = r;
    // At a workspace root, `run --target <t>` builds and runs each member in
    // its own process, over the workspace's one folder (decision 1015 (4)).
    if (opts.target) |t| if (opts.workspace_out == null) {
        if (try workspace_out.atRoot(gpa, io, .{ .command = .run, .target = t, .out_dir = opts.out_dir, .cold = opts.cold, .cache_root = opts.cache_root }, env_map)) |code| return code;
    };
    const out_dir = opts.workspace_out orelse opts.out_dir;

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
    const build_exit = try build_cmd.run(gpa, io, .{ .target = target, .out_dir = out_dir, .cold = opts.cold, .entry = opts.module, .workspace_out = opts.workspace_out }, env_map);
    if (build_exit != 0) return build_exit;

    // A `wasi` build runs in this process (decisions 1032 (3), 1034).
    if (target == .wasm and proj.wasmHost() != .browser) {
        if (try refuseWithoutMain(arena, io, proj, opts.module)) return 1;
        const packages: bp.codegen.crossModule.Packages = .{ .root = proj.name };
        // Decision 1032 — the entry is the unit `<pkg>@<path>.wasm`, composed
        // with the units beside it.
        const entry_path = if (build_cmd.wasm_units)
            try build_cmd.wasmEntryPath(arena, out_dir, packages, opts.module)
        else
            try build_cmd.artifactPath(arena, out_dir, target, packages, opts.module, build_cmd.artifactExt(target));
        const ran = try runWasi(arena, io, proj, entry_path, opts.extra_args, .{});
        return ran.code;
    }

    const argv = try programArgv(arena, io, proj, target, out_dir, opts.module) orelse return 1;
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
/// arguments and spawns it with inherited stdio. A `wasi` wasm build has no
/// command line: it runs in process (`runWasi`).
pub fn programArgv(
    arena: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    target: config.Target,
    out_dir: []const u8,
    module: []const u8,
) !?[]const []const u8 {
    // A package whose entry module declares no `fn main` has nothing to run:
    // one located refusal on every target and host (decision 517).
    if (try refuseWithoutMain(arena, io, proj, module)) return null;
    return programArgvFor(arena, io, proj, target, out_dir, module);
}

/// `programArgv` with no look for `fn main`: the caller made it.
fn programArgvFor(
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
    if (target == .erlang or target == .beam) {
        // A dependency's module is linked from the code cache when it is there
        // (decision 509); every module whose `.beam` record matches is loaded
        // as it is (decision 1007).
        const cache: Cache = .{ .dir = try code_cache.dir(arena, proj), .own_prefix = try code_cache.ownAtomPrefix(arena, proj.name) };
        return if (target == .erlang) erlangArgv(arena, io, out_dir, entry_atom, cache) else beamArgv(arena, io, out_dir, entry_atom, cache);
    }

    var argv = std.ArrayListUnmanaged([]const u8).empty;
    // A `browser` build is `node <module>.mjs`, its loader (node runs
    // exceptions by default); a `wasi` one runs in process (`runWasi`).
    switch (target) {
        // An uncaught abort writes the `Failure` an `attempt` would answer
        // (decision 535); on commonJS the program's own entry installs the
        // handler (decision 870), so node runs it bare.
        .commonJS => try argv.append(arena, "node"),
        .wasm => {
            std.debug.assert(browser);
            try argv.append(arena, "node");
        },
        .erlang, .beam => unreachable, // handled above
    }
    try argv.append(arena, entry_path);
    return argv.items;
}

// ── the wasi runner ───────────────────────────────────────────────────────────

/// How `runWasi` hands the program its streams and environment.
pub const WasiRun = struct {
    stdout: bp.codegen.wasmRunner.Stdio = .inherit,
    /// The environment; null, the host process's own.
    env: ?*const std.process.Environ.Map = null,
    /// Where a units entry's units are read (decision 1032): null, beside the
    /// entry (`build`'s `out/wasm/`); a test run names its folder, which
    /// holds only the program's units, the core and std's then the
    /// compiler's own bytes.
    units_dir: ?[]const u8 = null,
};

pub const WasiRan = struct {
    /// The process's exit status: the program's, 130 when Ctrl+C ended it
    /// (decision 878).
    code: u8,
    /// The captured stdout, when `WasiRun.stdout` captures.
    stdout: []const u8 = "",
};

/// Run the `wasi` program at `path` in this process (decisions 1032 (3),
/// 1034): a units entry (a core module, binary or text, whose
/// `botopink.units` names its units) composed by `wasmRunner.runEntry` with
/// the units beside it (or `how.units`), each unit and the frame compiled
/// through `<cache root>/.botopinkbuild/cache/wasmtime/<sha256>.cwasm` — once
/// for every program reaching it, decision 1032 (2) — and any other
/// component or core module run as it is (`--cold` reads no `.cwasm` and
/// writes what it compiled), handed the host services its
/// `botopink.needs` section names (decision 1034 (7): `http` → `wasi:http`
/// and the network; `filesystem` → the root and the working directory,
/// decision 992), argv `<path> <args…>`, stdin and stderr inherited. A trap
/// prints its `wasm trap: …` line on stderr and exits 1 (1034 (3)). Shared by
/// `run` and `test` (`test_cmd.zig`).
pub fn runWasi(arena: std.mem.Allocator, io: std.Io, proj: config.ProjectConfig, path: []const u8, args: []const []const u8, how: WasiRun) !WasiRan {
    const runner = bp.codegen.wasmRunner;
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited) catch {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no wasm artifact at {s} — nothing to run", .{path}));
        return .{ .code = 1 };
    };
    const cache_dir = try manifest.cacheDir(arena, analysis_store.root(proj), "wasmtime");
    const units_entry = isUnitsEntry(text);
    var failure: ?[]u8 = null;
    const code: ?bp.codegen.wasmEngine.Compiled = if (units_entry) null else (try runner.load(arena, io, cache_dir, text, bp.codegen.wasmEngine.kindOf(text), code_cache.cold, &failure)) orelse {
        reporter.errMsg(failure.?);
        return .{ .code = 1 };
    };
    defer if (code) |cd| cd.deinit();

    const needs = if (std.mem.startsWith(u8, text, "\x00asm")) bp.codegen.wasmNeeds.needsOf(text) else bp.codegen.wasmNeeds.needsOfText(text);
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd: ?[]const u8 = if (std.process.currentPath(io, &cwd_buf)) |n| cwd_buf[0..n] else |_| null;
    const argv = try arena.alloc([]const u8, args.len + 1);
    argv[0] = path;
    @memcpy(argv[1..], args);
    var env: runner.Env = .inherit;
    if (how.env) |m| {
        const list = try arena.alloc(runner.EnvVar, m.count());
        for (m.keys(), m.values(), 0..) |k, v, i| list[i] = .{ .name = k, .value = v };
        env = .{ .list = list };
    }
    const opts: runner.Options = .{ .stdout = how.stdout, .stdin_inherit = true, .argv = argv, .env = env, .needs = needs, .cwd = cwd };
    const ran = if (code) |cd| switch (cd) {
        .component => |c| try runner.run(arena, c, &.{}, opts),
        .module => |m| try runner.runCore(arena, m, opts),
    } else try runner.runEntry(arena, io, cache_dir, code_cache.cold, text, if (how.units_dir) |d| .{ .dir = d, .runtime = true } else .{ .dir = std.fs.path.dirname(path) orelse "." }, opts);
    if (ran.end == .interrupted) return .{ .code = 130, .stdout = ran.stdout orelse "" };
    if (ran.trap) |t| if (t.len > 0) {
        std.Io.File.stderr().writeStreamingAll(io, try std.fmt.allocPrint(arena, "{s}\n", .{t})) catch {};
    };
    return .{ .code = @intCast(std.math.clamp(ran.status, 0, 255)), .stdout = ran.stdout orelse "" };
}

/// Whether `bytes` is a units entry (decision 1032): a core module, binary or
/// `.wat` text, carrying a `botopink.units` section.
fn isUnitsEntry(bytes: []const u8) bool {
    const ru = bp.codegen.wasmRuntimeUnit;
    if (std.mem.startsWith(u8, bytes, "\x00asm")) return ru.customSection(bytes, ru.units_section) != null;
    return bp.codegen.wasmEngine.kindOf(bytes) == .module and std.mem.indexOf(u8, bytes, "(@custom \"" ++ ru.units_section ++ "\"") != null;
}

// ── no `fn main` ──────────────────────────────────────────────────────────────

/// False when `source` parses and declares no top-level `fn main` (pub or
/// not). A source that does not parse is not refused here: the build reports
/// it, located.
pub fn declaresMain(arena: std.mem.Allocator, source: []const u8) bool {
    var lx = bp.Lexer.init(source);
    const tokens = lx.scanAll(arena) catch return true;
    var p = bp.Parser.init(tokens);
    const program = p.parse(arena) catch return true;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (std.mem.eql(u8, f.name, "main")) return true,
        else => {},
    };
    return false;
}

/// Prints the refusal and returns true when the project's entry module
/// (`<src>/<module>.bp`) exists and declares no `fn main` (decision 517). The
/// message is the same for commonJS, erlang, beam and wasm on either host,
/// located at the entry module.
fn refuseWithoutMain(arena: std.mem.Allocator, io: std.Io, proj: config.ProjectConfig, module: []const u8) !bool {
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.bp", .{ proj.srcDir(), module });
    const source = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(16 * 1024 * 1024)) catch return false;
    if (declaresMain(arena, source)) return false;
    reporter.print("{s}\n", .{try refusalText(arena, path)});
    return true;
}

fn refusalText(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "error: the package's entry module declares no `fn main`, so there is nothing to run\n  --> {s}:1:1", .{path});
}

test "declaresMain: read by the parser, not by lines" {
    var ar = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer ar.deinit();
    const a = ar.allocator();
    try std.testing.expect(declaresMain(a, "fn main() -> void {\n}\n"));
    try std.testing.expect(declaresMain(a, "import x;\npub fn main() -> i32 {\n  return 0;\n}\n"));
    try std.testing.expect(declaresMain(a, "#[compiler.external(.Erlang(\"m:f()\"))] pub fn main() -> void {\n}\n"));
    try std.testing.expect(!declaresMain(a, "test \"t\" {\n}\npub mod registry;\n"));
    try std.testing.expect(!declaresMain(a, "fn mainly() -> void {\n}\n"));
    try std.testing.expect(!declaresMain(a, "val s = \"\"\"\nfn main() {\n}\n\"\"\";\n"));
    try std.testing.expect(!declaresMain(a, "// a comment\n// fn main() {}\nfn other() -> void {\n}\n"));
    // A source that does not parse is the build's to report.
    try std.testing.expect(declaresMain(a, "fn ( {{{"));
}

test "refusalText: located at the entry module, one message for every target" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const t = try refusalText(arena.allocator(), "src/main.bp");
    try std.testing.expectEqualStrings("error: the package's entry module declares no `fn main`, so there is nothing to run\n  --> src/main.bp:1:1", t);
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
/// The code cache a compile of the output directory reads (`code_cache.zig`):
/// its directory, and the atom prefix of the project's own modules — every
/// other emitted module is a dependency's (`code_cache.isDependencyArtifact`).
pub const Cache = struct {
    dir: []const u8,
    own_prefix: []const u8,
};

fn erlangArgv(arena: std.mem.Allocator, io: std.Io, out_dir: []const u8, entry_atom: []const u8, cache: Cache) !?[]const []const u8 {
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
    if (try compileAll(arena, io, dir, .erlang, erls.items, cache) != 0) return null;

    const eval = try otp.mainEval(arena, entry_atom);
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
fn beamArgv(arena: std.mem.Allocator, io: std.Io, out_dir: []const u8, entry_atom: []const u8, cache: Cache) !?[]const []const u8 {
    const dir = try std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, std.mem.trimEnd(u8, build_cmd.targetSubdir(.beam), "/") });

    // Every module, not just the entry: one left unassembled is an `undef` at
    // run time rather than an assembler error.
    var asms: std.ArrayListUnmanaged([]const u8) = .empty;
    try collectByExt(arena, io, dir, ".S", &asms);
    if (asms.items.len == 0) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no .S artifact under {s}/ — nothing to run", .{dir}));
        return null;
    }
    if (try compileAll(arena, io, dir, .beam, asms.items, cache) != 0) return null;

    const eval = try otp.mainEval(arena, try std.fmt.allocPrint(arena, "'{s}'", .{entry_atom}));
    return try otp.erlArgv(arena, &.{ "-noshell", "-pa", dir, "-eval", eval });
}

/// `erlc -o <dir> <files…>` (`+from_asm` for BEAM assembly), without a command
/// line that grows with the program: the files go through list files
/// (`arglist.write`) and one `erl` compiles each with the options `erlc` gives
/// it — `report` prints every error and warning as `erlc` does, on stderr
/// (the group leader is `standard_error`), so the program's stdout stays its
/// own — into `dir`.
/// `erlc` itself takes its files on the command line only, and one argument
/// per module passed macOS's 1 MiB `ARG_MAX` at ~200 modules with a deep
/// `--out`. Exit 1 when any file does not compile.
///
/// **The code cache** (decision 509, `code_cache.zig`): a dependency's module
/// — every emitted file whose atom is not the project's
/// (`code_cache.isDependencyArtifact`) — is linked into `dir` from the store
/// when its `.beam` is there, else compiled `deterministic` (its `.beam` is
/// then the same bytes wherever it is compiled) and stored, side by side on
/// the job's schedulers; one that is refused, or cannot be keyed, is compiled
/// as the project's own are, so its refusal reads as before. A file whose
/// `.beam` in `dir` carries the record of its bytes (`beam_record.zig`,
/// decision 1007) is not compiled at all, own or dependency's.
fn compileAll(arena: std.mem.Allocator, io: std.Io, dir: []const u8, kind: Kind, files: []const []const u8, cache: Cache) !u8 {
    const code = try compileInto(arena, io, dir, kind, files, cache);
    if (code != 0) reporter.errMsg("the OTP compiler refused the emitted program — nothing to run");
    return code;
}

pub const Kind = enum { erlang, beam };

/// `compileAll` without its closing line: `botopink test` on beam assembles
/// its run's `.S` files with it (`test_cmd.zig`), a refusal printed as `erlc`
/// prints it.
pub fn compileInto(arena: std.mem.Allocator, io: std.Io, dir: []const u8, kind: Kind, files: []const []const u8, cache: Cache) !u8 {
    // Decision 1007: a file whose `.beam` in `dir` carries the record of its
    // bytes, this compiler and this OTP release is loaded as it is — `build`'s
    // OTP check wrote the own modules' — and the rest compiled.
    var own: std.ArrayListUnmanaged(beam_record.Pair) = .empty;
    var deps: std.ArrayListUnmanaged(beam_record.Pair) = .empty;
    for (files) |f| {
        const stem = std.fs.path.stem(f);
        const pair: beam_record.Pair = .{ .src = f, .beam = try std.fmt.allocPrint(arena, "{s}/{s}.beam", .{ dir, stem }) };
        try (if (code_cache.isDependencyArtifact(f, cache.own_prefix)) &deps else &own).append(arena, pair);
    }
    const own_todo = try beam_record.stale(arena, io, own.items, false);
    const dep_todo = try beam_record.stale(arena, io, deps.items, false);
    if (own_todo.len + dep_todo.len == 0) return 0;
    const own_list = try arglist.write(arena, io, try beam_record.sources(arena, own_todo));
    defer arglist.remove(io, own_list);
    const dep_list = try arglist.write(arena, io, try beam_record.sources(arena, dep_todo));
    defer arglist.remove(io, dep_list);
    const mode: []const u8 = switch (kind) {
        .erlang => "erl",
        .beam => "asm",
    };
    // A job of the command's `erl` session (`otp.zig`), after `build`'s check.
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-eval", COMPILE_EVAL, "-extra", dir, mode, own_list, dep_list, cache.dir, code_cache.mode() };
    const result = otp.job(arena, io, COMPILE_EVAL, argv[5..], otp.onlineFor(dep_todo.len)) catch |err| {
        reporter.errMsg(arglist.spawnError(arena, "erl", argv, err));
        return 1;
    };
    if (result.stdout.len > 0) std.Io.File.stdout().writeStreamingAll(io, result.stdout) catch {};
    if (result.code == 0) {
        beam_record.writeAll(arena, io, own_todo);
        beam_record.writeAll(arena, io, dep_todo);
    }
    return result.code;
}

const COMPILE_EVAL =
    \\[OutDir, Mode, OwnListFile, DepListFile, CacheDir, CacheMode] = init:get_plain_arguments(),
++ arglist.READ_LIST("Own", "OwnListFile") ++ arglist.READ_LIST("Deps", "DepListFile") ++ code_cache.ERL_FUNS ++
    \\group_leader(whereis(standard_error), self()),
    \\Opts = case Mode of "asm" -> [from_asm, report, {outdir, OutDir}]; _ -> [report, {outdir, OutDir}] end,
    \\Kind = case Mode of "asm" -> asm; _ -> erl end,
    \\Beam = fun(F) -> filename:join(OutDir, filename:rootname(filename:basename(F)) ++ ".beam") end,
    \\N = erlang:max(1, erlang:system_info(schedulers_online)),
    \\Indexed = lists:zip(lists:seq(0, length(Deps) - 1), Deps),
    \\Parts = [[F || {I, F} <- Indexed, I rem N =:= K] || K <- lists:seq(0, N - 1)],
    \\Self = self(),
    \\Refs = [begin
    \\            R = make_ref(),
    \\            spawn(fun() -> Self ! {R, [F || F <- Part, (catch CodeDep(F, Kind, Beam(F))) =/= ok]} end),
    \\            R
    \\        end || Part <- Parts],
    \\Left = lists:append([receive {R, Missed} -> Missed end || R <- Refs]),
    \\Bad = [F || F <- Own ++ Left, case compile:file(F, Opts) of {ok, _} -> false; {ok, _, _} -> false; _ -> true end],
    \\CodeReap(),
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
