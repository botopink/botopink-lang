/// Lib discovery — enumerate projects across the resolved root list and decide
/// which have tests.
///
/// A "lib" is an immediate subdirectory of a root that holds a `botopink.json`,
/// or a **member** of a workspace found there (decision 75: a root — or a child
/// of one — whose manifest declares `"workspaces"` contributes every member it
/// expands to, examples included, each named by its manifest `name`; the
/// umbrella itself is not a cell). The enumeration is the shared
/// `manifest.scanRoots`, the same walk the compiler's loader and the language
/// server use. Roots are scanned in order — env-driven `BOTOPINK_LIB_ROOTS`
/// first, then the walk-up halves (an ancestor that is a workspace, bundled
/// `repository/botopink-lang/libs`, sibling `repository/`, legacy flat `libs/`),
/// finally any `--lib-root` flag entries. Two members with one `name` in
/// different directories are both a `✗` with a located error (first-root-wins
/// is what decision 75 retires); two plain packages keep first-root-wins.
/// "Has tests" means either a `test/` directory with at least one `.bp` suite,
/// or a `src/**/*.bp` file containing a `test` block. A lib with no tests
/// (`has_tests = false`) is still compiled per target by the runner
/// (`runner.compileCell`): `–` when it compiles, `✗` when it does not. A lib
/// with a `problem` (a refused manifest, a library member without `files` —
/// `ships nothing`) is `✗` on every target without a spawn.
const std = @import("std");
const manifest = @import("manifest");

/// Optional process-environment handle. The runner threads `init.environ_map`
/// through so the discovery walker honours `BOTOPINK_LIB_ROOTS` exactly like
/// the CLI driver (`compiler-cli/src/cli/libs.zig:resolveLibRoots`) and the
/// language server (`language-server/src/project_graph.zig:resolveRoots`).
/// `null` is the "no env" test mode.
pub const EnvMap = ?*const std.process.Environ.Map;

/// Name of the env var that prepends extra lib roots, mirroring the CLI driver.
pub const ENV_VAR = "BOTOPINK_LIB_ROOTS";

// ── Types ───────────────────────────────────────────────────────────────────────

pub const Lib = struct {
    /// Import name: the directory name of a plain package, the manifest `name`
    /// of a workspace member. Owned by `gpa`.
    name: []const u8,
    /// Full path to the lib's directory (`<root>/<name>`, or the member's
    /// directory under its workspace), used as the child's `cwd`. Owned by `gpa`.
    dir: []const u8,
    /// A rendered located error that fails every cell of this lib without a
    /// spawn: its manifest was refused, its workspace does not expand, its
    /// name is declared by two libraries, or it is a library member that lists
    /// no `files` (`ships nothing`). Owned by `gpa`.
    problem: ?[]const u8 = null,
    has_tests: bool,
    /// The lib has at least one `src/**/*.bp` file (declaration files
    /// included). A manifest with no botopink source (a tooling project that
    /// carries a `botopink.json` for its version) has nothing to compile.
    has_sources: bool = true,
    /// Per-lib supported-target whitelist from `botopink.json` `"targets":
    /// ["commonJS", …]`. `null` means "no whitelist, run every requested
    /// target" — the historic default. A non-null list filters the runner:
    /// cells whose target is not in the list become `skipped_unsupported`
    /// without spawning `botopink test`. Owned by `gpa` (each element AND
    /// the outer slice). Set by `discover` when the manifest carries the
    /// field; the single-string `"target"` field (canonical build target)
    /// is left unchanged.
    targets: ?[]const []const u8,
};

pub const Error = error{
    LibsRootNotFound,
} || std.mem.Allocator.Error;

// ── Roots ───────────────────────────────────────────────────────────────────────

/// Build the discovery root list for `start_dir` (typically cwd). Returns roots
/// in scan order: env entries (`BOTOPINK_LIB_ROOTS`) first, then walk-up roots
/// (an ancestor holding a workspace manifest, `repository/botopink-lang/libs`,
/// `repository`, `libs`), finally any
/// `extra_roots` (e.g. `--lib-root` flag entries). Empty / non-existent entries
/// are silently dropped, mirroring the CLI driver. De-duped first-occurrence-
/// wins. Caller owns the slice and every element via `arena`.
pub fn resolveRoots(
    arena: std.mem.Allocator,
    io: std.Io,
    env_map: EnvMap,
    extra_roots: []const []const u8,
    start_dir: []const u8,
) ![]const []const u8 {
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;

    // 1. Env-driven roots.
    const env_roots = try parseEnvRoots(arena, env_map, start_dir);
    for (env_roots) |er| try addRootIfExists(arena, io, &roots, &.{er});

    // 2. Walk-up roots. An ancestor that is itself a workspace comes first:
    // its members are what a member resolves its siblings from.
    var dir: []const u8 = start_dir;
    while (true) {
        if (manifest.isWorkspaceDir(io, dir)) try addRootIfExists(arena, io, &roots, &.{dir});
        try addRootIfExists(arena, io, &roots, &.{ dir, "repository", "botopink-lang", "libs" });
        try addRootIfExists(arena, io, &roots, &.{ dir, "repository" });
        try addRootIfExists(arena, io, &roots, &.{ dir, "libs" });
        const parent = std.fs.path.dirname(dir) orelse break;
        if (std.mem.eql(u8, parent, dir)) break;
        dir = parent;
    }

    // 3. --lib-root flag entries (appended after env+walk-up; lowest precedence).
    for (extra_roots) |raw| {
        const abs = if (std.fs.path.isAbsolute(raw))
            try arena.dupe(u8, raw)
        else
            try std.fs.path.resolve(arena, &.{ start_dir, raw });
        try addRootIfExists(arena, io, &roots, &.{abs});
    }

    return roots.toOwnedSlice(arena);
}

/// Read `BOTOPINK_LIB_ROOTS` from `env_map` and split it into absolute root
/// paths. Returns an empty slice when the map is null, the var is unset, or
/// the value is empty. Mirrors the CLI driver's `parseEnvRoots` (separator,
/// empty entries, relative-to-cwd resolution). Caller-owned (arena).
pub fn parseEnvRoots(
    arena: std.mem.Allocator,
    env_map: EnvMap,
    cwd: []const u8,
) ![][]const u8 {
    const m = env_map orelse return arena.alloc([]const u8, 0);
    const value = m.get(ENV_VAR) orelse return arena.alloc([]const u8, 0);
    return parseEnvRootsString(arena, value, cwd);
}

/// `parseEnvRoots` minus the env lookup — splits a literal value into roots.
/// Split out so tests can drive synthetic env contents.
pub fn parseEnvRootsString(
    arena: std.mem.Allocator,
    value: []const u8,
    cwd: []const u8,
) ![][]const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    if (value.len == 0) return out.toOwnedSlice(arena);
    var it = std.mem.splitScalar(u8, value, std.fs.path.delimiter);
    while (it.next()) |raw| {
        if (raw.len == 0) continue;
        const abs = if (std.fs.path.isAbsolute(raw))
            try arena.dupe(u8, raw)
        else
            try std.fs.path.resolve(arena, &.{ cwd, raw });
        try out.append(arena, abs);
    }
    return out.toOwnedSlice(arena);
}

fn addRootIfExists(
    arena: std.mem.Allocator,
    io: std.Io,
    roots: *std.ArrayListUnmanaged([]const u8),
    parts: []const []const u8,
) !void {
    const candidate = try std.fs.path.join(arena, parts);
    var d = std.Io.Dir.cwd().openDir(io, candidate, .{}) catch return;
    d.close(io);
    for (roots.items) |r| {
        if (std.mem.eql(u8, r, candidate)) return; // de-dup, first-occurrence wins
    }
    try roots.append(arena, candidate);
}

// ── Discovery ───────────────────────────────────────────────────────────────────

/// Discover every lib under each root in `roots` (relative to cwd) — plain
/// packages and workspace members alike (`manifest.scanRoots`). If `only` is
/// set, restrict to that one lib. Results are sorted by name; each string is
/// heap-allocated with `gpa` — call `free` when done. Roots that cannot be
/// opened are skipped; the call errors only if no root could be read at all.
pub fn discover(
    gpa: std.mem.Allocator,
    io: std.Io,
    roots: []const []const u8,
    only: ?[]const u8,
) Error![]Lib {
    var libs: std.ArrayListUnmanaged(Lib) = .empty;
    errdefer free(gpa, libs.items);
    errdefer libs.deinit(gpa);

    var any_opened = false;
    for (roots) |libs_root| {
        var root = std.Io.Dir.cwd().openDir(io, libs_root, .{}) catch continue;
        root.close(io);
        any_opened = true;
    }
    if (!any_opened) return error.LibsRootNotFound;

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const entries = try manifest.scanRoots(arena, io, roots);

    for (entries) |e| {
        // The umbrella is not a cell — its members are. It stays only when it
        // is what is wrong (a workspace that does not expand).
        if (e.is_workspace and e.problem == null) continue;
        if (only) |want| {
            if (!std.mem.eql(u8, e.name, want)) continue;
        }

        const name = try gpa.dupe(u8, e.name);
        errdefer gpa.free(name);
        const dir = try gpa.dupe(u8, e.dir);
        errdefer gpa.free(dir);

        const located: ?manifest.Located = e.problem orelse blk: {
            // A library member that lists no `files` ships nothing (decision 75).
            if (e.workspace != null) {
                if (e.manifest) |m| break :blk manifest.shipsNothing(io, m);
            }
            break :blk null;
        };
        const problem: ?[]const u8 = if (located) |l| try l.renderAlloc(gpa) else null;
        errdefer if (problem) |t| gpa.free(t);

        const targets: ?[]const []const u8 = if (e.manifest) |m| try dupeTargets(gpa, m.targets) else null;
        errdefer if (targets) |t| freeTargets(gpa, t);

        var lib_dir = std.Io.Dir.cwd().openDir(io, e.dir, .{}) catch {
            // Unreadable directory: keep the row so it is reported, not hidden.
            try libs.append(gpa, .{ .name = name, .dir = dir, .problem = problem, .has_tests = false, .has_sources = false, .targets = targets });
            continue;
        };
        defer lib_dir.close(io);

        try libs.append(gpa, .{
            .name = name,
            .dir = dir,
            .problem = problem,
            .has_tests = libHasTests(gpa, io, lib_dir),
            .has_sources = srcHasBpFile(gpa, io, lib_dir),
            .targets = targets,
        });
    }

    const items = libs.items;
    std.mem.sort(Lib, items, {}, struct {
        fn lt(_: void, a: Lib, b: Lib) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.lt);

    return libs.toOwnedSlice(gpa);
}

/// Copy a manifest's `targets` (arena-owned) into `gpa`, or null.
fn dupeTargets(gpa: std.mem.Allocator, targets: ?[]const []const u8) !?[]const []const u8 {
    const list = targets orelse return null;
    var out = try gpa.alloc([]const u8, list.len);
    var n: usize = 0;
    errdefer {
        for (out[0..n]) |t| gpa.free(t);
        gpa.free(out);
    }
    for (list) |t| {
        out[n] = try gpa.dupe(u8, t);
        n += 1;
    }
    return out;
}

pub fn free(gpa: std.mem.Allocator, libs: []Lib) void {
    for (libs) |l| {
        gpa.free(l.name);
        gpa.free(l.dir);
        if (l.problem) |t| gpa.free(t);
        if (l.targets) |t| freeTargets(gpa, t);
    }
    gpa.free(libs);
}

fn freeTargets(gpa: std.mem.Allocator, targets: []const []const u8) void {
    for (targets) |t| gpa.free(t);
    gpa.free(targets);
}

/// True when `lib` has no `targets` whitelist OR the whitelist contains
/// `target`. Comparison is case-sensitive (matches the on-disk `Target.toString`
/// form: `"commonJS"`, `"erlang"`, `"beam"`, `"wasm"`).
pub fn libSupportsTarget(lib: Lib, target: []const u8) bool {
    const list = lib.targets orelse return true;
    for (list) |t| {
        if (std.mem.eql(u8, t, target)) return true;
    }
    return false;
}

/// True when the runner should spawn this `(lib, target)` cell.
///
/// The whitelist normally decides (`libSupportsTarget`). `include_unsupported`
/// overrides it so a restricted cell runs anyway — the restriction is then
/// *measured* rather than obeyed, which is what turns it into a ledger line
/// (`scripts/restricted-targets.txt`) instead of a silent opt-out. The cell is
/// still flagged `restricted` in the JSON so its verdict is read against the
/// ledger and not against the ordinary pass/fail tally.
pub fn libRunsTarget(lib: Lib, target: []const u8, include_unsupported: bool) bool {
    return include_unsupported or libSupportsTarget(lib, target);
}

// ── "Has tests" detection ───────────────────────────────────────────────────────

/// True when `lib_dir` has a `test/` suite (`*.bp`) or a `src/**/*.bp` with a
/// `test` block. Any IO error is treated as "no tests" (conservative — a lib that
/// cannot be scanned is skipped, never falsely failed).
fn libHasTests(gpa: std.mem.Allocator, io: std.Io, lib_dir: std.Io.Dir) bool {
    if (dirHasBpSuite(io, lib_dir)) return true;
    return srcHasTestBlock(gpa, io, lib_dir);
}

/// Any `.bp` (non-`.d.bp`) file directly inside `test/`.
fn dirHasBpSuite(io: std.Io, lib_dir: std.Io.Dir) bool {
    var test_dir = lib_dir.openDir(io, "test", .{ .iterate = true }) catch return false;
    defer test_dir.close(io);

    var it = test_dir.iterate();
    while (it.next(io) catch return false) |entry| {
        if (entry.kind != .file) continue;
        if (isBpSource(entry.name)) return true;
    }
    return false;
}

/// Any `src/**/*.bp` (non-`.d.bp`) file containing a `test` block.
fn srcHasTestBlock(gpa: std.mem.Allocator, io: std.Io, lib_dir: std.Io.Dir) bool {
    var src_dir = lib_dir.openDir(io, "src", .{ .iterate = true }) catch return false;
    defer src_dir.close(io);

    var walker = src_dir.walk(gpa) catch return false;
    defer walker.deinit();

    while (walker.next(io) catch return false) |entry| {
        if (entry.kind != .file) continue;
        if (!isBpSource(entry.basename)) continue;

        const source = entry.dir.readFileAlloc(io, entry.basename, gpa, .limited(8 * 1024 * 1024)) catch continue;
        defer gpa.free(source);

        if (containsTestBlock(source)) return true;
    }
    return false;
}

/// Any `src/**/*.bp` file, declaration files included. An IO error answers
/// false — the lib is then reported `–` without a compile, as before.
fn srcHasBpFile(gpa: std.mem.Allocator, io: std.Io, lib_dir: std.Io.Dir) bool {
    var src_dir = lib_dir.openDir(io, "src", .{ .iterate = true }) catch return false;
    defer src_dir.close(io);

    var walker = src_dir.walk(gpa) catch return false;
    defer walker.deinit();

    while (walker.next(io) catch return false) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.endsWith(u8, entry.basename, ".bp")) return true;
    }
    return false;
}

// ── Pure helpers ────────────────────────────────────────────────────────────────

/// A runnable `.bp` source file — excludes declaration files (`*.d.bp`), which
/// carry type surface only and have no executable `test` blocks.
pub fn isBpSource(name: []const u8) bool {
    if (std.mem.endsWith(u8, name, ".d.bp")) return false;
    return std.mem.endsWith(u8, name, ".bp") or std.mem.endsWith(u8, name, ".botopink");
}

/// True when `source` contains a `test` block: the `test` keyword at a word
/// boundary, followed by whitespace and then a name string (`"`) or a body (`{`).
/// This matches `test "…" {}` (named) and `test {}` (anonymous) without tripping
/// on identifiers like `latest` or `tests`.
pub fn containsTestBlock(source: []const u8) bool {
    const kw = "test";
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, source, i, kw)) |pos| {
        i = pos + kw.len;

        // Left boundary: preceding byte must not be an identifier character.
        if (pos > 0 and isIdentByte(source[pos - 1])) continue;

        // Skip whitespace after the keyword; there must be at least one byte left.
        var j = i;
        while (j < source.len and isSpace(source[j])) j += 1;
        if (j == i) continue; // keyword must be followed by whitespace
        if (j >= source.len) continue;

        if (source[j] == '"' or source[j] == '{') return true;
    }
    return false;
}

fn isIdentByte(c: u8) bool {
    return c == '_' or std.ascii.isAlphanumeric(c);
}

fn isSpace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\r' or c == '\n';
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "isBpSource accepts .bp, rejects .d.bp" {
    try testing.expect(isBpSource("erika.bp"));
    try testing.expect(isBpSource("main.botopink"));
    try testing.expect(!isBpSource("primitives.d.bp"));
    try testing.expect(!isBpSource("README.md"));
}

test "libSupportsTarget: null whitelist accepts every target" {
    const lib: Lib = .{ .name = "anything", .dir = "/x", .has_tests = true, .targets = null };
    try testing.expect(libSupportsTarget(lib, "commonJS"));
    try testing.expect(libSupportsTarget(lib, "erlang"));
    try testing.expect(libSupportsTarget(lib, "beam"));
    try testing.expect(libSupportsTarget(lib, "wasm"));
}

test "libSupportsTarget: whitelist filters out missing targets" {
    const list = [_][]const u8{"commonJS"};
    const lib: Lib = .{ .name = "onze", .dir = "/x", .has_tests = true, .targets = &list };
    try testing.expect(libSupportsTarget(lib, "commonJS"));
    try testing.expect(!libSupportsTarget(lib, "erlang"));
    try testing.expect(!libSupportsTarget(lib, "beam"));
    try testing.expect(!libSupportsTarget(lib, "wasm"));
}

test "libSupportsTarget: empty whitelist rejects every target" {
    const list = [_][]const u8{};
    const lib: Lib = .{ .name = "stub", .dir = "/x", .has_tests = true, .targets = &list };
    try testing.expect(!libSupportsTarget(lib, "commonJS"));
    try testing.expect(!libSupportsTarget(lib, "erlang"));
}

test "libRunsTarget: --include-unsupported runs what the whitelist excludes" {
    const list = [_][]const u8{"commonJS"};
    const lib: Lib = .{ .name = "rakun", .dir = "/x", .has_tests = true, .targets = &list };
    // Default: the whitelist decides.
    try testing.expect(libRunsTarget(lib, "commonJS", false));
    try testing.expect(!libRunsTarget(lib, "erlang", false));
    // Lifted: every requested target runs, and the whitelist verdict stays
    // readable through `libSupportsTarget` so the cell can be marked restricted.
    try testing.expect(libRunsTarget(lib, "commonJS", true));
    try testing.expect(libRunsTarget(lib, "erlang", true));
    try testing.expect(!libSupportsTarget(lib, "erlang"));
}

test "libRunsTarget: an unrestricted lib is unaffected by the flag" {
    const lib: Lib = .{ .name = "std", .dir = "/x", .has_tests = true, .targets = null };
    try testing.expect(libRunsTarget(lib, "erlang", false));
    try testing.expect(libRunsTarget(lib, "erlang", true));
}

test "containsTestBlock detects named test" {
    try testing.expect(containsTestBlock("test \"adds two numbers\" {\n  ok\n}"));
}

test "containsTestBlock detects anonymous test" {
    try testing.expect(containsTestBlock("fn x() {}\ntest {\n  ok\n}"));
}

test "containsTestBlock detects indented test" {
    try testing.expect(containsTestBlock("module m\n    test \"x\" {}"));
}

test "containsTestBlock ignores 'latest' and 'tests' identifiers" {
    try testing.expect(!containsTestBlock("let latest = 1\nlet tests = 2\nfn testHelper() {}"));
}

test "containsTestBlock ignores the word test without a block" {
    try testing.expect(!containsTestBlock("// run the test suite\nlet x = test"));
}

test "containsTestBlock requires whitespace after keyword" {
    try testing.expect(!containsTestBlock("test{}")); // no space → treated as identifier-ish use
}

// ── Root resolution tests (env hook + --lib-root flag) ─────────────────────────

test "parseEnvRootsString: empty value yields no roots" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const roots = try parseEnvRootsString(arena_inst.allocator(), "", "/cwd");
    try testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRootsString: relative entries resolve against cwd" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const sep = std.fs.path.delimiter;
    const value = try std.fmt.allocPrint(arena_inst.allocator(), "rel{c}/abs", .{sep});
    const roots = try parseEnvRootsString(arena_inst.allocator(), value, "/home/u");
    try testing.expectEqual(@as(usize, 2), roots.len);
    try testing.expectEqualStrings("/home/u/rel", roots[0]);
    try testing.expectEqualStrings("/abs", roots[1]);
}

test "resolveRoots: env entry prepends before walk-up roots" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;

    const ws = ".botopinkbuild/runner-roots-env/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-env") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-env") catch {};
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/store/erika");
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/libs/std");

    // Pretend cwd is ws so the walk-up only sees the local synthetic tree.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const abs_ws = try std.fs.path.resolve(arena, &.{ cwd_buf[0..cwd_n], ws });

    // A relative env entry resolves against the start dir (`abs_ws` here), so
    // name the store absolutely.
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put(ENV_VAR, try std.fs.path.join(arena, &.{ abs_ws, "store" }));

    const roots = try resolveRoots(arena, io, &map, &.{}, abs_ws);
    try testing.expect(roots.len >= 2);
    try testing.expect(std.mem.endsWith(u8, roots[0], "/store"));
}

test "resolveRoots: --lib-root extras append after env + walk-up" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;

    const ws = ".botopinkbuild/runner-roots-extra/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-extra") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-extra") catch {};
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/extra/foo");
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/libs/std");

    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const abs_ws = try std.fs.path.resolve(arena, &.{ cwd_buf[0..cwd_n], ws });
    const abs_extra = try std.fs.path.resolve(arena, &.{ abs_ws, "extra" });

    const extras = [_][]const u8{abs_extra};
    const roots = try resolveRoots(arena, io, null, &extras, abs_ws);
    // The extra root is last (lowest precedence behind env + walk-up).
    try testing.expect(roots.len >= 2);
    try testing.expect(std.mem.endsWith(u8, roots[roots.len - 1], "/extra"));
}

test "resolveRoots: non-existent env entry silently dropped" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;

    const ws = ".botopinkbuild/runner-roots-miss/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-miss") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/runner-roots-miss") catch {};
    try std.Io.Dir.cwd().createDirPath(io, ws ++ "/libs/std");

    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const abs_ws = try std.fs.path.resolve(arena, &.{ cwd_buf[0..cwd_n], ws });

    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put(ENV_VAR, "/nonexistent/path/that/should/not/exist/here");

    const roots = try resolveRoots(arena, io, &map, &.{}, abs_ws);
    // Env entry dropped silently; only the walk-up `<abs_ws>/libs` is included.
    for (roots) |r| {
        try testing.expect(!std.mem.endsWith(u8, r, "/nonexistent/path/that/should/not/exist/here"));
    }
}

// ── Workspace discovery tests (fixtures of the shared manifest module) ─────────

const FIX = "../manifest/tests/fixtures/roots";

test "discover: workspace members are rows, the umbrella is not; a library member without files is a problem" {
    const gpa = testing.allocator;
    const roots = [_][]const u8{FIX ++ "/repository"};
    const libs = try discover(gpa, testing.io, &roots, null);
    defer free(gpa, libs);

    // plain + the four members (acme, acme-app, acme-empty, acme-web), sorted.
    try testing.expectEqual(@as(usize, 5), libs.len);
    try testing.expectEqualStrings("acme", libs[0].name);
    try testing.expectEqualStrings("acme-app", libs[1].name);
    try testing.expectEqualStrings("acme-empty", libs[2].name);
    try testing.expectEqualStrings("acme-web", libs[3].name);
    try testing.expectEqualStrings("plain", libs[4].name);
    try testing.expectEqualStrings(FIX ++ "/repository/workspace/modules/acme-web", libs[3].dir);

    // Inherited targets: the workspace allows commonJS+erlang, `acme` restricts.
    try testing.expectEqual(@as(usize, 1), libs[0].targets.?.len);
    try testing.expectEqual(@as(usize, 2), libs[3].targets.?.len);
    try testing.expect(libs[4].targets == null);

    // The example member is an application: nothing to ship, no problem.
    try testing.expect(libs[1].problem == null);
    // The library member without `files` fails every cell.
    try testing.expect(std.mem.indexOf(u8, libs[2].problem.?, "error: ships nothing: manifest has no \"files\"") != null);
    try testing.expect(std.mem.indexOf(u8, libs[2].problem.?, "--> " ++ FIX ++ "/repository/workspace/modules/acme-empty/botopink.json:2:3") != null);
    try testing.expect(libs[0].problem == null);
}

test "discover: --lib restricts to one member by its manifest name" {
    const gpa = testing.allocator;
    const roots = [_][]const u8{FIX ++ "/repository"};
    const libs = try discover(gpa, testing.io, &roots, "acme-web");
    defer free(gpa, libs);
    try testing.expectEqual(@as(usize, 1), libs.len);
    try testing.expectEqualStrings("acme-web", libs[0].name);
}

test "discover: two members with one name across roots are both a located problem" {
    const gpa = testing.allocator;
    const roots = [_][]const u8{ FIX ++ "/repository", FIX ++ "/other" };
    const libs = try discover(gpa, testing.io, &roots, "acme-web");
    defer free(gpa, libs);
    try testing.expectEqual(@as(usize, 2), libs.len);
    for (libs) |l| {
        try testing.expect(std.mem.indexOf(u8, l.problem.?, "error: \"acme-web\" is declared by two libraries") != null);
    }
}

test "discover: a manifest that is refused is a row with its located error, not a silent skip" {
    const gpa = testing.allocator;
    const roots = [_][]const u8{FIX ++ "/other"};
    const libs = try discover(gpa, testing.io, &roots, "array-deps");
    defer free(gpa, libs);
    try testing.expectEqual(@as(usize, 1), libs.len);
    try testing.expect(std.mem.indexOf(u8, libs[0].problem.?, "must be an object, not an array") != null);
}
