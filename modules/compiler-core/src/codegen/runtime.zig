//! Runtime execution for generated code.
//!
//! Provides functions to execute generated JavaScript (via Node.js),
//! Erlang code (via erlc + erl), BEAM assembly (via erlc +from_asm + erl),
//! and WebAssembly text (via `wasmtime run`), capturing the runtime output for
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
//!   - `.interrupted` — the tool ran but did not end by its own exit: a
//!     signal (Ctrl-C, a kill, a cut output), a stop, or an `erl` that went
//!     through its break handler (`BREAK: (a)bort …`, which then halts with
//!     status 0). Treated as `.unavailable`: never recorded, never cached —
//!     a stored one would be replayed by every later run.
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
//!   - **Syntax** (`node --check`): a failed `node` run is re-checked with
//!     `node --check`; a module node cannot parse records
//!     `COMPILE ERROR (node --check):` plus the SyntaxError, so JavaScript the
//!     backend emits wrong is never mistaken for a program that printed
//!     nothing. A module that parses always runs, so checking only after a
//!     failed run sees every unparseable module and costs a successful run
//!     nothing.
//!   - **Execute wasm** (`wasmtime run`): `.ok` records the output; `.failed`
//!     (a trap) records what the module printed plus a
//!     `RUNTIME TRAP (wasmtime):` block with the trap message — never an
//!     empty log, which would read like a program that ran and printed
//!     nothing.
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
const moduleOutput = @import("./moduleOutput.zig");
const crossModule = @import("./crossModule.zig");
const wasmNeeds = @import("./wat/needs.zig");
const runtimeUnit = @import("./wat/runtime_unit.zig");
const otp = @import("../otp.zig");
fn isProcessSuccess(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

/// The banner `erl`'s break handler prints when the emulator receives SIGINT.
/// With stdin at EOF the handler then halts the emulator with exit status 0,
/// so the exit status alone reads an interrupted run as a pass.
const ERL_BREAK_BANNER = "BREAK: (a)bort";

/// How a spawn that ran ended: `.ok` / `.failed` only when the process ended
/// by its own exit, `.interrupted` otherwise — a signal, a stop, an unknown
/// end, or an `erl` that went through its break handler.
fn classifyEnd(tool: []const u8, term: std.process.Child.Term, stdout: []const u8, stderr: []const u8) RunStatus {
    switch (term) {
        .exited => {},
        else => return .interrupted,
    }
    if (std.mem.eql(u8, tool, "erl") and
        (std.mem.indexOf(u8, stdout, ERL_BREAK_BANNER) != null or
            std.mem.indexOf(u8, stderr, ERL_BREAK_BANNER) != null)) return .interrupted;
    return if (isProcessSuccess(term)) .ok else .failed;
}

/// Default runtime execution timeout — 2 minutes.
/// Generous enough for cold erlc/erl (~2s worst case), short enough that
/// a hung suite doesn't waste CI minutes. A spawn's is `std.process.run`'s
/// built-in `timeout`; an in-process wasm run's is the runner's epoch
/// deadline (`executeWatIn`, decision 1034 (2)).
const RUNTIME_TIMEOUT_NS: i96 = 120 * std.time.ns_per_s;

/// How a spawn ended — the piece of information the captured output cannot
/// carry (an empty buffer is both "succeeded quietly" and "never ran").
pub const RunStatus = enum {
    /// Ran and exited 0.
    ok,
    /// Ran and exited non-zero by its own exit. Deterministic for the same
    /// inputs, so the outcome may be recorded and cached.
    failed,
    /// Ran but did not end by its own exit: killed by a signal (an
    /// interrupted run, a cut output), stopped, or an `erl` interrupted into
    /// its break handler. Says nothing about the program — never recorded,
    /// never cached.
    interrupted,
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
/// process ended. Never infers failure from the captured bytes. An `erl`,
/// `erlc` or `escript` starts only on the release the compiler emits for
/// (`otp.zig`, decision 228): another one is `error.OtpReleaseRefused`, never
/// an empty RUN LOG.
fn runCaptured(
    allocator: std.mem.Allocator,
    io: anytype,
    argv: []const []const u8,
    cwd: ?[]const u8,
    timeout_ns: i96,
) !RunOutcome {
    if (isErlangTool(argv[0])) try otp.check(io);
    const result = std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = if (cwd) |p| .{ .path = p } else .inherit,
        .timeout = .{ .duration = .{ .raw = .{ .nanoseconds = timeout_ns }, .clock = .real } },
    }) catch return .{ .output = try allocator.dupe(u8, ""), .status = .unavailable };

    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    const status = classifyEnd(argv[0], result.term, result.stdout, result.stderr);

    if (result.stderr.len == 0) return .{ .output = try allocator.dupe(u8, result.stdout), .status = status };

    var combined: std.ArrayListUnmanaged(u8) = .empty;
    errdefer combined.deinit(allocator);
    try combined.appendSlice(allocator, result.stdout);
    if (combined.items.len > 0) try combined.append(allocator, '\n');
    try combined.appendSlice(allocator, result.stderr);
    return .{ .output = try combined.toOwnedSlice(allocator), .status = status };
}

/// The tools whose release is the OTP release check's business.
fn isErlangTool(tool: []const u8) bool {
    for ([_][]const u8{ "erl", "erlc", "escript" }) |t| {
        if (std.mem.eql(u8, tool, t)) return true;
    }
    return false;
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

/// RUN LOG text for a wasm module that trapped: what it printed before the
/// trap (its stdout, then its stderr), then a marker line the snapshot review
/// can grep for, then the trap itself — the runner's `wasm trap: …` line, or
/// the last line of another failure (`runner.trapLine`), empty for a non-zero
/// exit with no trap. A trap must never read like a program that ran and
/// printed nothing, which is what an empty log would say. The marker keeps the
/// tool's name of the `wasmtime` CLI era, so every RUN LOG stays byte-identical
/// under the in-process runner (decision 1034 (3)).
fn runtimeTrapLog(allocator: std.mem.Allocator, tool: []const u8, printed: []const u8, trap: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    if (printed.len > 0) {
        try out.appendSlice(allocator, printed);
        if (printed[printed.len - 1] != '\n') try out.append(allocator, '\n');
    }
    try out.appendSlice(allocator, "RUNTIME TRAP (");
    try out.appendSlice(allocator, tool);
    try out.appendSlice(allocator, "):\n");
    try out.appendSlice(allocator, trap);
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
/// (the exit-status contract, compile-error capture, the cwd of the spawns,
/// the package-first scratch-file atom of decision 109, a run not ended by
/// its own exit never stored).
/// Folded into `cacheKey` so entries written by an older harness miss instead
/// of masking the change — a warm cache must never hide a harness defect.
pub const HARNESS_VERSION = "6-own-exit";

/// Hash (harness version + target_tag + module_name + code + aux entries)
/// into a 64-char hex SHA256 key. Each component is length-prefixed so two
/// layouts can never collide (e.g. `aaa`+`bbb` vs `a`+`aabbb`).
pub fn cacheKey(out: *[64]u8, target: []const u8, module_name: []const u8, code: []const u8, aux: []const AuxFile) void {
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
        // The file an aux is written to is named by its atom.
        if (a.atom) |atom| {
            std.mem.writeInt(u64, &lenbuf, atom.len, .little);
            h.update(&lenbuf);
            h.update(atom);
        }
    }

    var digest: [32]u8 = undefined;
    h.final(&digest);
    _ = std.fmt.bufPrint(out, "{x}", .{digest}) catch unreachable;
}

/// Read a cache hit; null on miss / corruption. Caller owns the slice
/// (a `OK:`-prefixed entry returns just the payload bytes).
pub fn cacheRead(allocator: std.mem.Allocator, io: anytype, key: []const u8) ?[]u8 {
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
///
/// **Staged and renamed, never written in place.** The path is content-keyed,
/// so two writers of one key write the same bytes — but they share this cwd
/// (parallel tests, two `zig build test` processes over one checkout), and a
/// plain truncate-and-write is not one step. A reader arriving mid-write saw a
/// SHORT entry that still began `OK:`, and `cacheRead` accepts it: a truncated
/// tail came back as the program's output and nothing said so. A rename is
/// atomic, so a reader sees the old entry or the whole new one. The staging
/// name carries 64 random bits, so two writers never stage over each other
/// either. Same shape as `comptime/template_eval.zig`'s `writeModule`, which
/// stages precisely against this.
fn cacheWrite(io: anytype, allocator: std.mem.Allocator, key: []const u8, output: []const u8) void {
    const cwd = std.Io.Dir.cwd();
    cwd.createDirPath(io, CACHE_ROOT) catch return;
    var path_buf: [128]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ CACHE_ROOT, key }) catch return;
    var nonce: [8]u8 = undefined;
    io.random(&nonce);
    var staging_buf: [160]u8 = undefined;
    const staging = std.fmt.bufPrint(&staging_buf, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &nonce, .little) }) catch return;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);
    buf.appendSlice(allocator, "OK:") catch return;
    buf.appendSlice(allocator, output) catch return;
    cwd.writeFile(io, .{ .sub_path = staging, .data = buf.items }) catch return;
    cwd.rename(staging, cwd, path, io) catch {
        cwd.deleteFile(io, staging) catch {};
        return;
    };
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
    /// The module atom, already rendered, when the aux is a per-`type` module
    /// (`GenerateResult.units`) — its name IS an atom, not a module path, so it
    /// must not go through `erlModuleAtom` again (the package would be
    /// prepended a second time and the declaration lowercased).
    /// Null for a sibling source module, whose path is rendered here.
    atom: ?[]const u8 = null,
};

/// The scratch-file atom of an aux module: the pre-rendered one of a per-type
/// unit, else the module path's.
fn auxAtom(allocator: std.mem.Allocator, a: AuxFile) ![]u8 {
    if (a.atom) |atom| return allocator.dupe(u8, atom);
    return erlModuleAtom(allocator, a.name);
}

/// Execute JavaScript code using Node.js and capture stdout/stderr.
/// `aux` modules are written flat as `<scratch>/<pkg>@<path>.js` (decision
/// 1015, `auxAtom`) so the entry's `require("./<pkg>@<path>")` calls resolve.
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
    // `node+check`: entries recorded before the `node --check` capture
    // existed hold an empty log for an unparseable module and must miss.
    cacheKey(&key, "node+check", "", js_code, aux);
    if (cacheRead(allocator, io, &key)) |hit| return hit;

    // One-shot node spawn for JavaScript execution (~30ms).
    if (aux.len == 0) {
        const ran = try runCaptured(allocator, io, &.{ "node", "-e", js_code }, null, RUNTIME_TIMEOUT_NS);
        if (ran.status != .ok) {
            allocator.free(ran.output);
            if (ran.status == .failed) {
                if (try nodeCheckFailure(allocator, io, js_code, aux)) |log| {
                    cacheWrite(io, allocator, &key, log);
                    return log;
                }
            }
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
        const flat = try auxAtom(allocator, a);
        defer allocator.free(flat);
        const aux_path = try std.fmt.allocPrint(allocator, "{s}/{s}.js", .{ tmp_dir, flat });
        defer allocator.free(aux_path);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_path, .data = a.code });
    }

    // Execute with Node.js
    const ran = try runCaptured(allocator, io, &.{ "node", tmp_path }, null, RUNTIME_TIMEOUT_NS);
    if (ran.status != .ok) {
        allocator.free(ran.output);
        if (ran.status == .failed) {
            if (try nodeCheckFailure(allocator, io, js_code, aux)) |log| {
                cacheWrite(io, allocator, &key, log);
                return log;
            }
        }
        const empty = try allocator.dupe(u8, "");
        if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
        return empty;
    }
    cacheWrite(io, allocator, &key, ran.output);
    return ran.output;
}

/// `node --check` over a module whose run failed. Returns the
/// `COMPILE ERROR (node --check):` RUN LOG when node cannot parse it, or null
/// when it parses (the program itself crashed) or the check could not run.
///
/// The module is checked under the name it is emitted as (the `aux` entry
/// holding the same code, else `main`), from a scratch dir used as the cwd,
/// so the location line reads `main.js:3` rather than a random absolute path.
fn nodeCheckFailure(allocator: std.mem.Allocator, io: anytype, js_code: []const u8, aux: []const AuxFile) !?[]u8 {
    var name: []const u8 = "main";
    for (aux) |a| {
        if (std.mem.eql(u8, a.code, js_code)) {
            name = a.name;
            break;
        }
    }

    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const rel = try std.fmt.allocPrint(allocator, "{s}.js", .{name});
    defer allocator.free(rel);
    const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, rel });
    defer allocator.free(path);
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = js_code });

    const checked = try runCaptured(allocator, io, &.{ "node", "--check", rel }, tmp_dir, RUNTIME_TIMEOUT_NS);
    defer allocator.free(checked.output);
    if (checked.status != .failed) return null;
    return try nodeCheckFailureLog(allocator, rel, checked.output);
}

/// RUN LOG text for a module `node --check` rejected: the marker line, the
/// `<module>.js:<line>` location (the scratch path stripped), node's source
/// echo and caret, and the `SyntaxError:` line. Node's internal stack frames
/// (`    at …`) and its trailing `Node.js v…` banner are dropped — they name
/// the node release, not the module.
fn nodeCheckFailureLog(allocator: std.mem.Allocator, rel: []const u8, diagnostics: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "COMPILE ERROR (node --check):");

    var lines = std.mem.splitScalar(u8, diagnostics, '\n');
    while (lines.next()) |raw| {
        var line = std.mem.trimEnd(u8, raw, &std.ascii.whitespace);
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "    at ")) continue;
        if (std.mem.startsWith(u8, line, "Node.js v")) continue;
        // `/abs/scratch/main.js:3` → `main.js:3`.
        if (std.mem.indexOf(u8, line, rel)) |at| {
            if (at > 0 and line[at - 1] == '/' and std.mem.startsWith(u8, line[at + rel.len ..], ":")) line = line[at..];
        }
        try out.append(allocator, '\n');
        try out.appendSlice(allocator, line);
    }
    try out.append(allocator, '\n');
    return try out.toOwnedSlice(allocator);
}

/// The Erlang/BEAM module atom of a module path — its package, then the whole
/// path joined with `@` (`std/bool` → `std@bool`, `main` → `test@main`: the
/// harness compiles under the implicit test manifest, `crossModule.test_packages`,
/// exactly as the codegen it runs — `helpers.configs`), which is what the erlang and
/// BEAM backends write into `-module(...)` / `{module, …}`. It was the path's BASENAME, and
/// the harness inherited the collision that made: two aux modules whose paths
/// shared a basename were written to the same scratch file and one silently
/// overwrote the other. Caller owns the result.
fn erlModuleAtom(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    return crossModule.erlAtom(allocator, crossModule.test_packages.idOf(name)) catch |err| switch (err) {
        error.OutOfMemory => error.OutOfMemory,
        else => allocator.dupe(u8, crossModule.moduleBasename(name)),
    };
}

/// Two modules of one program writing the same scratch filename. Loud, in the
/// RUN LOG, because the harness used to let the second overwrite the first.
fn duplicateAtomLog(allocator: std.mem.Allocator, atom: []const u8, first: []const u8, second: []const u8) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "HARNESS ERROR: modules `{s}` and `{s}` both render to the module atom `{s}`, so both would be written to `{s}`\n",
        .{ first, second, atom, atom },
    );
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

/// The `botopink test` targets a test-mode module can be run under.
pub const TestTarget = enum { commonJS, erlang };

/// Run a module's **test unit** (decision 513) the way `botopink test` does —
/// the production module `code` written where its unit reaches it
/// (`main.js` beside `__test__/main.js`; `<atom>.erl` beside
/// `<unit atom>.erl`), then `node __test__/main.js` / `escript <unit>.erl` —
/// and answer everything it printed, **whatever its exit status**. The test
/// runner exits non-zero when a test fails (`process.exit(1)` / `halt(1)`), and
/// that failing run is exactly the output a decision-74 fixture pins (`FAIL
/// <name> (<e>) at <file>:<line>`), so the "crash → empty RUN LOG" rule of
/// `executeJavaScript`/`executeErlang` does not apply here. Answers `""` only
/// when the runtime is not on PATH. No output cache: the caller compares the
/// text itself.
pub fn executeTestModule(allocator: std.mem.Allocator, io: anytype, target: TestTarget, code: []const u8, unit: moduleOutput.Unit) ![]u8 {
    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const prod_name: []const u8 = switch (target) {
        // Decision 1015 — the unit `__test__/<pkg>@<path>` requires its module
        // by that flat name, one folder up.
        .commonJS => try std.fmt.allocPrint(allocator, "{s}.js", .{if (std.mem.startsWith(u8, unit.atom, "__test__/")) unit.atom["__test__/".len..] else unit.atom}),
        .erlang => blk: {
            const at = std.mem.indexOf(u8, code, "-module(") orelse return error.NoModuleForm;
            const close = std.mem.indexOfScalarPos(u8, code, at, ')') orelse return error.NoModuleForm;
            break :blk try std.fmt.allocPrint(allocator, "{s}.erl", .{code[at + "-module(".len .. close]});
        },
    };
    defer allocator.free(prod_name);
    const unit_name = try std.fmt.allocPrint(allocator, "{s}{s}", .{ unit.atom, if (target == .commonJS) ".js" else ".erl" });
    defer allocator.free(unit_name);
    for ([_][2][]const u8{ .{ prod_name, code }, .{ unit_name, unit.code } }) |file| {
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, file[0] });
        defer allocator.free(path);
        if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = file[1] });
    }
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .erlang => "escript",
    };
    const ran = try runCaptured(allocator, io, &.{ runner, unit_name }, tmp_dir, RUNTIME_TIMEOUT_NS);
    if (ran.status == .unavailable or ran.status == .interrupted) {
        allocator.free(ran.output);
        return allocator.dupe(u8, "");
    }
    return ran.output;
}

/// One compile step's answer: every file compiled, the toolchain is missing
/// (or the run was interrupted), or the first rejection's RUN LOG text.
const BatchOutcome = union(enum) { ok, unavailable, failed: []u8 };

/// Compile `basenames` (in order) in `tmp_dir` with ONE `erlc` call: the VM
/// starts once for the whole fixture instead of once per module. `erlc` keeps
/// going past a rejected file and prints every file's diagnostics, but a RUN
/// LOG records only the first rejected file's, as the one-call-per-module
/// loop did — so a rejected batch is compiled again one file at a time and
/// the failure text is that loop's, byte for byte. Rejections are the rare
/// path; the batch is the common one.
fn compileModules(allocator: std.mem.Allocator, io: anytype, tmp_dir: []const u8, flags: []const []const u8, tool: []const u8, basenames: []const []const u8) !BatchOutcome {
    if (basenames.len == 0) return .ok;
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.append(allocator, "erlc");
    try argv.appendSlice(allocator, flags);
    try argv.appendSlice(allocator, &.{ "-o", "." });
    try argv.appendSlice(allocator, basenames);
    const batch = try runCaptured(allocator, io, argv.items, tmp_dir, RUNTIME_TIMEOUT_NS);
    defer allocator.free(batch.output);
    switch (batch.status) {
        .ok => return .ok,
        .unavailable, .interrupted => return .unavailable,
        .failed => {},
    }
    if (basenames.len == 1) return .{ .failed = try compileFailureLog(allocator, tool, batch.output) };
    for (basenames) |base| {
        argv.shrinkRetainingCapacity(1 + flags.len + 2);
        try argv.append(allocator, base);
        const one = try runCaptured(allocator, io, argv.items, tmp_dir, RUNTIME_TIMEOUT_NS);
        defer allocator.free(one.output);
        switch (one.status) {
            .ok => {},
            .unavailable, .interrupted => return .unavailable,
            .failed => return .{ .failed = try compileFailureLog(allocator, tool, one.output) },
        }
    }
    // The batch failed but every file passes alone: report it as the batch
    // saw it rather than run the program on a half-built scratch dir.
    return .{ .failed = try compileFailureLog(allocator, tool, batch.output) };
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

    const entry_module = try erlModuleAtom(allocator, module_name);
    defer allocator.free(entry_module);
    // Every module of the program writes one scratch file named by its atom.
    // A second module rendering the same atom is a harness error, not an
    // overwrite: `seen` maps an atom to the module path that claimed it.
    var seen = std.StringHashMap([]const u8).init(allocator);
    defer seen.deinit();
    try seen.put(entry_module, module_name);
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

    // Write every sibling module the entry calls into, then compile the whole
    // program with one `erlc` call (`compileModules`). `erlc` exits 0 for a
    // warning-only compilation and prints the warnings on stderr, so only the
    // exit status decides: warnings are dropped and the module still runs; a
    // rejection becomes the RUN LOG. A duplicate atom is refused after the
    // modules before it compiled, so a rejection of those still comes first.
    // `seen` keys on the atom slices it is handed, so every aux atom has to
    // outlive the loop: freed per iteration, the key of the first claim was
    // dangling by the time the second claim was compared against it, and the
    // refusal below read freed memory instead of firing.
    var aux_atoms: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (aux_atoms.items) |m| allocator.free(m);
        aux_atoms.deinit(allocator);
    }
    var basenames: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (basenames.items) |n| allocator.free(n);
        basenames.deinit(allocator);
    }
    try basenames.append(allocator, try allocator.dupe(u8, entry_basename));
    var duplicate: ?[]u8 = null;
    defer if (duplicate) |d| allocator.free(d);
    for (aux) |a| {
        const aux_module = try auxAtom(allocator, a);
        try aux_atoms.append(allocator, aux_module);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        if (seen.get(aux_module)) |first| {
            duplicate = try duplicateAtomLog(allocator, aux_module, first, a.name);
            break;
        }
        try seen.put(aux_module, a.name);
        const aux_basename = try std.fmt.allocPrint(allocator, "{s}.erl", .{aux_module});
        try basenames.append(allocator, aux_basename);
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, aux_basename });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
    }
    switch (try compileModules(allocator, io, tmp_dir, &.{}, "erlc", basenames.items)) {
        .ok => {},
        .unavailable => return allocator.dupe(u8, ""),
        .failed => |log| {
            cacheWrite(io, allocator, &key, log);
            return log;
        },
    }
    if (duplicate) |d| {
        const log = try allocator.dupe(u8, d);
        cacheWrite(io, allocator, &key, log);
        return log;
    }

    // A crashing program (non-zero exit) records an empty RUN LOG: the
    // partial stdout it managed to write comes with an Erlang stack trace
    // that is not worth pinning in a snapshot.
    const ran = try runCaptured(allocator, io, &([_][]const u8{"erl"} ++ otp.QUIET_FLAGS ++ [_][]const u8{ "-noinput", "-pa", ".", "-s", entry_module, "_botopink_main", "-s", "init", "stop" }), tmp_dir, RUNTIME_TIMEOUT_NS);
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

    const entry_module = try erlModuleAtom(allocator, module_name);
    defer allocator.free(entry_module);
    // As in `executeErlang`: one scratch file per atom, and a second claim is
    // a harness error rather than a silent overwrite.
    var seen = std.StringHashMap([]const u8).init(allocator);
    defer seen.deinit();
    try seen.put(entry_module, module_name);
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
    // Sibling modules the entry calls into (cross-module `call_ext`) are
    // written first and assembled with the entry in one `erlc` call
    // (`compileModules`); a duplicate atom is refused after the modules
    // before it assembled, as in `executeErlang`, whose note on `aux_atoms`
    // applies here too.
    var aux_atoms: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (aux_atoms.items) |m| allocator.free(m);
        aux_atoms.deinit(allocator);
    }
    var basenames: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (basenames.items) |n| allocator.free(n);
        basenames.deinit(allocator);
    }
    try basenames.append(allocator, try allocator.dupe(u8, asm_basename));
    var duplicate: ?[]u8 = null;
    defer if (duplicate) |d| allocator.free(d);
    for (aux) |a| {
        const aux_module = try auxAtom(allocator, a);
        try aux_atoms.append(allocator, aux_module);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        if (seen.get(aux_module)) |first| {
            duplicate = try duplicateAtomLog(allocator, aux_module, first, a.name);
            break;
        }
        try seen.put(aux_module, a.name);
        const aux_basename = try std.fmt.allocPrint(allocator, "{s}.S", .{aux_module});
        try basenames.append(allocator, aux_basename);
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, aux_basename });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
    }
    switch (try compileModules(allocator, io, tmp_dir, &.{"+from_asm"}, "erlc +from_asm", basenames.items)) {
        .ok => {},
        .unavailable => return allocator.dupe(u8, ""),
        .failed => |log| {
            cacheWrite(io, allocator, &key, log);
            return log;
        },
    }
    if (duplicate) |d| {
        const log = try allocator.dupe(u8, d);
        cacheWrite(io, allocator, &key, log);
        return log;
    }

    const ran = try runCaptured(allocator, io, &([_][]const u8{"erl"} ++ otp.QUIET_FLAGS ++ [_][]const u8{ "-noinput", "-pa", ".", "-s", entry_module, "_botopink_main", "-s", "init", "stop" }), tmp_dir, RUNTIME_TIMEOUT_NS);
    if (ran.status != .ok) {
        allocator.free(ran.output);
        const empty = try allocator.dupe(u8, "");
        if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
        return empty;
    }
    cacheWrite(io, allocator, &key, ran.output);
    return ran.output;
}

/// The backends `executeAborting` runs.
pub const AbortBackend = enum { commonJS, erlang, beam };

/// Run a one-module program that aborts the way `botopink run` runs it — node
/// on the file; `erl` with `otp.guardedEval` around the entry — and return
/// what it wrote, stdout then stderr. Null when it did not abort (exit 0), the
/// module did not compile, or the tool is missing. For the tests that claim
/// what an abort names (an `@panic`'s message on stderr, decision 430, 144
/// B-41), which the RUN LOG cannot: a crashing run records an empty one.
/// Nothing is cached.
pub fn executeAborting(allocator: std.mem.Allocator, backend: AbortBackend, code: []const u8, module_name: []const u8, io: anytype) !?[]u8 {
    var dir_buf: [96]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const atom = try erlModuleAtom(allocator, module_name);
    defer allocator.free(atom);
    const ext = switch (backend) {
        .commonJS => "js",
        .erlang => "erl",
        .beam => "S",
    };
    const basename = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ atom, ext });
    defer allocator.free(basename);
    const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ tmp_dir, basename });
    defer allocator.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = code });

    if (backend != .commonJS) {
        const erlc: []const []const u8 = if (backend == .beam)
            &.{ "erlc", "+from_asm", "-o", ".", basename }
        else
            &.{ "erlc", "-o", ".", basename };
        const compiled = try runCaptured(allocator, io, erlc, tmp_dir, RUNTIME_TIMEOUT_NS);
        allocator.free(compiled.output);
        if (compiled.status != .ok) return null;
    }

    var arena_inst = std.heap.ArenaAllocator.init(allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const argv: []const []const u8 = switch (backend) {
        .commonJS => &.{ "node", basename },
        .erlang, .beam => &([_][]const u8{"erl"} ++ otp.QUIET_FLAGS ++ [_][]const u8{
            "-noshell",
            "-pa",
            ".",
            "-eval",
            try otp.guardedEval(arena, try std.fmt.allocPrint(arena, "'{s}':'_botopink_main'()", .{atom})),
        }),
    };
    const ran = try runCaptured(allocator, io, argv, tmp_dir, RUNTIME_TIMEOUT_NS);
    if (ran.status != .failed) {
        allocator.free(ran.output);
        return null;
    }
    return ran.output;
}

/// Execute a wasm module in process (`wat/runner.zig`, decisions 1032, 1034):
/// the core module (WASI preview 1) is compiled through the `.cwasm` cache
/// and its `_start` called — the export the wasm backend emits for a module
/// with `fn main` (a module without one instantiates and ends, status 0).
///
/// Returns the module's output (stdout, then stderr) on a 0 exit, and on a
/// trap or another exit what it printed followed by `RUNTIME TRAP
/// (wasmtime):` and the trap's line (`runtimeTrapLog`). A run that hit the
/// time limit (`RUNTIME_TIMEOUT_NS`, the runner's epoch deadline) is not a
/// trap: an empty RUN LOG, never cached. There is no early bail on modules
/// that print nothing — a module that prints nothing can still trap, and that
/// is what the log must show. A module importing the runtime core runs with
/// the core and the std units it reaches defined first (`runner.runCoreWith`).
///
/// `wasm_binary`, when given, is the same module in the binary format
/// (`wat/wasm_binary_emitter.zig`), and it is what runs: every wasm RUN LOG is
/// then the binary emitter's answer, checked against the fixture the text
/// recorded. The text runs only where no binary was produced.
pub fn executeWat(allocator: std.mem.Allocator, wat_code: []const u8, wasm_binary: ?[]const u8, module_name: []const u8, io: anytype) ![]u8 {
    return executeWatIn(allocator, wat_code, wasm_binary, module_name, null, io);
}

/// Decisions 1021 (2), 1026 (3) — the units a wasm module binary imports, in
/// the order they are defined before it: the runtime core, then the std units it reaches in dependency order; none
/// for a module that imports no runtime. Allocated in `arena`.
pub fn wasmPreloads(arena: std.mem.Allocator, binary: []const u8) ![]const AuxFile {
    if (!runtimeUnit.importsRuntime(binary)) return &.{};
    var preload: std.ArrayListUnmanaged(AuxFile) = .empty;
    const r = try runtimeUnit.get();
    const im = try runtimeUnit.importsOf(arena, binary);
    // The core's bytes are fixed (decision 1032): the module grows the
    // memory past its own data.
    try preload.append(arena, .{ .name = runtimeUnit.name, .code = r.core_bytes });
    for (try r.closure(arena, im.units)) |u| try preload.append(arena, .{ .name = u.name, .code = u.bytes });
    return preload.items;
}

/// Give back a preloaded unit `executeWatIn` loaded (`runner.load` answers a
/// handle of its own).
fn runtimeUnitRelease(u: @import("./wat/runner.zig").Unit) void {
    @import("./wat/engine.zig").c.wasmtime_module_delete(u.module);
}

/// `executeWat` with the compiled-code cache at `cache_dir`
/// (`<cache root>/.botopinkbuild/cache/wasmtime`); null, `wasmNeeds.DEFAULT_CACHE_DIR`
/// of the working directory. Decision 1008 (5): no cache outside `.botopinkbuild`.
pub fn executeWatIn(allocator: std.mem.Allocator, wat_code: []const u8, wasm_binary: ?[]const u8, module_name: []const u8, cache_dir: ?[]const u8, io: anytype) ![]u8 {
    if (comptime @import("builtin").cpu.arch.isWasm()) return allocator.dupe(u8, "");
    const runner = @import("./wat/runner.zig");
    const code = wasm_binary orelse wat_code;
    // Decisions 1021 (2), 1026 (3) — a module importing the runtime core runs
    // with the core instantiated first, then the std units it reaches in
    // dependency order (what `wasmtime run --preload std@__rt=… --preload
    // std@string=… …` did), each defined under its name in the linker.
    var units_arena = std.heap.ArenaAllocator.init(allocator);
    defer units_arena.deinit();
    const uar = units_arena.allocator();
    const preload: []const AuxFile = if (wasm_binary) |b| try wasmPreloads(uar, b) else &.{};
    // The tag names the runner too: an entry the `wasmtime` CLI recorded is
    // not taken for the in-process runner's answer.
    var key: [64]u8 = undefined;
    cacheKey(&key, if (wasm_binary != null) "wasm-inproc" else "wat-inproc", module_name, code, preload);
    if (cacheRead(allocator, io, &key)) |hit| return hit;

    var failure: ?[]u8 = null;
    const compiled = (try runner.load(allocator, io, cache_dir orelse wasmNeeds.DEFAULT_CACHE_DIR, code, .module, false, &failure)) orelse {
        defer allocator.free(failure.?);
        const log = try runtimeTrapLog(allocator, "wasmtime", "", runner.trapLine(failure.?));
        cacheWrite(io, allocator, &key, log);
        return log;
    };
    defer compiled.deinit();

    // Decision 518 — the host is handed only the services the module's
    // `botopink.needs` section names. Decision 992 — a program that reaches
    // the file system has the root, its scratch directory as its working
    // directory (under its own absolute path), and the host's `TMPDIR`.
    var needs = if (wasm_binary) |b| wasmNeeds.needsOf(b) else wasmNeeds.needsOfText(wat_code);
    // The runtime's needs too (decision 1021 (2)): the program is all of it.
    for (preload) |u| needs.setUnion(wasmNeeds.needsOf(u.code));
    const units = try uar.alloc(runner.Unit, preload.len);
    var loaded_units: usize = 0;
    defer for (units[0..loaded_units]) |u| runtimeUnitRelease(u);
    for (preload, 0..) |u, i| {
        const m = (try runner.load(allocator, io, cache_dir orelse wasmNeeds.DEFAULT_CACHE_DIR, u.code, .module, false, &failure)) orelse {
            defer allocator.free(failure.?);
            const log = try runtimeTrapLog(allocator, "wasmtime", "", runner.trapLine(failure.?));
            cacheWrite(io, allocator, &key, log);
            return log;
        };
        units[i] = .{ .name = u.name, .module = m.module };
        loaded_units += 1;
    }
    var dir_buf: [96]u8 = undefined;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    var scratch: ?[]const u8 = null;
    defer if (scratch) |d| std.Io.Dir.cwd().deleteTree(io, d) catch {};
    var cwd: ?[]const u8 = null;
    var env_buf: [1]runner.EnvVar = undefined;
    var env: runner.Env = .none;
    if (needs.contains(.filesystem)) {
        scratch = try makeScratchDir(io, &dir_buf);
        if (std.Io.Dir.cwd().realPathFile(io, scratch.?, &cwd_buf)) |n| cwd = cwd_buf[0..n] else |_| {}
        if (std.c.getenv("TMPDIR")) |t| {
            env_buf[0] = .{ .name = "TMPDIR", .value = std.mem.span(t) };
            env = .{ .list = env_buf[0..1] };
        }
    }

    const ran = try runner.runCoreWith(allocator, compiled.module, units, .{
        .stdout = .capture,
        .stderr = .capture,
        .argv = &.{crossModule.moduleBasename(if (module_name.len > 0) module_name else "main")},
        .env = env,
        .needs = needs,
        .cwd = cwd,
        .timeout_ns = @intCast(RUNTIME_TIMEOUT_NS),
    });
    defer ran.deinit(allocator);
    // A run that did not end by its own exit is not a trap: nothing to
    // record, nothing to cache.
    if (ran.end != .exited) return allocator.dupe(u8, "");
    const combined = try std.mem.concat(allocator, u8, &.{ ran.stdout.?, ran.stderr.? });
    if (ran.status == 0) {
        cacheWrite(io, allocator, &key, combined);
        return combined;
    }
    defer allocator.free(combined);
    const log = try runtimeTrapLog(allocator, "wasmtime", combined, ran.trap orelse "");
    cacheWrite(io, allocator, &key, log);
    return log;
}

test "runtimeTrapLog keeps the printed text and the trap" {
    const alloc = std.testing.allocator;
    const log = try runtimeTrapLog(alloc, "wasmtime", "hello\n", "wasm trap: wasm `unreachable` instruction executed");
    defer alloc.free(log);
    try std.testing.expectEqualStrings(
        "hello\nRUNTIME TRAP (wasmtime):\nwasm trap: wasm `unreachable` instruction executed\n",
        log,
    );
}

test "runtimeTrapLog on a module that printed nothing" {
    const alloc = std.testing.allocator;
    const log = try runtimeTrapLog(alloc, "wasmtime", "", "wasm trap: out of bounds memory access");
    defer alloc.free(log);
    try std.testing.expectEqualStrings(
        "RUNTIME TRAP (wasmtime):\nwasm trap: out of bounds memory access\n",
        log,
    );
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

// 13-module-identity, half 1 step 3: the scratch filename IS the module atom,
// so two aux modules rendering one atom used to be one file — the second
// silently overwrote the first and the program ran against whichever won.
// `my__mod/user` and `my_mod/user` both render `test@my_mod@user` (A2 § 4 collapses
// a run of `_`, so `__` stays free for the qualifier), which is the one
// collision `crossModule.build` diagnoses and the harness must refuse too.
const duplicate_aux_erl = [_]AuxFile{
    .{ .name = "my__mod/user", .code = "-module(test@my_mod@user).\n-export([who/0]).\nwho() -> first.\n" },
    .{ .name = "my_mod/user", .code = "-module(test@my_mod@user).\n-export([who/0]).\nwho() -> second.\n" },
};

// The same pair as BEAM assembly: the first aux is assembled before the
// second is compared, so it has to be a module `erlc +from_asm` accepts.
const duplicate_aux_asm = [_]AuxFile{
    .{ .name = "my__mod/user", .code = duplicateAuxAsm("first") },
    .{ .name = "my_mod/user", .code = duplicateAuxAsm("second") },
};

fn duplicateAuxAsm(comptime answer: []const u8) []const u8 {
    return "{module, test@my_mod@user}.\n" ++
        "{exports, [{who, 0}]}.\n" ++
        "{attributes, []}.\n" ++
        "{labels, 3}.\n\n" ++
        "{function, who, 0, 2}.\n" ++
        "  {label, 1}.\n" ++
        "    {line, []}.\n" ++
        "    {func_info, {atom, test@my_mod@user}, {atom, who}, 0}.\n" ++
        "  {label, 2}.\n" ++
        "    {move, {atom, " ++ answer ++ "}, {x, 0}}.\n" ++
        "    return.\n";
}

fn expectDuplicateAtomRefused(log: []const u8) !void {
    try std.testing.expect(std.mem.startsWith(u8, log, "HARNESS ERROR:"));
    try std.testing.expect(std.mem.indexOf(u8, log, "`my__mod/user`") != null);
    try std.testing.expect(std.mem.indexOf(u8, log, "`my_mod/user`") != null);
    try std.testing.expect(std.mem.indexOf(u8, log, "module atom `test@my_mod@user`") != null);
    // The refusal is the whole log: nothing ran, so nothing printed.
    try std.testing.expect(std.mem.indexOf(u8, log, "hi") == null);
}

test "executeErlang: two aux modules rendering one atom fail loudly instead of overwriting" {
    const alloc = std.testing.allocator;
    const entry =
        \\-module(test@main).
        \\-export(['_botopink_main'/0]).
        \\'_botopink_main'() -> io:format("hi~n", []).
        \\
    ;
    const log = try executeErlang(alloc, entry, "main", &duplicate_aux_erl, std.testing.io);
    defer alloc.free(log);
    // An empty log is the harness's "erlc not on PATH" answer, not a verdict.
    if (log.len == 0) return error.SkipZigTest;
    try expectDuplicateAtomRefused(log);
}

test "executeBeamAsm: two aux modules rendering one atom fail loudly instead of overwriting" {
    const alloc = std.testing.allocator;
    const entry =
        \\{module, test@main}.
        \\{exports, [{'_botopink_main', 0}]}.
        \\{attributes, []}.
        \\{labels, 3}.
        \\
        \\{function, '_botopink_main', 0, 2}.
        \\  {label, 1}.
        \\    {line, []}.
        \\    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
        \\  {label, 2}.
        \\    {move, {literal, <<"hi~n">>}, {x, 0}}.
        \\    {move, nil, {x, 1}}.
        \\    {call_ext_only, 2, {extfunc, io, format, 2}}.
        \\
    ;
    const log = try executeBeamAsm(alloc, entry, "main", &duplicate_aux_asm, std.testing.io);
    defer alloc.free(log);
    if (log.len == 0) return error.SkipZigTest;
    try expectDuplicateAtomRefused(log);
}
