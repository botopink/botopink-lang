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
///   packages List the packages of the checkout
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
const packages_cmd = @import("./cli/packages.zig");
const packages_docs = @import("./cli/packages_docs.zig");
const test_cmd = @import("./cli/test_cmd.zig");
const cfg = @import("./cli/config.zig");
const otp = @import("./cli/otp.zig");
const libs = @import("./cli/libs.zig");
const builtin = @import("builtin");
const bp = @import("botopink");
const build_stamp = @import("build_stamp");

// ── Version ───────────────────────────────────────────────────────────────────

const VERSION = "0.1.0";

/// `build: zig <version> <optimize mode> <arch>-<os>-<abi> <source hash> <source root>` —
/// how this binary was built and from which sources (`build_stamp`, the hash
/// `source_stamp` computes over the checkout).
const BUILD_LINE = "build: zig " ++ builtin.zig_version_string ++ " " ++ @tagName(builtin.mode) ++ " " ++
    @tagName(builtin.cpu.arch) ++ "-" ++ @tagName(builtin.os.tag) ++ "-" ++ @tagName(builtin.abi) ++ " " ++
    build_stamp.source_hash ++ " " ++ build_stamp.source_root ++ "\n";

// ── Help text ─────────────────────────────────────────────────────────────────

const HELP =
    \\botopink — a compiled language targeting JavaScript and Erlang
    \\
    \\Usage:
    \\  botopink <command> [options]
    \\
    \\Commands:
    \\  build    Build the package's .bpr set (no --target), or compile it to a target
    \\  run      Compile and run the project
    \\  test     Compile and run every test block in the project
    \\  check    Type-check without generating code
    \\  format   Format source files
    \\  new      Create a new botopink project
    \\  clean    Remove build artifacts
    \\  packages List the packages of the checkout
    \\  help     Show this message
    \\  version  Show the compiler version and the Erlang/OTP release it emits for
    \\
    \\Every `--flag <value>` option also accepts `--flag=<value>`. An unknown flag,
    \\an unexpected argument or an unsupported target is a usage error (exit 1).
    \\
    \\Options for `build`:
    \\  (no --target)                Run comptime and write the package's .bpr set and its key to
    \\                               <cache root>/.botopinkbuild/runtime/<package>/ (no out/); reused while its key is fresh
    \\  --target <commonJS|erlang|beam|wasm>   Emit that target into --out, from the .bpr set when it is fresh, else
    \\                               building it first in the same pass
    \\  --out <dir>                  Output directory (default: out)
    \\  --typescript                 Emit TypeScript .d.ts definitions (also on with "typings": true)
    \\  --cold                       Read nothing from the code cache; write what is compiled; ignore the .bpr key and rebuild
    \\  --cache-root <dir>           File the code cache (levels A and B) under <dir>, not the project's or its workspace's
    \\  --json                       Stdout is JSON lines, one event each, stderr as without it: {"event":"targets","target":T,"targets":[…]},
    \\                               {"event":"build","text":L} (one per line a build body printed, in order),
    \\                               {"event":"refused","module":M,"message":E,"at":P|null,"label":S|null,"from":[…]},
    \\                               {"event":"runtime","path":F,"root":B} (per .bpr written by --emit-runtime), and last
    \\                               {"event":"summary","ok":B,"exit":N,"refused":N}
    \\  --emit-resolved <dir>        Write the resolved program (no comptime left) one file per module, <dir>/<package>/<module>.bp, for reading
    \\  --emit-runtime <dir>         The .bpr set's directory instead: each package's resolved tree to <dir>/<package>.bpr
    \\                               and the key to <dir>/<package>.key, to build any target from later
    \\  [<file>.bpr]                 Build the program a .bpr holds (no comptime; --target required; from the directory of the project that wrote it)
    \\
    \\Options for `run`:
    \\  --target <commonJS|erlang|beam|wasm>   Override the codegen target (default: the manifest's); the .bpr set is
    \\                               reused while its key is fresh, else built first
    \\  --module <name>              Entry-point module (default: main)
    \\  --out <dir>                  Output directory (default: out)
    \\  --cold                       Read nothing from the code cache; write what is compiled; a fresh .bpr set is reused
    \\  --cache-root <dir>           File the code cache (levels A and B) under <dir>, not the project's or its workspace's
    \\  --                           Pass remaining args to the program
    \\
    \\Options for `test`:
    \\  --target <commonJS|erlang|beam|wasm>   Override the codegen target
    \\  --filter <substr>            Only run tests whose name contains the substring
    \\  --json                       Emit one JSON object per test (JSONL)
    \\  --cold                       Read nothing from the code cache; write what is compiled
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
    \\The code cache (.botopinkbuild/cache/code/ under the workspace root, else the
    \\project): the compiled modules of a project's dependencies — std and the
    \\libraries — by the bytes compiled and the tool's version; the project's own
    \\modules are compiled every time.
    \\
    \\`clean` takes no option. It deletes out/ and .botopinkbuild/ whole: the
    \\comptime scratch (.botopinkbuild/tmp/), the run directories of `test` and
    \\the `bpmp install` / `bpmp link` links under .botopinkbuild/deps/ (run
    \\either again after it) and every build cache (.botopinkbuild/cache/: the code
    \\cache of the dependencies' compiled modules). In a
    \\workspace member, the workspace root's .botopinkbuild/cache/ and
    \\.botopinkbuild/analysis/ (the dependencies' analysis) go too.
    \\
    \\Options for `packages`:
    \\  --check-docs                  Check the workspace documents (*.md directly in a workspace directory) that quote the
    \\                               refusal's member list (`...run this command inside one of its members: <list>`)
    \\                               against the list the tool prints; exit 1, each mismatch on stderr as
    \\                               <file>:<line>. An elided quote is not checked.
    \\  --list                       One line per package of the checkout, tab-separated: <name>, <dir> (relative to the
    \\                               checkout root), <targets> (the manifest's "targets" joined by `,`, a workspace member's
    \\                               inheriting its workspace's; `all` when none), and `package` or `not-a-package`
    \\                               (a refused manifest, a workspace that does not expand, a name declared twice, a library
    \\                               member with no `files`). The set: every library under
    \\                               repository/, every workspace member, and std. Sorted by name, then dir.
    \\
    \\`botopink <command> --help` (or -h) prints this message.
    \\
;

// ── Main ──────────────────────────────────────────────────────────────────────

pub fn main(init: std.process.Init) void {
    installSigint();
    const exit_code = dispatch(init) catch |err| blk: {
        const name = @errorName(err);
        reporter.errMsg(name);
        break :blk 1;
    };
    // A build ended by Ctrl-C ends as a process killed by it does (decision 878).
    if (sigint_interrupted.load(.acquire)) std.process.exit(SIGINT_EXIT);
    if (exit_code != 0) std.process.exit(exit_code);
}

/// The exit status of a build the user interrupted: 128 + SIGINT.
const SIGINT_EXIT: u8 = 130;

/// Set by the SIGINT handler when it interrupted a running comptime body.
var sigint_interrupted: std.atomic.Value(bool) = .init(false);

/// Decision 878 — Ctrl-C while a comptime body runs interrupts that body
/// (`persistent_wat.interrupt()`): the build ends as `comptime-interrupted`,
/// located at the body, exit 130. With no body running, or on a second
/// Ctrl-C, the default action ends the process as before.
fn onSigint(sig: std.posix.SIG) callconv(.c) void {
    if (bp.comptime_runtime.running() and !sigint_interrupted.swap(true, .acq_rel)) {
        bp.comptime_runtime.interrupt();
        return;
    }
    const dfl: std.posix.Sigaction = .{
        .handler = .{ .handler = std.posix.SIG.DFL },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(sig, &dfl, null);
    std.posix.raise(sig) catch {};
}

fn installSigint() void {
    if (comptime builtin.os.tag == .windows or builtin.os.tag == .wasi) return;
    const act: std.posix.Sigaction = .{
        .handler = .{ .handler = onSigint },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(.INT, &act, null);
}

/// Exit code of a command-line usage error (unknown flag, bad target, …).
const USAGE_EXIT: u8 = 1;

fn dispatch(init: std.process.Init) !u8 {
    const gpa = init.gpa;
    const io = init.io;
    // The command's `erl` session (`cli/otp.zig`) ends with the command.
    defer otp.close(io);
    const env_map: ?*const std.process.Environ.Map = init.environ_map;
    // Decision 993 (1): a `compiler.load`ed package resolves its own
    // dependencies from its own directory, through the CLI.
    libs.installLoadResolver(env_map);
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

    if (wantsHelp(rest)) {
        reporter.stdout(io, HELP);
        return 0;
    }

    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        reporter.stdout(io, HELP);
        return 0;
    }

    if (std.mem.eql(u8, cmd, "version") or std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "-v")) {
        reporter.stdout(io, "botopink " ++ VERSION ++ "\notp: " ++ otp.RELEASE ++ "\n" ++ BUILD_LINE);
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
        return clean_cmd.run(gpa, io);
    }

    if (std.mem.eql(u8, cmd, "packages")) {
        const mode = parsePackagesOpts(rest, &diag) catch |err| return usageError(cmd, err, diag);
        return switch (mode) {
            .list => packages_cmd.run(gpa, io, env_map),
            .check_docs => packages_docs.run(gpa, io, env_map),
        };
    }

    // Unknown command.
    const msg = try std.fmt.allocPrint(gpa, "unknown command: {s}", .{cmd});
    defer gpa.free(msg);
    reporter.errMsg(msg);
    reporter.hintMsg("run `botopink help` for a list of commands");
    return 1;
}

/// `botopink <command> --help` / `-h`: a help flag among the command's own
/// arguments — the ones before a `--`, after which every token is the
/// program's (`run -- --help`).
fn wantsHelp(rest: []const []const u8) bool {
    for (rest) |a| {
        if (std.mem.eql(u8, a, "--")) return false;
        if (std.mem.eql(u8, a, "--help") or std.mem.eql(u8, a, "-h")) return true;
    }
    return false;
}

test "a help flag before `--` asks for the help, after it is the program's" {
    try std.testing.expect(wantsHelp(&.{"--help"}));
    try std.testing.expect(wantsHelp(&.{ "--target", "erlang", "-h" }));
    try std.testing.expect(!wantsHelp(&.{ "--", "--help" }));
    try std.testing.expect(!wantsHelp(&.{}));
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

/// The directory `--emit-runtime` / `--emit-resolved` write into (decision
/// 798 (3)): required, so a flag standing where it goes is no directory
/// (`--emit-resolved --target commonJS` names none).
fn dirValue(args: []const [:0]const u8, i: *usize, flag: FlagToken, diag: *ArgDiag) ArgError![]const u8 {
    const v = try flagValue(args, i, flag, diag);
    if (flag.inline_value == null and isFlag(v)) {
        diag.token = flag.name;
        return error.MissingArgument;
    }
    return v;
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
        } else if (std.mem.eql(u8, flag.name, "--cold")) {
            try noValue(flag, diag);
            // `build --cold` ignores the `.bpr` key and rebuilds (decision 1006 (4)).
            opts.cold = true;
            opts.rebuild = true;
        } else if (std.mem.eql(u8, flag.name, "--json")) {
            try noValue(flag, diag);
            opts.json = true;
        } else if (std.mem.eql(u8, flag.name, "--cache-root")) {
            opts.cache_root = try dirValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--emit-resolved")) {
            opts.emit_resolved = try dirValue(args, &i, flag, diag);
        } else if (std.mem.eql(u8, flag.name, "--emit-runtime")) {
            opts.emit_runtime = try dirValue(args, &i, flag, diag);
        } else if (isRuntimeFile(args[i]) and opts.runtime_input == null) {
            opts.runtime_input = args[i];
        } else return reject(args[i], diag);
    }
    // A `.bpr` is built, never written again: the resolved tree it holds
    // keeps no printing and is already the intermediate.
    if (opts.runtime_input != null) {
        if (opts.emit_runtime != null or opts.emit_resolved != null) {
            diag.token = if (opts.emit_runtime != null) "--emit-runtime" else "--emit-resolved";
            return error.UnexpectedArgument;
        }
    }
    return opts;
}

/// A positional naming a `.bpr` — the program `build` and `run` read back
/// (decision 805 (3)); no other positional is taken.
fn isRuntimeFile(a: []const u8) bool {
    return !isFlag(a) and std.mem.endsWith(u8, a, ".bpr");
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
        } else if (std.mem.eql(u8, flag.name, "--cold")) {
            try noValue(flag, diag);
            opts.cold = true;
        } else if (std.mem.eql(u8, flag.name, "--cache-root")) {
            opts.cache_root = try dirValue(args, &i, flag, diag);
            // No `.bpr` path (decision 1009): `run` finds its package's own set.
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
        } else if (std.mem.eql(u8, flag.name, "--cold")) {
            try noValue(flag, diag);
            opts.cold = true;
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

fn parseNoOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!void {
    if (args.len > 0) return reject(args[0], diag);
}

const PackagesMode = enum { list, check_docs };

/// `packages --list` or `packages --check-docs`: exactly one; neither is a usage error.
fn parsePackagesOpts(args: []const [:0]const u8, diag: *ArgDiag) ArgError!PackagesMode {
    var mode: ?PackagesMode = null;
    for (args) |a| {
        if (std.mem.eql(u8, a, "--list") and mode == null) {
            mode = .list;
        } else if (std.mem.eql(u8, a, "--check-docs") and mode == null) {
            mode = .check_docs;
        } else return reject(a, diag);
    }
    return mode orelse {
        diag.token = "--list";
        return error.MissingArgument;
    };
}

// ── Tests ─────────────────────────────────────────────────────────────────────
//
// One block per contract row the parsers close (`specs/1.0.2-beta/02-cli-gate/
// command-contract.md`): C10 check <path>, C11
// unknown flags and --flag=value, C12 new --target validation, C14 no leaked
// argument lists (the parsers run under `std.testing.allocator` via an arena).

// Zig runs the tests of an imported file only when a test references it: pull
// in every `cli/` file so their `test` blocks run under `zig build test`.
test {
    _ = @import("./cli/analysis_equivalence.zig");
    _ = @import("./cli/analysis_store.zig");
    _ = @import("./cli/arglist.zig");
    _ = @import("./cli/bpp.zig");
    _ = @import("./cli/bpp_unfold.zig");
    _ = @import("./cli/build.zig");
    _ = @import("./cli/check.zig");
    _ = @import("./cli/code_cache.zig");
    _ = @import("./cli/clean.zig");
    _ = @import("./cli/packages.zig");
    _ = @import("./cli/packages_docs.zig");
    _ = @import("./cli/config.zig");
    _ = @import("./cli/diagnostics.zig");
    _ = @import("./cli/format_cmd.zig");
    _ = @import("./cli/libs.zig");
    _ = @import("./cli/new.zig");
    _ = @import("./cli/otp.zig");
    _ = @import("./cli/reporter.zig");
    _ = @import("./cli/resolver.zig");
    _ = @import("./cli/run.zig");
    _ = @import("./cli/runtime_cache.zig");
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

test "B-163: build takes --emit-resolved <dir>, and the flag needs its directory (decision 798 (3))" {
    var d: ArgDiag = .{};
    try std.testing.expectEqualStrings("res", (try parseBuildOpts(argv(&.{ "--emit-resolved", "res" }), &d)).emit_resolved.?);
    try std.testing.expectEqualStrings("res", (try parseBuildOpts(argv(&.{"--emit-resolved=res"}), &d)).emit_resolved.?);
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{"--emit-resolved"}), &d));
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{ "--emit-resolved", "--target", "commonJS" }), &d));
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{"--emit-resolved="}), &d));
    try std.testing.expect((try parseBuildOpts(argv(&.{}), &d)).emit_resolved == null);
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

test "B-163: build takes --emit-runtime <dir> and one .bpr to build; run takes none (decisions 805 (1), (3), 1009)" {
    var d: ArgDiag = .{};
    try std.testing.expectEqualStrings("rt", (try parseBuildOpts(argv(&.{ "--emit-runtime", "rt" }), &d)).emit_runtime.?);
    try std.testing.expectEqualStrings("rt", (try parseBuildOpts(argv(&.{"--emit-runtime=rt"}), &d)).emit_runtime.?);
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{"--emit-runtime"}), &d));
    try std.testing.expectError(error.MissingArgument, parseBuildOpts(argv(&.{ "--emit-runtime", "--out", "o" }), &d));
    const b = try parseBuildOpts(argv(&.{ "--target", "wasm", "rt/app.bpr" }), &d);
    try std.testing.expectEqualStrings("rt/app.bpr", b.runtime_input.?);
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{ "rt/app.bpr", "rt/lib.bpr" }), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{ "rt/app.bpr", "--emit-runtime", "x" }), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{"src/main.bp"}), &d));
    try std.testing.expectError(error.UnexpectedArgument, parseRunOpts(std.testing.allocator, argv(&.{ "rt/app.bpr", "--target", "beam" }), &d));
    try std.testing.expectEqualStrings("rt/app.bpr", d.token);
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

test "build, run and test take --cold, which carries no value (decision 509 (5))" {
    var d: ArgDiag = .{};
    try std.testing.expect((try parseBuildOpts(argv(&.{"--cold"}), &d)).cold);
    try std.testing.expect(!(try parseBuildOpts(argv(&.{}), &d)).cold);
    try std.testing.expect((try parseTestOpts(argv(&.{ "--cold", "--target", "erlang" }), &d)).cold);
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    try std.testing.expect((try parseRunOpts(arena_inst.allocator(), argv(&.{"--cold"}), &d)).cold);
    try std.testing.expectError(error.UnexpectedArgument, parseBuildOpts(argv(&.{"--cold=yes"}), &d));
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

test "packages takes --list or --check-docs and nothing else" {
    var d: ArgDiag = .{};
    try std.testing.expectEqual(PackagesMode.list, try parsePackagesOpts(argv(&.{"--list"}), &d));
    try std.testing.expectEqual(PackagesMode.check_docs, try parsePackagesOpts(argv(&.{"--check-docs"}), &d));
    try std.testing.expectError(error.UnknownFlag, parsePackagesOpts(argv(&.{ "--list", "--check-docs" }), &d));
    try std.testing.expectError(error.MissingArgument, parsePackagesOpts(argv(&.{}), &d));
    try std.testing.expectError(error.UnknownFlag, parsePackagesOpts(argv(&.{ "--list", "--x" }), &d));
    try std.testing.expectError(error.UnexpectedArgument, parsePackagesOpts(argv(&.{ "--list", "x" }), &d));
}
