/// `bpmp env` — prints a shell-source-able snippet that puts
/// `$BPMP_HOME/bin` on `PATH`. Shell auto-detected from `$SHELL`; override
/// with `--shell bash|zsh|fish|pwsh`.
///
/// `BOTOPINK_LIB_ROOTS` is **not** exported by `env` — that's per-project
/// state set by `bpmp run`, not a global. Exporting it globally would make
/// every shell session reach for whichever project last set it.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const storage = @import("../storage.zig");

const Shell = enum { bash, zsh, fish, pwsh };

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var shell: ?Shell = null;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--shell")) {
            i += 1;
            if (i >= args.len) return common.errMsg("--shell expects a value");
            shell = parseShell(args[i]) orelse return common.errFmt("env: unknown shell '{s}'", .{args[i]});
        } else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx, "bpmp env [--shell bash|zsh|fish|pwsh]\n");
            return 0;
        }
    }

    const resolved = shell orelse detectShell(ctx);

    var paths = try storage.resolvePaths(ctx.gpa, ctx.env_map);
    defer paths.deinit(ctx.gpa);

    switch (resolved) {
        .bash, .zsh => common.printf(ctx,
            \\# Append to your ~/.{s}rc:
            \\export PATH="{s}:$PATH"
            \\
        , .{ @tagName(resolved), paths.bin_dir }),
        .fish => common.printf(ctx,
            \\# Add to ~/.config/fish/config.fish:
            \\set -gx PATH {s} $PATH
            \\
        , .{paths.bin_dir}),
        .pwsh => common.printf(ctx,
            \\# Add to your PowerShell $PROFILE:
            \\$env:Path = "{s};" + $env:Path
            \\
        , .{paths.bin_dir}),
    }
    return 0;
}

fn parseShell(s: []const u8) ?Shell {
    if (std.mem.eql(u8, s, "bash")) return .bash;
    if (std.mem.eql(u8, s, "zsh")) return .zsh;
    if (std.mem.eql(u8, s, "fish")) return .fish;
    if (std.mem.eql(u8, s, "pwsh") or std.mem.eql(u8, s, "powershell")) return .pwsh;
    return null;
}

fn detectShell(ctx: cli.Context) Shell {
    if (ctx.env_map) |m| {
        if (m.get("SHELL")) |sh| {
            if (std.mem.indexOf(u8, sh, "fish") != null) return .fish;
            if (std.mem.indexOf(u8, sh, "zsh") != null) return .zsh;
            if (std.mem.indexOf(u8, sh, "pwsh") != null) return .pwsh;
        }
    }
    return .bash;
}
