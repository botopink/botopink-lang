//! Persistent `node` runner — one long-lived node process per Zig process.
//!
//! Each evaluation spawns `node` cold today (~18ms). For 100+ test calls per
//! `zig build test` run, the spawns dominate the timeline. This module starts
//! `node` ONCE and feeds it length-prefixed scripts via stdin/stdout pipes.
//! Subsequent evals cost ~1–2ms (just pipe IPC + V8 vm context creation).
//!
//! Protocol (client ↔ server):
//!   request:  `<len-hex8>\n<script-bytes>`
//!   response: `<len-hex8>\n<captured-stdout-bytes>`
//!
//! The runner JS (embedded below) reads requests in a loop, evaluates each
//! script inside a fresh `vm.runInNewContext` so global state never leaks
//! between calls, captures everything the script writes to `process.stdout`,
//! and emits the captured bytes as the response. Errors during script eval
//! are serialised as a marker so the caller surfaces them as runtime
//! diagnostics (mirrors today's `Outcome.err` path).
//!
//! Thread-safety: tests run in parallel under Zig 0.16. A coarse atomic
//! spin-lock around the send/receive pair serialises pipe access; the actual
//! V8 eval inside node remains single-threaded (one script at a time), which
//! matches the existing per-spawn assumption.
//!
//! Lifecycle: the child process is leaked on purpose (process-lifetime, same
//! philosophy as `node.zig`'s `script_memo_arena`). When the parent exits,
//! the child's stdin EOFs and it exits cleanly.

const std = @import("std");

const Io = std.Io;
const Child = std.process.Child;
const File = std.Io.File;

/// JS runner. Read length-prefixed scripts from stdin, eval each in a fresh
/// vm context (so `const x = …` declarations don't leak), capture
/// `process.stdout.write`/`console.log` output, emit length-prefixed.
const runner_js =
    \\"use strict";
    \\const vm = require("vm");
    \\let buf = Buffer.alloc(0);
    \\function readLen() {
    \\    if (buf.length < 9) return -1;
    \\    const s = buf.slice(0, 8).toString("utf8");
    \\    const n = parseInt(s, 16);
    \\    if (Number.isNaN(n)) process.exit(2);
    \\    return n;
    \\}
    \\function runOne(script) {
    \\    let captured = "";
    \\    const fakeStdout = {
    \\        write(c) { captured += typeof c === "string" ? c : Buffer.from(c).toString("utf8"); return true; },
    \\    };
    \\    const fakeConsole = {
    \\        log(...a) { captured += a.map(x => typeof x === "string" ? x : String(x)).join(" ") + "\n"; },
    \\        error(...a) { captured += a.map(x => typeof x === "string" ? x : String(x)).join(" ") + "\n"; },
    \\        warn(...a) { captured += a.map(x => typeof x === "string" ? x : String(x)).join(" ") + "\n"; },
    \\    };
    \\    const fakeProcess = new Proxy(process, {
    \\        get(t, k) {
    \\            if (k === "stdout") return fakeStdout;
    \\            return t[k];
    \\        },
    \\    });
    \\    const moduleExports = {};
    \\    const moduleObj = { exports: moduleExports };
    \\    const ctx = vm.createContext({
    \\        require, console: fakeConsole, process: fakeProcess,
    \\        Buffer, setTimeout, clearTimeout, setImmediate, clearImmediate,
    \\        module: moduleObj, exports: moduleExports,
    \\        __filename: "bp.js", __dirname: ".",
    \\    });
    \\    try {
    \\        vm.runInContext(script, ctx, { filename: "bp.js" });
    \\    } catch (e) {
    \\        captured = "__BP_RUNNER_ERROR__:" + (e && (e.stack || e.message) || String(e));
    \\    }
    \\    return Buffer.from(captured, "utf8");
    \\}
    \\function emit(outBuf) {
    \\    const lenHex = outBuf.length.toString(16).padStart(8, "0") + "\n";
    \\    process.stdout.write(lenHex);
    \\    process.stdout.write(outBuf);
    \\}
    \\process.stdin.on("data", (chunk) => {
    \\    buf = Buffer.concat([buf, chunk]);
    \\    while (true) {
    \\        const n = readLen();
    \\        if (n < 0 || buf.length < 9 + n) break;
    \\        const script = buf.slice(9, 9 + n).toString("utf8");
    \\        buf = buf.slice(9 + n);
    \\        emit(runOne(script));
    \\    }
    \\});
    \\process.stdin.on("end", () => process.exit(0));
;

// ── singleton state ───────────────────────────────────────────────────────────

const State = struct {
    child: Child,
    stdin: File,
    stdout: File,
};

var state: State = undefined;
var init_state: std.atomic.Value(u8) = .init(0); // 0=uninit, 1=initing, 2=ready, 3=broken
var io_mu: std.atomic.Value(u8) = .init(0);

fn lock() void {
    while (io_mu.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| {
        std.atomic.spinLoopHint();
    }
}
fn unlock() void {
    io_mu.store(0, .release);
}

fn ensureSpawned(io: Io) !void {
    while (true) {
        const s = init_state.load(.acquire);
        if (s == 2) return;
        if (s == 3) return error.PersistentNodeBroken;
        if (s == 0) {
            if (init_state.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            errdefer init_state.store(3, .release);
            const child = try std.process.spawn(io, .{
                .argv = &.{ "node", "-e", runner_js },
                .stdin = .pipe,
                .stdout = .pipe,
                .stderr = .inherit,
            });
            state = .{
                .child = child,
                .stdin = child.stdin orelse return error.NoStdin,
                .stdout = child.stdout orelse return error.NoStdout,
            };
            init_state.store(2, .release);
            return;
        }
        std.atomic.spinLoopHint();
    }
}

/// Read exactly `out.len` bytes from the persistent node's stdout pipe.
/// Pipes can short-read; loop until full.
fn readExact(io: Io, out: []u8) !void {
    var filled: usize = 0;
    while (filled < out.len) {
        const n = state.stdout.readStreaming(io, &.{out[filled..]}) catch |err| switch (err) {
            error.EndOfStream => return error.PersistentNodeEof,
            else => return err,
        };
        if (n == 0) return error.PersistentNodeEof;
        filled += n;
    }
}

/// Evaluate `script` in the persistent node process and return its captured
/// `process.stdout` output. The returned slice is allocated from `allocator`
/// and owned by the caller. On the first call, lazy-spawns the runner.
pub fn eval(allocator: std.mem.Allocator, io: Io, script: []const u8) ![]u8 {
    try ensureSpawned(io);
    lock();
    defer unlock();

    // Send: 8 hex chars (length) + '\n' + script bytes.
    var hdr_buf: [9]u8 = undefined;
    _ = std.fmt.bufPrint(&hdr_buf, "{x:0>8}\n", .{script.len}) catch unreachable;
    try state.stdin.writeStreamingAll(io, &hdr_buf);
    try state.stdin.writeStreamingAll(io, script);

    // Receive: 9-byte header, then `len` bytes of output.
    var resp_hdr: [9]u8 = undefined;
    try readExact(io, &resp_hdr);
    if (resp_hdr[8] != '\n') return error.PersistentNodeBadFrame;
    const len = std.fmt.parseInt(usize, resp_hdr[0..8], 16) catch return error.PersistentNodeBadFrame;
    const out = try allocator.alloc(u8, len);
    errdefer allocator.free(out);
    try readExact(io, out);
    return out;
}

/// True after `eval` has spawned its child. Used by callers that want a
/// "fast-path only when warm" heuristic (we never reach this state today).
pub fn isReady() bool {
    return init_state.load(.acquire) == 2;
}
