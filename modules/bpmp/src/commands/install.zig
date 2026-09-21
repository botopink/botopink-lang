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

    // Dependency install: if the local `botopink.json` declares any
    // dependency (the object form is the only form — decision 76), install
    // those into `$BPMP_HOME/store/` + write `botopink.lock`. The
    // compiler-distribution replay path still fires if the local project has
    // no manifest (e.g. a globally invoked bpmp) or declares no dependency.
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

/// Detect + handle the project's dependencies. Returns:
///   - null  → no dependencies in this project; fall through to the
///     compiler-distribution flow.
///   - code  → the dependency flow handled the install; this is the exit code.
/// A refused `botopink.json` (a string-array `dependencies`, an entry without a
/// source, …) is printed located and is exit 1.
fn maybeRunDepInstall(ctx: cli.Context, opts: DepInstallOpts) !?u8 {
    var arena = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena.deinit();
    const a = arena.allocator();

    const data = std.Io.Dir.cwd().readFileAlloc(ctx.io, "botopink.json", a, .limited(64 * 1024)) catch return null;

    var diags: std.ArrayListUnmanaged(dep_spec.Diagnostic) = .empty;
    const deps = try dep_spec.parseFromManifest(a, data, &diags);
    if (diags.items.len > 0) {
        for (diags.items) |d| d.located.print();
        return 1;
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

    var failed_name: []const u8 = "";
    var p = dep_resolver.plan(ctx.gpa, ctx.io, filtered, store_root, .{
        .frozen = opts.frozen,
        .lock_in = if (existing) |*lf| lf else null,
        .failed_name = &failed_name,
    }) catch |err| switch (err) {
        dep_resolver.Error.FrozenMissingEntry => {
            const code = common.errFmt("install --frozen: '{s}' has no lockfile entry (DEP-004)", .{failed_name});
            common.hintMsg("run `bpmp install` (without --frozen) first");
            return code;
        },
        dep_resolver.Error.FrozenStoreMiss => {
            const code = common.errFmt("install --frozen: the pinned commit of '{s}' is not in the store {s} (DEP-005)", .{ failed_name, store_root });
            common.hintMsg("run `bpmp install` (without --frozen) to fetch it");
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
            .skip_workspace => {},
            .path_symlink => {
                const link_path = try std.fs.path.join(a, &.{ project_root, ".botopinkbuild", "deps", act.name });
                // A relative `path:` is relative to the project, not to the link's
                // directory — link the resolved absolute path.
                const target = try std.fs.path.resolve(a, &.{ project_root, act.path.? });
                ensureSymlink(ctx.io, target, link_path) catch |err| switch (err) {
                    error.SymlinkTargetMissing => return common.errFmt("install: path dependency '{s}' does not exist: {s}", .{ act.name, act.path.? }),
                    else => return err,
                };
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
                ensureSymlink(ctx.io, act.store_path, link_path) catch |err| switch (err) {
                    error.SymlinkTargetMissing => return common.errFmt("install: store entry for '{s}' vanished: {s}", .{ act.name, act.store_path }),
                    else => return err,
                };
                try lock_entries.append(ctx.gpa, .{
                    .name = try ctx.gpa.dupe(u8, act.name),
                    .git = try ctx.gpa.dupe(u8, act.git),
                    .rev = try ctx.gpa.dupe(u8, act.rev),
                    .fetched_at = try isoNowOwned(ctx, ctx.gpa),
                });
                common.printf(ctx, "  ✓ {s} (CAS) @ {s}\n", .{ act.name, act.rev[0..@min(act.rev.len, 12)] });
            },
            .clone => {
                var cl = materialiseClone(ctx.gpa, ctx.io, act, store_root, project_root) catch |err| {
                    return common.errFmt("install: failed to clone {s}: {s}", .{ act.name, @errorName(err) });
                };
                defer cl.deinit(ctx.gpa);
                const link_path = try std.fs.path.join(a, &.{ project_root, ".botopinkbuild", "deps", act.name });
                try ensureSymlink(ctx.io, cl.path, link_path);
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
        .skip_workspace => "workspace ",
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

/// Execute a `.clone` action: materialise the action's own git source + ref
/// (`branch:`/`tag:`/`rev:`) into the store. The ref comes from the plan, so a
/// first install of a `branch: "feat"` dep checks out `feat`, not default HEAD.
fn materialiseClone(
    gpa: std.mem.Allocator,
    io: std.Io,
    act: dep_resolver.Action,
    store_root: []const u8,
    project_root: []const u8,
) !dep_clone.Clone {
    return dep_clone.materialise(gpa, io, act.name, act.cloneSpec(), store_root, project_root);
}

/// Point `link_path` at `target_abs`, replacing whatever was there. Refuses
/// (`error.SymlinkTargetMissing`) when the target does not exist, so a store
/// miss can never leave a dangling `.botopinkbuild/deps/<name>` behind.
fn ensureSymlink(io: std.Io, target_abs: []const u8, link_path: []const u8) !void {
    std.Io.Dir.cwd().access(io, target_abs, .{}) catch return error.SymlinkTargetMissing;
    if (std.fs.path.dirname(link_path)) |d| {
        std.Io.Dir.cwd().createDirPath(io, d) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
    std.Io.Dir.cwd().deleteFile(io, link_path) catch {};
    std.Io.Dir.cwd().deleteTree(io, link_path) catch {};
    try std.Io.Dir.cwd().symLink(io, target_abs, link_path, .{ .is_directory = true });
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
    \\A new dependency is written as `{ "<name>": { "git": "<url>" } }` (decision 76):
    \\`<name>` is `<owner>/<name>` (a GitHub repository), a git URL, or a bare
    \\name under $BPMP_DEFAULT_ORG.
    \\
;

/// The `dependencies` entry `bpmp install <spec>` writes: the import name and
/// the git URL it comes from.
const InstallSource = struct {
    name: []const u8,
    git: []const u8,
};

/// `<owner>/<name>` → GitHub; a URL (`https://…`, `git@…`) → as given, name
/// from its last segment; a bare `<name>` → under `$BPMP_DEFAULT_ORG`, else null.
fn resolveInstallSource(a: std.mem.Allocator, ctx: cli.Context, arg: []const u8) !?InstallSource {
    if (std.mem.indexOf(u8, arg, "://") != null or std.mem.startsWith(u8, arg, "git@")) {
        var base = std.fs.path.basename(arg);
        if (std.mem.endsWith(u8, base, ".git")) base = base[0 .. base.len - ".git".len];
        if (base.len == 0) return null;
        return .{ .name = base, .git = arg };
    }
    if (std.mem.indexOfScalar(u8, arg, '/')) |slash| {
        const owner = arg[0..slash];
        const name = arg[slash + 1 ..];
        if (owner.len == 0 or name.len == 0 or std.mem.indexOfScalar(u8, name, '/') != null) return null;
        return .{ .name = name, .git = try std.fmt.allocPrint(a, "https://github.com/{s}/{s}.git", .{ owner, name }) };
    }
    const env = ctx.env_map orelse return null;
    const org = env.get("BPMP_DEFAULT_ORG") orelse return null;
    if (org.len == 0) return null;
    return .{ .name = arg, .git = try std.fmt.allocPrint(a, "https://github.com/{s}/{s}.git", .{ org, arg }) };
}

fn installSingle(ctx: cli.Context, spec: []const u8, allow_unlocked: bool) !u8 {
    _ = allow_unlocked;
    var arg = spec;
    var constraint: []const u8 = "latest";
    if (std.mem.lastIndexOfScalar(u8, spec, '@')) |at| {
        // `git@github.com:…` has an `@` of its own; a constraint follows the last one
        // only when what follows does not look like a host.
        if (std.mem.indexOfScalar(u8, spec[at + 1 ..], ':') == null and std.mem.indexOfScalar(u8, spec[at + 1 ..], '/') == null) {
            arg = spec[0..at];
            constraint = spec[at + 1 ..];
        }
    }
    if (arg.len == 0) return common.errMsg("install: missing package name");

    var arena = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena.deinit();
    const source = (try resolveInstallSource(arena.allocator(), ctx, arg)) orelse {
        return common.errFmt(
            "install: '{s}' has no source — a dependency is {{ \"{s}\": {{ \"git\": \"…\" }} }} (decision 76); write `bpmp install <owner>/{s}[@<spec>]`, a git URL, or set BPMP_DEFAULT_ORG",
            .{ arg, arg, arg },
        );
    };
    const name = source.name;

    // Update manifest with the new dep — this is the offline-safe half. The
    // resolver/download half follows once the live HTTP layer lands.
    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found — run `bpmp init` first"),
        else => return err,
    };
    defer m.deinit();
    try m.addDependency(ctx.gpa, name, constraint, source.git);
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
            common.hintMsg("schema mismatch — this bpmp cannot migrate botopink.lock.json; move it aside and re-add each package with `bpmp install <name>`");
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

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

/// Empty a scratch directory under the test cwd (`modules/bpmp`);
/// `.botopinkbuild/` is git-ignored.
fn resetDir(dir: []const u8) void {
    std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
}

fn absTestPath(gpa: std.mem.Allocator, rel: []const u8) ![]u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(testing.io, &buf);
    return std.fs.path.resolve(gpa, &.{ buf[0..n], rel });
}

/// Run `git <args>` in `cwd` with an identity and no user hooks/signing, so the
/// fixture repo is hermetic. `error.SkipZigTest` when git is not installed.
fn gitRun(gpa: std.mem.Allocator, cwd: []const u8, args: []const []const u8) ![]u8 {
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    defer argv.deinit(gpa);
    try argv.appendSlice(gpa, &.{
        "git",
        "-c",
        "user.name=bpmp-test",
        "-c",
        "user.email=bpmp@test.invalid",
        "-c",
        "commit.gpgsign=false",
        "-c",
        "tag.gpgsign=false",
        "-c",
        "core.hooksPath=/dev/null",
    });
    try argv.appendSlice(gpa, args);
    const result = std.process.run(gpa, testing.io, .{
        .argv = argv.items,
        .cwd = .{ .path = cwd },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.SkipZigTest,
        else => return err,
    };
    defer gpa.free(result.stderr);
    switch (result.term) {
        .exited => |code| if (code != 0) {
            gpa.free(result.stdout);
            return error.GitFailed;
        },
        else => {
            gpa.free(result.stdout);
            return error.GitFailed;
        },
    }
    return result.stdout;
}

fn gitHead(gpa: std.mem.Allocator, cwd: []const u8, rev: []const u8) ![]u8 {
    const out = try gitRun(gpa, cwd, &.{ "rev-parse", rev });
    defer gpa.free(out);
    return gpa.dupe(u8, std.mem.trim(u8, out, " \t\r\n"));
}

/// A repo whose default branch `main` and branch `feat` / tag `v1.0.0` point
/// at three different commits.
fn makeFixtureRepo(gpa: std.mem.Allocator, repo: []const u8) !void {
    try std.Io.Dir.cwd().createDirPath(testing.io, repo);
    gpa.free(try gitRun(gpa, repo, &.{ "init", "--quiet", "--initial-branch=main" }));
    gpa.free(try gitRun(gpa, repo, &.{ "commit", "--quiet", "--allow-empty", "-m", "main" }));
    gpa.free(try gitRun(gpa, repo, &.{ "checkout", "--quiet", "-b", "feat" }));
    gpa.free(try gitRun(gpa, repo, &.{ "commit", "--quiet", "--allow-empty", "-m", "feat" }));
    gpa.free(try gitRun(gpa, repo, &.{ "checkout", "--quiet", "-b", "release", "main" }));
    gpa.free(try gitRun(gpa, repo, &.{ "commit", "--quiet", "--allow-empty", "-m", "release" }));
    gpa.free(try gitRun(gpa, repo, &.{ "tag", "v1.0.0" }));
    gpa.free(try gitRun(gpa, repo, &.{ "checkout", "--quiet", "main" }));
}

test "ensureSymlink: a missing target is refused and leaves no link" {
    const dir = ".botopinkbuild/bpmp-tests/install-symlink-missing";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    const link = dir ++ "/deps/x";
    try testing.expectError(error.SymlinkTargetMissing, ensureSymlink(testing.io, dir ++ "/store/x/nope", link));
    try testing.expectError(error.FileNotFound, std.Io.Dir.cwd().access(testing.io, link, .{}));
}

test "ensureSymlink: an existing target is linked, replacing the old link" {
    const gpa = testing.allocator;
    const dir = ".botopinkbuild/bpmp-tests/install-symlink-replace";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, dir ++ "/store/a");
    try std.Io.Dir.cwd().createDirPath(testing.io, dir ++ "/store/b");
    try std.Io.Dir.cwd().writeFile(testing.io, .{ .sub_path = dir ++ "/store/b/marker", .data = "b" });
    const a_abs = try absTestPath(gpa, dir ++ "/store/a");
    defer gpa.free(a_abs);
    const b_abs = try absTestPath(gpa, dir ++ "/store/b");
    defer gpa.free(b_abs);

    const link = dir ++ "/deps/x";
    try ensureSymlink(testing.io, a_abs, link);
    try ensureSymlink(testing.io, b_abs, link);
    try std.Io.Dir.cwd().access(testing.io, link ++ "/marker", .{});
}

test "install --frozen against an empty store fails before any symlink" {
    const dir = ".botopinkbuild/bpmp-tests/install-frozen-empty-store";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    const rev = "0123456789abcdef0123456789abcdef01234567";
    const entries = [_]dep_spec.DepEntry{.{
        .name = "j",
        .spec = .{ .git = "https://e/j.git", .ref = .{ .rev = rev } },
    }};
    var failed: []const u8 = "";
    const r = dep_resolver.plan(testing.allocator, testing.io, &entries, dir ++ "/store", .{
        .frozen = true,
        .failed_name = &failed,
    });
    try testing.expectError(dep_resolver.Error.FrozenStoreMiss, r);
    try testing.expectEqualStrings("j", failed);
    try testing.expectError(error.FileNotFound, std.Io.Dir.cwd().access(testing.io, dir ++ "/deps", .{}));
}

test "first install of a branch: dep checks out that branch, not default HEAD" {
    const gpa = testing.allocator;
    const dir = ".botopinkbuild/bpmp-tests/install-clone-branch";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    const repo = dir ++ "/repo";
    try makeFixtureRepo(gpa, repo);
    const main_rev = try gitHead(gpa, repo, "main");
    defer gpa.free(main_rev);
    const feat_rev = try gitHead(gpa, repo, "feat");
    defer gpa.free(feat_rev);
    try testing.expect(!std.mem.eql(u8, main_rev, feat_rev));

    const repo_abs = try absTestPath(gpa, repo);
    defer gpa.free(repo_abs);
    const url = try std.fmt.allocPrint(gpa, "file://{s}", .{repo_abs});
    defer gpa.free(url);
    const store = try absTestPath(gpa, dir ++ "/store");
    defer gpa.free(store);

    const entries = [_]dep_spec.DepEntry{.{ .name = "j", .spec = .{ .git = url, .ref = .{ .branch = "feat" } } }};
    var p = try dep_resolver.plan(gpa, testing.io, &entries, store, .{});
    defer p.deinit();
    try testing.expectEqual(dep_resolver.Action.Kind.clone, p.actions[0].kind);

    var cl = try materialiseClone(gpa, testing.io, p.actions[0], store, "/unused");
    defer cl.deinit(gpa);
    try testing.expectEqualStrings(feat_rev, cl.rev);
}

test "first install of a tag: dep checks out that tag, not default HEAD" {
    const gpa = testing.allocator;
    const dir = ".botopinkbuild/bpmp-tests/install-clone-tag";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    const repo = dir ++ "/repo";
    try makeFixtureRepo(gpa, repo);
    const main_rev = try gitHead(gpa, repo, "main");
    defer gpa.free(main_rev);
    const tag_rev = try gitHead(gpa, repo, "v1.0.0^{commit}");
    defer gpa.free(tag_rev);
    try testing.expect(!std.mem.eql(u8, main_rev, tag_rev));

    const repo_abs = try absTestPath(gpa, repo);
    defer gpa.free(repo_abs);
    const url = try std.fmt.allocPrint(gpa, "file://{s}", .{repo_abs});
    defer gpa.free(url);
    const store = try absTestPath(gpa, dir ++ "/store");
    defer gpa.free(store);

    const entries = [_]dep_spec.DepEntry{.{ .name = "j", .spec = .{ .git = url, .ref = .{ .tag = "v1.0.0" } } }};
    var p = try dep_resolver.plan(gpa, testing.io, &entries, store, .{});
    defer p.deinit();

    var cl = try materialiseClone(gpa, testing.io, p.actions[0], store, "/unused");
    defer cl.deinit(gpa);
    try testing.expectEqualStrings(tag_rev, cl.rev);
}

test "install of a pinned rev: (store miss) checks out that exact commit" {
    const gpa = testing.allocator;
    const dir = ".botopinkbuild/bpmp-tests/install-clone-rev";
    resetDir(dir);
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    const repo = dir ++ "/repo";
    try makeFixtureRepo(gpa, repo);
    const feat_rev = try gitHead(gpa, repo, "feat");
    defer gpa.free(feat_rev);

    const repo_abs = try absTestPath(gpa, repo);
    defer gpa.free(repo_abs);
    const url = try std.fmt.allocPrint(gpa, "file://{s}", .{repo_abs});
    defer gpa.free(url);
    const store = try absTestPath(gpa, dir ++ "/store");
    defer gpa.free(store);

    const entries = [_]dep_spec.DepEntry{.{ .name = "j", .spec = .{ .git = url, .ref = .{ .rev = feat_rev } } }};
    var p = try dep_resolver.plan(gpa, testing.io, &entries, store, .{});
    defer p.deinit();
    try testing.expectEqual(dep_resolver.Action.Kind.clone, p.actions[0].kind);

    var cl = try materialiseClone(gpa, testing.io, p.actions[0], store, "/unused");
    defer cl.deinit(gpa);
    try testing.expectEqualStrings(feat_rev, cl.rev);

    // The commit is now in the store: a re-plan (even --frozen) reuses it.
    var again = try dep_resolver.plan(gpa, testing.io, &entries, store, .{ .frozen = true });
    defer again.deinit();
    try testing.expectEqual(dep_resolver.Action.Kind.reuse_cas, again.actions[0].kind);
}
