/// Argument parsing for `botopink-lib-test`.
///
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///
/// `--target` is repeatable and comma-separated. It accepts every codegen target
/// plus the alias `node` → `commonJS`, and both the `--target <t>` and
/// `--target=<t>` spellings. The default target set is `commonJS,erlang` — the two
/// backends `botopink test` runs today. `all` expands to every *supported* target.
const std = @import("std");

// ── Target ──────────────────────────────────────────────────────────────────────

/// Codegen targets, mirroring the compiler's `config.Target`. Kept local so the
/// runner stays self-contained (no `compiler-core` dependency). The runtime
/// "is this target supported?" question is answered by the spawned child's exit,
/// not by this enum — see `runner.zig`.
pub const Target = enum {
    commonJS,
    erlang,
    beam,
    wasm,

    /// Targets `botopink test` runs today; `--target all` expands to these.
    pub const supported = [_]Target{ .commonJS, .erlang };

    /// Parse a target name. Accepts the `node` alias for `commonJS`.
    pub fn fromString(s: []const u8) ?Target {
        if (std.mem.eql(u8, s, "commonJS")) return .commonJS;
        if (std.mem.eql(u8, s, "node")) return .commonJS;
        if (std.mem.eql(u8, s, "erlang")) return .erlang;
        if (std.mem.eql(u8, s, "beam")) return .beam;
        if (std.mem.eql(u8, s, "wasm")) return .wasm;
        return null;
    }

    pub fn toString(self: Target) []const u8 {
        return switch (self) {
            .commonJS => "commonJS",
            .erlang => "erlang",
            .beam => "beam",
            .wasm => "wasm",
        };
    }
};

// ── Options ─────────────────────────────────────────────────────────────────────

pub const Options = struct {
    /// Requested targets, in order, de-duplicated. Owned by the caller's arena.
    targets: []const Target = &.{},
    /// Restrict to a single lib under `libs/`; null → every lib.
    lib: ?[]const u8 = null,
    /// Forwarded to `botopink test --filter`.
    filter: ?[]const u8 = null,
    /// Treat an unsupported target as a failure instead of a skip.
    strict: bool = false,
    /// Override the `botopink` binary path (flag form; env var handled by caller).
    bin: ?[]const u8 = null,
};

pub const ParseError = error{
    MissingArgument,
    InvalidTarget,
    UnknownFlag,
} || std.mem.Allocator.Error;

/// Parse `args` (the slice *after* the program name). Allocations land in `arena`.
pub fn parse(arena: std.mem.Allocator, args: []const []const u8) ParseError!Options {
    var opts: Options = .{};
    var targets: std.ArrayListUnmanaged(Target) = .empty;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];

        // `--target=<v>` / `--lib=<v>` / `--filter=<v>` / `--bin=<v>` (the `=` form).
        if (splitEq(a, "--target")) |v| {
            try appendTargets(arena, &targets, v);
        } else if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try appendTargets(arena, &targets, args[i]);
        } else if (splitEq(a, "--lib")) |v| {
            opts.lib = v;
        } else if (std.mem.eql(u8, a, "--lib")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.lib = args[i];
        } else if (splitEq(a, "--filter")) |v| {
            opts.filter = v;
        } else if (std.mem.eql(u8, a, "--filter")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.filter = args[i];
        } else if (splitEq(a, "--bin")) |v| {
            opts.bin = v;
        } else if (std.mem.eql(u8, a, "--bin")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.bin = args[i];
        } else if (std.mem.eql(u8, a, "--strict")) {
            opts.strict = true;
        } else {
            return error.UnknownFlag;
        }
    }

    // Default target set: the two backends that run today.
    if (targets.items.len == 0) {
        try targets.append(arena, .commonJS);
        try targets.append(arena, .erlang);
    }

    opts.targets = try targets.toOwnedSlice(arena);
    return opts;
}

/// Append every target named in `spec` (a single name, `all`, or a comma-list)
/// to `out`, skipping duplicates so a target never runs twice.
fn appendTargets(
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(Target),
    spec: []const u8,
) ParseError!void {
    var it = std.mem.splitScalar(u8, spec, ',');
    while (it.next()) |raw| {
        const name = std.mem.trim(u8, raw, " ");
        if (name.len == 0) continue;

        if (std.mem.eql(u8, name, "all")) {
            for (Target.supported) |t| try appendUnique(arena, out, t);
            continue;
        }

        const t = Target.fromString(name) orelse return error.InvalidTarget;
        try appendUnique(arena, out, t);
    }
}

fn appendUnique(
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(Target),
    t: Target,
) std.mem.Allocator.Error!void {
    for (out.items) |existing| {
        if (existing == t) return;
    }
    try out.append(arena, t);
}

/// If `a` is exactly `flag` followed by `=`, return the value after `=`
/// (possibly empty). Otherwise null.
fn splitEq(a: []const u8, flag: []const u8) ?[]const u8 {
    if (a.len <= flag.len) return null;
    if (!std.mem.startsWith(u8, a, flag)) return null;
    if (a[flag.len] != '=') return null;
    return a[flag.len + 1 ..];
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "default targets are commonJS + erlang" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{});
    try testing.expectEqual(@as(usize, 2), opts.targets.len);
    try testing.expectEqual(Target.commonJS, opts.targets[0]);
    try testing.expectEqual(Target.erlang, opts.targets[1]);
    try testing.expect(!opts.strict);
    try testing.expect(opts.lib == null);
}

test "node alias maps to commonJS" {
    try testing.expectEqual(Target.commonJS, Target.fromString("node").?);
}

test "--target node aliases (space form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{ "--target", "node" });
    try testing.expectEqual(@as(usize, 1), opts.targets.len);
    try testing.expectEqual(Target.commonJS, opts.targets[0]);
}

test "--target=erlang (= form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{"--target=erlang"});
    try testing.expectEqual(@as(usize, 1), opts.targets.len);
    try testing.expectEqual(Target.erlang, opts.targets[0]);
}

test "comma-separated target list" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{ "--target", "commonJS,erlang,beam" });
    try testing.expectEqual(@as(usize, 3), opts.targets.len);
    try testing.expectEqual(Target.commonJS, opts.targets[0]);
    try testing.expectEqual(Target.erlang, opts.targets[1]);
    try testing.expectEqual(Target.beam, opts.targets[2]);
}

test "repeated --target accumulates and de-dups" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{ "--target", "erlang", "--target", "node", "--target", "erlang" });
    try testing.expectEqual(@as(usize, 2), opts.targets.len);
    try testing.expectEqual(Target.erlang, opts.targets[0]);
    try testing.expectEqual(Target.commonJS, opts.targets[1]);
}

test "all expands to supported targets" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{ "--target", "all" });
    try testing.expectEqual(@as(usize, 2), opts.targets.len);
    try testing.expectEqual(Target.commonJS, opts.targets[0]);
    try testing.expectEqual(Target.erlang, opts.targets[1]);
}

test "--lib, --filter, --strict, --bin" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{
        "--lib",         "rakun",
        "--filter",      "router",
        "--strict",      "--bin",
        "/tmp/botopink",
    });
    try testing.expectEqualStrings("rakun", opts.lib.?);
    try testing.expectEqualStrings("router", opts.filter.?);
    try testing.expect(opts.strict);
    try testing.expectEqualStrings("/tmp/botopink", opts.bin.?);
}

test "--lib=name (= form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{"--lib=onze"});
    try testing.expectEqualStrings("onze", opts.lib.?);
}

test "invalid target rejected" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectError(error.InvalidTarget, parse(arena.allocator(), &.{ "--target", "fortran" }));
}

test "missing argument rejected" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectError(error.MissingArgument, parse(arena.allocator(), &.{"--lib"}));
}

test "unknown flag rejected" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectError(error.UnknownFlag, parse(arena.allocator(), &.{"--nope"}));
}
