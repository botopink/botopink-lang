const std = @import("std");
const moduleOutput = @import("./codegen/moduleOutput.zig");
const configMod = @import("./codegen/config.zig");
const commonJS = @import("./codegen/commonJS.zig");
const erlang = @import("./codegen/erlang.zig");
const beam_asm = @import("./codegen/beam_asm.zig");
const wat = @import("./codegen/wat.zig");
const comptimeMod = @import("./comptime.zig");
const TypeError = @import("./comptime/error.zig").TypeError;
const loadMod = @import("./comptime/load.zig");
const moduleMod = @import("./module.zig");
const runtime = @import("./codegen/runtime.zig");
const hostRuntime = @import("./comptime/runtime/runtime.zig");
/// Decision 798 (4) — the target's checks over the analysed tree, at emit.
pub const targetCheck = @import("./codegen/target_check.zig");
pub const loadedTargets = @import("./codegen/loaded_targets.zig");

pub const Module = moduleMod.Module;
pub const ModuleOutput = moduleOutput.ModuleOutput;
/// A module's extra units (a `type`'s module, the test unit — decision 513).
pub const Unit = moduleOutput.Unit;
pub const ComptimeSession = comptimeMod.ComptimeSession;
pub const ComptimeOutput = comptimeMod.ComptimeOutput;

pub const Config = configMod.Config;
pub const TargetSource = configMod.TargetSource;
/// The module-atom / output-stem rules a driver needs to name an artifact:
/// `outputStem` (erlang, BEAM and commonJS take the module's flat name — its
/// ATOM, decision 1015 — wasm the module path) and `erlAtom` beside it.
pub const crossModule = @import("./codegen/crossModule.zig");
/// The unit cache an emit reads (decision 1008 (2)).
pub const unitCache = @import("./codegen/unit_cache.zig");
/// Decision 334 — the loader a wasm build for the `browser` host writes
/// beside its `.wasm` (`botopink build`).
pub const wasmBrowserLoader = @import("./codegen/wat/browser_loader.zig");
pub const wasmNeeds = @import("./codegen/wat/needs.zig");
pub const wasmRuntimeUnit = @import("./codegen/wat/runtime_unit.zig");
/// The embedded wasmtime engine and its `.cwasm` cache, and the in-process
/// runner over it (decisions 1032, 1034); native builds only.
pub const wasmEngine = if (@import("builtin").cpu.arch.isWasm()) struct {} else @import("./codegen/wat/engine.zig");
pub const wasmRunner = if (@import("builtin").cpu.arch.isWasm()) struct {} else @import("./codegen/wat/runner.zig");

/// What `generateWith` does after emitting each module.
pub const Options = struct {
    /// Run every emitted module through its target runtime
    /// (`runtime.execute*`) and keep the program's output on
    /// `GenerateResult.run_output`. Only the codegen snapshot harness sets it:
    /// the RUN LOG section is its evidence. `botopink build`, `test` and `run`
    /// leave it off — compiling a program must not execute it (no `node`,
    /// `erl` or `wasmtime` spawn, no runtime-cache entry, no side effect at
    /// build time).
    execute: bool,
    /// Called once with the analysed session, before the emit: the hook
    /// `--emit-resolved` prints the resolved program through (decision 798
    /// (2), `comptime/resolved_print.zig`).
    on_analysed: ?AnalysedHook = null,
    /// `wasmtime`'s compilation cache directory for `execute` on wasm
    /// (`<cache root>/.botopinkbuild/cache/wasmtime`); null, the working
    /// directory's own `.botopinkbuild` (decision 1008 (5)).
    wasmtime_cache_dir: ?[]const u8 = null,
};

/// A driver's look at the analysed modules (`Options.on_analysed`).
pub const AnalysedHook = struct {
    ctx: *anyopaque,
    /// `readers`: the paths of the modules that read `@TypeInfo.all`.
    call: *const fn (ctx: *anyopaque, outputs: []const ComptimeOutput, readers: []const []const u8) anyerror!void,
};

/// Decision 798 (1) — the resolved program's printer.
pub const resolvedPrint = @import("./comptime/resolved_print.zig");

/// The codegen snapshot harness's entry (`codegen/tests/helpers.zig`): emit
/// **and execute** every module. Drivers call `generateWith` with
/// `.execute = false`.
///
/// Returns only the modules that reached codegen or failed comptime
/// validation: an entry carrying a lex/parse/type `diagnostic` is dropped,
/// because the harness derives those diagnostics from its own comptime run
/// and renders a section for every entry it is given.
pub fn generate(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    config: Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var outputs = try generateWith(allocator, modules, io, config, .{ .execute = true });
    var kept: usize = 0;
    for (outputs.items) |*o| {
        if (o.result.diagnostic != null) {
            o.result.deinit(allocator);
            continue;
        }
        outputs.items[kept] = o.*;
        kept += 1;
    }
    outputs.shrinkRetainingCapacity(kept);
    return outputs;
}

/// Decision 57 — copy each module's `OkData.warnings` onto its output before
/// the comptime session that owns them is freed (front 26 step 4: `build` and
/// `test` print them as `check` does). Matched by module name; a module that
/// emitted no output has nothing to carry them.
fn attachWarnings(allocator: std.mem.Allocator, session: []const ComptimeOutput, outputs: []ModuleOutput, refused: []const []const u8) !void {
    for (session) |ct| {
        const ok = switch (ct.outcome) {
            .ok => |ok| ok,
            // Decision 904 — a module analysis refused still prints what its
            // build bodies printed before the refusal.
            .typeError, .validationError => {
                const trace = ct.target_trace orelse continue;
                if (trace.build_output.len == 0) continue;
                for (outputs) |*o| {
                    if (!std.mem.eql(u8, o.name, ct.name) or o.result.build_output.len > 0) continue;
                    o.result.build_output = try allocator.dupe(u8, trace.build_output);
                    break;
                }
                continue;
            },
            else => continue,
        };
        // A module the target refused at emit is a failed module, as one its
        // analysis refused (decision 798 (4)).
        if (for (refused) |r| {
            if (std.mem.eql(u8, r, ct.name)) break true;
        } else false) continue;
        // Decision 788 (3) — the build's output travels the same way.
        if (ok.build_output.len > 0) for (outputs) |*o| {
            if (!std.mem.eql(u8, o.name, ct.name) or o.result.build_output.len > 0) continue;
            o.result.build_output = try allocator.dupe(u8, ok.build_output);
            break;
        };
        if (ok.warnings.len == 0) continue;
        for (outputs) |*o| {
            if (!std.mem.eql(u8, o.name, ct.name) or o.result.warnings.len > 0) continue;
            const ws = try allocator.alloc(moduleOutput.Diagnostic.TypeDiagnostic, ok.warnings.len);
            var filled: usize = 0;
            errdefer {
                for (ws[0..filled]) |w| allocator.free(w.message);
                allocator.free(ws);
            }
            for (ok.warnings, ws) |w, *out| {
                out.* = .{ .message = try w.message(allocator), .loc = w.loc };
                filled += 1;
            }
            o.result.warnings = ws;
            break;
        }
    }
}

/// The comptime pass of `generateWith` alone: every module analysed, for no
/// target — comptime never reads the target (decision 798 (4)), so one
/// analysis serves every backend; what depends on the target is `emit`'s
/// (`codegen/target_check.zig`). The caller owns the session (`deinit`).
pub fn analyse(allocator: std.mem.Allocator, modules: []const Module, io: std.Io, config: Config) !ComptimeSession {
    // The comptime pass runs on the wasm runtime whatever the target
    // (decision 434).
    return comptimeMod.compileWith(allocator, modules, io, config.build_root, config.analysis_store);
}

/// The emit of `generateWith` alone, over analysed `outputs` — the session's,
/// or ones read back from the code cache's level B (144 B-60). An emitter may
/// rewrite an output's AST in place: an entry is encoded before this runs.
///
/// First the target's own checks over the analysed tree
/// (`codegen/target_check.zig`, decision 798 (4)): a module the target
/// refuses is emitted as a failed module, and its analysis is handed back
/// once the emit returns.
pub fn emit(allocator: std.mem.Allocator, outputs: []ComptimeOutput, config: Config) !std.ArrayListUnmanaged(ModuleOutput) {
    return emitChecked(allocator, outputs, config, null);
}

/// `emit`, naming in `refused_names` (when given) each module the target
/// refused: it carries no warnings and no build output, as a module refused
/// by its analysis does not (`attachWarnings`).
fn emitChecked(
    allocator: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: Config,
    refused_names: ?*std.ArrayListUnmanaged([]const u8),
) !std.ArrayListUnmanaged(ModuleOutput) {
    var scratch = std.heap.ArenaAllocator.init(allocator);
    defer scratch.deinit();
    const lookup = targetCheck.lookupName(config);
    const kept = try targetCheck.withoutBeamStorage(scratch.allocator(), outputs, lookup);
    const analysed = kept orelse outputs;
    defer if (kept) |k| targetCheck.writeBack(outputs, k);
    // Decision 989 (3) — a loaded package the target refuses answers its
    // `run()` instead of failing the build; one whose manifest leaves the
    // target out and that compiles there is refused.
    const loaded = try loadedTargets.apply(scratch.allocator(), analysed, config);
    const emitted = loaded.outputs orelse analysed;
    defer loadedTargets.writeBack(analysed, loaded);
    const refused = try targetCheck.apply(scratch.allocator(), emitted, lookup);
    defer targetCheck.restore(emitted, refused);
    // Decisions 853, 890 — two modules folding to one module atom (and two
    // types of one module folding to one type atom) are refused on every
    // target, before any backend.
    const paired = try pairRefusals(scratch.allocator(), emitted, config.packages, refused);
    defer targetCheck.restore(emitted, paired);
    if (refused_names) |names| for (paired) |r| try names.append(allocator, emitted[r.index].name);
    if (refused_names) |names| for (refused) |r| try names.append(allocator, emitted[r.index].name);
    return switch (config.targetSource) {
        .commonJS => commonJS.codegenEmit(allocator, emitted, config),
        .erlang => erlang.codegenEmit(allocator, emitted, config),
        .beam => beam_asm.codegenEmit(allocator, emitted, config),
        .wasm => wat.codegenEmit(allocator, emitted, config),
    };
}

/// Turn each module `crossModule.pairFaults` names into a `typeError` for the
/// emit alone (`restore` hands the analysis back); a module `already` refused
/// by the target keeps that refusal.
fn pairRefusals(arena: std.mem.Allocator, outputs: []ComptimeOutput, packages: crossModule.Packages, already: []const targetCheck.Refusal) ![]const targetCheck.Refusal {
    var faults = try crossModule.pairFaults(arena, outputs, packages);
    var out: std.ArrayListUnmanaged(targetCheck.Refusal) = .empty;
    if (faults.count() == 0) return out.items;
    for (outputs, 0..) |*o, i| {
        const fault = faults.get(o.name) orelse continue;
        if (targetCheck.isRefused(outputs, already, o.name)) continue;
        try out.append(arena, .{ .index = i, .saved = o.outcome });
        o.outcome = .{ .typeError = TypeError.custom(try fault.message(arena), null) };
    }
    return out.items;
}

/// Compile `modules` for `config.targetSource`. Executes the emitted modules
/// only when `options.execute` is set. Every module comes back: one that did
/// not lex, parse or type-check carries its `result.diagnostic`, one that
/// failed comptime validation its `result.comptime_err`.
pub fn generateWith(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    config: Config,
    options: Options,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var session = try analyse(allocator, modules, io, config);
    defer session.deinit(allocator);
    if (options.on_analysed) |hook| try hook.call(hook.ctx, session.outputs.items, session.readers);
    // The unit cache (decision 1008 (2)): a dependency module whose unit it
    // holds is not emitted again — never a module answering for the whole
    // program — and once the emit returned the store keeps what it will, while
    // the session's `readers` live. `botopink test` too: a dependency gets no
    // test unit and its production unit does not depend on `test_mode`
    // (decision 513).
    const cfg = config;
    if (cfg.unit_cache) |u| u.readers = session.readers;
    defer if (cfg.unit_cache) |u| {
        u.readers = &.{};
    };
    var refused: std.ArrayListUnmanaged([]const u8) = .empty;
    defer refused.deinit(allocator);
    var outputs = try emitChecked(allocator, session.outputs.items, cfg, &refused);
    errdefer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    if (cfg.unit_cache) |u| u.record(outputs.items);
    try attachWarnings(allocator, session.outputs.items, outputs.items, refused.items);

    // A host that cannot spawn a process (the browser build, front 18 step 5)
    // has no executor: the harness's `execute` is refused there rather than
    // answered with an empty RUN LOG, and `codegen/runtime.zig` is never
    // analysed for it.
    if (comptime !hostRuntime.can_spawn) {
        if (options.execute) return error.NoExecutorOnThisHost;
        return outputs;
    }
    if (!options.execute) return outputs;

    // Sibling modules (multi-module compilations, e.g. the "std" package) are
    // written next to each entry so `require`/remote calls resolve at runtime.
    var aux_files: std.ArrayListUnmanaged(runtime.AuxFile) = .empty;
    defer aux_files.deinit(allocator);
    var arena_aux = std.heap.ArenaAllocator.init(allocator);
    defer arena_aux.deinit();
    for (outputs.items) |o| {
        if (!o.result.failed() and o.name.len > 0) {
            // A dependency's module is named by its own package's atom
            // (decision 109), which the harness's `test` package would not give.
            const id = config.packages.idOf(o.name);
            const atom: ?[]const u8 = if (id.package_in_path) crossModule.erlAtom(arena_aux.allocator(), id) catch null else null;
            try aux_files.append(allocator, .{ .name = o.name, .code = o.result.js, .atom = atom });
            // Policy 3: every `type` of the module is a module of its own on
            // erlang/beam, compiled and loaded beside the file's.
            for (o.result.units) |u| try aux_files.append(allocator, .{ .name = u.atom, .code = u.code, .atom = u.atom });
        }
    }

    // Execute generated code and capture output
    for (outputs.items) |*output| {
        if (!output.result.failed()) {
            output.result.run_output = switch (config.targetSource) {
                // Decision 513: under `botopink test` the module's test unit
                // runs, its production module beside it.
                .commonJS => if (output.result.test_unit) |unit|
                    runtime.executeTestModule(allocator, io, .commonJS, output.result.js, unit) catch |err| blk: {
                        const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                        break :blk err_msg;
                    }
                else
                    runtime.executeJavaScript(allocator, output.result.js, aux_files.items, io) catch |err| blk: {
                        const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                        break :blk err_msg;
                    },
                .erlang => runtime.executeErlang(allocator, output.result.js, output.name, aux_files.items, io) catch |err| blk: {
                    const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                    break :blk err_msg;
                },
                .beam => runtime.executeBeamAsm(allocator, output.result.js, output.name, aux_files.items, io) catch |err| blk: {
                    const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                    break :blk err_msg;
                },
                .wasm => runtime.executeWatIn(allocator, output.result.js, output.result.wasm, output.name, options.wasmtime_cache_dir, io) catch |err| blk: {
                    const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                    break :blk err_msg;
                },
            };
        }
    }

    return outputs;
}
