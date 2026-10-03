/// The cell-result store (decisions 229 and 249 of 1.0.11-beta, front
/// `00-gate/133-gate-speed`): a run without `--cold` answers a spawning cell
/// from a stored PASS when the cell's key is equal, and runs every other cell;
/// every run, `--cold` included, writes the passes it ran.
///
/// The key is the SHA-256 of everything a cell can read, never an analysis of
/// what a change can affect:
///
///   - the compiler and the toolchain, as `scripts/lib/result-store.js
///     compiler --bin <botopink>` prints them (`global`) — the one computation
///     the shell runners use too: the build configuration (`botopink
///     --version`'s `build:` line), the compiler's sources partitioned by
///     backend (`modules/compiler-core/src/codegen/backend-partition.txt`: the
///     shared files in every key, a backend's own files only in the keys of
///     cells on that target — an audit's target is the one it excludes), the
///     binary built from exactly those sources, `node`, the OTP release,
///     `wasmtime`, the platform and the environment a compiler, a runtime or a
///     test reads;
///   - the library universe (`universe`): every package the run's library roots
///     hold — each child of a root that carries a `botopink.json`, or a root
///     that is itself a workspace — every file of each by content, `.git` and
///     `.botopinkbuild` directories left out. A cell compiles its own package
///     and its dependency closure, and its tests may read their repository
///     (onze-assets walks its siblings): rather than decide which packages a
///     cell reads, every key holds them all (decision 246), so a change to any
///     library runs every cell;
///   - the cell: its library's name and directory, the target, the kind, and the
///     flags that change what the child prints (`--filter`, `--strict`,
///     `--json`).
///
/// Only a pass is stored (`.pass`, `.no_tests` — compiled —, an audited
/// `.excluded`), only when the global part of the key is the same after the run
/// as before it (nothing moved under the run), and never when the key cannot be
/// computed with certainty (`Global.unstorable`: the binary not built from the
/// checkout's sources, a partition that fails its audit, a symbolic link or a
/// `.botopinkbuild/deps/` in the universe). The store lives in `<cache
/// root>/.botopinkbuild/cache/results/lib-test/` of each library (decision 225,
/// `schedule.cacheRoot`): deleting `.botopinkbuild/` wipes it. Entries no run
/// has read or written for 7 days are deleted.
const std = @import("std");
const manifest = @import("manifest");
const runner = @import("runner.zig");
const matrix = @import("matrix.zig");

pub const VERSION = "botopink result store v1";

/// Entries unused this long are deleted.
const TTL_NS: i96 = 7 * 24 * 3600 * std.time.ns_per_s;

/// The store's directory under a cache root.
pub const STORE = "results/lib-test";

/// What a digest found: the digest text, or why the bytes cannot be hashed.
pub const Digest = union(enum) {
    digest: []const u8,
    unstorable: []const u8,
};

fn hexOf(h: *std.crypto.hash.sha2.Sha256) [64]u8 {
    var d: [32]u8 = undefined;
    h.final(&d);
    return std.fmt.bytesToHex(d, .lower);
}

fn execBit(st: std.Io.File.Stat) bool {
    if (comptime !std.Io.File.Permissions.has_executable_bit) return false;
    return st.permissions.toMode() & 0o111 != 0;
}

/// The digest of the file or directory tree at `abs` (`absent` when there is
/// none). A tree is every directory and file path in sorted order, each file's
/// executable bit and SHA-256; `.git` and `.botopinkbuild` directories are
/// left out (a package's VCS data and the build caches its runs write), and a
/// `.botopinkbuild/deps/` (the `bpmp install` store the compiler resolves
/// dependencies through) or a symbolic link makes the tree unstorable.
pub fn digest(arena: std.mem.Allocator, io: std.Io, abs: []const u8) !Digest {
    const st = std.Io.Dir.cwd().statFile(io, abs, .{ .follow_symlinks = false }) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return .{ .digest = "absent" },
        else => return err,
    };
    switch (st.kind) {
        .file => {
            const bytes = try std.Io.Dir.cwd().readFileAlloc(io, abs, arena, .unlimited);
            var h = std.crypto.hash.sha2.Sha256.init(.{});
            h.update(bytes);
            return .{ .digest = try std.fmt.allocPrint(arena, "file {s} {s}", .{ if (execBit(st)) "x" else "-", &hexOf(&h) }) };
        },
        .directory => {},
        .sym_link => return .{ .unstorable = try std.fmt.allocPrint(arena, "{s} is a symbolic link", .{abs}) },
        else => return .{ .unstorable = try std.fmt.allocPrint(arena, "{s} is neither a file nor a directory", .{abs}) },
    }
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    if (try walk(arena, io, abs, "", &h)) |why| return .{ .unstorable = why };
    return .{ .digest = try std.fmt.allocPrint(arena, "tree {s}", .{&hexOf(&h)}) };
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

/// Hash the tree under `root`/`rel` into `h`; the reason it is unstorable, or null.
fn walk(arena: std.mem.Allocator, io: std.Io, root: []const u8, rel: []const u8, h: *std.crypto.hash.sha2.Sha256) !?[]const u8 {
    const dir_path = if (rel.len == 0) root else try std.fs.path.join(arena, &.{ root, rel });
    var dir = try std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true });
    defer dir.close(io);
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = dir.iterate();
    while (try it.next(io)) |e| try names.append(arena, try arena.dupe(u8, e.name));
    std.mem.sortUnstable([]const u8, names.items, {}, lessThan);
    for (names.items) |name| {
        const sub = if (rel.len == 0) name else try std.fmt.allocPrint(arena, "{s}/{s}", .{ rel, name });
        const st = try dir.statFile(io, name, .{ .follow_symlinks = false });
        switch (st.kind) {
            .directory => {
                if (std.mem.eql(u8, name, ".git")) continue;
                if (std.mem.eql(u8, name, ".botopinkbuild")) {
                    const deps = try std.fs.path.join(arena, &.{ dir_path, name, "deps" });
                    if (std.Io.Dir.cwd().statFile(io, deps, .{ .follow_symlinks = false })) |_| {
                        return try std.fmt.allocPrint(arena, "{s} is a dependency store the compiler resolves through", .{deps});
                    } else |_| {}
                    continue;
                }
                h.update("D ");
                h.update(sub);
                h.update("\n");
                if (try walk(arena, io, root, sub, h)) |why| return why;
            },
            .file => {
                const bytes = try dir.readFileAlloc(io, name, arena, .unlimited);
                var fh = std.crypto.hash.sha2.Sha256.init(.{});
                fh.update(bytes);
                h.update("F ");
                h.update(sub);
                h.update(if (execBit(st)) " x " else " - ");
                h.update(&hexOf(&fh));
                h.update("\n");
            },
            .sym_link => return try std.fmt.allocPrint(arena, "{s}/{s} is a symbolic link", .{ root, sub }),
            else => return try std.fmt.allocPrint(arena, "{s}/{s} is neither a file nor a directory", .{ root, sub }),
        }
    }
    return null;
}

/// The packages every key holds: each child of a root that carries a
/// `botopink.json`, or the root itself when it carries one (a workspace root).
pub fn universe(arena: std.mem.Allocator, io: std.Io, roots: []const []const u8) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (roots) |root| {
        const own = try std.fs.path.join(arena, &.{ root, "botopink.json" });
        if (std.Io.Dir.cwd().access(io, own, .{})) |_| {
            try appendUnique(arena, &out, root);
            continue;
        } else |_| {}
        var dir = std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true }) catch continue;
        defer dir.close(io);
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = dir.iterate();
        while (try it.next(io)) |e| {
            if (e.kind != .directory) continue;
            try names.append(arena, try arena.dupe(u8, e.name));
        }
        std.mem.sortUnstable([]const u8, names.items, {}, lessThan);
        for (names.items) |n| {
            const m = try std.fs.path.join(arena, &.{ root, n, "botopink.json" });
            std.Io.Dir.cwd().access(io, m, .{}) catch continue;
            try appendUnique(arena, &out, try std.fs.path.join(arena, &.{ root, n }));
        }
    }
    return out.items;
}

fn appendUnique(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged([]const u8), p: []const u8) !void {
    for (out.items) |q| if (std.mem.eql(u8, p, q)) return;
    try out.append(arena, p);
}

/// The global part of every key: the compiler and toolchain lines
/// `result-store.js compiler` prints (one `target <t> <hex>` per target kept
/// apart), and the universe.
pub const Global = struct {
    /// Hex SHA-256 of the global text but the target lines; meaningful only
    /// when `unstorable` is null.
    hex: [64]u8 = [_]u8{'0'} ** 64,
    /// `target <t> <hex>` per target — the backend's own compiler sources.
    targets: []const []const u8 = &.{},
    /// Why no cell of this run can be stored.
    unstorable: ?[]const u8 = null,
};

/// The compiler and toolchain part of every key, from the shell runners' own
/// `scripts/lib/result-store.js compiler --bin <bin>` under `checkout` (the
/// checkout this runner was built from, `build_stamp.source_root`): one
/// computation of the partitioned compiler sources, the build configuration,
/// the binary's freshness and the toolchain, for all three stores. A checkout
/// without the script, or a `node` that cannot run it, stores nothing.
pub fn global(arena: std.mem.Allocator, io: std.Io, checkout: []const u8, bin: []const u8, roots: []const []const u8) !Global {
    const script = try std.fs.path.join(arena, &.{ checkout, "scripts", "lib", "result-store.js" });
    std.Io.Dir.cwd().access(io, script, .{}) catch
        return .{ .unstorable = try std.fmt.allocPrint(arena, "{s} is not there to compute the compiler's key", .{script}) };
    const r = std.process.run(arena, io, .{
        .argv = &.{ "node", script, "compiler", "--bin", bin },
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    }) catch return .{ .unstorable = "`node` could not run result-store.js to compute the compiler's key" };
    switch (r.term) {
        .exited => |c| if (c != 0) return .{ .unstorable = "result-store.js could not compute the compiler's key" },
        else => return .{ .unstorable = "result-store.js could not compute the compiler's key" },
    }
    var text: std.ArrayListUnmanaged(u8) = .empty;
    var targets: std.ArrayListUnmanaged([]const u8) = .empty;
    try text.print(arena, "{s}\n", .{VERSION});
    var lines = std.mem.splitScalar(u8, r.stdout, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "why ")) return .{ .unstorable = try arena.dupe(u8, line["why ".len..]) };
        if (std.mem.startsWith(u8, line, "target ")) {
            try targets.append(arena, line);
            continue;
        }
        try text.print(arena, "{s}\n", .{line});
    }
    for (try universe(arena, io, roots)) |p| {
        switch (try digest(arena, io, p)) {
            .digest => |d| try text.print(arena, "global-tree {s} {s}\n", .{ p, d }),
            .unstorable => |why| return .{ .unstorable = why },
        }
    }
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update(text.items);
    return .{ .hex = hexOf(&h), .targets = targets.items };
}

/// One cell's identity under the global key.
pub const CellId = struct {
    lib: []const u8,
    dir: []const u8,
    target: []const u8,
    kind: []const u8,
    filter: ?[]const u8,
    strict: bool,
    json: bool,
};

/// The cell's key: the global part, the compiler sources of the target the
/// cell compiles for (an audit's is the target it excludes), and the cell.
pub fn cellKey(g: Global, c: CellId) [64]u8 {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update(&g.hex);
    for (g.targets) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        _ = it.next();
        if (std.mem.eql(u8, it.next() orelse "", c.target)) {
            h.update("\n");
            h.update(line);
        }
    }
    const fields = [_][]const u8{ "\nlib ", c.lib, "\ndir ", c.dir, "\ntarget ", c.target, "\nkind ", c.kind, "\nfilter ", c.filter orelse "<none>" };
    for (fields) |f| h.update(f);
    h.update(if (c.strict) "\nstrict" else "\nlenient");
    h.update(if (c.json) "\njson\n" else "\ntext\n");
    return hexOf(&h);
}

/// The entry of `key` in the store directory `store`.
pub fn entryPath(arena: std.mem.Allocator, store: []const u8, key: [64]u8) ![]const u8 {
    return std.fs.path.join(arena, &.{ store, key[0..2], &key });
}

/// The store directory of a library: `<store_root>`, or the results store under
/// the library's cache root.
pub fn storeDir(arena: std.mem.Allocator, io: std.Io, store_root: ?[]const u8, lib_dir: []const u8) ![]const u8 {
    if (store_root) |r| return r;
    var err: ?manifest.Located = null;
    const root = manifest.findCacheRoot(arena, io, lib_dir, &err) catch lib_dir;
    return manifest.cacheDir(arena, root, STORE);
}

/// Whether a captured cell is a pass the store may keep.
pub fn storable(cap: runner.Captured) bool {
    if (cap.spawn_err != null) return false;
    return switch (cap.status) {
        .pass, .no_tests, .excluded => true,
        else => false,
    };
}

const MAGIC = "botopink-lib-test result v1\n";

/// The bytes of one entry.
pub fn encode(arena: std.mem.Allocator, cap: runner.Captured) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.appendSlice(arena, MAGIC);
    try out.print(arena, "{s}\n{d}\n{d}\n{s}\n", .{ @tagName(cap.status), cap.counts.failed, @intFromBool(cap.counts.ran), @tagName(cap.audit.why) });
    for ([_][]const u8{ cap.audit.line, cap.audit.at, cap.stdout, cap.stderr }) |part| {
        try out.print(arena, "{d}\n", .{part.len});
        try out.appendSlice(arena, part);
        try out.append(arena, '\n');
    }
    return out.items;
}

/// An entry's bytes back to the captured cell; null when they do not parse.
pub fn decode(bytes: []const u8) ?runner.Captured {
    if (!std.mem.startsWith(u8, bytes, MAGIC)) return null;
    var rest = bytes[MAGIC.len..];
    const line = struct {
        fn next(r: *[]const u8) ?[]const u8 {
            const nl = std.mem.indexOfScalar(u8, r.*, '\n') orelse return null;
            const l = r.*[0..nl];
            r.* = r.*[nl + 1 ..];
            return l;
        }
        fn blob(r: *[]const u8) ?[]const u8 {
            const len = std.fmt.parseUnsigned(usize, next(r) orelse return null, 10) catch return null;
            if (r.len < len + 1 or r.*[len] != '\n') return null;
            const b = r.*[0..len];
            r.* = r.*[len + 1 ..];
            return b;
        }
    };
    const status = std.meta.stringToEnum(matrix.Status, line.next(&rest) orelse return null) orelse return null;
    const failed = std.fmt.parseUnsigned(usize, line.next(&rest) orelse return null, 10) catch return null;
    const ran = line.next(&rest) orelse return null;
    const why = std.meta.stringToEnum(runner.Audit.Why, line.next(&rest) orelse return null) orelse return null;
    const audit_line = line.blob(&rest) orelse return null;
    const at = line.blob(&rest) orelse return null;
    const stdout = line.blob(&rest) orelse return null;
    const stderr = line.blob(&rest) orelse return null;
    if (rest.len != 0) return null;
    return .{
        .stdout = stdout,
        .stderr = stderr,
        .status = status,
        .counts = .{ .failed = failed, .ran = std.mem.eql(u8, ran, "1") },
        .audit = .{ .why = why, .line = audit_line, .at = at },
    };
}

/// The stored pass of `key`, refreshing its time; null when there is none.
pub fn load(arena: std.mem.Allocator, io: std.Io, store: []const u8, key: [64]u8) ?runner.Captured {
    const p = entryPath(arena, store, key) catch return null;
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, p, arena, .limited(256 * 1024 * 1024)) catch return null;
    const cap = decode(bytes) orelse return null;
    if (!storable(cap)) return null;
    std.Io.Dir.cwd().setTimestamps(io, p, .{ .access_timestamp = .now, .modify_timestamp = .now }) catch {};
    return cap;
}

/// Write `cap` under `key` (staged and renamed). Best effort: a failure only
/// means the next run runs the cell.
pub fn save(arena: std.mem.Allocator, io: std.Io, store: []const u8, key: [64]u8, cap: runner.Captured) bool {
    const p = entryPath(arena, store, key) catch return false;
    const bytes = encode(arena, cap) catch return false;
    std.Io.Dir.cwd().createDirPath(io, std.fs.path.dirname(p).?) catch return false;
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const tmp = std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ p, std.mem.readInt(u64, &rand_bytes, .little) }) catch return false;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp, .data = bytes }) catch return false;
    std.Io.Dir.cwd().rename(tmp, std.Io.Dir.cwd(), p, io) catch {
        std.Io.Dir.cwd().deleteFile(io, tmp) catch {};
        return false;
    };
    return true;
}

/// Delete the entries of `store` no run has read or written for 7 days.
pub fn reap(arena: std.mem.Allocator, io: std.Io, store: []const u8) void {
    const cutoff = std.Io.Timestamp.now(io, .real).nanoseconds - TTL_NS;
    var dir = std.Io.Dir.cwd().openDir(io, store, .{ .iterate = true }) catch return;
    defer dir.close(io);
    var it = dir.iterate();
    while (it.next(io) catch return) |shard| {
        if (shard.kind != .directory) continue;
        var sd = dir.openDir(io, shard.name, .{ .iterate = true }) catch continue;
        defer sd.close(io);
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var sit = sd.iterate();
        while (sit.next(io) catch null) |e| names.append(arena, arena.dupe(u8, e.name) catch return) catch return;
        for (names.items) |n| {
            const st = sd.statFile(io, n, .{ .follow_symlinks = false }) catch continue;
            if (st.mtime.nanoseconds < cutoff) sd.deleteFile(io, n) catch {};
        }
    }
}

// ── tests ───────────────────────────────────────────────────────────────────

const test_scratch = @import("test_scratch");
const testing = std.testing;
/// The build directory name the digest leaves out (a test may not spell it).
const BUILD_DIR = manifest.CACHE_DIR[0..std.mem.indexOfScalar(u8, manifest.CACHE_DIR, '/').?];

test "encode/decode: a stored pass comes back byte for byte" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const cap: runner.Captured = .{
        .stdout = "{\"event\":\"summary\",\"passed\":3,\"failed\":0}\nline\n",
        .stderr = "  Compiling 3 module(s)...\n",
        .status = .pass,
        .counts = .{ .failed = 0, .ran = true },
    };
    const back = decode(try encode(a, cap)).?;
    try testing.expectEqualStrings(cap.stdout, back.stdout);
    try testing.expectEqualStrings(cap.stderr, back.stderr);
    try testing.expectEqual(cap.status, back.status);
    try testing.expect(back.counts.ran);

    const audit: runner.Captured = .{ .status = .excluded, .audit = .{ .why = .structural, .line = "error: `f` has no …", .at = "src/a.bp:1:2" } };
    const ab = decode(try encode(a, audit)).?;
    try testing.expectEqual(runner.Audit.Why.structural, ab.audit.why);
    try testing.expectEqualStrings("src/a.bp:1:2", ab.audit.at);

    // A truncated entry is no entry.
    const bytes = try encode(a, cap);
    try testing.expect(decode(bytes[0 .. bytes.len - 1]) == null);
}

test "storable: only a pass, a compiled cell or a structural exclusion" {
    try testing.expect(storable(.{ .status = .pass }));
    try testing.expect(storable(.{ .status = .no_tests }));
    try testing.expect(storable(.{ .status = .excluded }));
    try testing.expect(!storable(.{ .status = .fail }));
    try testing.expect(!storable(.{ .status = .not_structural }));
    try testing.expect(!storable(.{ .status = .skipped_unsupported }));
    try testing.expect(!storable(.{ .status = .pass, .spawn_err = error.FileNotFound }));
}

test "cellKey: every field of the cell moves the key" {
    const g: Global = .{ .hex = [_]u8{'a'} ** 64 };
    const base: CellId = .{ .lib = "std", .dir = "/r/std", .target = "erlang", .kind = "cell:test", .filter = null, .strict = false, .json = true };
    const k = cellKey(g, base);
    var other = base;
    other.target = "commonJS";
    try testing.expect(!std.mem.eql(u8, &k, &cellKey(g, other)));
    other = base;
    other.json = false;
    try testing.expect(!std.mem.eql(u8, &k, &cellKey(g, other)));
    const g2: Global = .{ .hex = [_]u8{'b'} ** 64 };
    try testing.expect(!std.mem.eql(u8, &k, &cellKey(g2, base)));
}

test "digest: one byte moves a tree; .git and .botopinkbuild do not; a symlink is unstorable" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "result-store-digest");
    const root = test_scratch.path(io, "result-store-digest/pkg");
    try std.Io.Dir.cwd().createDirPath(io, try std.fs.path.join(a, &.{ root, "src" }));
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ root, "src", "a.bp" }), .data = "pub fn a() {}\n" });
    const d1 = (try digest(a, io, root)).digest;
    try std.Io.Dir.cwd().createDirPath(io, try std.fs.path.join(a, &.{ root, BUILD_DIR, "cache" }));
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ root, BUILD_DIR, "cache", "x" }), .data = "x" });
    try testing.expectEqualStrings(d1, (try digest(a, io, root)).digest);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ root, "src", "a.bp" }), .data = "pub fn a() { }\n" });
    try testing.expect(!std.mem.eql(u8, d1, (try digest(a, io, root)).digest));
    try std.Io.Dir.cwd().createDirPath(io, try std.fs.path.join(a, &.{ root, BUILD_DIR, "deps" }));
    try testing.expect((try digest(a, io, root)) == .unstorable);
    test_scratch.remove(io, "result-store-digest");
}
