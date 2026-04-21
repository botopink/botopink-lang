const std = @import("std");
const comptimeMod = @import("../comptime.zig");

/// Final per-module output after all pipeline stages.
/// `js` and `comptime_script` are heap-allocated; call `deinit` when done.
/// `comptime_err` is set (and `js` is empty) when comptime validation failed.
pub const GenerateResult = struct {
    js: []u8,
    typedef: ?[]u8 = null,
    comptime_script: ?[]u8,
    comptime_err: ?comptimeMod.ComptimeError = null,

    pub fn deinit(self: *GenerateResult, allocator: std.mem.Allocator) void {
        allocator.free(self.js);
        if (self.typedef) |t| allocator.free(t);
        if (self.comptime_script) |s| allocator.free(s);
    }
};

/// One entry in the list returned by `codegen.generate`.
/// `src` is a borrowed reference to the caller-owned `Module.source`.
/// `result` is owned; call `result.deinit(allocator)` when done.
pub const ModuleOutput = struct {
    name: []const u8,
    src: []const u8,
    result: GenerateResult,
};
