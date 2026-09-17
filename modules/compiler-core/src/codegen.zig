const std = @import("std");
const moduleOutput = @import("./codegen/moduleOutput.zig");
const configMod = @import("./codegen/config.zig");
const commonJS = @import("./codegen/commonJS.zig");
const erlang = @import("./codegen/erlang.zig");
const beam_asm = @import("./codegen/beam_asm.zig");
const wat = @import("./codegen/wat.zig");
const comptimeMod = @import("./comptime.zig");
const moduleMod = @import("./module.zig");
const runtime = @import("./codegen/runtime.zig");

pub const Module = moduleMod.Module;
pub const ModuleOutput = moduleOutput.ModuleOutput;
pub const ComptimeSession = comptimeMod.ComptimeSession;
pub const ComptimeOutput = comptimeMod.ComptimeOutput;

pub const Config = configMod.Config;
pub const TargetSource = configMod.TargetSource;

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
    // STD-001 — lookup name the `#[@External.<Target>(…)]` parser expects for
    // each codegen target. BEAM consumes the Erlang vocabulary (matches the
    // `externalFor("erlang")` calls in `beam_asm.zig`).
    const target_name: []const u8 = switch (config.targetSource) {
        .commonJS => "node",
        .erlang, .beam => "erlang",
        .wasm => "wasm",
    };

    var session = try comptimeMod.compile(allocator, modules, io, config.build_root, target_name);
    defer session.deinit(allocator);
    const outputs = try switch (config.targetSource) {
        .commonJS => commonJS.codegenEmit(allocator, session.outputs.items, config),
        .erlang => erlang.codegenEmit(allocator, session.outputs.items, config),
        .beam => beam_asm.codegenEmit(allocator, session.outputs.items, config),
        .wasm => wat.codegenEmit(allocator, session.outputs.items, config),
    };

    if (!options.execute) return outputs;

    // Sibling modules (multi-module compilations, e.g. the "std" package) are
    // written next to each entry so `require`/remote calls resolve at runtime.
    var aux_files: std.ArrayListUnmanaged(runtime.AuxFile) = .empty;
    defer aux_files.deinit(allocator);
    for (outputs.items) |o| {
        if (!o.result.failed() and o.name.len > 0) {
            try aux_files.append(allocator, .{ .name = o.name, .code = o.result.js });
        }
    }

    // Execute generated code and capture output
    for (outputs.items) |*output| {
        if (!output.result.failed()) {
            output.result.run_output = switch (config.targetSource) {
                .commonJS => runtime.executeJavaScript(allocator, output.result.js, aux_files.items, io) catch |err| blk: {
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
                .wasm => runtime.executeWat(allocator, output.result.js, output.name, io) catch |err| blk: {
                    const err_msg = try std.fmt.allocPrint(allocator, "Execution error: {}", .{err});
                    break :blk err_msg;
                },
            };
        }
    }

    return outputs;
}
