//! Runtime execution for generated code.
//!
//! Provides functions to execute generated JavaScript (via Node.js),
//! Erlang code (via erlc + erl), BEAM assembly (via erlc +from_asm + erl),
//! and WebAssembly (currently a stub), capturing the runtime output for
//! inclusion in the codegen snapshots' `----- RUN LOG -----` block.
//!
//! ## RUN LOG capture contract
//!
//! Every spawn goes through `runCaptured`, which reports the **exit status**
//! (`RunStatus`) separately from the captured text. Output length says
//! nothing about success: a successful `erlc`/`erlc +from_asm` prints
//! nothing at all, and a program that prints nothing is not a failure —
//! reading "empty output" as "the tool failed" is what kept the BEAM
//! backend from ever executing (spec 06 H1).
//!
//!   - `.ok` — exited 0. The captured text is the RUN LOG (stdout, with
//!     stderr appended after a newline when both are non-empty).
//!   - `.failed` — ran and exited non-zero. Deterministic for the same
//!     inputs (a rejected module, a crashing program), so the verdict may be
//!     recorded in the snapshot and cached.
//!   - `.unavailable` — the tool could not be run at all: missing binary,
//!     spawn error or timeout. Host-dependent, so it is never recorded and
//!     never cached; the RUN LOG stays empty as if the run never happened.
//!
//! What each stage does with that status:
//!
//!   - **Compile / assemble** (`erlc`, `erlc +from_asm`): `.ok` continues —
//!     warnings print on stderr with a 0 exit and must not stop the run
//!     (spec 06 H2). `.failed` records `COMPILE ERROR (<tool>):` plus the
//!     diagnostics as the RUN LOG, so a module the backend emits wrong is
//!     visible in the snapshot instead of silently empty.
//!   - **Execute** (`node`, `erl`): `.ok` records the captured output;
//!     `.failed` (the program crashed) records an empty RUN LOG — the
//!     snapshot still shows source + generated code, and the crash text
//!     carries stack frames that are not worth pinning.
//!
//! Determinism: `erlc`/`erl` are spawned with the per-execution scratch dir
//! as their cwd, so diagnostics name `<module>.erl` / `<module>.S` instead of
//! the random `.botopinkbuild/tmp/<hex>/` path, and any `erl_crash.dump` a
//! crashing program writes lands in the scratch dir that is deleted right
//! after (instead of in the repo tree). No absolute path reaches a snapshot.
//!
//! stderr is part of the captured text on purpose (a `@print` lowering that
//! writes to stderr, or a Node warning that explains an empty stdout, would
//! otherwise vanish). Host-specific stderr noise — an Erlang logger notice on
//! one runner and not another — would make a RUN LOG host-dependent; if that
//! ever resurfaces, filter the known lines here, do not go back to inferring
//! failure from the output.
const std = @import("std");
fn isProcessSuccess(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

/// Default runtime execution timeout — 2 minutes.
/// Generous enough for cold erlc/erl (~2s worst case), short enough that
/// a hung suite doesn't waste CI minutes. `std.process.run`'s built-in
/// `timeout` field enforces the deadline via the Io abstractions, no
/// separate watchdog thread needed.
const RUNTIME_TIMEOUT_NS: i96 = 120 * std.time.ns_per_s;

/// How a spawn ended — the piece of information the captured output cannot
/// carry (an empty buffer is both "succeeded quietly" and "never ran").
pub const RunStatus = enum {
    /// Ran and exited 0.
    ok,
    /// Ran and exited non-zero (or died on a signal). Deterministic for the
    /// same inputs, so the outcome may be recorded and cached.
    failed,
    /// Never ran: missing binary, spawn error or timeout. Host-dependent —
    /// never recorded in a snapshot, never cached.
    unavailable,
};

/// One spawn's captured text plus its exit status. `output` is always an
/// owned slice (possibly empty); the caller frees it.
const RunOutcome = struct {
    output: []u8,
    status: RunStatus,
};

/// Spawn `argv` (optionally with `cwd` as the child's working directory),
/// capture combined stdout+stderr, enforce `timeout_ns`, and report how the
/// process ended. Never infers failure from the captured bytes.
fn runCaptured(
    allocator: std.mem.Allocator,
    io: anytype,
    argv: []const []const u8,
    cwd: ?[]const u8,
    timeout_ns: i96,
) !RunOutcome {
    const result = std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = if (cwd) |p| .{ .path = p } else .inherit,
        .timeout = .{ .duration = .{ .raw = .{ .nanoseconds = timeout_ns }, .clock = .real } },
    }) catch return .{ .output = try allocator.dupe(u8, ""), .status = .unavailable };

    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    const status: RunStatus = if (isProcessSuccess(result.term)) .ok else .failed;

    if (result.stderr.len == 0) return .{ .output = try allocator.dupe(u8, result.stdout), .status = status };

    var combined: std.ArrayListUnmanaged(u8) = .empty;
    errdefer combined.deinit(allocator);
    try combined.appendSlice(allocator, result.stdout);
    if (combined.items.len > 0) try combined.append(allocator, '\n');
    try combined.appendSlice(allocator, result.stderr);
    return .{ .output = try combined.toOwnedSlice(allocator), .status = status };
}

/// RUN LOG text for a rejected module: a marker line the snapshot review can
/// grep for, then the tool's error diagnostics. Paths are bare
/// (`main.erl:7:24: …`) because the tool runs with the scratch dir as its cwd.
///
/// Two classes of line are dropped to keep the block stable across OTP
/// releases and consistent with the success path:
///   - `Warning:` lines — warnings never stop a run, so they are not part of
///     the verdict here either (a rejected module usually prints both);
///   - the `%  7| …` / `%   | ^` source echo OTP prints under each
///     diagnostic — the source is already in the snapshot's `SOURCE CODE` and
///     `ERLANG` / `BEAM ASSEMBLY` sections, and the echo's shape is an OTP
///     formatting detail.
fn compileFailureLog(allocator: std.mem.Allocator, tool: []const u8, diagnostics: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "COMPILE ERROR (");
    try out.appendSlice(allocator, tool);
    try out.appendSlice(allocator, "):");

    var lines = std.mem.splitScalar(u8, diagnostics, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, &std.ascii.whitespace);
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "%")) continue;
        if (std.mem.indexOf(u8, line, ": Warning:") != null) continue;
        try out.append(allocator, '\n');
        try out.appendSlice(allocator, line);
    }
    // Trailing newline: `snapshot.zig` writes the RUN LOG straight before the
    // closing ``` fence, which would otherwise be glued to the last line.
    try out.append(allocator, '\n');
    return out.toOwnedSlice(allocator);
}

/// Single root for every per-test scratch dir. Lives under the
/// build dir (`.botopinkbuild/`) so the umbrella `.gitignore` rule
/// already swallows it — no separate `.tmp-exec-*/` line needed.
/// `clean-tmp` (in `build.zig`) reaps entries older than 1 day, so a
/// crashed test never leaks beyond that.
pub const TMP_ROOT = ".botopinkbuild/tmp";

/// Content-keyed output cache. Each `executeX` hashes its inputs (harness
/// version + target tag + emitted code + aux modules + module name) into a
/// SHA256 key and short-circuits the spawn on a cache hit — every cached
/// entry is prefixed with `OK:` so a corrupt/truncated file is treated as a
/// miss and re-executed. Content-keyed, so any change to the inputs
/// (compiler output, std library) misses naturally; toolchain upgrades
/// (node/erl) are NOT folded into the key — clear the cache dir after
/// upgrading.
///
/// Nothing reaps this directory: `clean-tmp` (in `build.zig`) only removes
/// entries under `TMP_ROOT`. Delete it by hand to force a cold run (which is
/// what CI and a fresh clone always get — the directory is git-ignored).
pub const CACHE_ROOT = ".botopinkbuild/runtime-cache";

/// Bumped whenever the harness changes what it records for unchanged inputs
/// (the exit-status contract, compile-error capture, the cwd of the spawns).
/// Folded into `cacheKey` so entries written by an older harness miss instead
/// of masking the change — a warm cache must never hide a harness defect.
pub const HARNESS_VERSION = "2-exit-status";

/// Hash (harness version + target_tag + module_name + code + aux entries)
/// into a 64-char hex SHA256 key. Each component is length-prefixed so two
/// layouts can never collide (e.g. `aaa`+`bbb` vs `a`+`aabbb`).
fn cacheKey(out: *[64]u8, target: []const u8, module_name: []const u8, code: []const u8, aux: []const AuxFile) void {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    var lenbuf: [8]u8 = undefined;

    inline for ([_][]const u8{ HARNESS_VERSION, target, module_name, code }) |s| {
        std.mem.writeInt(u64, &lenbuf, s.len, .little);
        h.update(&lenbuf);
        h.update(s);
    }
    std.mem.writeInt(u64, &lenbuf, aux.len, .little);
    h.update(&lenbuf);
    for (aux) |a| {
        std.mem.writeInt(u64, &lenbuf, a.name.len, .little);
        h.update(&lenbuf);
        h.update(a.name);
        std.mem.writeInt(u64, &lenbuf, a.code.len, .little);
        h.update(&lenbuf);
        h.update(a.code);
    }

    var digest: [32]u8 = undefined;
    h.final(&digest);
    _ = std.fmt.bufPrint(out, "{x}", .{digest}) catch unreachable;
}

/// Read a cache hit; null on miss / corruption. Caller owns the slice
/// (a `OK:`-prefixed entry returns just the payload bytes).
fn cacheRead(allocator: std.mem.Allocator, io: anytype, key: []const u8) ?[]u8 {
    var path_buf: [128]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ CACHE_ROOT, key }) catch return null;
    const raw = std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .unlimited) catch return null;
    if (!std.mem.startsWith(u8, raw, "OK:")) {
        allocator.free(raw);
        return null;
    }
    const payload = allocator.dupe(u8, raw["OK:".len..]) catch {
        allocator.free(raw);
        return null;
    };
    allocator.free(raw);
    return payload;
}

/// Write a cache entry (best-effort: a failed write just means the next
/// run pays the spawn again).
fn cacheWrite(io: anytype, allocator: std.mem.Allocator, key: []const u8, output: []const u8) void {
    std.Io.Dir.cwd().createDirPath(io, CACHE_ROOT) catch return;
    var path_buf: [128]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ CACHE_ROOT, key }) catch return;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);
    buf.appendSlice(allocator, "OK:") catch return;
    buf.appendSlice(allocator, output) catch return;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = buf.items }) catch return;
}

/// Tests may run concurrently (and several test binaries share this cwd), so
/// every execution gets its own scratch directory — fixed filenames like
/// `main.erl`/`main.beam` would otherwise race and lose runtime output.
pub fn makeScratchDir(io: anytype, buf: *[96]u8) ![]const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    const tmp_dir = std.fmt.bufPrint(buf, "{s}/{x}", .{ TMP_ROOT, id }) catch unreachable;
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);
    return tmp_dir;
}

/// A sibling module written next to the entry file so `require`/remote calls
/// resolve at runtime (multi-module compilations, e.g. the "std" package).
pub const AuxFile = struct {
    name: []const u8,
    code: []const u8,
};

/// Execute JavaScript code using Node.js and capture stdout/stderr.
/// `aux` modules are written as `<scratch>/<name>.js` (subdirs created) so the
/// entry's `require("./<name>.js")` calls resolve.
///
/// Fast path: when there are no aux modules, the script can run inside the
/// persistent `node` runner's vm sandbox — ~1ms instead of ~30ms cold spawn.
/// Aux-bearing executions still need a real filesystem because the generated
/// code uses `require("./<name>.js")` against actual files.
pub fn executeJavaScript(allocator: std.mem.Allocator, js_code: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    // Output-cache short-circuit: on a hit we skip even the persistent
    // node round-trip (~1ms vs ~0ms file read). Mostly buys us latency on
    // the few aux-bearing fixtures that fall off the persistent_node fast
    // path below.
    var key: [64]u8 = undefined;
    cacheKey(&key, "node", "", js_code, aux);
    if (cacheRead(allocator, io, &key)) |hit| return hit;

    // One-shot node spawn for JavaScript execution (~30ms).
    if (aux.len == 0) {
        const ran = try runCaptured(allocator, io, &.{ "node", "-e", js_code }, null, RUNTIME_TIMEOUT_NS);
        if (ran.status != .ok) {
            allocator.free(ran.output);
            const empty = try allocator.dupe(u8, "");
            if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
            return empty;
        }
        cacheWrite(io, allocator, &key, ran.output);
        return ran.output;
    }

    // Write code to a temporary file in a per-execution scratch dir
    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const tmp_path = try std.fmt.allocPrint(allocator, "{s}/tmp_run.js", .{tmp_dir});
    defer allocator.free(tmp_path);
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp_path, .data = js_code });
    }
    for (aux) |a| {
        const aux_path = try std.fmt.allocPrint(allocator, "{s}/{s}.js", .{ tmp_dir, a.name });
        defer allocator.free(aux_path);
        if (std.fs.path.dirname(aux_path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_path, .data = a.code });
    }

    // Execute with Node.js
    const ran = try runCaptured(allocator, io, &.{ "node", tmp_path }, null, RUNTIME_TIMEOUT_NS);
    if (ran.status != .ok) {
        allocator.free(ran.output);
        const empty = try allocator.dupe(u8, "");
        if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
        return empty;
    }
    cacheWrite(io, allocator, &key, ran.output);
    return ran.output;
}

/// An Erlang module name is the path basename (`std/bool` → `bool`) —
/// matches the `-module(...)` atom the erlang backend emits.
fn erlModuleName(name: []const u8) []const u8 {
    return if (std.mem.lastIndexOfScalar(u8, name, '/')) |i| name[i + 1 ..] else name;
}

/// True when `erl_code` reaches stdio at runtime — only `io:format` (the
/// `@print` codegen template) is currently used. A future `@stderr` /
/// `@io_write` builtin would join this allow-list. Heuristic is on
/// purpose: a false positive only costs the legacy spawn we already pay,
/// while a false negative would silently elide RUN LOG bytes — so the
/// check is intentionally inclusive of any `io:` invocation.
fn erlangCodeWritesOutput(erl_code: []const u8) bool {
    return std.mem.indexOf(u8, erl_code, "io:format") != null or
        std.mem.indexOf(u8, erl_code, "io:put_chars") != null or
        std.mem.indexOf(u8, erl_code, "io:fwrite") != null;
}

/// BEAM `.S` analogue of `erlangCodeWritesOutput` — looks for the
/// `call_ext`/`extfunc` reference to `io:format`/`io:put_chars` the BEAM
/// backend emits when lowering `@print`. The `.S` syntax uses tuples
/// like `{extfunc, io, format, 2}` (spaces between commas), so the
/// substring is keyed on the module + fn pair to be space-tolerant.
fn beamAsmCodeWritesOutput(asm_code: []const u8) bool {
    return std.mem.indexOf(u8, asm_code, "io, format") != null or
        std.mem.indexOf(u8, asm_code, "io,format") != null or
        std.mem.indexOf(u8, asm_code, "io, put_chars") != null or
        std.mem.indexOf(u8, asm_code, "io,put_chars") != null or
        std.mem.indexOf(u8, asm_code, "io, fwrite") != null or
        std.mem.indexOf(u8, asm_code, "io,fwrite") != null;
}

/// Execute Erlang code and capture stdout/stderr.
/// `aux` modules are compiled into the same scratch dir so remote calls
/// (`option:map(...)`) resolve at runtime.
///
/// Returns the run's output on a 0 exit, `COMPILE ERROR (erlc):` plus the
/// diagnostics when `erlc` rejects a module, and the empty string when the
/// program crashes or the toolchain is missing.
pub fn executeErlang(allocator: std.mem.Allocator, erl_code: []const u8, module_name: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    // Two early exits, before spawning any erlc/erl subprocess (each spawn
    // is ~500–700ms cold and the snapshot block ahead of us is the only
    // consumer of this output):
    //   1. library-style fixtures (no `fn main`) cannot be executed by
    //      `erl -s <mod> _botopink_main`;
    //   2. fixtures that emit no I/O — `io:format` is the codegen's only
    //      stdout/stderr-writing primitive — would produce an empty RUN
    //      LOG anyway. Across the codegen test suite this is the dominant
    //      case (every `fn main() { val x = 1 + 2; }`-style fixture), so
    //      gating the spawn here drops ~1.2s off each of those tests.
    //   The same logic lives in `executeBeamAsm` below for the BEAM-asm
    //   path. Aux modules don't change this — if the entry module never
    //   writes, no `lists:map(...)` call inside an aux can either (the
    //   aux's pure-fn return value travels back as a plain term, not as
    //   stdout bytes).
    if (std.mem.indexOf(u8, erl_code, "_botopink_main") == null) {
        return allocator.dupe(u8, "");
    }
    if (!erlangCodeWritesOutput(erl_code)) {
        for (aux) |a| {
            if (erlangCodeWritesOutput(a.code)) break;
        } else return allocator.dupe(u8, "");
    }

    // Output-cache short-circuit: spares the erlc+erl spawn (~600ms) on a
    // hit. The key folds module_name in so two fixtures with the same
    // body but different entry-module names don't share.
    var key: [64]u8 = undefined;
    cacheKey(&key, "erlang", module_name, erl_code, aux);
    if (cacheRead(allocator, io, &key)) |hit| return hit;

    // Create temporary .erl file in a per-execution scratch dir
    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const entry_module = erlModuleName(module_name);
    // Two spellings of every file: the path from the process cwd (used to
    // write it) and the bare basename (used in argv — `erlc`/`erl` run *in*
    // the scratch dir, so their diagnostics never quote the random hex).
    const entry_basename = try std.fmt.allocPrint(allocator, "{s}.erl", .{entry_module});
    defer allocator.free(entry_basename);
    const erl_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, entry_basename });
    defer allocator.free(erl_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_filename, .data = erl_code });
    }

    // Compile the Erlang module (and any sibling modules it calls into).
    // `erlc` exits 0 for a warning-only compilation and prints the warnings
    // on stderr, so only the exit status decides: warnings are dropped and
    // the module still runs; a rejection becomes the RUN LOG.
    {
        const compiled = try runCaptured(allocator, io, &.{ "erlc", "-o", ".", entry_basename }, tmp_dir, RUNTIME_TIMEOUT_NS);
        defer allocator.free(compiled.output);
        switch (compiled.status) {
            .ok => {},
            .unavailable => return allocator.dupe(u8, ""),
            .failed => {
                const log = try compileFailureLog(allocator, "erlc", compiled.output);
                cacheWrite(io, allocator, &key, log);
                return log;
            },
        }
    }
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_basename = try std.fmt.allocPrint(allocator, "{s}.erl", .{aux_module});
        defer allocator.free(aux_basename);
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, aux_basename });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_compiled = try runCaptured(allocator, io, &.{ "erlc", "-o", ".", aux_basename }, tmp_dir, RUNTIME_TIMEOUT_NS);
        defer allocator.free(aux_compiled.output);
        switch (aux_compiled.status) {
            .ok => {},
            .unavailable => return allocator.dupe(u8, ""),
            .failed => {
                const log = try compileFailureLog(allocator, "erlc", aux_compiled.output);
                cacheWrite(io, allocator, &key, log);
                return log;
            },
        }
    }

    // A crashing program (non-zero exit) records an empty RUN LOG: the
    // partial stdout it managed to write comes with an Erlang stack trace
    // that is not worth pinning in a snapshot.
    const ran = try runCaptured(allocator, io, &.{ "erl", "-noinput", "-pa", ".", "-s", entry_module, "_botopink_main", "-s", "init", "stop" }, tmp_dir, RUNTIME_TIMEOUT_NS);
    if (ran.status != .ok) {
        allocator.free(ran.output);
        const empty = try allocator.dupe(u8, "");
        if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
        return empty;
    }
    cacheWrite(io, allocator, &key, ran.output);
    return ran.output;
}

/// Execute BEAM Assembly code: write the `.S`, assemble it with
/// `erlc +from_asm <file>.S` (produces `<module>.beam` in the scratch dir),
/// then run the generated `_botopink_main/0` via `erl -s ...`.
///
/// Returns the run's output on a 0 exit, `COMPILE ERROR (erlc +from_asm):`
/// plus the diagnostics when the assembler or the loader's validator rejects
/// a module, and the empty string when the program crashes or `erlc`/`erl`
/// is missing — the test still produces a readable snapshot either way.
pub fn executeBeamAsm(allocator: std.mem.Allocator, asm_code: []const u8, module_name: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    // Two early exits, before spawning any `erlc +from_asm` / `erl` (each
    // is ~600–700ms cold). Mirrors `executeErlang` above — see that fn for
    // the rationale.
    if (std.mem.indexOf(u8, asm_code, "'_botopink_main', 0") == null) {
        return allocator.dupe(u8, "");
    }
    if (!beamAsmCodeWritesOutput(asm_code)) {
        for (aux) |a| {
            if (beamAsmCodeWritesOutput(a.code)) break;
        } else return allocator.dupe(u8, "");
    }

    // Output-cache short-circuit: spares the erlc+from_asm + erl spawn
    // (~700ms) on a hit.
    var key: [64]u8 = undefined;
    cacheKey(&key, "beam", module_name, asm_code, aux);
    if (cacheRead(allocator, io, &key)) |hit| return hit;

    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const entry_module = erlModuleName(module_name);
    const asm_basename = try std.fmt.allocPrint(allocator, "{s}.S", .{entry_module});
    defer allocator.free(asm_basename);
    const asm_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, asm_basename });
    defer allocator.free(asm_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = asm_filename, .data = asm_code });
    }

    // A successful `erlc +from_asm` prints nothing, so the exit status is the
    // only signal: reading "no output" as failure is what kept every BEAM
    // fixture from running (spec 06 H1). A rejection (the loader's validator
    // included) becomes the RUN LOG instead of being silently dropped.
    {
        const assembled = try runCaptured(allocator, io, &.{ "erlc", "+from_asm", "-o", ".", asm_basename }, tmp_dir, RUNTIME_TIMEOUT_NS);
        defer allocator.free(assembled.output);
        switch (assembled.status) {
            .ok => {},
            .unavailable => return allocator.dupe(u8, ""),
            .failed => {
                const log = try compileFailureLog(allocator, "erlc +from_asm", assembled.output);
                cacheWrite(io, allocator, &key, log);
                return log;
            },
        }
    }

    // Assemble sibling modules the entry calls into (cross-module `call_ext`).
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_basename = try std.fmt.allocPrint(allocator, "{s}.S", .{aux_module});
        defer allocator.free(aux_basename);
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, aux_basename });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_assembled = try runCaptured(allocator, io, &.{ "erlc", "+from_asm", "-o", ".", aux_basename }, tmp_dir, RUNTIME_TIMEOUT_NS);
        defer allocator.free(aux_assembled.output);
        switch (aux_assembled.status) {
            .ok => {},
            .unavailable => return allocator.dupe(u8, ""),
            .failed => {
                const log = try compileFailureLog(allocator, "erlc +from_asm", aux_assembled.output);
                cacheWrite(io, allocator, &key, log);
                return log;
            },
        }
    }

    const ran = try runCaptured(allocator, io, &.{ "erl", "-noinput", "-pa", ".", "-s", entry_module, "_botopink_main", "-s", "init", "stop" }, tmp_dir, RUNTIME_TIMEOUT_NS);
    if (ran.status != .ok) {
        allocator.free(ran.output);
        const empty = try allocator.dupe(u8, "");
        if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
        return empty;
    }
    cacheWrite(io, allocator, &key, ran.output);
    return ran.output;
}

/// WebAssembly Text execution — **a stub**: every wasm RUN LOG is empty
/// until a runtime is wired back in (spec 03 step 2). The embedded wasm3
/// interpreter it used to call was removed with `vendor/wasm3`.
///
/// `wat_code` / `module_name` / `io` are kept for parity with the sibling
/// `executeJavaScript` / `executeErlang` signatures.
pub fn executeWat(allocator: std.mem.Allocator, wat_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    _ = wat_code;
    _ = module_name;
    _ = io;
    return allocator.dupe(u8, "");
}

test "compileFailureLog keeps the errors, drops warnings and the source echo" {
    const alloc = std.testing.allocator;
    const diagnostics =
        \\main.erl:31:24: function all/2 undefined
        \\%   31|     io:format("~p~n", [all(Xs, fun(X) ->
        \\%     |                        ^
        \\
        \\main.erl:6:1: Warning: function array_range/2 is unused
        \\%    6| array_range(Start, Stop) ->
        \\%     | ^
        \\
    ;
    const log = try compileFailureLog(alloc, "erlc", diagnostics);
    defer alloc.free(log);
    try std.testing.expectEqualStrings(
        "COMPILE ERROR (erlc):\nmain.erl:31:24: function all/2 undefined\n",
        log,
    );
}

test "compileFailureLog keeps the indented body of a validator rejection" {
    const alloc = std.testing.allocator;
    const diagnostics =
        \\main:1: function diff/2+8:
        \\  Internal consistency check failed - please report this bug.
        \\  Error:       {{x,2},not_live}:
        \\
    ;
    const log = try compileFailureLog(alloc, "erlc +from_asm", diagnostics);
    defer alloc.free(log);
    try std.testing.expectEqualStrings(
        "COMPILE ERROR (erlc +from_asm):\n" ++
            "main:1: function diff/2+8:\n" ++
            "  Internal consistency check failed - please report this bug.\n" ++
            "  Error:       {{x,2},not_live}:\n",
        log,
    );
}
