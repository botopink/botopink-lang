/// `$BPMP_HOME` resolution + on-disk layout helpers.
///
/// ```text
/// $BPMP_HOME/                                  # default: $HOME/.bpmp  (Windows: %USERPROFILE%\.bpmp)
/// ├── bin/
/// │   └── bpmp                                 # shim → active version's bpmp
/// ├── botopink/
/// │   └── versions/
/// │       ├── <ver>/
/// │       │   ├── botopink
/// │       │   ├── botopink-lsp
/// │       │   ├── botopink-lib-test
/// │       │   └── bpmp
/// │       └── stable -> <ver>
/// ├── packages/
/// │   └── <name>/versions/<ver>/{botopink.json,src/…}
/// ├── cache/
/// │   ├── tarballs/<sha256>.<ext>
/// │   └── manifests/<owner>-<repo>.<sha7>.json
/// └── lock                                     # fs flock for "one bpmp at a time"
/// ```
///
/// Resolution precedence:
///   1. `$BPMP_HOME` env var (explicit override).
///   2. `$HOME/.bpmp` on POSIX / `%USERPROFILE%\.bpmp` on Windows.
///   3. error.NoHome (no usable env) — bpmp refuses to operate without a home.
const std = @import("std");

pub const Error = error{
    NoHome,
    StorageWriteFailed,
} || std.mem.Allocator.Error;

pub const EnvMap = ?*const std.process.Environ.Map;

/// Resolve the active `$BPMP_HOME` directory. Caller owns the returned slice.
pub fn home(gpa: std.mem.Allocator, env_map: EnvMap) Error![]u8 {
    if (env_map) |m| {
        if (m.get("BPMP_HOME")) |v| if (v.len > 0) return gpa.dupe(u8, v);
        // POSIX `$HOME` / Windows `%USERPROFILE%`.
        if (m.get("HOME")) |home_dir| if (home_dir.len > 0)
            return std.fs.path.join(gpa, &.{ home_dir, ".bpmp" });
        if (m.get("USERPROFILE")) |up| if (up.len > 0)
            return std.fs.path.join(gpa, &.{ up, ".bpmp" });
    }
    return error.NoHome;
}

/// One resolved set of paths derived from a home directory. All slices are
/// owned by `gpa`; free via `deinit`.
pub const Paths = struct {
    home: []u8,
    bin_dir: []u8,
    botopink_versions: []u8,
    packages: []u8,
    cache_tarballs: []u8,
    cache_manifests: []u8,
    lock_file: []u8,

    pub fn deinit(self: *Paths, gpa: std.mem.Allocator) void {
        gpa.free(self.home);
        gpa.free(self.bin_dir);
        gpa.free(self.botopink_versions);
        gpa.free(self.packages);
        gpa.free(self.cache_tarballs);
        gpa.free(self.cache_manifests);
        gpa.free(self.lock_file);
    }

    pub fn versionDir(self: Paths, gpa: std.mem.Allocator, version: []const u8) ![]u8 {
        return std.fs.path.join(gpa, &.{ self.botopink_versions, version });
    }

    pub fn packageVersionDir(
        self: Paths,
        gpa: std.mem.Allocator,
        name: []const u8,
        version: []const u8,
    ) ![]u8 {
        return std.fs.path.join(gpa, &.{ self.packages, name, "versions", version });
    }

    pub fn cachedTarball(
        self: Paths,
        gpa: std.mem.Allocator,
        sha256_hex: []const u8,
        ext: []const u8,
    ) ![]u8 {
        const name = try std.fmt.allocPrint(gpa, "{s}.{s}", .{ sha256_hex, ext });
        defer gpa.free(name);
        return std.fs.path.join(gpa, &.{ self.cache_tarballs, name });
    }
};

pub fn resolvePaths(gpa: std.mem.Allocator, env_map: EnvMap) !Paths {
    const root = try home(gpa, env_map);
    errdefer gpa.free(root);
    return .{
        .home = root,
        .bin_dir = try std.fs.path.join(gpa, &.{ root, "bin" }),
        .botopink_versions = try std.fs.path.join(gpa, &.{ root, "botopink", "versions" }),
        .packages = try std.fs.path.join(gpa, &.{ root, "packages" }),
        .cache_tarballs = try std.fs.path.join(gpa, &.{ root, "cache", "tarballs" }),
        .cache_manifests = try std.fs.path.join(gpa, &.{ root, "cache", "manifests" }),
        .lock_file = try std.fs.path.join(gpa, &.{ root, "lock" }),
    };
}

/// `mkdir -p` every directory the layout needs. Idempotent.
pub fn ensureLayout(io: std.Io, p: Paths) !void {
    const dirs = [_][]const u8{
        p.home,                                                                          p.bin_dir,
        p.botopink_versions,                                                             p.packages,
        p.cache_tarballs,                                                                p.cache_manifests,
    };
    for (dirs) |d| {
        std.Io.Dir.cwd().createDirPath(io, d) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
}

/// Move `src` to `dst` atomically — used for "write-temp, rename into place".
/// Wraps `std.posix.rename` semantics: the move is atomic on the same fs.
pub fn atomicMove(io: std.Io, src: []const u8, dst: []const u8) !void {
    if (std.fs.path.dirname(dst)) |parent| {
        std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
    try std.Io.Dir.cwd().rename(src, std.Io.Dir.cwd(), dst, io);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "home: honours $BPMP_HOME override" {
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put("BPMP_HOME", "/tmp/x/.bpmp");
    const h = try home(testing.allocator, &map);
    defer testing.allocator.free(h);
    try testing.expectEqualStrings("/tmp/x/.bpmp", h);
}

test "home: falls back to $HOME/.bpmp on POSIX" {
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put("HOME", "/home/u");
    const h = try home(testing.allocator, &map);
    defer testing.allocator.free(h);
    try testing.expect(std.mem.endsWith(u8, h, "/.bpmp"));
    try testing.expect(std.mem.startsWith(u8, h, "/home/u"));
}

test "home: errors when no env source is available" {
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try testing.expectError(error.NoHome, home(testing.allocator, &map));
    try testing.expectError(error.NoHome, home(testing.allocator, null));
}

test "resolvePaths derives the expected layout" {
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    try map.put("BPMP_HOME", "/r");

    var paths = try resolvePaths(testing.allocator, &map);
    defer paths.deinit(testing.allocator);

    try testing.expectEqualStrings("/r", paths.home);
    try testing.expectEqualStrings("/r/bin", paths.bin_dir);
    try testing.expectEqualStrings("/r/botopink/versions", paths.botopink_versions);
    try testing.expectEqualStrings("/r/packages", paths.packages);
    try testing.expectEqualStrings("/r/cache/tarballs", paths.cache_tarballs);
}

test "Paths.versionDir + packageVersionDir + cachedTarball" {
    var paths = Paths{
        .home = try testing.allocator.dupe(u8, "/r"),
        .bin_dir = try testing.allocator.dupe(u8, "/r/bin"),
        .botopink_versions = try testing.allocator.dupe(u8, "/r/botopink/versions"),
        .packages = try testing.allocator.dupe(u8, "/r/packages"),
        .cache_tarballs = try testing.allocator.dupe(u8, "/r/cache/tarballs"),
        .cache_manifests = try testing.allocator.dupe(u8, "/r/cache/manifests"),
        .lock_file = try testing.allocator.dupe(u8, "/r/lock"),
    };
    defer paths.deinit(testing.allocator);

    const vd = try paths.versionDir(testing.allocator, "0.0.1");
    defer testing.allocator.free(vd);
    try testing.expectEqualStrings("/r/botopink/versions/0.0.1", vd);

    const pkgvd = try paths.packageVersionDir(testing.allocator, "erika", "0.0.1");
    defer testing.allocator.free(pkgvd);
    try testing.expectEqualStrings("/r/packages/erika/versions/0.0.1", pkgvd);

    const tb = try paths.cachedTarball(testing.allocator, "abc123", "tar.gz");
    defer testing.allocator.free(tb);
    try testing.expectEqualStrings("/r/cache/tarballs/abc123.tar.gz", tb);
}
