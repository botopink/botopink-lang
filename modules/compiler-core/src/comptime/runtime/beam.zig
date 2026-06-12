/// BEAM comptime evaluation backend.
///
/// Identical to the Erlang backend but writes to a `beam/` subdirectory.
/// Compiles an Erlang module via `erlc`, then runs via `erl -noshell`.
const std = @import("std");
const ast = @import("../../ast.zig");
const eval = @import("../eval.zig");
const erlang = @import("./erlang.zig");

pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    return erlang.run(allocator, io, entries, build_root);
}
