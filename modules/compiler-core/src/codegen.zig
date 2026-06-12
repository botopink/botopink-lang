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

pub fn generate(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    config: Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var session = try comptimeMod.compile(allocator, modules, io, config.comptimeRuntime, config.build_root);
    defer session.deinit(allocator);
    const outputs = try switch (config.targetSource) {
        .commonJS => commonJS.codegenEmit(allocator, session.outputs.items, config),
        .erlang => erlang.codegenEmit(allocator, session.outputs.items, config),
        .beam => beam_asm.codegenEmit(allocator, session.outputs.items, config),
        .wasm => wat.codegenEmit(allocator, session.outputs.items, config),
    };

    // Sibling modules (multi-module compilations, e.g. the "std" package) are
    // written next to each entry so `require`/remote calls resolve at runtime.
    var aux_files: std.ArrayListUnmanaged(runtime.AuxFile) = .empty;
    defer aux_files.deinit(allocator);
    for (outputs.items) |o| {
        if (o.result.comptime_err == null and o.name.len > 0) {
            try aux_files.append(allocator, .{ .name = o.name, .code = o.result.js });
        }
    }

    // Execute generated code and capture output
    for (outputs.items) |*output| {
        if (output.result.comptime_err == null) {
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
