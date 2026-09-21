//! Build-time renderer of the resident node's three Erlang sources.
//!
//! `zig build` runs this (root `build.zig`, "resident comptime modules") with one
//! argument, an output directory, and writes there:
//!
//!   botopink_comptime_server.erl   `server_source.zig`
//!   bp_comptime_template.erl       `prelude.zig` (rendered from its `erl_ast` forms)
//!   bp_comptime_decorator.erl      `prelude.zig`
//!
//! `erlc +deterministic` then compiles the three into `.beam`s the build hands
//! to `persistent_erl.zig` as `@embedFile`s (decision 83): the Erlang compiler
//! is a dependency of *building* the botopink compiler, and of nothing a user
//! runs. This program imports the sources' Zig and nothing of the runtime, so
//! the graph is acyclic: renderer → `.erl` → `erlc` → `.beam` → runtime.

const std = @import("std");
const serverSource = @import("./server_source.zig");
const preludeMod = @import("./prelude.zig");

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.debug.print("render-resident: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const argv = try init.minimal.args.toSlice(arena);
    if (argv.len != 2) {
        std.debug.print("usage: render-resident <out-dir>\n", .{});
        return error.Usage;
    }
    const out_dir = argv[1];
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, out_dir);

    try write(io, arena, out_dir, serverSource.module_name, serverSource.source);
    for (try preludeMod.modules(arena)) |m| try write(io, arena, out_dir, m.name, m.source);
}

fn write(io: std.Io, arena: std.mem.Allocator, dir: []const u8, name: []const u8, source: []const u8) !void {
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, name });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = source });
}
