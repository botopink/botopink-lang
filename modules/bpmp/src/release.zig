/// Release-asset installer — the shared "fetch sidecar + tarball, verify,
/// extract" flow used by `bpmp self update` (single binary) and
/// `bpmp use botopink <ver>` (full toolchain).
///
/// The release-pack contract from `scripts/release-pack.sh` is:
///
///   `<bin>-<ver>-<target>.<ext>`         (archive; tar.gz or zip; flat)
///   `<bin>-<ver>-<target>.<ext>.sha256`  (single 64-hex-char line)
///
/// Each archive contains exactly one file at top level (no embedded
/// directory) so `extract.Options.strip_components` stays `0`. The sha256
/// sidecar drives `download.fetch`'s content-addressed cache: a second
/// `bpmp use` of the same version is hermetic.
const std = @import("std");
const download = @import("./download.zig");
const extract = @import("./extract.zig");
const registry = @import("./registry.zig");

pub const Target = struct {
    os: []const u8, // "linux" | "macos" | "windows"
    arch: []const u8, // "x86_64" | "aarch64"

    pub fn ext(self: Target) []const u8 {
        return if (std.mem.eql(u8, self.os, "windows")) "zip" else "tar.gz";
    }

    pub fn exeSuffix(self: Target) []const u8 {
        return if (std.mem.eql(u8, self.os, "windows")) ".exe" else "";
    }

    pub fn tuple(self: Target, gpa: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(gpa, "{s}-{s}", .{ self.os, self.arch });
    }
};

/// Detect the build target from `@import("builtin")`. Used as the default
/// when `bpmp self update` / `bpmp use botopink <ver>` aren't passed an
/// explicit `--target`.
pub fn nativeTarget() ?Target {
    const builtin = @import("builtin");
    const os: []const u8 = switch (builtin.os.tag) {
        .linux => "linux",
        .macos => "macos",
        .windows => "windows",
        else => return null,
    };
    const arch: []const u8 = switch (builtin.cpu.arch) {
        .x86_64 => "x86_64",
        .aarch64 => "aarch64",
        else => return null,
    };
    return .{ .os = os, .arch = arch };
}

pub const InstallOptions = struct {
    /// `<owner>/<repo>` carrying the release assets.
    spec: registry.RepoSpec,
    /// Release tag (`v0.0.1` etc.).
    tag: []const u8,
    /// Asset target tuple (`linux-x86_64`, …).
    target: Target,
    /// Binary stem — e.g. `bpmp` (asset becomes `bpmp-<tag>-<target>.<ext>`).
    bin: []const u8,
    /// Destination directory; the extracted file lands flat under here.
    dest_dir: []const u8,
    /// Cache root — bpmp's `<BPMP_HOME>/cache/tarballs/`.
    cache_dir: []const u8,
    /// Optional GH auth token (CI sets `GITHUB_TOKEN`).
    auth_token: ?[]const u8 = null,
};

pub const InstallResult = struct {
    /// Cached archive path. Caller owns via `gpa`.
    cache_path: []u8,
    /// Final extracted binary path. Caller owns via `gpa`.
    bin_path: []u8,
    /// True iff the cache short-circuited the HTTP fetch.
    cache_hit: bool,
};

/// Download `<bin>-<tag>-<target>.<ext>` + its sidecar, verify the sha,
/// extract the single binary into `dest_dir`, and return both paths.
pub fn installOne(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts: InstallOptions,
) !InstallResult {
    const tuple = try opts.target.tuple(gpa);
    defer gpa.free(tuple);

    const ext = opts.target.ext();
    const archive_name = try std.fmt.allocPrint(
        gpa,
        "{s}-{s}-{s}.{s}",
        .{ opts.bin, opts.tag, tuple, ext },
    );
    defer gpa.free(archive_name);

    const tarball_url = try opts.spec.releaseAssetUrl(gpa, opts.tag, archive_name);
    defer gpa.free(tarball_url);

    const sidecar_name = try std.fmt.allocPrint(gpa, "{s}.sha256", .{archive_name});
    defer gpa.free(sidecar_name);

    const sidecar_url = try opts.spec.releaseAssetUrl(gpa, opts.tag, sidecar_name);
    defer gpa.free(sidecar_url);

    // 1. Sidecar — no cache. Small, unknown digest, refetch every time.
    const sidecar_bytes = try download.fetchBytes(gpa, io, sidecar_url, opts.auth_token, 3);
    defer gpa.free(sidecar_bytes);
    const expected_hex = try @import("./sha256.zig").parseSidecar(sidecar_bytes);

    // 2. Tarball — content-addressed cache.
    const fr = try download.fetch(gpa, io, tarball_url, &expected_hex, .{
        .cache_dir = opts.cache_dir,
        .ext = ext,
        .auth_token = opts.auth_token,
    });
    errdefer gpa.free(fr.cache_path);

    // 3. Extract — release archives are flat (no leading dir).
    try std.Io.Dir.cwd().createDirPath(io, opts.dest_dir);
    if (std.mem.eql(u8, ext, "tar.gz")) {
        try extract.extractTarGz(gpa, io, fr.cache_path, opts.dest_dir, .{});
    } else {
        try extract.extractZip(gpa, io, fr.cache_path, opts.dest_dir, .{});
    }

    const bin_name = try std.fmt.allocPrint(gpa, "{s}{s}", .{ opts.bin, opts.target.exeSuffix() });
    defer gpa.free(bin_name);
    const bin_path = try std.fs.path.join(gpa, &.{ opts.dest_dir, bin_name });

    return .{
        .cache_path = fr.cache_path,
        .bin_path = bin_path,
        .cache_hit = fr.cache_hit,
    };
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "Target.ext / exeSuffix vary by os" {
    const linux: Target = .{ .os = "linux", .arch = "x86_64" };
    try testing.expectEqualStrings("tar.gz", linux.ext());
    try testing.expectEqualStrings("", linux.exeSuffix());

    const win: Target = .{ .os = "windows", .arch = "x86_64" };
    try testing.expectEqualStrings("zip", win.ext());
    try testing.expectEqualStrings(".exe", win.exeSuffix());
}

test "Target.tuple formats as <os>-<arch>" {
    const t: Target = .{ .os = "macos", .arch = "aarch64" };
    const s = try t.tuple(testing.allocator);
    defer testing.allocator.free(s);
    try testing.expectEqualStrings("macos-aarch64", s);
}

test "nativeTarget: returns a recognised tuple on this build" {
    const got = nativeTarget() orelse return; // wasm/etc — skip
    try testing.expect(got.os.len > 0);
    try testing.expect(got.arch.len > 0);
}
