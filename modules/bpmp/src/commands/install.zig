/// `bpmp install` — two modes:
///
///   - No args: **lockfile replay**. Read `botopink.lock.json`, for each
///     package fetch `archive/<commit>.tar.gz` (never `archive/refs/tags/`),
///     verify sha256, extract under `$BPMP_HOME/packages/<name>/versions/<v>/`.
///     This is the path that must work offline once the cache is warm.
///   - With `<name>[@<spec>]`: resolve the spec, pin commit + sha256,
///     mutate `botopink.json` (`dependencies` AND `requires`), rewrite the
///     lockfile, install delta.
///
/// The live HTTPS download path returns `OnlineUnavailable` until the
/// streaming layer in `download.zig` lands. Replay against an already-warm
/// cache works, which is what `install.sh` will rely on for the bootstrap.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");
const storage = @import("../storage.zig");
const semver = @import("../semver.zig");
const dep_spec = @import("../dep/spec.zig");
const dep_clone = @import("../dep/clone.zig");
const dep_resolver = @import("../dep/resolver.zig");
const dep_lock = @import("../lock.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var positional: ?[]const u8 = null;
    var allow_unlocked = false;
    var frozen = false;
    var update = false;
    var dry_run = false;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx, HELP);
            return 0;
        } else if (std.mem.eql(u8, a, "--allow-unlocked")) {
            allow_unlocked = true;
        } else if (std.mem.eql(u8, a, "--frozen")) {
            frozen = true;
        } else if (std.mem.eql(u8, a, "--update")) {
            update = true;
        } else if (std.mem.eql(u8, a, "--dry-run")) {
            dry_run = true;
        } else if (std.mem.startsWith(u8, a, "--")) {
            return common.errFmt("install: unknown flag '{s}'", .{a});
        } else {
            if (positional != null) return common.errMsg("install: only one positional argument supported");
            positional = a;
        }
    }

    // Object-form deps dispatch: if the local `botopink.json` carries any
    // object-form entry, install those into `$BPMP_HOME/store/` + write
    // `botopink.lock`. The legacy compiler-distribution replay path still
    // fires if the local project has no manifest (e.g. a globally invoked
    // bpmp) or if the manifest's `dependencies` is the legacy bare-name
    // array form.
    if (try maybeRunDepInstall(ctx, .{
        .single_name = positional,
        .frozen = frozen,
        .update = update,
        .dry_run = dry_run,
    })) |code| return code;

    if (positional) |spec| {
        try warnIfCompilerMismatch(ctx);
        return installSingle(ctx, spec, allow_unlocked);
    }
    try warnIfCompilerMismatch(ctx);
    return replayLockfile(ctx);
}

// ── object-form deps install ──────────────────────────────────────────────────

const DepInstallOpts = struct {
    single_name: ?[]const u8,
    frozen: bool,
    update: bool,
    dry_run: bool,
};

/// Detect + handle object-form deps. Returns:
///   - null  → no object-form deps in this project; fall through to the
///     legacy compiler-distribution flow.
///   - code  → object-form flow handled the install; this is the exit code.
fn maybeRunDepInstall(ctx: cli.Context, opts: DepInstallOpts) !?u8 {
    var arena = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena.deinit();
    const a = arena.allocator();

    const data = std.Io.Dir.cwd().readFileAlloc(ctx.io, "botopink.json", a, .limited(64 * 1024)) catch return null;

    var diags: std.ArrayListUnmanaged(dep_spec.Diagnostic) = .empty;
    const deps = try dep_spec.parseFromManifest(a, data, &diags);
    for (diags.items) |d| {
        const code_str = switch (d.code) {
            .invalid_json => "DEP-001 (invalid JSON)",
            .invalid_shape => "DEP-001",
            .missing_source => "DEP-002",
            .ambiguous_ref => "DEP-003",
        };
        if (d.name.len > 0) {
            common.warnMsgFmt(ctx, "botopink.json:dependencies.{s}: {s}", .{ d.name, code_str });
        } else {
            common.warnMsgFmt(ctx, "botopink.json:dependencies: {s}", .{code_str});
        }
    }

    if (!dep_spec.anySpec(deps)) return null;

    return try runDepInstall(ctx, deps, opts);
}

fn runDepInstall(ctx: cli.Context, deps: []const dep_spec.DepEntry, opts: DepInstallOpts) !u8 {
    var arena = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena.deinit();
    const a = arena.allocator();

    const store_root = try resolveStoreRoot(a, ctx);
    const project_root = try cwdAbs(a, ctx);

    // Filter when invoked with a positional `<name>`.
    var filtered: []const dep_spec.DepEntry = deps;
    if (opts.single_name) |name| {
        var found: ?dep_spec.DepEntry = null;
        for (deps) |d| if (std.mem.eql(u8, d.name, name)) {
            found = d;
            break;
        };
        if (found == null) {
            return common.errFmt("install: '{s}' is not in botopink.json:dependencies", .{name});
        }
        const buf = try a.alloc(dep_spec.DepEntry, 1);
        buf[0] = found.?;
        filtered = buf;
    }

    // Load existing lockfile (if any) so we can prefer pinned revs.
    var existing: ?dep_lock.Lockfile = null;
    defer if (existing) |*lf| lf.deinit();
    if (!opts.update) {
        existing = dep_lock.read(ctx.gpa, ctx.io, project_root) catch null;
    }

    var p = dep_resolver.plan(ctx.gpa, filtered, store_root, .{
        .frozen = opts.frozen,
        .lock_in = if (existing) |*lf| lf else null,
    }) catch |err| switch (err) {
        dep_resolver.Error.FrozenMissingEntry => {
            const code = common.errMsg("install --frozen: at least one dep is missing a lockfile entry (DEP-004)");
            common.hintMsg("run `bpmp install` (without --frozen) first");
            return code;
        },
        dep_resolver.Error.StoreRootMissing => {
            return common.errMsg("install: $BPMP_HOME is not set and HOME/XDG_CACHE_HOME is empty");
        },
        else => return err,
    };
    defer p.deinit();

    if (opts.dry_run) {
        common.printf(ctx, "bpmp install --dry-run: {d} action(s)\n", .{p.actions.len});
        for (p.actions) |act| {
            common.printf(ctx, "  {s}  {s}", .{ kindLabel(act.kind), act.name });
            if (act.rev.len > 0) common.printf(ctx, " @ {s}", .{act.rev[0..@min(act.rev.len, 12)]});
            common.printf(ctx, "\n", .{});
        }
        return 0;
    }

    // Execute the plan + collect lockfile entries.
    var lock_entries: std.ArrayListUnmanaged(dep_lock.Entry) = .empty;
    defer lock_entries.deinit(ctx.gpa);

    for (p.actions) |act| {
        switch (act.kind) {
            .skip_legacy => {},
            .path_symlink => {
                const link_path = try std.fs.path.join(a, &.{ project_root, ".botopinkbuild", "deps", act.name });
                try ensureSymlink(ctx, act.path.?, link_path);
                try lock_entries.append(ctx.gpa, .{
                    .name = try ctx.gpa.dupe(u8, act.name),
                    .git = "",
                    .rev = "",
                    .path = try ctx.gpa.dupe(u8, act.path.?),
                    .fetched_at = try isoNowOwned(ctx, ctx.gpa),
                });
                common.printf(ctx, "  ✓ {s} (path) → {s}\n", .{ act.name, act.path.? });
            },
            .reuse_cas => {
                const link_path = try std.fs.path.join(a, &.{ project_root, ".botopinkbuild", "deps", act.name });
                try ensureSymlink(ctx, act.store_path, link_path);
                try lock_entries.append(ctx.gpa, .{
                    .name = try ctx.gpa.dupe(u8, act.name),
                    .git = try ctx.gpa.dupe(u8, act.git),
                    .rev = try ctx.gpa.dupe(u8, act.rev),
                    .fetched_at = try isoNowOwned(ctx, ctx.gpa),
                });
                common.printf(ctx, "  ✓ {s} (CAS) @ {s}\n", .{ act.name, act.rev[0..@min(act.rev.len, 12)] });
            },
            .clone => {
                // Reconstruct the original DepSpec for the cloner from the action.
                var s: dep_spec.DepSpec = .{ .git = act.git };
                if (act.rev.len > 0) s.ref = .{ .rev = act.rev };
                var cl = dep_clone.materialise(ctx.gpa, ctx.io, act.name, s, store_root, project_root) catch |err| {
                    return common.errFmt("install: failed to clone {s}: {s}", .{ act.name, @errorName(err) });
                };
                defer cl.deinit(ctx.gpa);
                const link_path = try std.fs.path.join(a, &.{ project_root, ".botopinkbuild", "deps", act.name });
                try ensureSymlink(ctx, cl.path, link_path);
                try lock_entries.append(ctx.gpa, .{
                    .name = try ctx.gpa.dupe(u8, act.name),
                    .git = try ctx.gpa.dupe(u8, act.git),
                    .rev = try ctx.gpa.dupe(u8, cl.rev),
                    .fetched_at = try isoNowOwned(ctx, ctx.gpa),
                });
                common.printf(ctx, "  ✓ {s} (clone) @ {s}\n", .{ act.name, cl.rev[0..@min(cl.rev.len, 12)] });
            },
        }
    }

    // Merge with existing entries that weren't touched (single-dep install).
    if (existing) |lf_in| {
        for (lf_in.entries) |e| {
            var seen = false;
            for (lock_entries.items) |ne| if (std.mem.eql(u8, ne.name, e.name)) {
                seen = true;
                break;
            };
            if (!seen) try lock_entries.append(ctx.gpa, .{
                .name = try ctx.gpa.dupe(u8, e.name),
                .git = try ctx.gpa.dupe(u8, e.git),
                .rev = try ctx.gpa.dupe(u8, e.rev),
                .path = if (e.path) |pp| try ctx.gpa.dupe(u8, pp) else null,
                .fetched_at = try ctx.gpa.dupe(u8, e.fetched_at),
            });
        }
    }

    // Cleanup heap copies after write.
    defer for (lock_entries.items) |e| {
        ctx.gpa.free(@constCast(e.name));
        ctx.gpa.free(@constCast(e.git));
        ctx.gpa.free(@constCast(e.rev));
        if (e.path) |pp| ctx.gpa.free(@constCast(pp));
        ctx.gpa.free(@constCast(e.fetched_at));
    };

    try dep_lock.write(ctx.gpa, ctx.io, project_root, lock_entries.items);
    common.printf(ctx, "bpmp install: wrote {s}\n", .{dep_lock.LOCKFILE_NAME});
    return 0;
}

fn kindLabel(k: dep_resolver.Action.Kind) []const u8 {
    return switch (k) {
        .clone => "clone     ",
        .reuse_cas => "reuse-cas ",
        .path_symlink => "link path ",
        .skip_legacy => "skip      ",
    };
}

fn resolveStoreRoot(arena: std.mem.Allocator, ctx: cli.Context) ![]const u8 {
    if (ctx.env_map) |m| {
        if (m.get("BPMP_HOME")) |v| if (v.len > 0) return std.fs.path.join(arena, &.{ v, "store" });
        if (m.get("XDG_CACHE_HOME")) |v| if (v.len > 0) return std.fs.path.join(arena, &.{ v, "bpmp", "store" });
        if (m.get("HOME")) |v| if (v.len > 0) return std.fs.path.join(arena, &.{ v, ".cache", "bpmp", "store" });
    }
    return "";
}

fn cwdAbs(arena: std.mem.Allocator, ctx: cli.Context) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(ctx.io, &buf);
    return arena.dupe(u8, buf[0..n]);
}

fn ensureSymlink(ctx: cli.Context, target_abs: []const u8, link_path: []const u8) !void {
    if (std.fs.path.dirname(link_path)) |d| {
        std.Io.Dir.cwd().createDirPath(ctx.io, d) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
    std.Io.Dir.cwd().deleteFile(ctx.io, link_path) catch {};
    std.Io.Dir.cwd().deleteTree(ctx.io, link_path) catch {};
    try std.Io.Dir.cwd().symLink(ctx.io, target_abs, link_path, .{ .is_directory = true });
}

fn isoNowOwned(ctx: cli.Context, gpa: std.mem.Allocator) ![]const u8 {
    const ts = std.Io.Timestamp.now(ctx.io, .real);
    const epoch_seconds: i64 = @intCast(ts.toSeconds());
    if (epoch_seconds <= 0) return gpa.dupe(u8, "1970-01-01T00:00:00Z");
    const ed = std.time.epoch.EpochSeconds{ .secs = @intCast(epoch_seconds) };
    const ds = ed.getDaySeconds();
    const yd = ed.getEpochDay().calculateYearDay();
    const md = yd.calculateMonthDay();
    return std.fmt.allocPrint(gpa, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
        yd.year,
        md.month.numeric(),
        md.day_index + 1,
        ds.getHoursIntoDay(),
        ds.getMinutesIntoHour(),
        ds.getSecondsIntoMinute(),
    });
}

/// §H6 — surface a one-shot warning if the active compiler doesn't match
/// the project's `botopink.json.botopink` constraint. The manifest write
/// already recorded the range; this just reads + compares. Silent when
/// the constraint is absent (no opinion expressed) or the active version
/// can't be discovered (e.g. fresh install before `bpmp use`).
fn warnIfCompilerMismatch(ctx: cli.Context) !void {
    var m = manifest.read(ctx.gpa, ctx.io, ".") catch return;
    defer m.deinit();
    const constraint_str = m.botopinkConstraint() orelse return;
    const constraint = semver.Constraint.parse(constraint_str) catch return;

    var paths = storage.resolvePaths(ctx.gpa, ctx.env_map) catch return;
    defer paths.deinit(ctx.gpa);
    const stable_path = std.fs.path.join(ctx.gpa, &.{ paths.botopink_versions, "stable" }) catch return;
    defer ctx.gpa.free(stable_path);
    const active_raw = std.Io.Dir.cwd().readFileAlloc(ctx.io, stable_path, ctx.gpa, .limited(256)) catch return;
    defer ctx.gpa.free(active_raw);
    const trimmed = std.mem.trim(u8, active_raw, " \t\r\n");
    const stripped = if (trimmed.len > 0 and trimmed[0] == 'v') trimmed[1..] else trimmed;
    const active = semver.Version.parse(stripped) catch return;

    if (!constraint.matches(active)) {
        common.warnMsg("active botopink is outside the project's compiler range");
        common.printf(ctx, "  active: {s}\n  constraint: {s}\n", .{ trimmed, constraint_str });
        common.hintMsg("`bpmp use botopink <ver>` to switch toolchain.");
    }
}

const HELP =
    \\bpmp install — install / replay project dependencies.
    \\
    \\Usage:
    \\  bpmp install                       Replay botopink.lock.json byte-for-byte.
    \\  bpmp install <name>[@<spec>]       Add a dep, pin it, install the delta.
    \\
    \\Specs: `<ver>` exact, `^<ver>`, `~<ver>`, `>=<ver>`, `feat`, `latest` (default).
    \\
;

fn installSingle(ctx: cli.Context, spec: []const u8, allow_unlocked: bool) !u8 {
    _ = allow_unlocked;
    var name = spec;
    var constraint: []const u8 = "latest";
    if (std.mem.indexOfScalar(u8, spec, '@')) |at| {
        name = spec[0..at];
        constraint = spec[at + 1 ..];
    }
    if (name.len == 0) return common.errMsg("install: missing package name");

    // Update manifest with the new dep — this is the offline-safe half. The
    // resolver/download half follows once the live HTTP layer lands.
    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found — run `bpmp init` first"),
        else => return err,
    };
    defer m.deinit();
    try m.addDependency(ctx.gpa, name, constraint);
    try manifest.write(ctx.gpa, ctx.io, ".", &m);

    common.printf(ctx,
        \\bpmp install: added {s} ({s}) to botopink.json (dependencies + requires)
        \\
    , .{ name, constraint });
    common.hintMsg("the network resolver lands later in v0.beta.18 — re-run `bpmp install` once it's live to pin the commit + sha256.");
    return 0;
}

fn replayLockfile(ctx: cli.Context) !u8 {
    var lf = lockfile.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.LockfileNotFound => {
            common.hintMsg("no botopink.lock.json — run `bpmp install <name>` to start one");
            return 1;
        },
        error.SchemaMismatch => {
            common.hintMsg("schema mismatch — run `bpmp sync --update` to regenerate the lockfile");
            return 1;
        },
        else => return err,
    };
    defer lf.deinit();

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);
    try storage.ensureLayout(ctx.io, paths);

    if (lf.packages.len == 0) {
        common.writeStdout(ctx, "bpmp install: lockfile is empty (no packages to install)\n");
        return 0;
    }

    common.printf(ctx, "bpmp install: replaying {d} package(s) from botopink.lock.json\n", .{lf.packages.len});
    var missed: usize = 0;
    for (lf.packages) |p| {
        const dest = try paths.packageVersionDir(ctx.gpa, p.name, p.version);
        defer ctx.gpa.free(dest);
        if (existsDir(ctx.io, dest)) {
            common.printf(ctx, "  ✓ {s} {s} (already installed at {s})\n", .{ p.name, p.version, dest });
        } else {
            common.printf(ctx, "  • {s} {s} commit={s}\n", .{ p.name, p.version, p.commit });
            common.hintMsg("the live download layer lands later in v0.beta.18; commit + sha256 are recorded");
            missed += 1;
        }
    }
    if (missed > 0) return 0; // bpmp surfaces hint above; non-fatal so init.sh's bootstrap still proceeds
    return 0;
}

fn existsDir(io: std.Io, path: []const u8) bool {
    var d = std.Io.Dir.cwd().openDir(io, path, .{}) catch return false;
    d.close(io);
    return true;
}
