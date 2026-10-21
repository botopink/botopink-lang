/// `botopink build` — compile the project to the configured target.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");
const diagnostics = @import("./diagnostics.zig");
const arglist = @import("./arglist.zig");
const otp = @import("./otp.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");
const build_stamp = @import("build_stamp");
const runtime_file = bp.runtime_file;

const Module = bp.Module;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    out_dir: []const u8 = "out",
    /// `--typescript`: write a `.d.ts` beside each `.js` for this build. The
    /// package's `"typings": true` turns it on too (decisions 619, 620):
    /// either one says so, and neither turns it off.
    typescript: bool = false,
    /// `--cold`: the code cache is not read, and what ran is written
    /// (decision 509 (5), `code_cache.zig`).
    cold: bool = false,
    /// `--emit-resolved <dir>`: the resolved program of the package written to
    /// `<dir>/<pkg>.bp`, for reading (decision 798 (2), (3)).
    emit_resolved: ?[]const u8 = null,
    /// `--emit-runtime <dir>`: the resolved tree of every package of the
    /// program written to `<dir>/<group>.bpr`, to build any target from later
    /// (decision 805 (1)).
    emit_runtime: ?[]const u8 = null,
    /// `botopink build <file>.bpr`: the program read back from its root
    /// package's `.bpr` and emitted with no comptime (decision 805 (3)).
    runtime_input: ?[]const u8 = null,
};

/// The hooks a build runs over its analysed session
/// (`codegen.Options.on_analysed`): `--emit-resolved`'s and `--emit-runtime`'s.
const AnalysedSinks = struct {
    resolved: ?*ResolvedSink = null,
    runtime: ?*RuntimeSink = null,

    fn call(ctx: *anyopaque, outputs: []const bp.codegen.ComptimeOutput, readers: []const []const u8) anyerror!void {
        const self: *AnalysedSinks = @ptrCast(@alignCast(ctx));
        if (self.resolved) |r| try ResolvedSink.call(r, outputs, readers);
        if (self.runtime) |r| try RuntimeSink.call(r, outputs, readers);
    }
};

/// `--emit-resolved`'s hook (`codegen.Options.on_analysed`).
const ResolvedSink = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    package: []const u8,
    paths: []const []const u8,

    fn call(ctx: *anyopaque, outputs: []const bp.codegen.ComptimeOutput, _: []const []const u8) anyerror!void {
        const self: *ResolvedSink = @ptrCast(@alignCast(ctx));
        const text = bp.codegen.resolvedPrint.print(self.gpa, outputs, self.paths) catch |err| switch (err) {
            // A refused analysis has no resolved program; its diagnostic is the build's.
            error.NotResolved => return,
            else => return err,
        };
        defer self.gpa.free(text);
        std.Io.Dir.cwd().createDirPath(self.io, self.dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        const name = try std.fmt.allocPrint(self.gpa, "{s}.bp", .{self.package});
        defer self.gpa.free(name);
        const path = try std.fs.path.join(self.gpa, &.{ self.dir, name });
        defer self.gpa.free(path);
        try std.Io.Dir.cwd().writeFile(self.io, .{ .sub_path = path, .data = text });
        reporter.print("  wrote {s}\n", .{path});
    }
};

/// The compiler a `.bpr` is written and read by (decision 805 (2)): the hash
/// of the sources this binary is built from, which covers the analysis's
/// types the file's encoding follows.
pub fn runtimeStamp() runtime_file.Stamp {
    var out: runtime_file.Stamp = undefined;
    std.crypto.hash.sha2.Sha256.hash("botopink .bpr\x00" ++ build_stamp.source_hash, &out, .{});
    return out;
}

/// `--emit-runtime`'s hook: one `<dir>/<group>.bpr` per package of the
/// analysed program (decision 805 (1)) — a dependency's, a loaded file's, each
/// embedded std module's, then the root package's, which alone names the
/// program (`runtime_file.Meta.program`). A program one of whose modules did
/// not analyse writes none: its diagnostic is the build's.
const RuntimeSink = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    root: []const u8,
    deps: []const []const u8,
    wasm_host: bp.ast.WasmHost,

    fn call(ctx: *anyopaque, outputs: []const bp.codegen.ComptimeOutput, readers: []const []const u8) anyerror!void {
        const self: *RuntimeSink = @ptrCast(@alignCast(ctx));
        for (outputs) |o| if (o.outcome != .ok) return;
        var arena_inst = std.heap.ArenaAllocator.init(self.gpa);
        defer arena_inst.deinit();
        const arena = arena_inst.allocator();

        // The groups in the order their first module comes, each its modules.
        var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(bp.codegen.ComptimeOutput)) = .empty;
        const program = try arena.alloc(runtime_file.Placed, outputs.len);
        for (outputs, program) |o, *p| {
            // A module reading `@TypeInfo.all` answers for the whole program
            // (805 (1)): the root's file holds it, whatever its package.
            const reads = for (readers) |r| {
                if (std.mem.eql(u8, r, o.name)) break true;
            } else false;
            const g = if (reads) self.root else runtime_file.groupOf(o.name, self.root, self.deps);
            const slot = try groups.getOrPut(arena, g);
            if (!slot.found_existing) slot.value_ptr.* = .empty;
            try slot.value_ptr.append(arena, o);
            p.* = .{ .group = g, .module = o.name };
        }
        std.Io.Dir.cwd().createDirPath(self.io, self.dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        const stamp = runtimeStamp();
        var it = groups.iterator();
        while (it.next()) |g| {
            const mods = g.value_ptr.items;
            const names = try arena.alloc([]const u8, mods.len);
            for (mods, names) |m, *n| n.* = m.name;
            const is_root = std.mem.eql(u8, g.key_ptr.*, self.root);
            const meta: runtime_file.Meta = .{
                .group = g.key_ptr.*,
                .modules = names,
                .program = if (is_root) program else &.{},
                .root = if (is_root) self.root else "",
                .deps = if (is_root) self.deps else &.{},
                .wasm_host = if (is_root) self.wasm_host else .wasi,
            };
            const bytes = try runtime_file.write(self.gpa, stamp, meta, mods);
            defer self.gpa.free(bytes);
            const path = try runtimePath(arena, self.dir, g.key_ptr.*);
            // Whole or not at all (`analysis_store.write`): a build reading a
            // dependency's `.bpr` another build is writing reads the old file
            // or the new one, never a part.
            try analysis_store.write(arena, self.io, path, bytes);
            reporter.print("  wrote {s}\n", .{path});
        }
    }
};

/// `<dir>/<group>.bpr` (`std/io` → `<dir>/std/io.bpr`).
fn runtimePath(arena: std.mem.Allocator, dir: []const u8, group: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), group, runtime_file.EXT });
}

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
    if (opts.cold) code_cache.cold = true;
    if (opts.runtime_input) |file| return (try runRuntime(gpa, io, arena, opts, file, env_map, null)).exit;

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget() orelse {
        reportUnsupportedTarget(proj.target);
        return 1;
    };
    // erlang and beam: the `erl` on PATH runs the OTP release the compiler
    // emits for, or nothing is built (decision 228, `otp.zig`).
    if ((target == .erlang or target == .beam) and !try otp.check(arena, io)) return 1;

    // Resolve declared external libs from disk (generic — `libs/<name>/`). The
    // core never names a lib; it only sees these as ordinary `Module[]` and
    // resolves `from "<lib>"` through the shared import registry. `std` is the
    // embedded exception and is not loaded here.
    const entry_target: code_cache.EntryTarget = .{ .target = target, .host = proj.wasmHost() };
    var closure_keys: libs.ClosureKeys = .{ .arena = arena, .target = entry_target, .cache_root = analysis_store.root(proj) };
    const dep_modules = libs.loadDependenciesWith(gpa, io, proj, env_map, &closure_keys) catch |err| {
        reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Resolve project source files through the explicit module tree, after
    // the dependencies: a `.bpp` file unfolds onto the package `"bpp"` names
    // (front 116 step 2, `closure_keys.bpp`). (`sources.load` reports
    // resolution errors itself.)
    var loaded = sources.loadWith(gpa, io, proj, proj.srcDir(), if (closure_keys.bpp) |*b| b else null) catch return 1;
    defer loaded.free(gpa);
    const project_modules = loaded.modules;

    if (project_modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    // The code cache's level B (144 B-60): a dependency whose analysis entry
    // reads back under its closure key is not analysed again; the entries
    // this build analyses are written once its generate returned.
    var level_b: analysis_store.Cache = undefined;
    try level_b.init(gpa, io, analysis_store.root(proj), entry_target, closure_keys.keys);
    level_b.logs = closure_keys.logs;
    defer level_b.deinit();
    // The compiled comptime modules beside it (decision 543).
    try bp.comptime_runtime.useCompiledCache(analysis_store.root(proj), code_cache.cold);

    // Compile dependency modules ahead of project modules (their types/decorators
    // must resolve before the project that imports them).
    const all_modules = try std.mem.concat(arena, Module, &.{ dep_modules, project_modules });

    reporter.compiling(all_modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // A module that does not lex, parse or type-check is reported with its
    // location (below); the rest still compile.
    const modules = all_modules;

    // Build codegen config. The package names start every erlang/BEAM
    // module atom (decision 109).
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (opts.typescript or proj.manifest.typings) .typescript else null,
        .build_root = ".botopinkbuild",
        .packages = try libs.packagesOf(arena, proj, dep_modules),
        .wasm_host = proj.wasmHost(),
        // The file a wasm build writes is what its host runs: the WASI
        // preview 2 component on `wasi` (decision 334).
        .wasm_artifact = true,
        .analysis_store = &level_b.store,
    };

    // Run the compiler. `build` emits only: the program is not executed.
    var sink: ResolvedSink = undefined;
    var runtime_sink: RuntimeSink = undefined;
    var sinks: AnalysedSinks = .{};
    if (opts.emit_resolved) |dir| {
        const paths = try arena.alloc([]const u8, project_modules.len);
        for (project_modules, paths) |m, *p| p.* = m.path;
        sink = .{ .gpa = gpa, .io = io, .dir = dir, .package = proj.name, .paths = paths };
        bp.comptime_pipeline.keep_resolved = true;
        sinks.resolved = &sink;
    }
    if (opts.emit_runtime) |dir| {
        runtime_sink = .{ .gpa = gpa, .io = io, .dir = dir, .root = proj.name, .deps = cfg.packages.deps, .wasm_host = cfg.wasm_host };
        sinks.runtime = &runtime_sink;
    }
    const hook: ?bp.codegen.AnalysedHook = if (sinks.resolved != null or sinks.runtime != null)
        .{ .ctx = &sinks, .call = AnalysedSinks.call }
    else
        null;
    var outputs = bp.codegen.generateWith(gpa, modules, io, cfg, .{ .execute = false, .on_analysed = hook }) catch |err| {
        reporter.errMsg("compilation failed");
        reporter.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }
    level_b.commit();

    const t1 = std.Io.Timestamp.now(io, .awake);

    // Every module comes back from the compiler; one that did not lex, parse,
    // type-check or pass comptime validation carries its diagnostic instead of
    // an artifact, rendered here.
    diagnostics.renderWarnings(gpa, io, arena, outputs.items);
    // Decision 788 (3) — what the build bodies printed is the build's output,
    // on stdout, module by module in build order; the CLI's own messages stay
    // on stderr. A cell check's in-process build (`reporter.sink` set) keeps
    // it out of its own output.
    if (reporter.sink == null) for (outputs.items) |o| if (o.result.build_output.len > 0) reporter.stdout(io, o.result.build_output);
    const failed = try diagnostics.failedOutputs(gpa, io, arena, modules, outputs.items);

    // Write what compiled; remove any previous artifact of a module that did not,
    // so nothing stale is left claiming to be current.
    writeOutputs(gpa, io, outputs.items, opts.out_dir, target, cfg.packages, cfg.wasm_host, env_map) catch |err| switch (err) {
        // A sidecar the build cannot ship: the located refusal is already
        // printed by the shipper, and the build ends here with exit 1.
        error.SidecarRefused => return 1,
        else => return err,
    };
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target, cfg.packages);

    // erlang: emitted text is not yet a program — the OTP compiler must accept
    // it. Every `.erl` this build wrote is compiled (in memory, nothing is
    // written) and one it refuses fails the build, so "it builds on erlang"
    // means what it says.
    const erl_ok = if (target == .erlang)
        try checkErlang(arena, io, outputs.items, opts.out_dir, cfg.packages, try code_cache.dir(arena, proj))
    else
        true;

    diagnostics.reportOrphans(arena, loaded.orphans.len);

    if (failed.len > 0) {
        diagnostics.reportFailedModules(arena, failed);
        return 1;
    }
    if (!erl_ok) return 1;

    reporter.compiled(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}

/// What a build from a `.bpr` answers `run` (`run.zig`): its exit status, the
/// program's root package and whether its entry module declares `fn main`.
pub const RuntimeBuild = struct {
    exit: u8,
    root: []const u8 = "",
    has_main: bool = false,
    wasm_host: bp.ast.WasmHost = .wasi,
};

/// `botopink build --target <t> <file>.bpr` (decision 805 (1), (3)): the
/// program the root package's `.bpr` names, each module read from its
/// package's file beside it, emitted for `--target` — no lexer, parser, check
/// or comptime, and nothing of the build phase printed (798 (4)). `--target`
/// is required: a `.bpr` has no manifest. `entry` names the module `run`
/// starts (its `fn main` is looked for), null for a build.
pub fn runRuntime(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    opts: Options,
    file: []const u8,
    env_map: libs.EnvMap,
    entry: ?[]const u8,
) !RuntimeBuild {
    const target = opts.target orelse {
        reporter.errCode(runtime_codes.target_required, "a .bpr has no manifest; write --target <commonJS|erlang|beam|wasm>");
        return .{ .exit = 1 };
    };
    if ((target == .erlang or target == .beam) and !try otp.check(arena, io)) return .{ .exit = 1 };

    const stamp = runtimeStamp();
    const root_file = readRuntime(arena, io, file, stamp, null) orelse return .{ .exit = 1 };
    const meta = root_file.meta;
    if (meta.program.len == 0) {
        reporter.errCode(runtime_codes.not_a_program, try std.fmt.allocPrint(arena, "{s} is the .bpr of `{s}`, a package another one depends on; build the .bpr of the program's own package", .{ file, meta.group }));
        return .{ .exit = 1 };
    }

    // A `.bpr` is built from the directory of the project that wrote it (decision 838 (3)):
    // its host files are found from there, as a direct build finds them.
    if (!inItsProject(arena, io, file, meta.root)) return .{ .exit = 1 };

    // Each package's file once, beside the root's.
    const dir = std.fs.path.dirname(file) orelse ".";
    var files: std.StringHashMapUnmanaged(runtime_file.Decoded) = .empty;
    try files.put(arena, meta.group, root_file);
    const outputs = try arena.alloc(bp.codegen.ComptimeOutput, meta.program.len);
    for (meta.program, outputs) |placed, *out| {
        const decoded = files.get(placed.group) orelse blk: {
            const path = try runtimePath(arena, dir, placed.group);
            const d = readRuntime(arena, io, path, stamp, file) orelse return .{ .exit = 1 };
            try files.put(arena, placed.group, d);
            break :blk d;
        };
        out.* = for (decoded.outputs) |o| {
            if (std.mem.eql(u8, o.name, placed.module)) break o;
        } else {
            reporter.errCode(runtime_codes.unreadable, try std.fmt.allocPrint(arena, "the .bpr of `{s}` holds no module `{s}`, which {s} names; run the build again", .{ placed.group, placed.module, file }));
            return .{ .exit = 1 };
        };
    }

    // Read before the emit, which may rewrite a tree in place.
    const has_main = if (entry) |name| declaresMain(outputs, name) else false;
    const proj: config.ProjectConfig = .{ .name = meta.root };
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (opts.typescript) .typescript else null,
        .build_root = ".botopinkbuild",
        .packages = .{ .root = meta.root, .deps = meta.deps },
        .wasm_host = meta.wasm_host,
        .wasm_artifact = true,
    };
    var emitted = try bp.codegen.emit(gpa, outputs, cfg);
    defer {
        for (emitted.items) |*o| o.result.deinit(gpa);
        emitted.deinit(gpa);
    }
    const failed = try diagnostics.failedOutputs(gpa, io, arena, &.{}, emitted.items);
    writeOutputs(gpa, io, emitted.items, opts.out_dir, target, cfg.packages, cfg.wasm_host, env_map) catch |err| switch (err) {
        error.SidecarRefused => return .{ .exit = 1 },
        else => return err,
    };
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target, cfg.packages);
    const erl_ok = if (target == .erlang)
        try checkErlang(arena, io, emitted.items, opts.out_dir, cfg.packages, try code_cache.dir(arena, proj))
    else
        true;
    if (failed.len > 0) {
        diagnostics.reportFailedModules(arena, failed);
        return .{ .exit = 1, .root = meta.root, .wasm_host = meta.wasm_host };
    }
    if (!erl_ok) return .{ .exit = 1, .root = meta.root, .wasm_host = meta.wasm_host };

    return .{ .exit = 0, .root = meta.root, .has_main = has_main, .wasm_host = meta.wasm_host };
}

/// Whether the working directory is the project `root` wrote `file` from — its
/// `botopink.json` names `root` (decision 838 (3)); else the refusal printed,
/// naming both.
fn inItsProject(arena: std.mem.Allocator, io: std.Io, file: []const u8, root: []const u8) bool {
    const here = config.load(arena, io) catch |err| switch (err) {
        error.ConfigNotFound => {
            reporter.errCode(runtime_codes.other_project, std.fmt.allocPrint(arena, "{s} is the .bpr of project `{s}`, and the working directory holds no botopink.json; build it from the directory of `{s}`", .{ file, root, root }) catch "the working directory holds no botopink.json");
            return false;
        },
        // The manifest's own refusal is printed.
        else => return false,
    };
    if (std.mem.eql(u8, here.name, root)) return true;
    reporter.errCode(runtime_codes.other_project, std.fmt.allocPrint(arena, "{s} is the .bpr of project `{s}`, and the working directory holds project `{s}`; build it from the directory of `{s}`", .{ file, root, here.name, root }) catch "the working directory is another project");
    return false;
}

/// Whether the analysed module `name` of `outputs` declares a top-level
/// `fn main` (decision 517, read from the tree a `.bpr` holds).
fn declaresMain(outputs: []const bp.codegen.ComptimeOutput, name: []const u8) bool {
    for (outputs) |o| {
        if (!std.mem.eql(u8, o.name, name)) continue;
        for (o.outcome.ok.transformed.decls) |d| switch (d) {
            .@"fn" => |f| if (std.mem.eql(u8, f.name, "main")) return true,
            else => {},
        };
        return false;
    }
    return false;
}

/// The codes of a refused `.bpr` (decision 805 (2), (3)).
pub const runtime_codes = struct {
    /// `build` / `run` over a `.bpr` without `--target`.
    pub const target_required = "runtime-target-required";
    /// A `.bpr` another compiler wrote.
    pub const other_compiler = "runtime-other-compiler";
    /// A file that is no `.bpr`, or one of this compiler that does not read back whole.
    pub const unreadable = "runtime-unreadable";
    /// A package's `.bpr` the root's names, not beside it.
    pub const missing = "runtime-missing";
    /// A dependency's `.bpr` handed as the program.
    pub const not_a_program = "runtime-not-a-program";
    /// The working directory holds no `botopink.json`, or the manifest of another project
    /// than the one that wrote the `.bpr` (decision 838 (3)).
    pub const other_project = "runtime-other-project";
};

/// The `.bpr` at `path`, decoded — else its refusal printed and null.
/// `named_by` is the root's file when `path` is a package's it names.
fn readRuntime(arena: std.mem.Allocator, io: std.Io, path: []const u8, stamp: runtime_file.Stamp, named_by: ?[]const u8) ?runtime_file.Decoded {
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited) catch |err| {
        const msg = if (named_by) |root|
            std.fmt.allocPrint(arena, "{s} is not there, and {s} needs it; run the build again", .{ path, root }) catch "a .bpr is missing"
        else
            std.fmt.allocPrint(arena, "cannot read {s} ({s})", .{ path, @errorName(err) }) catch "cannot read the .bpr";
        reporter.errCode(runtime_codes.missing, msg);
        return null;
    };
    return runtime_file.read(arena, bytes, stamp) catch |err| {
        const msg = switch (err) {
            error.OtherCompiler => std.fmt.allocPrint(arena, "{s} was built by another compiler; run the build again", .{path}),
            error.NotRuntimeFile, error.Malformed => std.fmt.allocPrint(arena, "{s} is not a .bpr this compiler reads whole; run the build again", .{path}),
            error.OutOfMemory => std.fmt.allocPrint(arena, "out of memory reading {s}", .{path}),
        } catch "the .bpr is refused";
        reporter.errCode(if (err == error.OtherCompiler) runtime_codes.other_compiler else runtime_codes.unreadable, msg);
        return null;
    };
}

/// Compile every `.erl` this build wrote with the OTP compiler, in one `erl`
/// (one process per scheduler, `compile:file(F, [binary, return_errors])` —
/// in memory, so `out/` holds exactly what it held before), and print each
/// refusal as `<file>:<line>: <message>`. False when any module is refused, or
/// when `erl` cannot be run: a build that did not check its output does not
/// get to say it succeeded.
///
/// A build that only transpiles proved nothing about erlang: a module `erlc`
/// rejects wrote, exited 0, and a `botopink run` / `test` of the same program
/// then failed on it — and "it builds on that target" was read as evidence.
/// The warnings of generated code are not reported (`return_errors` alone).
///
/// **The code cache** (decision 509, `code_cache.zig`, `cache_dir`). The
/// project's own modules are compiled every time. A DEPENDENCY's module (std,
/// a library — `Packages.idOf`) is answered from the store when its `.beam` is
/// there under the key of its bytes and the OTP compiler's version: the same
/// bytes under the same compiler compile the same — rakun's build tests spawn
/// 22 builds of one closure in a cell. One it compiles is stored (its `.beam`,
/// which `run` and `test` then link into their output instead of compiling
/// it); a refusal is compiled, and printed, every time. `--cold` reads
/// nothing and stores what it compiled. The lookup is inside the same `erl`,
/// so a build with no working `erl` fails exactly as before.
fn checkErlang(
    arena: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    packages: bp.codegen.crossModule.Packages,
    cache_dir: []const u8,
) !bool {
    // The files go through list files, never the command line: one path per
    // module made `erl`'s argv grow with the program, and a 203-module build
    // with a deep `--out` passed macOS's 1 MiB `ARG_MAX` (`arglist.zig`).
    var own = std.ArrayListUnmanaged([]const u8).empty;
    var deps = std.ArrayListUnmanaged([]const u8).empty;
    for (outputs) |o| {
        if (o.result.failed()) continue;
        const list = if (packages.idOf(o.name).package_in_path) &deps else &own;
        try list.append(arena, try artifactPath(arena, out_dir, .erlang, packages, o.name, ".erl"));
        for (o.result.units) |u| {
            try list.append(arena, try std.fmt.allocPrint(arena, "{s}/{s}{s}.erl", .{ out_dir, targetSubdir(.erlang), u.atom }));
        }
    }
    const total = own.items.len + deps.items.len;
    if (total == 0) return true;
    const own_list = try arglist.write(arena, io, own.items);
    defer arglist.remove(io, own_list);
    const dep_list = try arglist.write(arena, io, deps.items);
    defer arglist.remove(io, dep_list);

    // One job of the command's `erl` session (`otp.zig`): the VM that answered
    // the release, and that `run` compiles the output directory in next.
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-eval", ERLANG_CHECK_EVAL, "-extra", cache_dir, code_cache.mode(), own_list, dep_list };
    const result = otp.job(arena, io, ERLANG_CHECK_EVAL, argv[5..], otp.onlineFor(total)) catch |err| {
        const msg = try std.fmt.allocPrint(arena, "`botopink build --target erlang` compiles what it emits with the OTP compiler, and {s}", .{arglist.spawnError(arena, "erl", argv, err)});
        reporter.errMsg(msg);
        if (err == error.FileNotFound) reporter.hintMsg("install Erlang/OTP 28+ and put `erl` on PATH");
        return false;
    };
    if (result.stdout.len > 0) reporter.print("{s}", .{result.stdout});
    const code: u8 = result.code;
    if (code == 0) return true;
    reporter.errMsg("the OTP compiler refused emitted erlang — the build is not a program");
    return false;
}

/// The check `checkErlang` runs in one `erl`: the plain arguments are the code
/// cache's directory and mode (`code_cache.ERL_FUNS`) and the list files of
/// the project's own `.erl` and of its dependencies' (`arglist.write`); the
/// files are dealt round-robin to one process per online scheduler, each
/// compiling its share in memory — a dependency's through `CodeDep`, answered
/// from the store when it is there and its `.beam` materialised beside its
/// `.erl` (decisions 509 (4), 767: what `run` links, so a consumer of the
/// output compiles only the project's own modules); every refusal is printed as
/// `<file>:<line>: <message>`; exit 1 when there is any.
const ERLANG_CHECK_EVAL =
    \\[CacheDir, CacheMode, OwnListFile, DepListFile] = init:get_plain_arguments(),
++ arglist.READ_LIST("Own", "OwnListFile") ++ arglist.READ_LIST("Deps", "DepListFile") ++ code_cache.ERL_FUNS ++
    \\N = erlang:max(1, erlang:system_info(schedulers_online)),
    \\Files = [{own, F} || F <- Own] ++ [{dep, F} || F <- Deps],
    \\Indexed = lists:zip(lists:seq(0, length(Files) - 1), Files),
    \\Parts = [[F || {I, F} <- Indexed, I rem N =:= K] || K <- lists:seq(0, N - 1)],
    \\Self = self(),
    \\Loc = fun({L, C}) -> io_lib:format("~p:~p", [L, C]); (none) -> "0"; (L) -> io_lib:format("~p", [L]) end,
    \\Compile = fun(F) ->
    \\    case catch compile:file(F, [binary, return_errors]) of
    \\        {ok, _, _} -> [];
    \\        {ok, _, _, _} -> [];
    \\        {error, Errors, _} ->
    \\            [io_lib:format("~ts:~ts: ~ts~n", [File, Loc(L), M:format_error(D)])
    \\             || {File, Items} <- Errors, {L, M, D} <- Items];
    \\        Other -> [io_lib:format("~ts: ~p~n", [F, Other])]
    \\    end
    \\end,
    \\Check = fun({own, F}) -> Compile(F);
    \\           ({dep, F}) -> case catch CodeDep(F, erl, filename:rootname(F) ++ ".beam") of ok -> []; _ -> Compile(F) end
    \\        end,
    \\Refs = [begin
    \\            R = make_ref(),
    \\            spawn(fun() -> Self ! {R, lists:append([Check(F) || F <- Part])} end),
    \\            R
    \\        end || Part <- Parts],
    \\Out = lists:append([receive {R, Lines} -> Lines end || R <- Refs]),
    \\io:put_chars(Out),
    \\CodeReap(),
    \\halt(case Out of [] -> 0; _ -> 1 end).
;

/// `botopink.json` names a target the compiler does not support.
pub fn reportUnsupportedTarget(name: []const u8) void {
    var buf: [256]u8 = undefined;
    reporter.errMsg(std.fmt.bufPrint(&buf, "botopink.json declares an unsupported target '{s}'", .{name}) catch "botopink.json declares an unsupported target");
    reporter.hintMsg("use one of commonJS, erlang, beam or wasm");
}

/// Shared message for a `libs.loadDependencies` failure.
pub fn reportDependencyError(err: anyerror) void {
    switch (err) {
        error.LibsRootNotFound => {
            reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory");
            reporter.hintMsg("if your botopink.json uses the new object form ({\"<name>\": {\"git\": ...}}), run `bpmp install` to fetch deps into $BPMP_HOME first");
        },
        error.LibNotFound => reporter.hintMsg("a git dependency resolves from BOTOPINK_LIB_ROOTS, then .botopinkbuild/deps/<name> (`bpmp link` or `bpmp install`), then <ancestor>/repository/botopink-lang/libs, <ancestor>/repository and <ancestor>/libs"),
        // Already rendered, located in the manifest that is wrong.
        error.LibManifestInvalid => {},
        // Already rendered with the path and the manifest line.
        error.LibFileNotFound => {},
        // Already rendered, located at the `dependencies` entry.
        error.BundledDependency => {},
        // Already rendered, located at the dependency's import.
        error.ImportSourceRefused => {},
        // Already rendered (decision 361): at the `"bpp"` key, at a role
        // declaration of the package it names, or at a `.bpp` file's line.
        error.BppRefused => {},
        else => reporter.errMsg("failed to load project dependencies"),
    }
}

pub fn artifactExt(target: config.Target) []const u8 {
    return switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        .beam => ".S",
        .wasm => ".wat",
    };
}

/// The codegen target a CLI target emits.
pub fn targetSource(target: config.Target) bp.codegen.TargetSource {
    return switch (target) {
        .commonJS => .commonJS,
        .erlang => .erlang,
        .beam => .beam,
        .wasm => .wasm,
    };
}

/// Where a target's artifacts live under `out/`.
///
/// `erlc` refuses a `-module` atom that differs from its file's basename, so an
/// erlang or BEAM artifact is named by the module ATOM (`std/math` →
/// `std@math.erl`) and the tree is FLAT — one directory per target, which is
/// also the only shape `erl -pa <one directory>` can load a multi-module program
/// from. commonJS, its `.d.ts` and wasm keep the mirrored module-path tree
/// directly under `out/`: a `require` target and a wasm import segment ARE the
/// module path, so flattening them would break every multi-module JS program.
pub fn targetSubdir(target: config.Target) []const u8 {
    return switch (target) {
        .erlang => "erl/",
        .beam => "beam/",
        .commonJS, .wasm => "",
    };
}

/// `<out_dir>/<subdir><stem><ext>` for one module — the stem is the module atom
/// for erlang and BEAM (its package first, decision 109), the module path for
/// commonJS and wasm. Caller owns it.
pub fn artifactPath(
    alloc: std.mem.Allocator,
    out_dir: []const u8,
    target: config.Target,
    packages: bp.codegen.crossModule.Packages,
    module_name: []const u8,
    ext: []const u8,
) ![]u8 {
    const stem = try bp.codegen.crossModule.outputStem(targetSource(target), alloc, packages.idOf(module_name));
    defer alloc.free(stem);
    return std.fmt.allocPrint(alloc, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), stem, ext });
}

/// Delete the artifact (and `.d.ts`) of every module that failed — and, on
/// erlang and BEAM, the per-`type` modules it wrote beside it when it last
/// succeeded (policy 3 of `13-module-identity`). A failed module carries no
/// `GenerateResult`, so its units cannot be named from the output; they are
/// found by their prefix instead, which is exactly this module's: every unit is
/// `<module atom>@@<Decl><ext>` (decision 109) and no other module can render
/// that stem: `@@` never occurs inside a module atom.
fn removeStaleArtifacts(arena: std.mem.Allocator, io: std.Io, failed: []const []const u8, out_dir: []const u8, target: config.Target, packages: bp.codegen.crossModule.Packages) void {
    for (failed) |name| {
        const exts = [_][]const u8{ artifactExt(target), ".d.ts" };
        for (exts) |ext| {
            const p = artifactPath(arena, out_dir, target, packages, name, ext) catch continue;
            std.Io.Dir.cwd().deleteFile(io, p) catch {};
        }
        removeStaleUnits(arena, io, packages, name, out_dir, target);
    }
}

/// The `<module atom>@@…<ext>` files of one failed module, deleted from the
/// flat per-target directory. A no-op on commonJS and wasm, which emit no units.
fn removeStaleUnits(arena: std.mem.Allocator, io: std.Io, packages: bp.codegen.crossModule.Packages, name: []const u8, out_dir: []const u8, target: config.Target) void {
    switch (target) {
        .erlang, .beam => {},
        .commonJS, .wasm => return,
    }
    const atom = bp.codegen.crossModule.erlAtom(arena, packages.idOf(name)) catch return;
    const prefix = std.fmt.allocPrint(arena, "{s}{s}", .{ atom, bp.codegen.crossModule.DECL_SEP }) catch return;
    const ext = artifactExt(target);
    const dir_path = std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, targetSubdir(target) }) catch return;
    var dir = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);
    var it = dir.iterate();
    while (it.next(io) catch null) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.startsWith(u8, entry.name, prefix)) continue;
        if (!std.mem.endsWith(u8, entry.name, ext)) continue;
        dir.deleteFile(io, entry.name) catch {};
    }
}

// ── Output writer ─────────────────────────────────────────────────────────────

fn writeOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    target: config.Target,
    packages: bp.codegen.crossModule.Packages,
    wasm_host: bp.ast.WasmHost,
    env_map: libs.EnvMap,
) !void {
    // Ensure output directory exists.
    std.Io.Dir.cwd().createDirPath(io, out_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext = artifactExt(target);

    for (outputs) |o| {
        // A validation error carries no artifact.
        if (o.result.failed()) continue;
        // erlang/BEAM: `out/<target>/<atom><ext>`, flat. commonJS/wasm:
        // `out/<module path><ext>`, so subdirectories may have to be created.
        const sub_path = try artifactPath(gpa, out_dir, target, packages, o.name, ext);
        defer gpa.free(sub_path);

        // Ensure parent directory exists.
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }

        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });

        // Decision 334: a `browser` build is the module's binary and the
        // loader that instantiates it with a browser's imports (node runs it
        // too) — `<module>.wasm` and `<module>.mjs` beside the `.wat`.
        if (target == .wasm and wasm_host == .browser) {
            const bin = o.result.wasm orelse return error.MissingWasmBinary;
            const wasm_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".wasm");
            defer gpa.free(wasm_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = wasm_path, .data = bin });
            const loader_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".mjs");
            defer gpa.free(loader_path);
            const loader = try bp.codegen.wasmBrowserLoader.render(gpa, std.fs.path.basename(wasm_path));
            defer gpa.free(loader);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = loader_path, .data = loader });
        }

        // Policy 3 (`13-module-identity`): every `type` of the module is a
        // module of its own on erlang/beam — `out/<target>/<type atom><ext>`,
        // flat beside the file's, which is where `erl -pa` loads it from.
        for (o.result.units) |u| {
            const unit_path = try std.fmt.allocPrint(gpa, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), u.atom, ext });
            defer gpa.free(unit_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = unit_path, .data = u.code });
        }

        // Optional TypeScript typedef.
        if (o.result.typedef) |td| {
            const dts_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".d.ts");
            defer gpa.free(dts_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dts_path, .data = td });
        }
    }

    // Ship runtime `.mjs` sidecars (G2) so a built program resolves every
    // `#[@external(.JavaScript(…))]` `require("…/x.mjs")` — including a dependency's, whose
    // emitted module sits a directory deeper than in its own build.
    if (target == .commonJS) {
        try libs.shipMjsSidecars(gpa, io, outputs, packages, out_dir, ext, env_map);
    }
    // erlang and BEAM: a `#[@external(.Erlang("host:fn($0)"))]`'s `host.erl` goes
    // beside the emitted modules — `out/erl/`, where `botopink run` compiles
    // every `.erl` onto the code path, and `out/beam/`, where the assembled
    // entry's `'__bp_load_siblings'/0` compiles and loads every `.erl` beside
    // it. A host module that is neither shipped nor in the Erlang code path is
    // a located refusal here, not an `undef` at run time.
    switch (target) {
        .erlang, .beam => {
            const host_dir = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ out_dir, std.mem.trimEnd(u8, targetSubdir(target), "/") });
            defer gpa.free(host_dir);
            _ = try libs.shipErlSidecars(gpa, io, outputs, packages, host_dir, if (target == .beam) .beam else .erlang, env_map);
        },
        .commonJS, .wasm => {},
    }
}
