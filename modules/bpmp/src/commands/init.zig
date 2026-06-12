/// `bpmp init` — write a fresh `botopink.json` + `botopink.lock.json` pair
/// in the current directory. Refuses if either file already exists (use
/// `bpmp install` / `bpmp sync` for existing projects).
///
/// Defaults:
///   `--name`    cwd basename
///   `--target`  commonJS
///   `--version` 0.0.1
const std = @import("std");
const cli = @import("../cli.zig");
const manifest = @import("../manifest.zig");
const lockfile = @import("../lockfile.zig");

const Options = struct {
    name: ?[]const u8 = null,
    version: []const u8 = "0.0.1",
    target: []const u8 = "commonJS",
};

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var opts: Options = .{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--name")) {
            i += 1;
            if (i >= args.len) return printErr(ctx, "--name expects a value");
            opts.name = args[i];
        } else if (std.mem.eql(u8, a, "--version")) {
            i += 1;
            if (i >= args.len) return printErr(ctx, "--version expects a value");
            opts.version = args[i];
        } else if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return printErr(ctx, "--target expects a value");
            opts.target = args[i];
        } else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            try writeStdout(ctx, HELP);
            return 0;
        } else {
            return printErr(ctx, "init: unknown flag");
        }
    }

    if (existsCwd(ctx.io, manifest.FILENAME)) {
        return printErr(ctx, "bpmp init: " ++ manifest.FILENAME ++ " already exists in this directory");
    }
    if (existsCwd(ctx.io, lockfile.FILENAME)) {
        return printErr(ctx, "bpmp init: " ++ lockfile.FILENAME ++ " already exists in this directory");
    }

    const name = opts.name orelse try cwdBasename(ctx);

    var m = try manifest.create(ctx.gpa, name, opts.version, opts.target, "src/main.bp");
    defer m.deinit();
    try manifest.write(ctx.gpa, ctx.io, ".", &m);

    var lf = try lockfile.create(ctx.gpa, "");
    defer lf.deinit();
    try lockfile.write(ctx.gpa, ctx.io, ".", &lf);

    try writeStdout(ctx,
        \\bpmp init: wrote botopink.json + botopink.lock.json
        \\next steps:
        \\  • run `bpmp install <name>` to add a framework
        \\  • run `bpmp run -- build src/main.bp` to compile
        \\
    );
    return 0;
}

const HELP =
    \\bpmp init — initialise a project in the current directory.
    \\
    \\Usage:
    \\  bpmp init [--name <name>] [--version <ver>] [--target <commonJS|erlang|beam|wasm>]
    \\
    \\Refuses if botopink.json or botopink.lock.json already exists.
    \\
;

fn writeStdout(ctx: cli.Context, text: []const u8) !void {
    std.Io.File.stdout().writeStreamingAll(ctx.io, text) catch {};
}

fn printErr(ctx: cli.Context, msg: []const u8) !u8 {
    std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{msg});
    _ = ctx;
    return 1;
}

fn existsCwd(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

fn cwdBasename(ctx: cli.Context) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(ctx.io, &buf);
    const cwd = buf[0..n];
    const base = std.fs.path.basename(cwd);
    return ctx.gpa.dupe(u8, base);
}
