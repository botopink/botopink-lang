/// A workspace's one output folder per target (decision 1015 (4)): at a
/// workspace root, `build --target <t>` and `run --target <t>` lay one
/// `<out>/` holding every member and every dependency once — the member's own
/// files written by its own process, a dependency's written once per its key.
///
/// **The pieces, one place.** `atRoot` is what the root's command does: for
/// a target it refuses two packages that would write one `<pkg>@<path>`
/// (`refuseShared`), then hands each member to its own `botopink <cmd>
/// [--target <t> --workspace-out <out>]` process — a bare `build` hands each
/// member a bare `build` (its `.bpr` set, no `out/`) — through the fan-out of
/// decision 1006 (5) (`fanout.zig`: in the workspace's order, on `--jobs`,
/// each under `--timeout`, one `ok` / `FAIL` line per member and the count).
///
/// **Written once** (`Once`): a member process given `--workspace-out` writes
/// a dependency's files — every module of the package, its units, `.d.ts`,
/// the browser `.wasm` / `.mjs` — each under a temporary name renamed over the
/// final one, then the package's key file `.<pkg>.key` in the target's folder
/// (`keyPath`), written last the same way. A process that finds the key file
/// holding its key writes nothing of that package; `build --cold` reads no key
/// and rewrites (1008 (4)). Concurrent writers of one key rename the same
/// bytes (the closure invariant, 509 (2)), so a reader sees one whole file.
/// The member's own files are staged and renamed too: members run side by
/// side over one folder, and no process ever reads a file half written —
/// what the OTP compile writes (a `.beam` and its record), the wasm runtime
/// units and the sidecars included (`build.zig`, `run.zig`, `libs.zig`).
/// The key (`depKey`): the package's `.bpr` key (1006 (3)) — none for std,
/// whose bytes are the compiler's —, the target, the wasm host, whether
/// `.d.ts` files are written, and the compiler's source stamp.
const std = @import("std");
const bp = @import("botopink");
const build_stamp = @import("build_stamp");
const manifest = @import("manifest");
const config = @import("./config.zig");
const libs = @import("./libs.zig");
const reporter = @import("./reporter.zig");
const analysis_store = @import("./analysis_store.zig");
const code_cache = @import("./code_cache.zig");
const fanout = @import("./fanout.zig");

pub const Key = [code_cache.KEY_HEX]u8;

/// The command the root hands each member.
pub const Command = enum { build, run };

/// What a member process given `--workspace-out` writes with: the `.bpr`
/// keys of its closure's packages (`libs.ClosureKeys.runtime`), and whether
/// keys are read at all.
pub const Shared = struct {
    runtime: *const std.StringHashMapUnmanaged(Key),
    /// `build --cold`: no key read, every file rewritten.
    rebuild: bool = false,
};

/// `<folder>/.<pkg>.key` — the key a dependency's files in `folder` were
/// written under.
pub fn keyPath(arena: std.mem.Allocator, folder: []const u8, pkg: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/.{s}.key", .{ std.mem.trimEnd(u8, folder, "/"), pkg });
}

/// The key a dependency `pkg`'s files are written once under.
pub fn depKey(pkg: []const u8, runtime: ?Key, target: []const u8, host: []const u8) Key {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    for ([_][]const u8{ "botopink flat dependency", pkg, if (runtime) |*r| r else "", target, host, build_stamp.source_hash }) |part| {
        h.update(part);
        h.update("\x00");
    }
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// One member's writing into the shared folder.
pub const Once = struct {
    arena: std.mem.Allocator,
    io: std.Io,
    folder: []const u8,
    /// Each dependency package of the build: its key, and whether the folder
    /// already holds it under that key (nothing of it is written).
    keys: std.StringHashMapUnmanaged(Key) = .empty,
    present: std.StringHashMapUnmanaged(void) = .empty,
    /// Packages one of whose modules did not compile: no key file.
    failed: std.StringHashMapUnmanaged(void) = .empty,

    pub fn begin(
        arena: std.mem.Allocator,
        io: std.Io,
        shared: Shared,
        folder: []const u8,
        deps: []const []const u8,
        target: []const u8,
        host: []const u8,
    ) !Once {
        var self: Once = .{ .arena = arena, .io = io, .folder = folder };
        // std is embedded: in every program, never one of `deps`.
        const all = try std.mem.concat(arena, []const u8, &.{ &.{bp.codegen.crossModule.EMBEDDED_PACKAGE}, deps });
        for (all) |pkg| {
            if (self.keys.contains(pkg)) continue;
            const key = depKey(pkg, shared.runtime.get(pkg), target, host);
            try self.keys.put(arena, pkg, key);
            if (shared.rebuild) continue;
            const held = std.Io.Dir.cwd().readFileAlloc(io, try keyPath(arena, folder, pkg), arena, .limited(4096)) catch continue;
            if (std.mem.eql(u8, std.mem.trimEnd(u8, held, "\n"), &key)) try self.present.put(arena, pkg, {});
        }
        return self;
    }

    /// Whether the files of `pkg` (null: the member's own) are left as the
    /// folder holds them.
    pub fn skips(self: *const Once, pkg: ?[]const u8) bool {
        return if (pkg) |p| self.present.contains(p) else false;
    }

    /// `bytes` at `path`, staged and renamed over it: the member's own file
    /// and a dependency's alike, so a member running beside it never reads
    /// one half written.
    pub fn write(self: *Once, pkg: ?[]const u8, path: []const u8, bytes: []const u8) !void {
        _ = pkg;
        try analysis_store.write(self.arena, self.io, path, bytes);
    }

    pub fn markFailed(self: *Once, pkg: ?[]const u8) !void {
        if (pkg) |p| try self.failed.put(self.arena, p, {});
    }

    /// The key file of every dependency written whole by this build.
    pub fn finish(self: *Once) !void {
        var it = self.keys.iterator();
        while (it.next()) |e| {
            if (self.present.contains(e.key_ptr.*) or self.failed.contains(e.key_ptr.*)) continue;
            try analysis_store.write(self.arena, self.io, try keyPath(self.arena, self.folder, e.key_ptr.*), try std.fmt.allocPrint(self.arena, "{s}\n", .{e.value_ptr}));
        }
    }
};

// ── The root's command ───────────────────────────────────────────────────────

pub const RootOptions = struct {
    command: Command,
    /// null: a bare `build` — each member's `.bpr` set, no `out/` (1006 (2)).
    target: ?config.Target,
    out_dir: []const u8 = "out",
    cold: bool = false,
    cache_root: ?[]const u8 = null,
    /// `--jobs`: members at once (default `fanout.defaultJobs`).
    jobs: ?usize = null,
    /// `--timeout`: seconds each member is given (default 900).
    timeout_s: ?u64 = null,
};

/// The working directory's command when it is a workspace root: the shared
/// folder refused or laid (a target named), or each member's bare `build`,
/// one process per member; null when the working directory is no workspace
/// root (the command goes on as a package's).
pub fn atRoot(gpa: std.mem.Allocator, io: std.Io, opts: RootOptions, env_map: libs.EnvMap) !?u8 {
    if (!manifest.isWorkspaceDir(io, ".")) return null;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    var err: ?manifest.Located = null;
    const m = manifest.read(arena, io, ".", &err) catch |e| switch (e) {
        error.Invalid => {
            err.?.print();
            return 1;
        },
        error.NotFound => return null,
        error.OutOfMemory => return error.OutOfMemory,
    };
    const ws = manifest.expand(arena, io, m, &err) catch |e| switch (e) {
        error.Invalid => {
            err.?.print();
            return 1;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };

    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    if (opts.target != null) if (try refuseShared(gpa, io, arena, cwd, ws, env_map)) return 1;
    return try fanOut(gpa, arena, io, cwd, ws, opts);
}

/// Decision 1015 (4), 1013 (2) — one `<pkg>@<path>` is one module of the
/// shared folder: a package name (folded as its module atoms fold it,
/// decision 109) that two members' closures — or a member and a closure —
/// reach at two directories is refused, naming both, before anything is
/// built. Two members of one `name` are `manifest.expand`'s refusal already.
/// A member whose manifest or closure is refused is left to its own process,
/// which prints that refusal located.
pub fn refuseShared(gpa: std.mem.Allocator, io: std.Io, arena: std.mem.Allocator, cwd: []const u8, ws: manifest.Workspace, env_map: libs.EnvMap) !bool {
    const Seen = struct { name: []const u8, dir: []const u8, by: []const u8 };
    var seen: std.StringArrayHashMapUnmanaged(Seen) = .empty;
    var refused = false;
    for (ws.members) |member| {
        const member_dir = try std.fs.path.resolve(arena, &.{ cwd, member.dir });
        var packages: std.ArrayListUnmanaged(libs.NamedDir) = .empty;
        try packages.append(arena, .{ .name = member.name, .dir = member_dir });
        if (quietly(arena, io, member_dir, gpa, env_map)) |closure| try packages.appendSlice(arena, closure);
        for (packages.items) |pkg| {
            const folded = try foldedName(arena, pkg.name);
            const dir = try realDir(arena, io, pkg.dir);
            const slot = try seen.getOrPut(arena, folded);
            if (!slot.found_existing) {
                slot.value_ptr.* = .{ .name = pkg.name, .dir = dir, .by = member.name };
                continue;
            }
            const first = slot.value_ptr.*;
            if (std.mem.eql(u8, first.dir, dir)) continue;
            refused = true;
            reporter.errMsg(try std.fmt.allocPrint(arena, "two packages render one `{s}@<path>` in the workspace's output folder — \"{s}\" at {s} (member `{s}`) and \"{s}\" at {s} (member `{s}`) — one name is one package", .{
                folded,
                first.name,
                try display(arena, cwd, first.dir),
                first.by,
                pkg.name,
                try display(arena, cwd, dir),
                member.name,
            }));
        }
    }
    return refused;
}

/// The member's closure, nothing printed: a refusal is its own process's.
fn quietly(arena: std.mem.Allocator, io: std.Io, member_dir: []const u8, gpa: std.mem.Allocator, env_map: libs.EnvMap) ?[]const libs.NamedDir {
    var discard: std.Io.Writer.Discarding = .init(&.{});
    const saved = .{ reporter.capture, reporter.sink, manifest.capture, manifest.sink };
    reporter.capture = null;
    manifest.capture = null;
    reporter.sink = &discard.writer;
    manifest.sink = &discard.writer;
    defer {
        reporter.capture, reporter.sink, manifest.capture, manifest.sink = saved;
    }
    const proj = config.loadAt(arena, io, member_dir) catch return null;
    return libs.closurePackages(gpa, io, arena, proj, env_map) catch null;
}

/// A package name as its atoms start (`my-lib` → `my_lib`, decision 109).
fn foldedName(arena: std.mem.Allocator, name: []const u8) ![]const u8 {
    const atom = bp.codegen.crossModule.erlAtom(arena, bp.codegen.crossModule.ModuleId.inPackage(name, "m")) catch return name;
    return atom[0 .. std.mem.lastIndexOfScalar(u8, atom, '@') orelse atom.len];
}

fn realDir(arena: std.mem.Allocator, io: std.Io, dir: []const u8) ![]const u8 {
    return std.Io.Dir.cwd().realPathFileAlloc(io, dir, arena) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => dir,
    };
}

fn display(arena: std.mem.Allocator, cwd: []const u8, dir: []const u8) ![]const u8 {
    const rel = try std.fs.path.relative(arena, cwd, null, cwd, dir);
    return if (rel.len == 0) "." else rel;
}

/// Each member's own process (decision 1006 (5), `fanout.zig`): `botopink
/// <cmd> --target <t> --workspace-out <root>/<out>` — or a bare `botopink
/// build` — in the member's directory, `--cold` and `--cache-root` handed on;
/// one line per member in the workspace's order, then the count, exit 1 on
/// any red.
fn fanOut(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io, cwd: []const u8, ws: manifest.Workspace, opts: RootOptions) !u8 {
    const self_exe = try std.process.executablePathAlloc(io, arena);
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    try argv.appendSlice(arena, &.{ self_exe, @tagName(opts.command) });
    if (opts.target) |t| try argv.appendSlice(arena, &.{ "--target", t.toString(), "--workspace-out", try std.fs.path.resolve(arena, &.{ cwd, opts.out_dir }) });
    if (opts.cold) try argv.append(arena, "--cold");
    if (opts.cache_root) |r| try argv.appendSlice(arena, &.{ "--cache-root", try std.fs.path.resolve(arena, &.{ cwd, r }) });

    const members = try arena.alloc(fanout.Member, ws.members.len);
    for (ws.members, members) |member, *m| {
        const dir = try std.fs.path.resolve(arena, &.{ cwd, member.dir });
        m.* = .{ .name = try display(arena, cwd, dir), .dir = dir };
    }
    var rand: [8]u8 = undefined;
    io.random(&rand);
    const log_dir = try std.fmt.allocPrint(arena, "{s}/.botopinkbuild/tmp/fanout/{x}", .{ cwd, std.mem.readInt(u64, &rand, .little) });
    return fanout.run(gpa, io, members, .{
        .argv = argv.items,
        .jobs = opts.jobs orelse fanout.defaultJobs(io),
        .timeout_s = opts.timeout_s orelse fanout.DEFAULT_TIMEOUT_S,
        .log_dir = log_dir,
    });
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "depKey: the package's key, the target, the host move it" {
    const r: Key = @splat('a');
    const k = depKey("lib", r, "erlang", "wasi");
    try testing.expectEqualSlices(u8, &k, &depKey("lib", r, "erlang", "wasi"));
    try testing.expect(!std.mem.eql(u8, &k, &depKey("lib", @splat('b'), "erlang", "wasi")));
    try testing.expect(!std.mem.eql(u8, &k, &depKey("lib", r, "beam", "wasi")));
    try testing.expect(!std.mem.eql(u8, &k, &depKey("lib", r, "erlang", "browser")));
    try testing.expect(!std.mem.eql(u8, &k, &depKey("other", r, "erlang", "wasi")));
}

test "foldedName: a package name as its atoms start" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    try testing.expectEqualStrings("my_lib", try foldedName(arena_inst.allocator(), "my-lib"));
    try testing.expectEqualStrings("std", try foldedName(arena_inst.allocator(), "std"));
}
