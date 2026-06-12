/// Lib discovery — enumerate projects across the resolved root list and decide
/// which have tests.
///
/// A "lib" is any immediate subdirectory of a root that holds a `botopink.json`.
/// Roots are scanned in order — env-driven `BOTOPINK_LIB_ROOTS` first, then the
/// walk-up halves (bundled `repository/botopink-lang/libs`, sibling `repository/`,
/// legacy flat `libs/`), finally any `--lib-root` flag entries. The first root
/// carrying a given name wins, later duplicates are dropped. "Has tests" means
/// either a `test/` directory with at least one `.bp` suite, or a `src/**/*.bp`
/// file containing a `test` block. A lib with no tests is reported
/// (`has_tests = false`) and rendered as a green skip — never a failure,
/// matching `botopink test`'s own "no test blocks found" → exit 0.
const std = @import("std");

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
    /// Directory name (the immediate child of its root). Owned by `gpa`.
    name: []const u8,
    /// Full path to the lib's directory (`<root>/<name>`), used as the child's
    /// `cwd`. Owned by `gpa`.
    dir: []const u8,
    has_tests: bool,
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
/// (`repository/botopink-lang/libs`, `repository`, `libs`), finally any
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

    // 2. Walk-up roots.
    var dir: []const u8 = start_dir;
    while (true) {
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

/// Discover every lib under each root in `roots` (relative to cwd) that carries a
/// `botopink.json`. If `only` is set, restrict to that one lib. A name found in an
/// earlier root shadows the same name in a later one (first-root-wins). Results
/// are sorted by name; each `name`/`dir` is heap-allocated with `gpa` — call
/// `free` when done. Roots that cannot be opened are skipped; the call errors only
/// if no root could be read at all.
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
        var root = std.Io.Dir.cwd().openDir(io, libs_root, .{ .iterate = true }) catch continue;
        defer root.close(io);
        any_opened = true;

        var it = root.iterate();
        while (it.next(io) catch break) |entry| {
            if (entry.kind != .directory) continue;
            if (only) |want| {
                if (!std.mem.eql(u8, entry.name, want)) continue;
            }
            // First root carrying this name wins — skip a later duplicate.
            if (hasName(libs.items, entry.name)) continue;

            var lib_dir = root.openDir(io, entry.name, .{}) catch continue;
            defer lib_dir.close(io);

            // A project is a lib iff it has a manifest.
            lib_dir.access(io, "botopink.json", .{}) catch continue;

            // `entry.name` is backed by the iterator's scratch buffer — dupe before
            // any further `it.next()` invalidates it.
            const name = try gpa.dupe(u8, entry.name);
            errdefer gpa.free(name);
            const dir = try std.fs.path.join(gpa, &.{ libs_root, entry.name });
            errdefer gpa.free(dir);

            const targets = readManifestTargets(gpa, io, lib_dir);
            errdefer if (targets) |t| freeTargets(gpa, t);

            try libs.append(gpa, .{
                .name = name,
                .dir = dir,
                .has_tests = libHasTests(gpa, io, lib_dir),
                .targets = targets,
            });
        }
    }
    if (!any_opened) return error.LibsRootNotFound;

    const items = libs.items;
    std.mem.sort(Lib, items, {}, struct {
        fn lt(_: void, a: Lib, b: Lib) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.lt);

    return libs.toOwnedSlice(gpa);
}

fn hasName(libs: []const Lib, name: []const u8) bool {
    for (libs) |l| {
        if (std.mem.eql(u8, l.name, name)) return true;
    }
    return false;
}

pub fn free(gpa: std.mem.Allocator, libs: []Lib) void {
    for (libs) |l| {
        gpa.free(l.name);
        gpa.free(l.dir);
        if (l.targets) |t| freeTargets(gpa, t);
    }
    gpa.free(libs);
}

fn freeTargets(gpa: std.mem.Allocator, targets: []const []const u8) void {
    for (targets) |t| gpa.free(t);
    gpa.free(targets);
}

/// Read the `"targets"` array from a lib's `botopink.json` and return the list
/// of host-supported targets. Returns `null` when the field is absent, malformed,
/// or the manifest can't be opened — the runner treats `null` as "no whitelist,
/// run every requested target". Caller owns the slice + element strings.
///
/// Why parse the JSON here instead of routing through `compiler-cli`'s
/// `ProjectConfig`: the lib-test runner explicitly carries `no compiler-core
/// dependency` (see AGENTS.md "Design contract"). A minimal in-house parser
/// keeps that contract; the only field we read is the optional `targets`
/// array. Schema documented in `docs/botopink-json.md` — keep in sync if the
/// shape changes.
fn readManifestTargets(
    gpa: std.mem.Allocator,
    io: std.Io,
    lib_dir: std.Io.Dir,
) ?[]const []const u8 {
    const data = lib_dir.readFileAlloc(io, "botopink.json", gpa, .limited(64 * 1024)) catch return null;
    defer gpa.free(data);

    var parsed = std.json.parseFromSlice(std.json.Value, gpa, data, .{}) catch return null;
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return null;
    const targets_val = root.object.get("targets") orelse return null;
    if (targets_val != .array) return null;

    const items = targets_val.array.items;
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    out.ensureTotalCapacity(gpa, items.len) catch return null;
    for (items) |item| {
        if (item != .string) {
            // Drop a malformed list rather than partially honoring it — a
            // misspelled or wrong-shape entry would otherwise silently widen
            // the "supported" set on the runner side.
            for (out.items) |s| gpa.free(s);
            out.deinit(gpa);
            return null;
        }
        const dup = gpa.dupe(u8, item.string) catch {
            for (out.items) |s| gpa.free(s);
            out.deinit(gpa);
            return null;
        };
        out.appendAssumeCapacity(dup);
    }
    return out.toOwnedSlice(gpa) catch return null;
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

    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put(ENV_VAR, ws ++ "/store");

    // Pretend cwd is ws so the walk-up only sees the local synthetic tree.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const abs_ws = try std.fs.path.resolve(arena, &.{ cwd_buf[0..cwd_n], ws });

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
