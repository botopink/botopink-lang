/// Argument parsing for `botopink-lib-test`.
///
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///                     [--jobs <n>] [--json] [--list] [--cold] [--store-root <dir>]
///
/// `--target` is repeatable and comma-separated. It accepts every codegen target
/// plus the alias `node` → `commonJS`, and both the `--target <t>` and
/// `--target=<t>` spellings. The default target set is `commonJS,erlang` — the two
/// backends `botopink test` runs today. `all` expands to every *supported* target.
///
/// There is no flag that runs a target a manifest excludes: the manifest's
/// `"targets"` list decides which (lib, target) pairs are cells, and an excluded
/// pair is audited instead (`runner.captureAudit`).
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

    /// Whether `botopink test` runs this target today (`supported`). A target
    /// a manifest excludes is audited only when this holds: an exclusion of a
    /// target no cell can run on hides nothing the run could have measured.
    pub fn isSupported(self: Target) bool {
        for (supported) |t| {
            if (t == self) return true;
        }
        return false;
    }

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
    /// Extra lib roots appended to the discovery walker after env-derived roots
    /// (`BOTOPINK_LIB_ROOTS`) and the walk-up halves. Repeatable
    /// (`--lib-root /a --lib-root /b`). For ad-hoc CI without mutating env.
    lib_roots: []const []const u8 = &.{},
    /// `--json` — pass `--json` to each spawned `botopink test` and re-emit
    /// the child's JSONL with `"lib":"<name>"` + `"target":"<t>"` fields
    /// injected, plus per-cell `{"event":"cell_summary",…}` and a final
    /// `{"event":"run_summary",…}` record. Text-mode matrix is skipped.
    json: bool = false,
    /// `--jobs <n>` — how many cells run at once. `null` → the runner's
    /// default (`main.defaultJobs`: the CPU count, bounded by available
    /// memory). Scheduling only: every cell runs either way, and the output is
    /// emitted in discovery order, byte for byte what `--jobs 1` prints.
    jobs: ?usize = null,
    /// `--list` — print the plan and spawn nothing: one
    /// `<lib>\t<target>\t<kind>` line per (lib, target) pair, in discovery
    /// order. The lines whose kind starts with `cell:` are the cells the
    /// manifests declare; `audit` is an excluded pair the run would audit.
    list: bool = false,
    /// `--cold` — do not read the cell-result store (`result_store.zig`):
    /// every spawning cell runs, and its passes are written (decision 249).
    /// `scripts/gate.sh --cold` passes it. It changes what is executed, never
    /// a verdict.
    cold: bool = false,
    /// `--store-root <dir>` — keep the result store in `<dir>` instead of each
    /// library's `<cache root>/.botopinkbuild/cache/results/lib-test/`.
    store_root: ?[]const u8 = null,
};

pub const ParseError = error{
    MissingArgument,
    InvalidTarget,
    UnknownFlag,
    InvalidJobs,
} || std.mem.Allocator.Error;

/// Parse `args` (the slice *after* the program name). Allocations land in `arena`.
pub fn parse(arena: std.mem.Allocator, args: []const []const u8) ParseError!Options {
    var opts: Options = .{};
    var targets: std.ArrayListUnmanaged(Target) = .empty;
    var lib_roots: std.ArrayListUnmanaged([]const u8) = .empty;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const a = args[i];

        // `--target=<v>` / `--lib=<v>` / `--filter=<v>` / `--bin=<v>` /
        // `--lib-root=<v>` (the `=` form). `--lib-root` is checked BEFORE `--lib`
        // so the more specific prefix wins.
        if (splitEq(a, "--target")) |v| {
            try appendTargets(arena, &targets, v);
        } else if (std.mem.eql(u8, a, "--target")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try appendTargets(arena, &targets, args[i]);
        } else if (splitEq(a, "--lib-root")) |v| {
            try lib_roots.append(arena, v);
        } else if (std.mem.eql(u8, a, "--lib-root")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try lib_roots.append(arena, args[i]);
        } else if (splitEq(a, "--store-root")) |v| {
            opts.store_root = v;
        } else if (std.mem.eql(u8, a, "--store-root")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.store_root = args[i];
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
        } else if (splitEq(a, "--jobs")) |v| {
            opts.jobs = try parseJobs(v);
        } else if (std.mem.eql(u8, a, "--jobs")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.jobs = try parseJobs(args[i]);
        } else if (std.mem.eql(u8, a, "--strict")) {
            opts.strict = true;
        } else if (std.mem.eql(u8, a, "--json")) {
            opts.json = true;
        } else if (std.mem.eql(u8, a, "--list")) {
            opts.list = true;
        } else if (std.mem.eql(u8, a, "--cold")) {
            opts.cold = true;
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
    opts.lib_roots = try lib_roots.toOwnedSlice(arena);
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

/// A positive decimal worker count; `0` or anything else is refused.
fn parseJobs(v: []const u8) ParseError!usize {
    const n = std.fmt.parseUnsigned(usize, v, 10) catch return error.InvalidJobs;
    if (n == 0) return error.InvalidJobs;
    return n;
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
        "--lib",         "acme",
        "--filter",      "router",
        "--strict",      "--bin",
        "/tmp/botopink",
    });
    try testing.expectEqualStrings("acme", opts.lib.?);
    try testing.expectEqualStrings("router", opts.filter.?);
    try testing.expect(opts.strict);
    try testing.expectEqualStrings("/tmp/botopink", opts.bin.?);
}

test "--lib=name (= form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{"--lib=acme-web"});
    try testing.expectEqualStrings("acme-web", opts.lib.?);
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

test "isSupported: the targets `botopink test` runs today" {
    try testing.expect(Target.commonJS.isSupported());
    try testing.expect(Target.erlang.isSupported());
    try testing.expect(!Target.beam.isSupported());
    try testing.expect(!Target.wasm.isSupported());
}

test "--list is off by default and set by the flag" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const off = try parse(arena.allocator(), &.{});
    try testing.expect(!off.list);
    const on = try parse(arena.allocator(), &.{"--list"});
    try testing.expect(on.list);
}

test "--cold and --store-root: the store is read unless --cold, in its default place unless named" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const warm = try parse(arena.allocator(), &.{});
    try testing.expect(!warm.cold);
    try testing.expect(warm.store_root == null);
    const cold = try parse(arena.allocator(), &.{ "--cold", "--store-root", "/s" });
    try testing.expect(cold.cold);
    try testing.expectEqualStrings("/s", cold.store_root.?);
    const eq = try parse(arena.allocator(), &.{"--store-root=/t"});
    try testing.expectEqualStrings("/t", eq.store_root.?);
    try testing.expectError(error.MissingArgument, parse(arena.allocator(), &.{"--store-root"}));
}

test "unknown flag rejected" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectError(error.UnknownFlag, parse(arena.allocator(), &.{"--nope"}));
}

test "--lib-root accumulates (space form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{
        "--lib-root", "/tmp/a",
        "--lib-root", "/tmp/b",
    });
    try testing.expectEqual(@as(usize, 2), opts.lib_roots.len);
    try testing.expectEqualStrings("/tmp/a", opts.lib_roots[0]);
    try testing.expectEqualStrings("/tmp/b", opts.lib_roots[1]);
}

test "--lib-root=path (= form)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{"--lib-root=/tmp/store"});
    try testing.expectEqual(@as(usize, 1), opts.lib_roots.len);
    try testing.expectEqualStrings("/tmp/store", opts.lib_roots[0]);
}

test "--lib-root does not shadow --lib" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const opts = try parse(arena.allocator(), &.{
        "--lib-root", "/store",
        "--lib",      "foo",
    });
    try testing.expectEqualStrings("/store", opts.lib_roots[0]);
    try testing.expectEqualStrings("foo", opts.lib.?);
}

test "--jobs takes a positive count, both spellings; 0 and junk are refused" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const unset = try parse(arena.allocator(), &.{});
    try testing.expect(unset.jobs == null);
    const space = try parse(arena.allocator(), &.{ "--jobs", "3" });
    try testing.expectEqual(@as(usize, 3), space.jobs.?);
    const eq = try parse(arena.allocator(), &.{"--jobs=1"});
    try testing.expectEqual(@as(usize, 1), eq.jobs.?);
    try testing.expectError(error.InvalidJobs, parse(arena.allocator(), &.{ "--jobs", "0" }));
    try testing.expectError(error.InvalidJobs, parse(arena.allocator(), &.{"--jobs=many"}));
    try testing.expectError(error.MissingArgument, parse(arena.allocator(), &.{"--jobs"}));
}
