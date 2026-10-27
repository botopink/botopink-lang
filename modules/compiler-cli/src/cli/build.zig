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
const refusals = @import("./refusals.zig");
const manifest = @import("manifest");
const runtime_file = bp.runtime_file;
const runtime_cache = @import("./runtime_cache.zig");
const beam_record = @import("./beam_record.zig");
const workspace_out = @import("./workspace_out.zig");
const unit_cache = @import("./unit_cache.zig");

const Module = bp.Module;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    /// null: a bare `build` — comptime and the package's `.bpr` set, no
    /// `out/` (decision 1006 (2)); `run` hands the manifest's target when it
    /// is given none.
    target: ?config.Target = null,
    out_dir: []const u8 = "out",
    /// `--typescript`: write a `.d.ts` beside each `.js` for this build. The
    /// package's `"typings": true` turns it on too (decisions 619, 620):
    /// either one says so, and neither turns it off.
    typescript: bool = false,
    /// `--cold`: the code cache is not read, and what ran is written
    /// (decision 509 (5), `code_cache.zig`).
    cold: bool = false,
    /// `build --cold`: the `.bpr` key is ignored and the set rebuilt (decision
    /// 1006 (4)); `run --cold` leaves it off and reuses a fresh set.
    rebuild: bool = false,
    /// `--emit-resolved <dir>`: the resolved program written one file per
    /// module, `<dir>/<pkg>/<module path>.bp`, for reading (decisions 798 (2),
    /// (3), 834 (1)).
    emit_resolved: ?[]const u8 = null,
    /// `--emit-runtime <dir>`: the directory of the `.bpr` set — the resolved
    /// tree of every package of the program, `<dir>/<group>.bpr`, and the
    /// root's key `<dir>/<pkg>.key` — instead of the cache root's
    /// `.botopinkbuild/runtime/<pkg>/` (decisions 805 (1), 1006 (2)); each
    /// file written is named on stderr.
    emit_runtime: ?[]const u8 = null,
    /// `botopink build <file>.bpr`: the program read back from its root
    /// package's `.bpr` and emitted with no comptime (decision 805 (3)).
    runtime_input: ?[]const u8 = null,
    /// `--json`: stdout is JSON lines — `targets`, `build`, `refused`,
    /// `runtime`, `summary` (decision 798 (6), `modules/compiler-cli/AGENTS.md`);
    /// stderr is as without it.
    json: bool = false,
    /// The module the program starts (`run --module`, default `main`): on wasm
    /// a build emits only its component (decision 1017 (5), `Config.wasm_entry_only`).
    entry: []const u8 = "main",
    /// `--cache-root <dir>`: the root the code cache's levels A and B file
    /// under, instead of the project's or its workspace's.
    cache_root: ?[]const u8 = null,
    /// `--workspace-out <dir>`: the member's build into its workspace's one
    /// output folder (decision 1015 (4), `workspace_out.zig`) — `<dir>` is the
    /// output directory, the member's own files written in place and each
    /// dependency's once per its key. Handed by the workspace root's command.
    workspace_out: ?[]const u8 = null,
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

/// `--emit-resolved`'s hook (`codegen.Options.on_analysed`): one
/// `<dir>/<pkg>/<module path>.bp` per module of the program, grouped as the
/// `.bpr` groups them (decision 834 (1), `resolvedPrint.files`).
const ResolvedSink = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    root: []const u8,
    deps: []const []const u8,

    fn call(ctx: *anyopaque, outputs: []const bp.codegen.ComptimeOutput, _: []const []const u8) anyerror!void {
        const self: *ResolvedSink = @ptrCast(@alignCast(ctx));
        const printed = bp.codegen.resolvedPrint.files(self.gpa, outputs, self.root, self.deps) catch |err| switch (err) {
            // A refused analysis has no resolved program; its diagnostic is the build's.
            error.NotResolved => return,
            else => return err,
        };
        defer bp.codegen.resolvedPrint.freeFiles(self.gpa, printed);
        for (printed) |f| {
            const path = try std.fs.path.join(self.gpa, &.{ self.dir, f.path });
            defer self.gpa.free(path);
            if (std.fs.path.dirname(path)) |parent| std.Io.Dir.cwd().createDirPath(self.io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
            try std.Io.Dir.cwd().writeFile(self.io, .{ .sub_path = path, .data = f.text });
            reporter.print("  wrote {s}\n", .{path});
        }
    }
};

/// The compiler a `.bpr` is written and read by (decision 805 (2),
/// `runtime_cache.stamp`).
pub fn runtimeStamp() runtime_file.Stamp {
    return runtime_cache.bprStamp();
}

/// `--emit-runtime`'s hook: the analysed program's `.bpr` set
/// (`runtime_cache.writeSet`, decision 805 (1)). A program one of whose
/// modules did not analyse writes none: its diagnostic is the build's.
const RuntimeSink = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    root: []const u8,
    deps: []const []const u8,
    wasm_host: bp.ast.WasmHost,
    /// `--emit-runtime`: each file written named on stderr (decision 798 (3));
    /// the cache root's set is written silently.
    announce: bool,
    /// The package's own key (decision 1006 (3)); the key written combines it
    /// with the packages the analysis loaded by name (1006 (6) P5,
    /// `libs.keyWithNamedLoads`), once the set is whole.
    base: runtime_cache.Key,
    /// The package's directory: the loads are kept relative to it.
    pkg_dir: []const u8,
    /// `--json`: the `.bpr` paths written, root's flagged, for the `runtime` events.
    written: ?*std.ArrayListUnmanaged(Written) = null,
    keep: std.mem.Allocator = undefined,
    /// The key the set was written under (null: none written), which the
    /// target key hashes (decision 1008 (1)).
    key_written: ?runtime_cache.Key = null,

    fn call(ctx: *anyopaque, outputs: []const bp.codegen.ComptimeOutput, readers: []const []const u8) anyerror!void {
        const self: *RuntimeSink = @ptrCast(@alignCast(ctx));
        for (outputs) |o| if (o.outcome != .ok) return;
        var arena_inst = std.heap.ArenaAllocator.init(self.gpa);
        defer arena_inst.deinit();
        const arena = arena_inst.allocator();
        const loads = try libs.relativeLoads(arena, self.io, self.pkg_dir, try bp.load.namedLoadsSince(arena, 0));
        const key = try libs.keyWithNamedLoads(arena, self.io, self.pkg_dir, self.base, loads);
        var written: std.ArrayListUnmanaged(Written) = .empty;
        try runtime_cache.writeSet(self.gpa, self.io, self.dir, .{ .root = self.root, .deps = self.deps, .wasm_host = self.wasm_host }, key, loads, outputs, readers, &written, arena);
        self.key_written = key;
        if (!self.announce) return;
        for (written.items) |w| {
            reporter.print("  wrote {s}\n", .{w.path});
            if (self.written) |list| try list.append(self.keep, .{ .path = try self.keep.dupe(u8, w.path), .root = w.root });
        }
    }
};

const Written = runtime_cache.Written;

// ── --json (decision 798 (6)) ────────────────────────────────────────────────

/// One JSON line on stdout. `fields` is a struct whose first field is the event.
fn jsonLine(arena: std.mem.Allocator, io: std.Io, value: anytype) void {
    var w: std.Io.Writer.Allocating = .init(arena);
    std.json.Stringify.value(value, .{}, &w.writer) catch return;
    w.writer.writeByte('\n') catch return;
    reporter.stdout(io, w.written());
}

/// What a `--json` build keeps for its closing events.
const Json = struct {
    arena: std.mem.Allocator,
    io: std.Io,
    written: std.ArrayListUnmanaged(Written) = .empty,
    modules: usize = 0,
};

var json_state: ?*Json = null;

/// `held`: the targets the package holds (decision 770, `libs.heldTargets`) —
/// its own `"targets"`, else its workspace's and its dependencies'; null when
/// the closure does not resolve (the build then refuses, and that refusal is
/// its answer). Resolved with nothing printed or captured: the build prints the
/// closure's refusal itself, once.
fn jsonTargets(j: *Json, gpa: std.mem.Allocator, proj: config.ProjectConfig, target: config.Target, env_map: libs.EnvMap) void {
    const all = [_][]const u8{ "commonJS", "erlang", "beam", "wasm" };
    const declared: []const []const u8 = proj.manifest.targets orelse &all;
    var discard: std.Io.Writer.Discarding = .init(&.{});
    const saved = .{ reporter.capture, reporter.sink, manifest.capture, manifest.sink };
    reporter.capture = null;
    manifest.capture = null;
    reporter.sink = &discard.writer;
    manifest.sink = &discard.writer;
    const held: ?[]const []const u8 = libs.heldTargets(gpa, j.io, j.arena, proj, env_map) catch null;
    reporter.capture, reporter.sink, manifest.capture, manifest.sink = saved;
    jsonLine(j.arena, j.io, .{ .event = "targets", .target = target.toString(), .targets = declared, .held = held });
}

fn jsonBuildLines(j: *Json, text: []const u8) void {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        // The text ends with its last newline: no event for the empty tail.
        if (lines.peek() == null and line.len == 0) break;
        jsonLine(j.arena, j.io, .{ .event = "build", .text = line });
    }
}

/// `<dir>/<group>.bpr` (`std/io` → `<dir>/std/io.bpr`).
fn runtimePath(arena: std.mem.Allocator, dir: []const u8, group: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), group, runtime_file.EXT });
}

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts_in: Options,
    env_map: libs.EnvMap,
) !u8 {
    if (opts_in.cache_root) |r| code_cache.root_override = r;
    var opts = opts_in;
    if (opts.workspace_out) |dir| opts.out_dir = dir;
    // At a workspace root, `build --target <t>` lays the workspace's one
    // folder, each member in its own process (decision 1015 (4)).
    if (opts.target) |t| if (opts.workspace_out == null and opts.runtime_input == null) {
        if (try workspace_out.atRoot(gpa, io, .{ .command = .build, .target = t, .out_dir = opts.out_dir, .cold = opts.cold, .cache_root = opts.cache_root }, env_map)) |code| return code;
    };
    if (!opts.json) return runBuild(gpa, io, opts, env_map);

    // `--json`: the build runs as without it (stderr unchanged, tee'd into
    // `captured`); its stdout is events. The `refused` events are the
    // refusals read back from what it printed (`refusals.refusalsOf`).
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    var captured: std.Io.Writer.Allocating = .init(arena);
    var state: Json = .{ .arena = arena, .io = io };
    json_state = &state;
    // A manifest's, a dependency's and a sidecar's located refusal is printed
    // by the manifest module (`Located.print`), beside `reporter.print`.
    reporter.capture = &captured.writer;
    manifest.capture = &captured.writer;
    defer {
        json_state = null;
        reporter.capture = null;
        manifest.capture = null;
    }
    const code = runBuild(gpa, io, opts, env_map) catch |err| {
        reporter.capture = null;
        manifest.capture = null;
        jsonLine(arena, io, .{ .event = "summary", .ok = false, .exit = @as(u8, 1), .refused = @as(usize, 0), .@"error" = @errorName(err) });
        return err;
    };
    reporter.capture = null;
    manifest.capture = null;
    const text = try refusals.stripAnsi(arena, captured.written());
    const found = try refusals.refusalsOf(arena, text);
    var count: usize = 0;
    for (found.keys(), found.values()) |module, sn| {
        for (sn.refusals) |r| {
            count += 1;
            jsonLine(arena, io, .{ .event = "refused", .module = module, .message = r.message, .at = r.at, .label = r.label, .from = r.from });
        }
    }
    for (state.written.items) |w| jsonLine(arena, io, .{ .event = "runtime", .path = w.path, .root = w.root });
    jsonLine(arena, io, .{ .event = "summary", .ok = code == 0, .exit = code, .refused = count });
    return code;
}

fn runBuild(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    env_map: libs.EnvMap,
) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    if (opts.cold) code_cache.cold = true;
    if (opts.runtime_input) |file| return (try runRuntime(gpa, io, arena, opts, file, env_map, null, null, null, null)).exit;

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    // A bare `build` emits no target (decision 1006 (2)); the manifest's
    // target still names the level B entries its analysis reads and writes.
    const target = opts.target orelse proj.parsedTarget() orelse {
        reportUnsupportedTarget(proj.target);
        return 1;
    };
    // erlang and beam: the `erl` on PATH runs the OTP release the compiler
    // emits for, or nothing is built (decision 228, `otp.zig`).
    if (opts.target != null and (target == .erlang or target == .beam) and !try otp.check(arena, io)) return 1;
    if (json_state) |j| jsonTargets(j, gpa, proj, target, env_map);

    // Resolve declared external libs from disk (generic — `libs/<name>/`). The
    // core never names a lib; it only sees these as ordinary `Module[]` and
    // resolves `from "<lib>"` through the shared import registry. `std` is the
    // embedded exception and is not loaded here.
    const entry_target: code_cache.EntryTarget = .{ .target = target, .host = proj.wasmHost() };
    var closure_keys: libs.ClosureKeys = .{ .arena = arena, .target = entry_target, .cache_root = analysis_store.root(proj), .want_runtime = true };
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

    // The `.bpr` set (decision 1006 (2), (3), `runtime_cache.zig`): fresh — its
    // key the one computed now, its root file this compiler's — it is built
    // from, with no comptime; else this build writes it, and its key, from
    // the same comptime pass that emits. `--cold` on `build` ignores the key;
    // `--emit-resolved` needs the analysis.
    // The key covers the packages the last analysis loaded by name (1006
    // (6) P5): one whose current key cannot be computed makes the set stale.
    runtime_cache.rebuild = opts.rebuild;
    // A package this build loads by name keeps its set under this build's
    // cache root (decision 1030 (1)).
    runtime_cache.load_root = analysis_store.root(proj);
    const rt_dir = opts.emit_runtime orelse try runtime_cache.dirFor(arena, proj);
    const rt_base = try runtime_cache.keyOf(arena, io, proj, &closure_keys, if (opts.emit_runtime) |d| &.{ opts.out_dir, d } else &.{opts.out_dir});
    const rt_key = try libs.keyWithNamedLoads(arena, io, proj.dir, rt_base, runtime_cache.loadsOf(arena, io, rt_dir, proj.name));
    // A member's build into its workspace's one folder (decision 1015 (4)).
    const shared: ?workspace_out.Shared = if (opts.workspace_out != null) .{ .runtime = &closure_keys.runtime, .rebuild = opts.rebuild } else null;
    if (!opts.rebuild and opts.emit_resolved == null and rt_key != null and runtime_cache.isFresh(arena, io, rt_dir, proj.name, rt_key.?, runtimeStamp())) {
        const t = opts.target orelse return 0;
        // Decision 1008 (1): the emit's own key matching and its entry artifact
        // present, nothing is emitted or compiled; else emit from the set and
        // write the key last.
        const packages = try libs.packagesOf(arena, proj, dep_modules);
        const tkey = targetKeyFor(proj, opts, t, rt_key.?);
        if (shared == null and !opts.rebuild and targetReused(arena, io, rt_dir, opts, t, tkey, packages)) return 0;
        if (shared == null) runtime_cache.removeTargetKey(arena, io, rt_dir, t);
        const root_bpr = try runtime_cache.rootPath(arena, rt_dir, proj.name);
        const built = (try runRuntime(gpa, io, arena, opts, root_bpr, env_map, opts.entry, proj, shared, &closure_keys.runtime)).exit;
        if (built == 0 and shared == null) runtime_cache.writeTargetKey(arena, io, rt_dir, t, tkey);
        return built;
    }
    if (opts.target) |t| if (shared == null) runtime_cache.removeTargetKey(arena, io, rt_dir, t);

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

    // The unit cache (decision 1008 (2), `unit_cache.zig`): a dependency's
    // units taken from it instead of emitted again; what this build emitted
    // of one is written there once the emit returned.
    const packages = try libs.packagesOf(arena, proj, dep_modules);
    const typings = opts.typescript or proj.manifest.typings;
    var units: unit_cache.Cache = undefined;
    try units.init(gpa, arena, io, analysis_store.root(proj), entry_target, packages, &closure_keys.runtime, .{ .wasm_artifact = true, .typedef = typings });

    // Build codegen config. The package names start every erlang/BEAM
    // module atom (decision 109).
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (typings) .typescript else null,
        .build_root = ".botopinkbuild",
        .packages = packages,
        .wasm_host = proj.wasmHost(),
        // The file a wasm build writes is what its host runs: the WASI
        // preview 2 component on `wasi` (decision 334).
        .wasm_artifact = true,
        .analysis_store = &level_b.store,
        .unit_cache = &units.iface,
        // Decision 1017 (5) — on wasm only the entry's component is written (it links
        // every body it reaches); a package with no such module keeps every unit.
        .wasm_entry_only = if (target == .wasm and hasModule(project_modules, opts.entry)) opts.entry else null,
    };

    // Run the compiler. `build` emits only: the program is not executed.
    var sink: ResolvedSink = undefined;
    var runtime_sink: RuntimeSink = undefined;
    var sinks: AnalysedSinks = .{};
    if (opts.emit_resolved) |dir| {
        sink = .{ .gpa = gpa, .io = io, .dir = dir, .root = proj.name, .deps = cfg.packages.deps };
        bp.comptime_pipeline.keep_resolved = true;
        sinks.resolved = &sink;
    }
    runtime_sink = .{ .gpa = gpa, .io = io, .dir = rt_dir, .root = proj.name, .deps = cfg.packages.deps, .wasm_host = cfg.wasm_host, .announce = opts.emit_runtime != null, .base = rt_base, .pkg_dir = proj.dir };
    if (json_state) |j| if (opts.emit_runtime != null) {
        runtime_sink.written = &j.written;
        runtime_sink.keep = j.arena;
    };
    sinks.runtime = &runtime_sink;
    const hook: bp.codegen.AnalysedHook = .{ .ctx = &sinks, .call = AnalysedSinks.call };
    if (opts.target == null) return analyseOnly(gpa, io, arena, modules, cfg, &sinks, &level_b, loaded.orphans.len, t0);
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
    // on stderr. A build whose messages are redirected (`reporter.sink` set)
    // keeps it out of its own output.
    if (json_state) |j| {
        j.modules = outputs.items.len;
        for (outputs.items) |o| if (o.result.build_output.len > 0) jsonBuildLines(j, o.result.build_output);
    } else if (reporter.sink == null) for (outputs.items) |o| if (o.result.build_output.len > 0) reporter.stdout(io, o.result.build_output);
    const failed = try diagnostics.failedOutputs(gpa, io, arena, modules, outputs.items, cfg.wasm_entry_only != null);

    // Write what compiled; remove any previous artifact of a module that did not,
    // so nothing stale is left claiming to be current.
    writeOutputs(gpa, io, arena, outputs.items, opts.out_dir, target, cfg.packages, cfg.wasm_host, env_map, shared, cfg.typeDefLanguage != null) catch |err| switch (err) {
        // A sidecar the build cannot ship: the located refusal is already
        // printed by the shipper, and the build ends here with exit 1.
        error.SidecarRefused => return 1,
        else => return err,
    };
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target, cfg.packages);

    // erlang: emitted text is not yet a program — the OTP compiler must accept
    // it. Every `.erl` this build wrote whose `.beam` record does not match is
    // compiled into its `.beam` beside it (decision 1007) and one it refuses
    // fails the build, so "it builds on erlang" means what it says.
    const erl_ok = if (target == .erlang)
        try checkErlang(arena, io, outputs.items, opts.out_dir, cfg.packages, try code_cache.dir(arena, proj), opts.rebuild)
    else
        true;

    diagnostics.reportOrphans(arena, loaded.orphans.len);

    if (failed.len > 0) {
        diagnostics.reportFailedModules(arena, failed);
        return 1;
    }
    if (!erl_ok) return 1;

    if (opts.target) |t| if (shared == null) if (runtime_sink.key_written) |k| runtime_cache.writeTargetKey(arena, io, rt_dir, t, targetKeyFor(proj, opts, t, k));
    reporter.compiled(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}

/// The target key of this emit (decision 1008 (1), `runtime_cache.targetKey`).
fn targetKeyFor(proj: config.ProjectConfig, opts: Options, target: config.Target, bpr_key: runtime_cache.Key) runtime_cache.Key {
    return runtime_cache.targetKey(.{
        .bpr_key = bpr_key,
        .target = target,
        .wasm_host = proj.wasmHost(),
        .typings = opts.typescript or proj.manifest.typings,
        .out_dir = opts.out_dir,
        .entry = opts.entry,
    });
}

/// Whether the emit into `opts.out_dir` is already what `tkey` names: the
/// target key file holds it and the entry's artifact is there (decision 1008 (1)).
fn targetReused(
    arena: std.mem.Allocator,
    io: std.Io,
    rt_dir: []const u8,
    opts: Options,
    target: config.Target,
    tkey: runtime_cache.Key,
    packages: bp.codegen.crossModule.Packages,
) bool {
    if (!runtime_cache.targetMatches(arena, io, rt_dir, target, tkey)) return false;
    const entry = artifactPath(arena, opts.out_dir, target, packages, opts.entry, artifactExt(target)) catch return false;
    std.Io.Dir.cwd().access(io, entry, .{}) catch return false;
    return true;
}

/// A bare `build` (decision 1006 (2)): the comptime pass alone, for no target
/// (798 (4)), its `.bpr` set and key written by `sinks`, no `out/`. What the
/// build bodies printed goes to stdout in build order, as a target's build
/// prints it; each module's diagnostics are rendered as `check` renders them.
fn analyseOnly(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    modules: []const Module,
    cfg: bp.codegen.Config,
    sinks: *AnalysedSinks,
    level_b: *analysis_store.Cache,
    orphans: usize,
    t0: std.Io.Timestamp,
) !u8 {
    var session = bp.codegen.analyse(gpa, modules, io, cfg) catch |err| {
        reporter.errMsg("compilation failed");
        reporter.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer session.deinit(gpa);
    try AnalysedSinks.call(sinks, session.outputs.items, session.readers);
    level_b.commit();
    const t1 = std.Io.Timestamp.now(io, .awake);

    for (session.outputs.items) |o| {
        const text = switch (o.outcome) {
            .ok => |ok| ok.build_output,
            .typeError, .validationError => if (o.target_trace) |t| t.build_output else "",
            .parseError => "",
        };
        if (text.len == 0) continue;
        if (json_state) |j| jsonBuildLines(j, text) else if (reporter.sink == null) reporter.stdout(io, text);
    }
    if (json_state) |j| j.modules = session.outputs.items.len;
    var failed: std.ArrayListUnmanaged([]const u8) = .empty;
    for (session.outputs.items) |o| {
        if (diagnostics.renderOutcome(gpa, io, arena, o)) try failed.append(arena, o.name);
    }
    diagnostics.reportOrphans(arena, orphans);
    if (failed.items.len > 0) {
        diagnostics.reportFailedModules(arena, failed.items);
        return 1;
    }
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
    /// The project a fresh `.bpr` set is built for (decision 1006 (2)), its
    /// manifest read: its directory is the working one, its code cache and
    /// `"typings"` its own. Null for a `.bpr` named on the command line.
    project: ?config.ProjectConfig,
    /// `--workspace-out`'s keys (`workspace_out.Shared`); null otherwise.
    shared: ?workspace_out.Shared,
    /// The `.bpr` keys of the program's dependencies
    /// (`libs.ClosureKeys.runtime`): the unit cache's keys (decision 1008
    /// (2)). Null for a `.bpr` named on the command line: every unit emitted.
    runtime_keys: ?*const std.StringHashMapUnmanaged(unit_cache.Key),
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
    if (project == null and !inItsProject(arena, io, file, meta.root)) return .{ .exit = 1 };

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
    const proj: config.ProjectConfig = project orelse .{ .name = meta.root };
    const typings = opts.typescript or (project != null and proj.manifest.typings);
    const packages: bp.codegen.crossModule.Packages = .{ .root = meta.root, .deps = meta.deps };
    // The unit cache (decision 1008 (2)), as a direct build reads it; a
    // dependency module the root's file holds answers for the whole program.
    var units: unit_cache.Cache = undefined;
    if (runtime_keys) |keys| {
        try units.init(gpa, arena, io, analysis_store.root(proj), .{ .target = target, .host = meta.wasm_host }, packages, keys, .{ .wasm_artifact = true, .typedef = typings });
        units.iface.readers = try unit_cache.readersOf(arena, packages, meta.program);
    }
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (typings) .typescript else null,
        .build_root = ".botopinkbuild",
        .packages = packages,
        .wasm_host = meta.wasm_host,
        .wasm_artifact = true,
        // Decisions 1008 (3), 1017 (5) — only the entry's component is emitted on
        // wasm (`run` executes it alone); a program with no such module keeps every unit.
        .wasm_entry_only = if (target == .wasm) wasmEntry(outputs, entry orelse opts.entry) else null,
        .unit_cache = if (runtime_keys != null) &units.iface else null,
    };
    var emitted = try bp.codegen.emit(gpa, outputs, cfg);
    defer {
        for (emitted.items) |*o| o.result.deinit(gpa);
        emitted.deinit(gpa);
    }
    if (runtime_keys != null) units.iface.record(emitted.items);
    const failed = try diagnostics.failedOutputs(gpa, io, arena, &.{}, emitted.items, false);
    writeOutputs(gpa, io, arena, emitted.items, opts.out_dir, target, cfg.packages, cfg.wasm_host, env_map, shared, cfg.typeDefLanguage != null) catch |err| switch (err) {
        error.SidecarRefused => return .{ .exit = 1 },
        else => return err,
    };
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target, cfg.packages);
    const erl_ok = if (target == .erlang)
        try checkErlang(arena, io, emitted.items, opts.out_dir, cfg.packages, try code_cache.dir(arena, proj), opts.rebuild)
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
fn hasModule(modules: []const Module, name: []const u8) bool {
    for (modules) |m| if (std.mem.eql(u8, m.path, name)) return true;
    return false;
}

fn wasmEntry(outputs: []const bp.codegen.ComptimeOutput, name: []const u8) ?[]const u8 {
    for (outputs) |o| if (std.mem.eql(u8, o.name, name)) return name;
    return null;
}

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
/// (one process per scheduler, `compile:file(F, [deterministic,
/// return_errors, {outdir, …}])` — each `.beam` beside its `.erl`, its record
/// beside it once the job succeeded, `beam_record.zig`; a module whose record
/// matches is not compiled, `build --cold` compiling every one), and print each
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
/// project's own modules are compiled when their record does not match
/// (decision 1007). A DEPENDENCY's module (std,
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
    /// `build --cold`: every module compiled, whatever its record says
    /// (decision 1007 (3)).
    rebuild: bool,
) !bool {
    // The files go through list files, never the command line: one path per
    // module made `erl`'s argv grow with the program, and a 203-module build
    // with a deep `--out` passed macOS's 1 MiB `ARG_MAX` (`arglist.zig`).
    var own = std.ArrayListUnmanaged(beam_record.Pair).empty;
    var deps = std.ArrayListUnmanaged(beam_record.Pair).empty;
    for (outputs) |o| {
        if (o.result.failed()) continue;
        const list = if (packages.idOf(o.name).package_in_path) &deps else &own;
        try list.append(arena, try erlPair(arena, try artifactPath(arena, out_dir, .erlang, packages, o.name, ".erl")));
        for (o.result.units) |u| {
            try list.append(arena, try erlPair(arena, try std.fmt.allocPrint(arena, "{s}/{s}{s}.erl", .{ out_dir, targetSubdir(.erlang), u.atom })));
        }
    }
    // Decision 1007: a module whose `.beam` beside it carries the record of
    // its `.erl`'s bytes, this compiler and this OTP release was checked and
    // compiled already; it is loaded as it is.
    const own_todo = try beam_record.stale(arena, io, own.items, rebuild);
    const dep_todo = try beam_record.stale(arena, io, deps.items, rebuild);
    const total = own_todo.len + dep_todo.len;
    if (total == 0) return true;
    const own_list = try arglist.write(arena, io, try beam_record.sources(arena, own_todo));
    defer arglist.remove(io, own_list);
    const dep_list = try arglist.write(arena, io, try beam_record.sources(arena, dep_todo));
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
    if (code == 0) {
        beam_record.writeAll(arena, io, own_todo);
        beam_record.writeAll(arena, io, dep_todo);
        return true;
    }
    reporter.errMsg("the OTP compiler refused emitted erlang — the build is not a program");
    return false;
}

/// `<dir>/<atom>.erl` and the `.beam` its compile writes beside it.
fn erlPair(arena: std.mem.Allocator, src: []const u8) !beam_record.Pair {
    const stem = src[0 .. src.len - ".erl".len];
    return .{ .src = src, .beam = try std.mem.concat(arena, u8, &.{ stem, ".beam" }) };
}

/// The check `checkErlang` runs in one `erl`: the plain arguments are the code
/// cache's directory and mode (`code_cache.ERL_FUNS`) and the list files of
/// the project's own `.erl` and of its dependencies' (`arglist.write`); the
/// files are dealt round-robin to one process per online scheduler, each
/// compiling its share in memory — a dependency's through `CodeDep`, answered
/// from the store when it is there and its `.beam` materialised beside its
/// `.erl` (decisions 509 (4), 767: what `run` links, so a consumer of the
/// output compiles only the project's own modules); every refusal is printed as
/// `<file>:<line>: <message>`; exit 1 when there is any. The own modules are
/// compiled `deterministic` into their `.beam` beside the `.erl` (decision
/// 1007 (2)), which a `run` then loads as it is; `deterministic` names a file
/// by its base name, so a refusal's file is given back as the path the job
/// was handed (`Named`), the text it had.
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
    \\    Named = fun(File) -> case File =:= filename:basename(F) of true -> F; false -> File end end,
    \\    case catch compile:file(F, [deterministic, return_errors, {outdir, filename:dirname(F)}]) of
    \\        {ok, _} -> [];
    \\        {ok, _, _} -> [];
    \\        {ok, _, _, _} -> [];
    \\        {error, Errors, _} ->
    \\            [io_lib:format("~ts:~ts: ~ts~n", [Named(File), Loc(L), M:format_error(D)])
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
/// Decision 1015: every target's output is FLAT, each module once, named
/// `<pkg>@<path>` (`crossModule.outputStem`). `erlc` refuses a `-module` atom
/// that differs from its file's basename, so an erlang or BEAM artifact is
/// named by the module ATOM (`std/math` → `std@math.erl`) — the only shape
/// `erl -pa <one directory>` can load a multi-module program from; commonJS
/// and its `.d.ts` take the same name (`std@math.js`, `std@math.d.ts`), each
/// `require` naming a sibling. wasm keeps the module path.
///
/// Decision 1023: the folder is named by the target, literally — `out/commonJS/`,
/// `out/erlang/`, `out/beam/`, `out/wasm/` — for a package's build and a
/// workspace root's alike; an `--out <dir>` names the base the folder goes under.
pub fn targetSubdir(target: config.Target) []const u8 {
    return switch (target) {
        .commonJS => "commonJS/",
        .erlang => "erlang/",
        .beam => "beam/",
        .wasm => "wasm/",
    };
}

/// `<out_dir>/<subdir><stem><ext>` for one module — the stem is the module's
/// flat name for erlang, BEAM and commonJS (its package first, decisions 109,
/// 1015), the module path for wasm. Caller owns it.
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

/// One module's files: written in place, or through the shared folder's
/// writer when the build has one (`workspace_out.Once`).
const FileWriter = struct {
    io: std.Io,
    once: ?*workspace_out.Once,
    pkg: ?[]const u8,

    fn write(self: FileWriter, path: []const u8, bytes: []const u8) !void {
        if (self.once) |w| return w.write(self.pkg, path, bytes);
        try std.Io.Dir.cwd().writeFile(self.io, .{ .sub_path = path, .data = bytes });
    }
};

/// `<out_dir>/std@__rt.wasm`, the runtime core, and `<out_dir>/std@<path>.wasm`
/// for each std unit the program `bin` reaches (decisions 1021 (2), 1026), each
/// left alone when the file already holds its bytes: they are the compiler's
/// alone, the same for every program of one compiler build.
fn writeRuntimeUnits(gpa: std.mem.Allocator, io: std.Io, out_dir: []const u8, bin: []const u8) !void {
    const ru = bp.codegen.wasmRuntimeUnit;
    const rt = ru.get() catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.RuntimeUnitUnavailable,
    };
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    try writeIfChanged(ar, io, out_dir, ru.file_name, rt.core_bytes);
    const im = try ru.importsOf(ar, bin);
    for (try rt.closure(ar, im.units)) |u| try writeIfChanged(ar, io, out_dir, u.file_name, u.bytes);
}

fn writeIfChanged(ar: std.mem.Allocator, io: std.Io, out_dir: []const u8, file: []const u8, bytes: []const u8) !void {
    const path = try std.fs.path.join(ar, &.{ out_dir, file });
    if (std.Io.Dir.cwd().readFileAlloc(io, path, ar, .limited(bytes.len + 1))) |have| {
        if (std.mem.eql(u8, have, bytes)) return;
    } else |_| {}
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = bytes });
}

fn writeOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    target: config.Target,
    packages: bp.codegen.crossModule.Packages,
    wasm_host: bp.ast.WasmHost,
    env_map: libs.EnvMap,
    /// `--workspace-out` (decision 1015 (4)): each dependency's files
    /// written once per its key (`workspace_out.Once`); null writes every file.
    shared: ?workspace_out.Shared,
    /// Whether this build writes `.d.ts` files — part of a dependency's key.
    typings: bool,
) !void {
    // Ensure output directory exists.
    std.Io.Dir.cwd().createDirPath(io, out_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext = artifactExt(target);
    const folder = try std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, targetSubdir(target) });
    var once: ?workspace_out.Once = if (shared) |sh|
        try workspace_out.Once.begin(arena, io, sh, folder, packages.deps, target.toString(), @tagName(wasm_host), typings)
    else
        null;

    for (outputs) |o| {
        // The dependency the module is of (null: the member's own), and the
        // writer of its files: in place, or once per the package's key.
        const pkg = libs.sidecarPackage(packages, o.name);
        // A validation error carries no artifact.
        if (o.result.failed()) {
            if (once) |*w| try w.markFailed(pkg);
            continue;
        }
        if (once) |*w| if (w.skips(pkg)) continue;
        var file: FileWriter = .{ .io = io, .once = if (once) |*w| w else null, .pkg = pkg };
        // erlang/BEAM: `out/<target>/<atom><ext>`, commonJS
        // `out/commonJS/<pkg>@<path>.js`, flat (decisions 1015, 1023). wasm:
        // `out/wasm/<module path><ext>`, so subdirectories may have to be created.
        const sub_path = try artifactPath(gpa, out_dir, target, packages, o.name, ext);
        defer gpa.free(sub_path);

        // Ensure parent directory exists.
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }

        try file.write(sub_path, o.result.js);

        // Decision 334: a `browser` build is the module's binary and the
        // loader that instantiates it with a browser's imports (node runs it
        // too) — `<module>.wasm` and `<module>.mjs` beside the `.wat`.
        if (target == .wasm and wasm_host == .browser) {
            const bin = o.result.wasm orelse return error.MissingWasmBinary;
            const wasm_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".wasm");
            defer gpa.free(wasm_path);
            try file.write(wasm_path, bin);
            const loader_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".mjs");
            defer gpa.free(loader_path);
            const loader = try bp.codegen.wasmBrowserLoader.render(gpa, std.fs.path.basename(wasm_path));
            defer gpa.free(loader);
            try file.write(loader_path, loader);
        }

        // Policy 3 (`13-module-identity`): every `type` of the module is a
        // module of its own on erlang/beam — `out/<target>/<type atom><ext>`,
        // flat beside the file's, which is where `erl -pa` loads it from.
        for (o.result.units) |u| {
            const unit_path = try std.fmt.allocPrint(gpa, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), u.atom, ext });
            defer gpa.free(unit_path);
            try file.write(unit_path, u.code);
        }

        // Optional TypeScript typedef.
        if (o.result.typedef) |td| {
            const dts_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".d.ts");
            defer gpa.free(dts_path);
            try file.write(dts_path, td);
        }
    }
    if (once) |*w| try w.finish();

    // Decisions 1021 (2), 1026 — a `wasi` program imports the runtime core
    // and std's units: `std@__rt.wasm` and the units it reaches beside the
    // program's, each written once per compiler build.
    if (target == .wasm and wasm_host == .wasi) for (outputs) |o| {
        const bin = o.result.wasm orelse continue;
        if (o.result.failed() or !bp.codegen.wasmRuntimeUnit.importsRuntime(bin)) continue;
        try writeRuntimeUnits(gpa, io, out_dir, bin);
    };

    // Ship runtime `.mjs` sidecars (G2) so a built program resolves every
    // `#[@external(.JavaScript(…))]` `require("…/x.mjs")` — each flat beside the
    // modules as `<pkg>@<base>` (decision 1015).
    if (target == .commonJS) {
        try libs.shipMjsSidecars(gpa, io, outputs, packages, std.mem.trimEnd(u8, folder, "/"), ext, env_map);
    }
    // erlang and BEAM: a `#[@external(.Erlang("host:fn($0)"))]`'s `host.erl` goes
    // beside the emitted modules — `out/erlang/`, where `botopink run` compiles
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
