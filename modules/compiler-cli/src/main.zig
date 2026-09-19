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
const test_cmd = @import("./cli/test_cmd.zig");
const migrate_cmd = @import("./cli/migrate.zig");
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
    \\  test     Compile and run every test block in the project
    \\  check    Type-check without generating code
    \\  format   Format source files
    \\  new      Create a new botopink project
    \\  clean    Remove build artifacts
    \\  migrate  Generate the module tree (mod/pub mod) from the src/ layout
    \\  help     Show this message
    \\  version  Show the compiler version
    \\
    \\Every `--flag <value>` option also accepts `--flag=<value>`. An unknown flag,
    \\an unexpected argument or an unsupported target is a usage error (exit 1).
    \\
    \\Options for `build`:
    \\  --target <commonJS|erlang|beam|wasm>   Override the codegen target
    \\  --out <dir>                  Output directory (default: out)
    \\  --typescript                 Emit TypeScript .d.ts definitions
    \\
    \\Options for `run`:
    \\  --target <commonJS|erlang|beam|wasm>   Override the codegen target
    \\  --module <name>              Entry-point module (default: main)
    \\  --out <dir>                  Output directory (default: out)
    \\  --                           Pass remaining args to the program
    \\
    \\Options for `test`:
    \\  --target <commonJS|erlang>   Override the codegen target
    \\  --filter <substr>            Only run tests whose name contains the substring
    \\  --json                       Emit one JSON object per test (JSONL)
    \\
    \\Options for `check`:
    \\  [<path>]                     Project directory to check (default: .)
    \\
    \\Options for `format`:
    \\  --check                      Exit 1 if any file would be reformatted
    \\  [files...]                   Explicit files; default: all in src/
    \\
    \\Options for `new`:
    \\  <name>                       Project name
    \\  --target <commonJS|erlang|beam|wasm>   Initial target (default: commonJS)
    \\
    \\Options for `migrate`:
    \\  --dry-run                    Report the index files without writing them
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

/// Exit code of a command-line usage error (unknown flag, bad target, …).
const USAGE_EXIT: u8 = 1;

fn dispatch(init: std.process.Init) !u8 {
    const gpa = init.gpa;
    const io = init.io;
    const env_map: ?*const std.process.Environ.Map = init.environ_map;
    // Parsed options live as long as the process: allocate them in the process
    // arena so no command has to free its argument lists.
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    // args[0] is the program name; skip it.
    if (args.len < 2) {
        reporter.stdout(io, HELP);
        return 0;
    }

    const cmd = args[1];
    const rest = args[2..];
    var diag: ArgDiag = .{};

    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        reporter.stdout(io, HELP);
        return 0;
    }

    if (std.mem.eql(u8, cmd, "version") or std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        reporter.stdout(io, "botopink " ++ VERSION ++ "\n");
        return 0;
    }

    if (std.mem.eql(u8, cmd, "build")) {
        const opts = parseBuildOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return build_cmd.run(gpa, io, opts, env_map);
    }

    if (std.mem.eql(u8, cmd, "check")) {
        const opts = parseCheckOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return check_cmd.run(gpa, io, opts, env_map);
    }

    if (std.mem.eql(u8, cmd, "run")) {
        const opts = parseRunOpts(arena, rest, &diag) catch |err| return usageError(cmd, err, diag);
        return run_cmd.run(gpa, io, opts, env_map);
    }

    if (std.mem.eql(u8, cmd, "test")) {
        const opts = parseTestOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return test_cmd.run(gpa, io, opts, env_map);
    }

    if (std.mem.eql(u8, cmd, "format") or std.mem.eql(u8, cmd, "fmt")) {
        const opts = parseFormatOpts(arena, rest, &diag) catch |err| return usageError(cmd, err, diag);
        return format_cmd.run(gpa, io, opts);
    }

    if (std.mem.eql(u8, cmd, "new")) {
        const opts = parseNewOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return new_cmd.run(gpa, io, opts);
    }

    if (std.mem.eql(u8, cmd, "clean")) {
        parseNoOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return clean_cmd.run(io);
    }

    if (std.mem.eql(u8, cmd, "migrate")) {
        const opts = parseMigrateOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return migrate_cmd.run(gpa, io, opts);
    }

    // Unknown command.
    const msg = try std.fmt.allocPrint(gpa, "unknown command: {s}", .{cmd});
    defer gpa.free(msg);
    reporter.errMsg(msg);
    reporter.hintMsg("run `botopink help` for a list of commands");
    return 1;
}

// ── Arg parsers ───────────────────────────────────────────────────────────────
//
// Every parser is pure: it reads `args`, fills an options struct, and on a
// usage error returns one of `ArgError` with the offending token in `diag`.
// No parser silently drops a token — an unrecognised flag, a positional the
// command does not take, or an unsupported target is an error.

pub const ArgError = error{
    UnknownFlag,
    MissingArgument,
    InvalidTarget,
    UnexpectedArgument,
    MissingProjectName,
    OutOfMemory,
};

/// The token a parser rejected, for the usage message.
pub const ArgDiag = struct {
    token: []const u8 = "",
};

fn usageError(cmd: []const u8, err: ArgError, diag: ArgDiag) u8 {
    var buf: [512]u8 = undefined;
    const msg = switch (err) {
        error.UnknownFlag => std.fmt.bufPrint(&buf, "`{s}`: unknown flag '{s}'", .{ cmd, diag.token }),
        error.MissingArgument => std.fmt.bufPrint(&buf, "`{s}`: flag '{s}' needs a value", .{ cmd, diag.token }),
        error.InvalidTarget => std.fmt.bufPrint(&buf, "`{s}`: unsupported target '{s}' (expected commonJS, erlang, beam or wasm)", .{ cmd, diag.token }),
        error.UnexpectedArgument => std.fmt.bufPrint(&buf, "`{s}`: unexpected argument '{s}'", .{ cmd, diag.token }),
        error.MissingProjectName => std.fmt.bufPrint(&buf, "usage: botopink new <name> [--target <t>]", .{}),
        error.OutOfMemory => std.fmt.bufPrint(&buf, "out of memory while parsing arguments", .{}),
    } catch "invalid arguments";
    reporter.errMsg(msg);
    reporter.hintMsg("run `botopink help` for the options of each command");
    return USAGE_EXIT;
}

/// A `--name` or `--name=value` token split into its parts.
const FlagToken = struct {
    name: []const u8,
    inline_value: ?[]const u8,
};

fn splitFlag(a: []const u8) FlagToken {
    if (std.mem.startsWith(u8, a, "--")) {
        if (std.mem.indexOfScalar(u8, a, '=')) |eq| {
            return .{ .name = a[0..eq], .inline_value = a[eq + 1 ..] };
        }
    }
    return .{ .name = a, .inline_value = null };
}

fn isFlag(a: []const u8) bool {
    return a.len > 1 and a[0] == '-';
}

/// The value of a flag: its `=value` part, else the next argument.
fn flagValue(args: []const [:0]const u8, i: *usize, flag: FlagToken, diag: *ArgDiag) ArgError![]const u8 {
    if (flag.inline_value) |v| {
        if (v.len == 0) {
            diag.token = flag.name;
            return error.MissingArgument;
        }
        return v;
    }
    i.* += 1;
    if (i.* >= args.len) {
        diag.token = flag.name;
        return error.MissingArgument;
    }
    return args[i.*];
}

fn targetValue(args: []const [:0]const u8, i: *usize, flag: FlagToken, diag: *ArgDiag) ArgError!cfg.Target {
    const v = try flagValue(args, i, flag, diag);
    return cfg.Target.fromString(v) orelse {
        diag.token = v;
        return error.InvalidTarget;
    };
}

/// A flag that takes no value must not carry one (`--typescript=yes`).
fn noValue(flag: FlagToken, diag: *ArgDiag) ArgError!void {
    if (flag.inline_value != null) {
        diag.token = flag.name;
        return error.UnexpectedArgument;
    }
}

fn reject(a: []const u8, diag: *ArgDiag) ArgError {
    diag.token = a;
    return if (isFlag(a)) error.UnknownFlag else error.UnexpectedArgument;
}

fn parseBuildOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!build_cmd.Options {
    var opts: build_cmd.Options = .{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const flag = splitFlag(args[i]);
        if (std.mem.eql(u8, flag.name, "--target")) {
            opts.target = try targetValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--out")) {
            opts.out_dir = try flagValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--typescript")) {
            try noValue(flag, diag);
            opts.typescript = true;
        } else return reject(args[i], diag);
    }
    return opts;
}

fn parseCheckOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!check_cmd.Options {
    var opts: check_cmd.Options = .{};
    for (args) |a| {
        if (isFlag(a) or opts.path != null) return reject(a, diag);
        opts.path = a;
    }
    return opts;
}

fn parseRunOpts(arena: std.mem.Allocator, args: []const [:0]const u8, diag: *ArgDiag) ArgError!run_cmd.Options {
    var opts: run_cmd.Options = .{};
    var extra = std.ArrayListUnmanaged([]const u8).empty;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--")) {
            for (args[i + 1 ..]) |e| try extra.append(arena, e);
            break;
        }
        const flag = splitFlag(a);
        if (std.mem.eql(u8, flag.name, "--target")) {
            opts.target = try targetValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--module")) {
            opts.module = try flagValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--out")) {
            opts.out_dir = try flagValue(args, &i, flag, diag);
        } else return reject(a, diag);
    }
    opts.extra_args = try extra.toOwnedSlice(arena);
    return opts;
}

fn parseTestOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!test_cmd.Options {
    var opts: test_cmd.Options = .{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const flag = splitFlag(args[i]);
        if (std.mem.eql(u8, flag.name, "--target")) {
            opts.target = try targetValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--filter")) {
            opts.filter = try flagValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--json")) {
            try noValue(flag, diag);
            opts.json = true;
        } else return reject(args[i], diag);
    }
    return opts;
}

fn parseFormatOpts(arena: std.mem.Allocator, args: []const [:0]const u8, diag: *ArgDiag) ArgError!format_cmd.Options {
    var opts: format_cmd.Options = .{};
    var files = std.ArrayListUnmanaged([]const u8).empty;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--check")) {
            opts.check = true;
        } else if (isFlag(a)) {
            return reject(a, diag);
        } else {
            try files.append(arena, a);
        }
    }
    opts.files = try files.toOwnedSlice(arena);
    return opts;
}

fn parseNewOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!new_cmd.Options {
    var opts: new_cmd.Options = .{ .name = "" };
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        const flag = splitFlag(a);
        if (std.mem.eql(u8, flag.name, "--target")) {
            // Store the canonical spelling — never the raw token.
            opts.target = (try targetValue(args, &i, flag, diag)).toString();
        } else if (isFlag(a) or opts.name.len > 0) {
            return reject(a, diag);
        } else {
            opts.name = a;
        }
    }
    if (opts.name.len == 0) return error.MissingProjectName;
    return opts;
}

fn parseMigrateOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!migrate_cmd.Options {
    var opts: migrate_cmd.Options = .{};
    for (args) |a| {
        if (std.mem.eql(u8, a, "--dry-run")) {
            opts.dry_run = true;
        } else return reject(a, diag);
    }
    return opts;
}

fn parseNoOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!void {
    if (args.len > 0) return reject(args[0], diag);
}

// ── Tests ─────────────────────────────────────────────────────────────────────
//
// One block per contract row the parsers close (`specs/1.0.2-beta/02-cli-gate/
// command-contract.md`): C8 migrate --dry-run anywhere, C10 check <path>, C11
// unknown flags and --flag=value, C12 new --target validation, C14 no leaked
// argument lists (the parsers run under `std.testing.allocator` via an arena).

// Zig runs the tests of an imported file only when a test references it: pull
// in every `cli/` file so their `test` blocks run under `zig build test`.
test {
    _ = @import("./cli/build.zig");
    _ = @import("./cli/check.zig");
    _ = @import("./cli/clean.zig");
    _ = @import("./cli/config.zig");
    _ = @import("./cli/diagnostics.zig");
    _ = @import("./cli/format_cmd.zig");
    _ = @import("./cli/libs.zig");
    _ = @import("./cli/migrate.zig");
    _ = @import("./cli/new.zig");
    _ = @import("./cli/reporter.zig");
    _ = @import("./cli/resolver.zig");
    _ = @import("./cli/run.zig");
    _ = @import("./cli/scanner.zig");
    _ = @import("./cli/sources.zig");
    _ = @import("./cli/test_cmd.zig");
}

fn argv(comptime xs: []const [:0]const u8) []const [:0]const u8 {
    return xs;
}

test "C11: build rejects an unknown flag instead of dropping it" {
    var d: ArgDiag = .{};
    try std.testing.expectError(error.UnknownFlag, parseBuildOpts(argv(&.{"--frobnicate"}), &d));
    try std.testing.expectEqualStrings("--frobnicate", d.token);
}

test "C11: build accepts --target=erlang as well as --target erlang" {
    var d: ArgDiag = .{};
    const eq = try parseBuildOpts(argv(&.{ "--target=erlang", "--out=out-eq" }), &d);
    try std.testing.expectEqual(cfg.Target.erlang, eq.target.?);
    try std.testing.expectEqualStrings("out-eq", eq.out_dir);
    const sp = try parseBuildOpts(argv(&.{ "--target", "erlang", "--out", "out-sp" }), &d);
    try std.testing.expectEqual(cfg.Target.erlang, sp.target.?);
    try std.testing.expectEqualStrings("out-sp", sp.out_dir);
}

test "C11: an empty --flag= value and a trailing flag both need a value" {
    var d: ArgDiag = .{};
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{"--target="}), &d));
    try std.testing.expectError(error.MissingArgument, parseTestOpts(argv(&.{"--filter"}), &d));
    try std.testing.expectEqualStrings("--filter", d.token);
}

test "C11: an unsupported target is rejected with the token named" {
    var d: ArgDiag = .{};
    try std.testing.expectError(error.InvalidTarget, parseRunOpts(std.testing.allocator, argv(&.{ "--target", "frobnicate" }), &d));
    try std.testing.expectEqualStrings("frobnicate", d.token);
}

test "C11: build and test reject positional arguments" {
    var d: ArgDiag = .{};
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{"src"}), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseTestOpts(argv(&.{"main_test"}), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{"--typescript=yes"}), &d));
}

test "C11: test parses --json and --filter=value" {
    var d: ArgDiag = .{};
    const o = try parseTestOpts(argv(&.{ "--json", "--filter=math", "--target=commonJS" }), &d);
    try std.testing.expect(o.json);
    try std.testing.expectEqualStrings("math", o.filter.?);
    try std.testing.expectEqual(cfg.Target.commonJS, o.target.?);
}

test "C11: format rejects an unknown flag and keeps files" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    var d: ArgDiag = .{};
    try std.testing.expectError(error.UnknownFlag, parseFormatOpts(arena_inst.allocator(), argv(&.{"--chekc"}), &d));
    const o = try parseFormatOpts(arena_inst.allocator(), argv(&.{ "a.bp", "--check", "b.bp" }), &d);
    try std.testing.expect(o.check);
    try std.testing.expectEqual(@as(usize, 2), o.files.len);
}

test "C12: new --target validates and stores the canonical name" {
    var d: ArgDiag = .{};
    try std.testing.expectError(error.InvalidTarget, parseNewOpts(argv(&.{ "app", "--target", "frobnicate" }), &d));
    const o = try parseNewOpts(argv(&.{ "--target=beam", "app" }), &d);
    try std.testing.expectEqualStrings("beam", o.target);
    try std.testing.expectEqualStrings("app", o.name);
    try std.testing.expectError(error.MissingProjectName, parseNewOpts(argv(&.{}), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseNewOpts(argv(&.{ "app", "other" }), &d));
}

test "C12: a manifest target the compiler does not support is not degraded to commonJS" {
    const proj: cfg.ProjectConfig = .{ .name = "p", .target = "frobnicate" };
    try std.testing.expectEqual(@as(?cfg.Target, null), proj.parsedTarget());
    const ok: cfg.ProjectConfig = .{ .name = "p", .target = "wasm" };
    try std.testing.expectEqual(cfg.Target.wasm, ok.parsedTarget().?);
}

test "C10: check forwards one path and rejects anything else" {
    var d: ArgDiag = .{};
    const none = try parseCheckOpts(argv(&.{}), &d);
    try std.testing.expectEqual(@as(?[]const u8, null), none.path);
    const one = try parseCheckOpts(argv(&.{"libs/std"}), &d);
    try std.testing.expectEqualStrings("libs/std", one.path.?);
    try std.testing.expectError(error.UnexpectedArgument, parseCheckOpts(argv(&.{ "a", "b" }), &d));
    try std.testing.expectError(error.UnknownFlag, parseCheckOpts(argv(&.{"--strict"}), &d));
}

test "C8: migrate recognises --dry-run wherever it appears and rejects a positional" {
    var d: ArgDiag = .{};
    try std.testing.expect((try parseMigrateOpts(argv(&.{"--dry-run"}), &d)).dry_run);
    try std.testing.expectError(error.UnexpectedArgument, parseMigrateOpts(argv(&.{ "src", "--dry-run" }), &d));
    try std.testing.expectEqualStrings("src", d.token);
    try std.testing.expect(!(try parseMigrateOpts(argv(&.{}), &d)).dry_run);
}

test "C14: run and format argument lists are arena-owned (no leak under testing.allocator)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var d: ArgDiag = .{};
    const r = try parseRunOpts(arena, argv(&.{ "--module", "app", "--", "--not-a-flag", "x" }), &d);
    try std.testing.expectEqualStrings("app", r.module);
    try std.testing.expectEqual(@as(usize, 2), r.extra_args.len);
    try std.testing.expectEqualStrings("--not-a-flag", r.extra_args[0]);
    const f = try parseFormatOpts(arena, argv(&.{ "a.bp", "b.bp" }), &d);
    try std.testing.expectEqual(@as(usize, 2), f.files.len);
}

test "clean takes no arguments" {
    var d: ArgDiag = .{};
    try parseNoOpts(argv(&.{}), &d);
    try std.testing.expectError(error.UnexpectedArgument, parseNoOpts(argv(&.{"out"}), &d));
}
