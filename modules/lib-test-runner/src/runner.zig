/// Per-cell execution — spawn `botopink test` for one `(lib, target)` pair.
///
/// The runner orchestrates the existing CLI; it never re-implements test running.
/// Each child runs with `cwd = <lib_dir>` (the lib's own directory, which may live
/// under any resolved root) so it reads that lib's `botopink.json` and writes its
/// own `.botopinkbuild/test-out/` — per-lib isolation falls out of the working
/// directory, exactly as CI would do it.
const std = @import("std");
const args = @import("args.zig");
const matrix = @import("matrix.zig");

const Target = args.Target;
const Status = matrix.Status;

/// The substring `botopink test` prints when asked for a backend it cannot run
/// yet (beam/wasm today). Detection is driven by this child output — not a
/// hard-coded target list — so the moment the CLI learns a new backend, that
/// target stops being skipped with no change here.
const UNSUPPORTED_MARK = "currently supports only";

/// Run one cell and return its status. Re-emits the child's captured stdout/stderr
/// so its inline report still reaches the user. Returns an error only when the
/// child cannot be spawned at all (e.g. the binary path is wrong).
pub fn runCell(
    arena: std.mem.Allocator,
    io: std.Io,
    bin: []const u8,
    lib_dir: []const u8,
    lib_name: []const u8,
    target: Target,
    filter: ?[]const u8,
    strict: bool,
) !Status {
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    try argv.append(arena, bin);
    try argv.append(arena, "test");
    try argv.append(arena, "--target");
    try argv.append(arena, target.toString());
    if (filter) |f| {
        try argv.append(arena, "--filter");
        try argv.append(arena, f);
    }

    // Header to stderr (the status channel) so the cell's output is attributable.
    std.debug.print("\n\x1b[36m── {s} · {s} ──\x1b[0m\n", .{ lib_name, target.toString() });

    const result = std.process.run(arena, io, .{
        .argv = argv.items,
        .cwd = .{ .path = lib_dir },
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| {
        std.debug.print(
            "\x1b[1m\x1b[31merror\x1b[0m: failed to spawn '{s}': {s}\n",
            .{ bin, @errorName(err) },
        );
        return err;
    };

    // Re-emit the child's output inline.
    if (result.stdout.len > 0) std.Io.File.stdout().writeStreamingAll(io, result.stdout) catch {};
    if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};

    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };

    if (code == 0) return .pass;

    // Non-zero exit: distinguish a not-yet-runnable backend from a real failure.
    const unsupported =
        std.mem.indexOf(u8, result.stdout, UNSUPPORTED_MARK) != null or
        std.mem.indexOf(u8, result.stderr, UNSUPPORTED_MARK) != null;

    if (unsupported and !strict) return .skipped_unsupported;
    return .fail;
}
