const std = @import("std");
const moduleOutput = @import("./codegen/moduleOutput.zig");
const configMod = @import("./codegen/config.zig");
const commonJS = @import("./codegen/commonJS.zig");
const erlang = @import("./codegen/erlang.zig");
const beam_asm = @import("./codegen/beam_asm.zig");
const wat = @import("./codegen/wat.zig");
const comptimeMod = @import("./comptime.zig");
const loadMod = @import("./comptime/load.zig");
const moduleMod = @import("./module.zig");
const runtime = @import("./codegen/runtime.zig");
const hostRuntime = @import("./comptime/runtime/runtime.zig");
/// Decision 798 (4) — the target's checks over the analysed tree, at emit.
pub const targetCheck = @import("./codegen/target_check.zig");

pub const Module = moduleMod.Module;
pub const ModuleOutput = moduleOutput.ModuleOutput;
/// A module's extra units (a `type`'s module, the test unit — decision 513).
pub const Unit = moduleOutput.Unit;
pub const ComptimeSession = comptimeMod.ComptimeSession;
pub const ComptimeOutput = comptimeMod.ComptimeOutput;

pub const Config = configMod.Config;
pub const TargetSource = configMod.TargetSource;
/// The module-atom / output-stem rules a driver needs to name an artifact:
/// `outputStem` (erlang and BEAM take the module ATOM, commonJS and wasm the
/// module path) and `erlAtom` beside it.
pub const crossModule = @import("./codegen/crossModule.zig");
/// Decision 334 — the loader a wasm build for the `browser` host writes
/// beside its `.wasm` (`botopink build`).
pub const wasmBrowserLoader = @import("./codegen/wat/browser_loader.zig");
pub const wasmNeeds = @import("./codegen/wat/needs.zig");

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
};

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
    const emitted = kept orelse outputs;
    defer if (kept) |k| targetCheck.writeBack(outputs, k);
    const refused = try targetCheck.apply(scratch.allocator(), emitted, lookup);
    defer targetCheck.restore(emitted, refused);
    if (refused_names) |names| for (refused) |r| try names.append(allocator, emitted[r.index].name);
    return switch (config.targetSource) {
        .commonJS => commonJS.codegenEmit(allocator, emitted, config),
        .erlang => erlang.codegenEmit(allocator, emitted, config),
        .beam => beam_asm.codegenEmit(allocator, emitted, config),
        .wasm => wat.codegenEmit(allocator, emitted, config),
    };
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
    // The code cache's level B CODE (144 B-60 S4): a dependency module whose
    // entry holds its unit is not emitted again, and an entry without one is
    // staged again with it. `botopink test` too: a dependency gets no test
    // unit and its production unit does not depend on `test_mode` (decision
    // 513), and a test unit is never cached (`analysis_entry.code_skips`).
    var cfg = config;
    cfg.level_b_code = session.level_b_code;
    var refused: std.ArrayListUnmanaged([]const u8) = .empty;
    defer refused.deinit(allocator);
    var outputs = try emitChecked(allocator, session.outputs.items, cfg, &refused);
    errdefer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    if (cfg.level_b_code) |code| try code.record(allocator, outputs.items, cfg.codeEmit());
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
    for (outputs.items) |o| {
        if (!o.result.failed() and o.name.len > 0) {
            try aux_files.append(allocator, .{ .name = o.name, .code = o.result.js });
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
                .wasm => runtime.executeWat(allocator, output.result.js, output.result.wasm, output.name, io) catch |err| blk: {
                    const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                    break :blk err_msg;
                },
            };
        }
    }

    return outputs;
}
