/// The order the worker pool STARTS cells in — never what runs, never what is
/// printed. Every spawning cell of the plan runs exactly once, and `main.zig`
/// emits them in plan order whatever order they ran in; this file only decides
/// which cell a free worker takes next.
///
/// The longest cell first: a pool that takes cells in discovery order starts
/// the slowest one whenever discovery reaches it, and the run then waits for
/// it alone at the end (onze-cli, discovered late, measured 222 s of a 473 s
/// `test-libs` stage, started at 244 s). So the runner remembers how long each
/// cell took — `<ms>\t<lib>\t<target>\t<kind>` lines in
/// `$XDG_CACHE_HOME/botopink/lib-test/durations.tsv` (else
/// `$HOME/.cache/botopink/lib-test/durations.tsv`) — and starts the cells in
/// descending order of their last time, the cells it has no time for first
/// (a new cell may be the long one). The file is a scheduling hint shared by
/// every checkout of the machine: a missing, unreadable or stale one changes
/// the order and nothing else, and it is rewritten after every run by staging
/// and renaming (two runs racing write whole files, the last one wins).
const std = @import("std");

/// One spawning cell, as the history names it.
pub const Key = struct {
    lib: []const u8,
    target: []const u8,
    kind: []const u8,
};

/// `<lib>\t<target>\t<kind>` — the history's key for a cell.
pub fn keyText(arena: std.mem.Allocator, k: Key) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\t{s}\t{s}", .{ k.lib, k.target, k.kind });
}

pub const History = std.StringHashMapUnmanaged(u64);

/// Parse the history file's text: one `<ms>\t<key>` per line. A line that does
/// not parse is ignored — the file only orders cells.
pub fn parse(arena: std.mem.Allocator, text: []const u8) !History {
    var map: History = .empty;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        const tab = std.mem.indexOfScalar(u8, line, '\t') orelse continue;
        const ms = std.fmt.parseUnsigned(u64, line[0..tab], 10) catch continue;
        const key = line[tab + 1 ..];
        if (key.len == 0) continue;
        try map.put(arena, try arena.dupe(u8, key), ms);
    }
    return map;
}

/// The indices of `keys` in the order the pool starts them: the cells the
/// history does not know first, then by descending time; ties (and the
/// unknown cells among themselves) keep plan order.
pub fn order(arena: std.mem.Allocator, keys: []const []const u8, history: *const History) ![]usize {
    const Entry = struct { index: usize, ms: u64 };
    const entries = try arena.alloc(Entry, keys.len);
    for (keys, 0..) |k, i| entries[i] = .{ .index = i, .ms = history.get(k) orelse std.math.maxInt(u64) };
    std.mem.sort(Entry, entries, {}, struct {
        fn lessThan(_: void, a: Entry, b: Entry) bool {
            if (a.ms != b.ms) return a.ms > b.ms;
            return a.index < b.index;
        }
    }.lessThan);
    const out = try arena.alloc(usize, keys.len);
    for (entries, 0..) |e, i| out[i] = e.index;
    return out;
}

/// The history file's path, or null when neither `XDG_CACHE_HOME` nor `HOME`
/// is an absolute path (then the pool keeps plan order).
pub fn path(arena: std.mem.Allocator, env: *const std.process.Environ.Map) ?[]const u8 {
    if (env.get("XDG_CACHE_HOME")) |v| if (v.len > 0 and std.fs.path.isAbsolute(v))
        return std.fs.path.join(arena, &.{ v, "botopink", "lib-test", "durations.tsv" }) catch null;
    if (env.get("HOME")) |v| if (v.len > 0 and std.fs.path.isAbsolute(v))
        return std.fs.path.join(arena, &.{ v, ".cache", "botopink", "lib-test", "durations.tsv" }) catch null;
    return null;
}

/// Read the history; an absent or unreadable file is an empty one.
pub fn load(arena: std.mem.Allocator, io: std.Io, file: []const u8) History {
    const text = std.Io.Dir.cwd().readFileAlloc(io, file, arena, .limited(4 * 1024 * 1024)) catch return .empty;
    return parse(arena, text) catch .empty;
}

/// Merge this run's times into the history and write it back (staged and
/// renamed). Best effort: a failure leaves the old file, which only orders.
pub fn store(arena: std.mem.Allocator, io: std.Io, file: []const u8, history: *History, keys: []const []const u8, ms: []const u64) void {
    for (keys, ms) |k, t| history.put(arena, k, t) catch return;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var it = history.iterator();
    while (it.next()) |e| {
        out.print(arena, "{d}\t{s}\n", .{ e.value_ptr.*, e.key_ptr.* }) catch return;
    }
    const dir = std.fs.path.dirname(file) orelse return;
    std.Io.Dir.cwd().createDirPath(io, dir) catch return;
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const tmp = std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ file, std.mem.readInt(u64, &rand_bytes, .little) }) catch return;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp, .data = out.items }) catch return;
    std.Io.Dir.cwd().rename(tmp, std.Io.Dir.cwd(), file, io) catch {
        std.Io.Dir.cwd().deleteFile(io, tmp) catch {};
    };
}

test "parse: one time per key, bad lines ignored" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const h = try parse(a, "120\temilia\terlang\tcell:test\nnot a line\n\t\n7\tstd\tcommonJS\tcell:test\n");
    try std.testing.expectEqual(@as(usize, 2), h.count());
    try std.testing.expectEqual(@as(u64, 120), h.get("emilia\terlang\tcell:test").?);
    try std.testing.expectEqual(@as(u64, 7), h.get("std\tcommonJS\tcell:test").?);
}

test "order: unknown cells first in plan order, then the longest first; every cell once" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const h = try parse(a, "5\ta\tx\tcell:test\n300\tb\tx\tcell:test\n40\td\tx\tcell:test\n40\te\tx\tcell:test\n");
    const keys = [_][]const u8{
        try keyText(a, .{ .lib = "a", .target = "x", .kind = "cell:test" }),
        try keyText(a, .{ .lib = "b", .target = "x", .kind = "cell:test" }),
        try keyText(a, .{ .lib = "c", .target = "x", .kind = "cell:test" }),
        try keyText(a, .{ .lib = "d", .target = "x", .kind = "cell:test" }),
        try keyText(a, .{ .lib = "e", .target = "x", .kind = "cell:test" }),
        try keyText(a, .{ .lib = "f", .target = "x", .kind = "cell:test" }),
    };
    const got = try order(a, &keys, &h);
    try std.testing.expectEqualSlices(usize, &.{ 2, 5, 1, 3, 4, 0 }, got);
}

test "order: no history keeps plan order" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const h: History = .empty;
    const keys = [_][]const u8{ "x", "y", "z" };
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2 }, try order(a, &keys, &h));
}
