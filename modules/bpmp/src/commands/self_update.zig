/// `bpmp self update` — swap the running bpmp binary in-place.
///
/// Two modes:
///   - `--check`    no install, just report current vs latest.
///   - `--toolchain` also bump the active `botopink` (resolves a fresh
///     toolchain via `bpmp use botopink <latest>`).
///
/// Atomic swap (POSIX): download the new bpmp into a staging dir, place
/// the binary at `$BPMP_HOME/bin/bpmp.new`, then `rename` over
/// `$BPMP_HOME/bin/bpmp`. The running process's file handle survives the
/// rename — the old bytes keep executing, the new bytes are picked up by
/// the next invocation.
///
/// Windows: write `bpmp.new` and document the deferred-swap helper —
/// `cmd /c move /Y bpmp.new bpmp` after the current process exits. The
/// live shim isn't spawned here; the user is shown the exact swap line.
const std = @import("std");
const builtin = @import("builtin");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const release = @import("../release.zig");
const registry = @import("../registry.zig");
const storage = @import("../storage.zig");

const BPMP_REPO_OWNER = "botopink";
const BPMP_REPO_NAME = "botopink-lang";

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var check = false;
    var toolchain = false;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--check")) check = true
        else if (std.mem.eql(u8, a, "--toolchain")) toolchain = true
        else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx,
                \\bpmp self update [--check] [--toolchain]
                \\
                \\Downloads the latest bpmp release and atomically swaps it in.
                \\--check    only compare current vs latest (no swap).
                \\--toolchain also reinstall `botopink` (`bpmp use botopink <latest>`).
                \\
            );
            return 0;
        } else return common.errFmt("self update: unknown flag '{s}'", .{a});
    }

    const current = @import("../version.zig").BPMP_VERSION;
    common.printf(ctx, "current bpmp version: {s}\n", .{current});

    const auth = if (ctx.env_map) |m| m.get("GITHUB_TOKEN") else null;
    const spec = registry.RepoSpec{ .owner = BPMP_REPO_OWNER, .repo = BPMP_REPO_NAME };
    const latest = registry.fetchLatestRelease(ctx.gpa, ctx.io, spec, auth) catch |err| {
        common.warnMsg("could not resolve latest release from GitHub");
        common.printf(ctx, "  reason: {s}\n", .{@errorName(err)});
        return 1;
    };
    defer ctx.gpa.free(latest.tag_name);
    defer ctx.gpa.free(latest.name);
    common.printf(ctx, "latest release tag: {s}\n", .{latest.tag_name});

    if (sameVersion(current, latest.tag_name)) {
        common.writeStdout(ctx, "already up to date.\n");
        return 0;
    }
    if (check) return 0;

    const target = release.nativeTarget() orelse {
        common.warnMsg("self update: target unsupported on this build (use the installer)");
        return 1;
    };

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);
    try storage.ensureLayout(ctx.io, paths);

    // Stage the new bpmp under a per-version directory so a future
    // rollback still has it locally cached.
    const stage_dir = try paths.versionDir(ctx.gpa, latest.tag_name);
    defer ctx.gpa.free(stage_dir);

    const result = release.installOne(ctx.gpa, ctx.io, .{
        .spec = spec,
        .tag = latest.tag_name,
        .target = target,
        .bin = "bpmp",
        .dest_dir = stage_dir,
        .cache_dir = paths.cache_tarballs,
        .auth_token = auth,
    }) catch |err| {
        common.warnMsg("self update: download/extract failed");
        common.printf(ctx, "  reason: {s}\n", .{@errorName(err)});
        return 1;
    };
    defer ctx.gpa.free(result.cache_path);
    defer ctx.gpa.free(result.bin_path);

    // Atomic swap into $BPMP_HOME/bin/bpmp. The running process's open
    // text image survives the rename — the OS gives the new caller the
    // new file via inode lookup, never the running one's mapping.
    const bin_target = try std.fs.path.join(ctx.gpa, &.{ paths.bin_dir, "bpmp" });
    defer ctx.gpa.free(bin_target);
    const bin_new = try std.fmt.allocPrint(ctx.gpa, "{s}.new", .{bin_target});
    defer ctx.gpa.free(bin_new);

    std.Io.Dir.cwd().copyFile(result.bin_path, std.Io.Dir.cwd(), bin_new, ctx.io, .{}) catch |err| {
        common.warnMsg("self update: stage copy failed");
        common.printf(ctx, "  reason: {s}\n", .{@errorName(err)});
        return 1;
    };

    if (builtin.os.tag == .windows) {
        common.printf(ctx,
            \\self update: staged new bpmp at {s}
            \\Windows manual swap (run from a new shell after this process exits):
            \\  cmd /c move /Y "{s}" "{s}"
            \\
        , .{ bin_new, bin_new, bin_target });
    } else {
        storage.atomicMove(ctx.io, bin_new, bin_target) catch |err| {
            common.warnMsg("self update: rename failed");
            common.printf(ctx, "  reason: {s}\n", .{@errorName(err)});
            return 1;
        };
        common.printf(ctx, "self update: bpmp swapped to {s}.\n", .{latest.tag_name});
    }

    if (toolchain) {
        common.hintMsg("`bpmp use botopink latest` will pull the matching toolchain.");
    }
    return 0;
}

/// Match `current` (which may be `0.0.1`) against a release tag (which may
/// be `v0.0.1`). We are deliberately lax — leading `v` is ignored.
fn sameVersion(current: []const u8, tag: []const u8) bool {
    const a = if (current.len > 0 and current[0] == 'v') current[1..] else current;
    const b = if (tag.len > 0 and tag[0] == 'v') tag[1..] else tag;
    return std.mem.eql(u8, a, b);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "sameVersion: strips leading v on either side" {
    try testing.expect(sameVersion("0.0.1", "v0.0.1"));
    try testing.expect(sameVersion("v0.0.1", "0.0.1"));
    try testing.expect(sameVersion("v0.0.1", "v0.0.1"));
    try testing.expect(!sameVersion("0.0.1", "0.0.2"));
}
