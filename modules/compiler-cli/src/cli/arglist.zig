/// A per-module list handed to a child process, without growing its command
/// line.
///
/// `execve` refuses an argument list (plus environment) above the system's
/// `ARG_MAX` — 1 MiB on macOS — and Linux refuses any single argument above
/// 128 KiB (`MAX_ARG_STRLEN`). A build that put every emitted path on `erl`'s
/// command line failed on macOS at ~200 modules with a deep `--out` (onze-cli:
/// 5 905 arguments, ~1.29 MB). So a list whose length depends on the program —
/// files, atoms — goes into a file, one entry per line, and the child's
/// command line names only that file (`write`); the Erlang side reads it with
/// `READ_LIST`. Chunking an argv that still grows is not a fix: each chunk is
/// bounded only by luck.
const std = @import("std");
const test_scratch = @import("test_scratch");

/// Where list files live: under `.botopinkbuild/`, which `botopink clean`
/// removes and `.gitignore` covers, beside the comptime scratch.
pub const DIR = ".botopinkbuild/tmp/arglist";

/// Write `entries`, one per line, to a fresh file under `DIR` (64 random bits
/// name it, so two builds in one checkout never share one) and return its
/// path. The caller deletes it with `remove` once the child has exited. An
/// entry with a newline cannot be written as one line and is a bug of the
/// caller (paths and atoms never hold one).
pub fn write(arena: std.mem.Allocator, io: std.Io, entries: []const []const u8) ![]const u8 {
    return writeIn(arena, io, DIR, entries);
}

fn writeIn(arena: std.mem.Allocator, io: std.Io, dir: []const u8, entries: []const []const u8) ![]const u8 {
    std.Io.Dir.cwd().createDirPath(io, dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    const path = try std.fmt.allocPrint(arena, "{s}/{x:0>16}.txt", .{ dir, id });
    var text: std.ArrayListUnmanaged(u8) = .empty;
    for (entries) |e| {
        std.debug.assert(std.mem.indexOfScalar(u8, e, '\n') == null);
        try text.appendSlice(arena, e);
        try text.append(arena, '\n');
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = text.items });
    return path;
}

pub fn remove(io: std.Io, path: []const u8) void {
    std.Io.Dir.cwd().deleteFile(io, path) catch {};
}

/// Erlang: bind `Var` to the entries of the list file named by the expression
/// `PathExpr` (a string), each as a character list — `READ_LIST("Files",
/// "ListFile")`. The file is read as UTF-8, empty lines dropped.
pub fn READ_LIST(comptime var_name: []const u8, comptime path_expr: []const u8) []const u8 {
    return var_name ++ " = case file:read_file(" ++ path_expr ++ ") of " ++
        "{ok, ListBin__} -> [unicode:characters_to_list(L__) || L__ <- binary:split(ListBin__, <<\"\\n\">>, [global, trim_all])]; " ++
        "{error, ListErr__} -> io:format(standard_error, \"cannot read the list file ~ts: ~p~n\", [" ++ path_expr ++ ", ListErr__]), halt(1) end,\n";
}

/// The message for a spawn of `tool` that failed with `err`. Zig reports
/// `execve`'s `E2BIG` as `error.SystemResources` — the error `ENOMEM` gets
/// too — so an argument list at or above the smallest limit any supported
/// system enforces (Linux's 128 KiB per argument and its 128 KiB floor for the
/// whole list) is named for what it is: the argument list is too long.
pub fn spawnError(arena: std.mem.Allocator, tool: []const u8, argv: []const []const u8, err: anyerror) []const u8 {
    if (err == error.SystemResources) {
        var total: usize = 0;
        var largest: usize = 0;
        for (argv) |a| {
            total += a.len + 1;
            largest = @max(largest, a.len + 1);
        }
        if (total >= TOO_LONG or largest >= TOO_LONG)
            return std.fmt.allocPrint(arena, "the argument list for {s} is too long ({d} arguments, {d} bytes)", .{ tool, argv.len, total }) catch "the argument list is too long";
    }
    return std.fmt.allocPrint(arena, "`{s}` could not be run: {s}", .{ tool, @errorName(err) }) catch "a child process could not be run";
}

/// 128 KiB: Linux's `MAX_ARG_STRLEN` and the floor of its `ARG_MAX`; macOS
/// allows 1 MiB for the whole list.
const TOO_LONG: usize = 128 * 1024;

test "spawnError names a long argument list, and passes any other failure through" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const big = try arena.alloc(u8, TOO_LONG);
    @memset(big, 'a');
    try std.testing.expectEqualStrings(
        "the argument list for erl is too long (2 arguments, 131077 bytes)",
        spawnError(arena, "erl", &.{ "erl", big }, error.SystemResources),
    );
    try std.testing.expectEqualStrings("`erl` could not be run: SystemResources", spawnError(arena, "erl", &.{"erl"}, error.SystemResources));
    try std.testing.expectEqualStrings("`erl` could not be run: FileNotFound", spawnError(arena, "erl", &.{"erl"}, error.FileNotFound));
}

test "write puts one entry per line" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    defer test_scratch.remove(io, "arglist");
    const p = try writeIn(arena, io, test_scratch.path(io, "arglist"), &.{ "out/erl/a@b.erl", "out/erl/c.erl" });
    const text = try std.Io.Dir.cwd().readFileAlloc(io, p, arena, .unlimited);
    try std.testing.expectEqualStrings("out/erl/a@b.erl\nout/erl/c.erl\n", text);
}
