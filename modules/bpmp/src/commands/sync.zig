/// `bpmp sync` — re-resolve `requires` to the current highest tag and
/// record each one's current commit SHA. Without `--update` prints drift +
/// exits non-zero so CI can flag "the lockfile is stale".
///
/// This is the **only** command that moves an existing commit pin forward;
/// `bpmp install <name>` only adds new pins (see spec §"Lockfile").
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");
const registry = @import("../registry.zig");
const semver = @import("../semver.zig");

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var update = false;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--update")) update = true
        else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx,
                \\bpmp sync [--update]
                \\
                \\Re-resolves `requires` constraints against the current tag list
                \\and reports drift. With --update, rewrites botopink.lock.json.
                \\
            );
            return 0;
        } else return common.errFmt("sync: unknown flag '{s}'", .{a});
    }

    var m = manifest.read(ctx.gpa, ctx.io, ".") catch |err| switch (err) {
        error.ManifestNotFound => return common.errMsg("botopink.json not found"),
        else => return err,
    };
    defer m.deinit();
    const deps = try m.dependencies(ctx.gpa);
    defer ctx.gpa.free(deps);

    if (deps.len == 0) {
        common.writeStdout(ctx, "bpmp sync: no dependencies declared in botopink.json\n");
        return 0;
    }

    common.printf(ctx, "bpmp sync: {d} dep(s) to re-resolve\n", .{deps.len});

    // Pull existing pins (if any) so drift reporting can compare.
    var lf: ?lockfile.Lockfile = lockfile.read(ctx.gpa, ctx.io, ".") catch null;
    defer if (lf) |*l| l.deinit();

    const auth = if (ctx.env_map) |m_env| m_env.get("GITHUB_TOKEN") else null;
    var live_ctx: registry.LiveCtx = .{ .io = ctx.io, .auth_token = auth };

    var drift_count: usize = 0;
    for (deps) |d| {
        const c = m.requirement(d) orelse "*";
        // Resolve the dep's repo. Without a registry server, we assume
        // `botopink/<name>` for now (matches how libs were structured in
        // v0.beta.18); a future spec can pull a `source` field from the
        // manifest's `dependencies.<name>` entry.
        const repo_url = try std.fmt.allocPrint(ctx.gpa, "botopink/{s}", .{d});
        defer ctx.gpa.free(repo_url);
        const repo = registry.RepoSpec.parse(repo_url) catch {
            common.printf(ctx, "  • {s: <14} bad source — skipping\n", .{d});
            continue;
        };
        const tags = registry.liveTags(&live_ctx, ctx.gpa, repo) catch |err| {
            common.printf(ctx, "  • {s: <14} fetch failed ({s})\n", .{ d, @errorName(err) });
            continue;
        };
        defer {
            for (tags) |t| {
                ctx.gpa.free(t.name);
                ctx.gpa.free(t.commit);
            }
            ctx.gpa.free(tags);
        }
        const constraint = semver.Constraint.parse(c) catch {
            common.printf(ctx, "  • {s: <14} bad constraint '{s}'\n", .{ d, c });
            continue;
        };
        const picked = semver.pickHighest(constraint, tags) orelse {
            common.printf(ctx, "  • {s: <14} no tag satisfies '{s}'\n", .{ d, c });
            continue;
        };

        const prev_commit = if (lf) |*l| if (l.findPackage(d)) |p| p.commit else "" else "";
        if (prev_commit.len > 0 and !std.mem.eql(u8, prev_commit, picked.commit)) {
            common.printf(ctx, "  • {s: <14} drift: {s}@{s} (was {s})\n", .{
                d, picked.name, picked.commit[0..@min(picked.commit.len, 7)], prev_commit[0..@min(prev_commit.len, 7)],
            });
            drift_count += 1;
        } else {
            common.printf(ctx, "  • {s: <14} {s}@{s}\n", .{
                d, picked.name, picked.commit[0..@min(picked.commit.len, 7)],
            });
        }
    }

    if (update) {
        common.hintMsg("`--update` lockfile rewrite is not yet implemented; pins above were resolved but not persisted.");
    } else if (drift_count > 0) {
        common.printf(ctx, "bpmp sync: {d} drifted pin(s). Run `bpmp sync --update` to refresh the lockfile.\n", .{drift_count});
        return 1;
    }
    return 0;
}
