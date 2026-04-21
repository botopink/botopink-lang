const std = @import("std");
const moduleOutput = @import("./codegen/moduleOutput.zig");
const configMod = @import("./codegen/config.zig");
const commonJS = @import("./codegen/commonJS.zig");
const erlang = @import("./codegen/erlang.zig");
const comptimeMod = @import("./comptime.zig");
const moduleMod = @import("./module.zig");

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
    return switch (config.targetSource) {
        .commonJS => try commonJS.codegenEmit(allocator, session.outputs.items, config),
        .erlang => try erlang.codegenEmit(allocator, session.outputs.items, config),
    };
}
