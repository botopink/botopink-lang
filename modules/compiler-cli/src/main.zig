/// CLI entry point for the botopink compiler.
///
/// Usage:
///   botopink <command> [options]
///
/// Commands:
///   build    Compile the project to the configured target
///   run      Compile and run the project
///   check    Type-check without generating code
///   format   Format source files
///   new      Create a new botopink project
///   clean    Remove build artifacts (out/, .botopinkbuild/)
///   help     Show this help message
///   version  Show the compiler version
const std = @import("std");

const reporter = @import("./cli/reporter.zig");
const build_cmd = @import("./cli/build.zig");
const check_cmd = @import("./cli/check.zig");
const run_cmd = @import("./cli/run.zig");
const format_cmd = @import("./cli/format_cmd.zig");
const new_cmd = @import("./cli/new.zig");
const clean_cmd = @import("./cli/clean.zig");
const cfg = @import("./cli/config.zig");

// ── Version ───────────────────────────────────────────────────────────────────

const VERSION = "0.1.0";

// ── Help text ─────────────────────────────────────────────────────────────────

const HELP =
    \\botopink — a compiled language targeting JavaScript and Erlang
    \\
    \\Usage:
    \\  botopink <command> [options]
    \\
    \\Commands:
    \\  build    Compile the project to the configured target
    \\  run      Compile and run the project
    \\  check    Type-check without generating code
    \\  format   Format source files
    \\  new      Create a new botopink project
    \\  clean    Remove build artifacts
    \\  help     Show this message
    \\  version  Show the compiler version
    \\
    \\Options for `build`:
    \\  --target <commonJS|erlang>   Override the codegen target
    \\  --out <dir>                  Output directory (default: out)
    \\  --typescript                 Emit TypeScript .d.ts definitions
    \\
    \\Options for `run`:
    \\  --target <commonJS|erlang>   Override the codegen target
    \\  --module <name>              Entry-point module (default: main)
    \\  --                           Pass remaining args to the program
    \\
    \\Options for `format`:
    \\  --check                      Exit 1 if any file would be reformatted
    \\  [files...]                   Explicit files; default: all in src/
    \\
    \\Options for `new`:
    \\  <name>                       Project name
    \\  --target <commonJS|erlang>   Initial target (default: commonJS)
    \\
;

// ── Main ──────────────────────────────────────────────────────────────────────

pub fn main(init: std.process.Init) void {
    const exit_code = dispatch(init) catch |err| blk: {
        const name = @errorName(err);
        reporter.errMsg(name);
        break :blk 1;
    };
    if (exit_code != 0) std.process.exit(exit_code);
}

fn dispatch(init: std.process.Init) !u8 {
    const gpa = init.gpa;
    const io = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    // args[0] is the program name; skip it.
    if (args.len < 2) {
        reporter.stdout(io, HELP);
        return 0;
    }

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        reporter.stdout(io, HELP);
        return 0;
    }

    if (std.mem.eql(u8, cmd, "version") or std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        reporter.stdout(io, "botopink " ++ VERSION ++ "\n");
        return 0;
    }

    if (std.mem.eql(u8, cmd, "build")) {
        return build_cmd.run(gpa, io, try parseBuildOpts(args[2..]));
    }

    if (std.mem.eql(u8, cmd, "check")) {
        return check_cmd.run(gpa, io);
    }

    if (std.mem.eql(u8, cmd, "run")) {
        return run_cmd.run(gpa, io, try parseRunOpts(gpa, args[2..]));
    }

    if (std.mem.eql(u8, cmd, "format") or std.mem.eql(u8, cmd, "fmt")) {
        return format_cmd.run(gpa, io, try parseFormatOpts(gpa, args[2..]));
    }

    if (std.mem.eql(u8, cmd, "new")) {
        return new_cmd.run(gpa, io, try parseNewOpts(args[2..]));
    }

    if (std.mem.eql(u8, cmd, "clean")) {
        return clean_cmd.run(io);
    }

    // Unknown command.
    const msg = try std.fmt.allocPrint(gpa, "unknown command: {s}", .{cmd});
    defer gpa.free(msg);
    reporter.errMsg(msg);
    reporter.hintMsg("run `botopink help` for a list of commands");
    return 1;
}

// ── Arg parsers ───────────────────────────────────────────────────────────────

fn parseBuildOpts(args: []const [:0]const u8) !build_cmd.Options {
    var opts: build_cmd.Options = .{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.target = cfg.Target.fromString(args[i]) orelse return error.InvalidTarget;
        } else if (std.mem.eql(u8, a, "--out")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.out_dir = args[i];
        } else if (std.mem.eql(u8, a, "--typescript")) {
            opts.typescript = true;
        }
    }
    return opts;
}

fn parseRunOpts(gpa: std.mem.Allocator, args: []const [:0]const u8) !run_cmd.Options {
    var opts: run_cmd.Options = .{};
    var extra = std.ArrayListUnmanaged([]const u8).empty;
    var i: usize = 0;
    var after_dashdash = false;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (after_dashdash) {
            try extra.append(gpa, a);
            continue;
        }
        if (std.mem.eql(u8, a, "--")) {
            after_dashdash = true;
        } else if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.target = cfg.Target.fromString(args[i]) orelse return error.InvalidTarget;
        } else if (std.mem.eql(u8, a, "--module")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.module = args[i];
        }
    }
    opts.extra_args = try extra.toOwnedSlice(gpa);
    return opts;
}

fn parseFormatOpts(gpa: std.mem.Allocator, args: []const [:0]const u8) !format_cmd.Options {
    var opts: format_cmd.Options = .{};
    var files = std.ArrayListUnmanaged([]const u8).empty;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--check")) {
            opts.check = true;
        } else {
            try files.append(gpa, a);
        }
    }
    opts.files = try files.toOwnedSlice(gpa);
    return opts;
}

fn parseNewOpts(args: []const [:0]const u8) !new_cmd.Options {
    var opts: new_cmd.Options = .{ .name = "" };
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.target = args[i];
        } else if (!std.mem.startsWith(u8, a, "--")) {
            opts.name = a;
        }
    }
    if (opts.name.len == 0) {
        reporter.errMsg("usage: botopink new <name>");
        return error.MissingProjectName;
    }
    return opts;
}
