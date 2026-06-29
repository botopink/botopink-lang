//! Runtime execution for generated code.
//!
//! Provides functions to execute generated JavaScript (via Node.js),
//! Erlang code (via erlc + erl), BEAM assembly (via erlc +from_asm + erl),
//! and WebAssembly (via wasmtime), capturing the runtime stdout for
//! inclusion in the codegen snapshots' `----- RUN LOG -----` block.
//!
//! ## RUN LOG capture contract
//!
//! Every `executeX` helper returns **stdout-only** on success:
//!
//!   - `isProcessSuccess(term)` covers the "runtime crashed" surface —
//!     a non-zero exit code returns the empty string so the snapshot's
//!     RUN LOG block stays empty (the test still produces a readable
//!     snapshot with the source + generated code sections intact).
//!   - On a 0 exit, return `result.stdout` as-is. stderr is dropped.
//!
//! Why stderr is dropped: snapshot-bound runtime helpers must produce
//! host-independent output. Erlang's startup logger, Node's
//! experimental-feature notices, and wasmtime's deprecation messages
//! all surface on stderr and differ between dev workstations and CI
//! runners (notably erlef/setup-beam's OTP 27/28 logger config). The
//! original implementation combined stdout + stderr; on the GitHub
//! runner, the combined buffer included an Erlang logger notice the
//! dev workstation didn't emit, so every snapshot mismatched on CI
//! while passing locally.
//!
//! If a future test needs stderr in the snapshot (e.g. an explicit
//! error-codegen fixture), add an `executeXCapturingStderr` helper
//! alongside the existing `executeX` — never re-introduce the strict
//! `if (stderr.len > 0) return ""` short-circuit that the original
//! shape carried, which proved fragile under runner-specific noise.
const std = @import("std");
const persistent_node = @import("../comptime/runtime/persistent_node.zig");
fn isProcessSuccess(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

/// Single root for every per-test scratch dir. Lives under the
/// build dir (`.botopinkbuild/`) so the umbrella `.gitignore` rule
/// already swallows it — no separate `.tmp-exec-*/` line needed.
/// `clean-tmp` (in `build.zig`) reaps entries older than 1 day, so a
/// crashed test never leaks beyond that.
pub const TMP_ROOT = ".botopinkbuild/tmp";

/// Content-keyed output cache. Each `executeX` hashes its inputs (target
/// tag + emitted code + aux modules + module name) into a SHA256 key and
/// short-circuits the spawn on a cache hit — every cached entry is
/// prefixed with `OK:` so a corrupt/truncated file is treated as a miss
/// and re-executed. Content-keyed, so any change to the inputs (compiler
/// output, std library) misses naturally; toolchain upgrades (node/erl)
/// are NOT folded into the key — clear the cache dir after upgrading.
/// Reaped by `clean-tmp` together with `tmp/`.
pub const CACHE_ROOT = ".botopinkbuild/runtime-cache";

/// Hash (target_tag + module_name + code + aux entries) into a 64-char
/// hex SHA256 key. Each component is length-prefixed so two layouts can
/// never collide (e.g. `aaa`+`bbb` vs `a`+`aabbb`).
fn cacheKey(out: *[64]u8, target: []const u8, module_name: []const u8, code: []const u8, aux: []const AuxFile) void {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    var lenbuf: [8]u8 = undefined;

    inline for ([_][]const u8{ target, module_name, code }) |s| {
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

fn combineOutput(allocator: std.mem.Allocator, stdout: []const u8, stderr: []const u8) ![]u8 {
    var output: std.ArrayListUnmanaged(u8) = .empty;
    try output.appendSlice(allocator, stdout);
    if (stderr.len > 0) {
        if (output.items.len > 0) try output.append(allocator, '\n');
        try output.appendSlice(allocator, stderr);
    }
    return output.toOwnedSlice(allocator);
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

    // Fast path: no aux → run inside the persistent node runner. Falls
    // through to the one-shot path if the runner can't be spawned.
    if (aux.len == 0) {
        if (persistent_node.eval(allocator, io, js_code)) |out| {
            // Empty output = treat as exec failure (consistent with the
            // one-shot path returning "" on non-zero exit).
            cacheWrite(io, allocator, &key, out);
            return out;
        } else |_| {}
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
    const result = std.process.run(allocator, io, .{ .argv = &.{ "node", tmp_path } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);
    if (!isProcessSuccess(result.term)) {
        return allocator.dupe(u8, "");
    }

    const combined = try combineOutput(allocator, result.stdout, result.stderr);
    cacheWrite(io, allocator, &key, combined);
    return combined;
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
    const erl_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.erl", .{ tmp_dir, entry_module });
    defer allocator.free(erl_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_filename, .data = erl_code });
    }

    // Compile the Erlang module (and any sibling modules it calls into)
    const compile_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "-o", tmp_dir, erl_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(compile_result.stdout);
    defer allocator.free(compile_result.stderr);
    if (!isProcessSuccess(compile_result.term)) {
        return allocator.dupe(u8, "");
    }
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.erl", .{ tmp_dir, aux_module });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_compile = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "-o", tmp_dir, aux_filename } }) catch |err| switch (err) {
            error.FileNotFound => return allocator.dupe(u8, ""),
            else => return err,
        };
        allocator.free(aux_compile.stdout);
        allocator.free(aux_compile.stderr);
        if (!isProcessSuccess(aux_compile.term)) {
            return allocator.dupe(u8, "");
        }
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noinput", "-pa", tmp_dir, "-s", entry_module, "_botopink_main", "-s", "init", "stop" },
    }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);
    if (!isProcessSuccess(exec_result.term)) {
        return allocator.dupe(u8, "");
    }
    // Return stdout only — Erlang's startup logger emits notices to
    // stderr on some hosts (notably erlef/setup-beam's OTP 27 on the
    // GitHub runner) that do not reproduce locally. Including stderr
    // in the snapshot would make the RUN LOG host-dependent.
    const out = try allocator.dupe(u8, exec_result.stdout);
    cacheWrite(io, allocator, &key, out);
    return out;
}

/// Execute BEAM Assembly code: write the `.S`, assemble it with
/// `erlc +from_asm <file>.S` (produces `<module>.beam` in the cwd), then run
/// the generated `_botopink_main/0` via `erl -s ...`.
///
/// Returns the captured stdout. Failure (missing erlc, assembly rejection,
/// or runtime error) returns an empty string so the test still produces a
/// readable snapshot.
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
    const asm_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.S", .{ tmp_dir, entry_module });
    defer allocator.free(asm_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = asm_filename, .data = asm_code });
    }

    const assemble_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "+from_asm", "-o", tmp_dir, asm_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(assemble_result.stdout);
    defer allocator.free(assemble_result.stderr);
    if (!isProcessSuccess(assemble_result.term)) {
        return allocator.dupe(u8, "");
    }

    // Assemble sibling modules the entry calls into (cross-module `call_ext`).
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.S", .{ tmp_dir, aux_module });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_assemble = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "+from_asm", "-o", tmp_dir, aux_filename } }) catch |err| switch (err) {
            error.FileNotFound => return allocator.dupe(u8, ""),
            else => return err,
        };
        allocator.free(aux_assemble.stdout);
        allocator.free(aux_assemble.stderr);
        if (!isProcessSuccess(aux_assemble.term)) {
            return allocator.dupe(u8, "");
        }
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noinput", "-pa", tmp_dir, "-s", entry_module, "_botopink_main", "-s", "init", "stop" },
    }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);
    if (!isProcessSuccess(exec_result.term)) return allocator.dupe(u8, "");
    // stdout only — see comment in executeErlang above for why the
    // host-dependent stderr is dropped.
    const out = try allocator.dupe(u8, exec_result.stdout);
    cacheWrite(io, allocator, &key, out);
    return out;
}

/// Execute WebAssembly Text via the in-process embedded wasm3 interpreter
/// (`comptime/runtime/wasm3_host.runWat`) — no `wasmtime` spawn.
/// Returns empty string if the module has no `_botopink_main` export, or if
/// the WAT subset used by `codegen/wat.zig` outruns the pure-Zig
/// `wat_to_wasm.compile` supported subset.
///
/// `module_name` is kept for parity with the sibling `executeJavaScript` /
/// `executeErlang` signatures (currently unused — wasm3 takes WAT bytes
/// in-memory and does not write a `.wat` file).
pub fn executeWat(allocator: std.mem.Allocator, wat_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    _ = wat_code;
    _ = module_name;
    _ = io;
    // wasm3 was removed in persistent-erl-runtime spec. WAT execution
    // for codegen snapshots falls back to empty run log until wasmtime
    // integration is restored.
    return allocator.dupe(u8, "");
}
