//! Decision 1026 (2) — `zig build std-wasm`'s tool: writes the runtime core
//! `std@__rt.wasm` and every std unit `std@<path>.wasm` (`codegen/wat/runtime_unit.zig`,
//! cut from std-wasm's side module) into the directory it is given, and prints
//! the units' dependency graph. `std-units --blob <file>` writes the runtime
//! serialized instead (`runtimeUnit.serialize`), which `zig build` embeds in
//! the compiler (decision 1032 (4)).

const std = @import("std");
const runtimeUnit = @import("codegen/wat/runtime_unit.zig");

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.debug.print("error: {s}: {s}\n", .{ @errorName(err), runtimeUnit.failure() });
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const r = try runtimeUnit.built();
    if (args.len == 3 and std.mem.eql(u8, args[1], "--blob")) {
        const blob = try runtimeUnit.serialize(arena, r);
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[2], .data = blob });
        return;
    }
    if (args.len != 2) return error.UsageStdUnitsOutDir;
    const dir: []const u8 = args[1];
    try std.Io.Dir.cwd().createDirPath(init.io, dir);
    const core_path = try std.fs.path.join(arena, &.{ dir, runtimeUnit.file_name });
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = core_path, .data = r.core_bytes });
    for (r.units) |u| {
        const p = try std.fs.path.join(arena, &.{ dir, u.file_name });
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = p, .data = u.bytes });
    }
    std.Io.File.stdout().writeStreamingAll(init.io, r.graph) catch {};
}
