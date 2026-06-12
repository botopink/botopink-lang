/// `bpmp use botopink <spec>` — switch active compiler.
///
/// `<spec>`:
///   - `<version>` (exact) — download from `botopink-lang` GH Releases.
///   - `latest` — current highest stable.
///   - `dev --from <dir>` — link a local `zig-out` (compiler-hacker workflow).
///
/// Updates `$BPMP_HOME/botopink/versions/stable` (sentinel file pointing at
/// `<ver>`) to mark the new toolchain as active. Symlinks are platform-
/// specific (POSIX symlink vs Windows junction); the sentinel-file approach
/// works on both without privileged operations.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const storage = @import("../storage.zig");
const registry = @import("../registry.zig");
const release_mod = @import("../release.zig");

const BPMP_REPO_OWNER = "botopink";
const BPMP_REPO_NAME = "botopink-lang";
const TOOLCHAIN_BINS = [_][]const u8{ "botopink", "botopink-lsp", "botopink-lib-test", "bpmp" };

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    if (args.len < 2 or !std.mem.eql(u8, args[0], "botopink")) {
        common.writeStdout(ctx,
            \\bpmp use botopink <spec>     # <spec> = <version> | latest | dev --from <dir>
            \\
        );
        return 1;
    }
    const spec = args[1];

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);
    try storage.ensureLayout(ctx.io, paths);

    if (std.mem.eql(u8, spec, "dev")) {
        return useDev(ctx, args[2..], paths);
    }

    const auth = if (ctx.env_map) |m| m.get("GITHUB_TOKEN") else null;
    const repo: registry.RepoSpec = .{ .owner = BPMP_REPO_OWNER, .repo = BPMP_REPO_NAME };

    // Resolve `latest` → concrete tag via GH API; otherwise treat `spec` as
    // the tag. We accept both `0.0.1` and `v0.0.1` — the asset naming
    // convention from release-pack.sh is whatever the workflow tagged.
    var resolved_release: ?registry.Release = null;
    defer if (resolved_release) |r| {
        ctx.gpa.free(r.tag_name);
        ctx.gpa.free(r.name);
    };
    const tag: []const u8 = if (std.mem.eql(u8, spec, "latest")) blk: {
        const latest = registry.fetchLatestRelease(ctx.gpa, ctx.io, repo, auth) catch |err| {
            common.warnMsg("use: could not resolve `latest` from GitHub");
            common.printf(ctx, "  reason: {s}\n", .{@errorName(err)});
            return 1;
        };
        resolved_release = latest;
        break :blk latest.tag_name;
    } else spec;

    const target = release_mod.nativeTarget() orelse {
        common.warnMsg("use: target unsupported on this build");
        return 1;
    };

    const version_dir = try paths.versionDir(ctx.gpa, tag);
    defer ctx.gpa.free(version_dir);

    common.printf(ctx, "bpmp use: installing toolchain {s} into {s}\n", .{ tag, version_dir });

    var failures: usize = 0;
    for (TOOLCHAIN_BINS) |bin| {
        const result = release_mod.installOne(ctx.gpa, ctx.io, .{
            .spec = repo,
            .tag = tag,
            .target = target,
            .bin = bin,
            .dest_dir = version_dir,
            .cache_dir = paths.cache_tarballs,
            .auth_token = auth,
        }) catch |err| {
            common.warnMsg("use: install failed");
            common.printf(ctx, "  bin: {s}\n  reason: {s}\n", .{ bin, @errorName(err) });
            failures += 1;
            continue;
        };
        defer ctx.gpa.free(result.cache_path);
        defer ctx.gpa.free(result.bin_path);
        common.printf(ctx, "  ✓ {s} ({s})\n", .{ bin, if (result.cache_hit) "cache hit" else "downloaded" });
    }
    if (failures > 0) return 1;

    // Sentinel `stable` file → `<ver>`. Symlinks are unnecessarily
    // platform-specific; a single-line file is read by everything.
    const stable = try std.fs.path.join(ctx.gpa, &.{ paths.botopink_versions, "stable" });
    defer ctx.gpa.free(stable);
    try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = stable, .data = tag });

    common.printf(ctx, "bpmp use: active toolchain → {s}\n", .{tag});
    return 0;
}

fn useDev(ctx: cli.Context, args: []const []const u8, paths: storage.Paths) !u8 {
    var from: ?[]const u8 = null;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--from")) {
            i += 1;
            if (i >= args.len) return common.errMsg("--from expects a directory");
            from = args[i];
        }
    }
    const dev_src = from orelse return common.errMsg("dev requires --from <dir>");
    const dev_dir = try paths.versionDir(ctx.gpa, "dev");
    defer ctx.gpa.free(dev_dir);
    std.Io.Dir.cwd().deleteTree(ctx.io, dev_dir) catch {};
    try std.Io.Dir.cwd().createDirPath(ctx.io, dev_dir);
    const sentinel = try std.fs.path.join(ctx.gpa, &.{ dev_dir, "dev.path" });
    defer ctx.gpa.free(sentinel);
    try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = sentinel, .data = dev_src });
    common.printf(ctx, "bpmp use: dev → {s} (recorded at {s})\n", .{ dev_src, sentinel });
    return 0;
}
