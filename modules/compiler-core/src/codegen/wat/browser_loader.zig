//! Decision 334 — the `browser` host's loader: the small ES module a wasm
//! build for `"wasm": { "host": "browser" }` writes beside its `.wasm`.
//!
//! The module keeps importing what the backend emits (`wasi_snapshot_preview1`'s
//! `fd_write` and `random_get`, the two `wat_emitter.preview1_adapted` names);
//! here they are JavaScript over what a browser offers — `fd_write` on the
//! console (line by line, `console.log` for fd 1 and `console.error` for fd 2;
//! under node, `fs.writeSync` on the same fd, so the bytes and their order are
//! the program's), `random_get` on `crypto.getRandomValues`. The loader
//! instantiates the module, then calls the start the backend exported for the
//! host (`wat_ast.host_init_export`, `wat_ast.startAsExport`) and `_start`. A
//! trap rejects the module's top-level `await`: node prints it and exits 1.
//! Node runs the loader as it is (`botopink run`, `node <name>.mjs`).
//!
//! Decisions 392–394 — the host tasks. A module whose tasks wait on the host
//! imports `bp_host.delay(ms) -> id` (`wat_prelude.zig`): here a `setTimeout`
//! re-armed until `performance.now()` has passed the deadline (a timer may
//! fire early by the loop's cached time), whose firing queues the id. After
//! `_start` the loader drives the module from the event loop — no JSPI: while
//! a host task is pending it waits for the next answer and hands it to the
//! module's `__bp_ready(id)`, which settles the task and runs the ready ones,
//! the same state machines `wasi`'s poll resumes.

const std = @import("std");

/// The loader of `<wasm_basename>` (the `.wasm` file beside it), caller-owned.
pub fn render(alloc: std.mem.Allocator, wasm_basename: []const u8) ![]u8 {
    return std.mem.concat(alloc, u8, &.{ head, "const url = new URL(\"./", wasm_basename, "\", import.meta.url);\n", body });
}

const head =
    \\// The `browser` host's loader (botopink, decision 334): instantiates the
    \\// module beside it with the imports a browser offers and runs it. Node runs
    \\// it too: `node <name>.mjs`.
    \\
;

const body =
    \\const node = typeof process === "object" && process.versions != null && process.versions.node != null;
    \\const fs = node ? await import("node:fs") : null;
    \\const bytes = node ? fs.readFileSync(url) : await (await fetch(url)).arrayBuffer();
    \\let memory = null;
    \\const decoders = [null, new TextDecoder(), new TextDecoder()];
    \\const pending = ["", "", ""];
    \\function write(fd, chunk) {
    \\  if (node) {
    \\    let off = 0;
    \\    while (off < chunk.length) off += fs.writeSync(fd, chunk, off);
    \\    return;
    \\  }
    \\  pending[fd] += decoders[fd].decode(chunk, { stream: true });
    \\  let nl;
    \\  while ((nl = pending[fd].indexOf("\n")) >= 0) {
    \\    (fd === 1 ? console.log : console.error)(pending[fd].slice(0, nl));
    \\    pending[fd] = pending[fd].slice(nl + 1);
    \\  }
    \\}
    \\const wasi_snapshot_preview1 = {
    \\  fd_write(fd, iovs, n, written) {
    \\    if (fd !== 1 && fd !== 2) return 8;
    \\    const view = new DataView(memory.buffer);
    \\    let total = 0;
    \\    for (let i = 0; i < n; i++) {
    \\      const ptr = view.getUint32(iovs + 8 * i, true);
    \\      const len = view.getUint32(iovs + 8 * i + 4, true);
    \\      write(fd, new Uint8Array(memory.buffer, ptr, len).slice());
    \\      total += len;
    \\    }
    \\    view.setUint32(written, total, true);
    \\    return 0;
    \\  },
    \\  random_get(buf, len) {
    \\    for (let off = 0; off < len; off += 65536) {
    \\      crypto.getRandomValues(new Uint8Array(memory.buffer, buf + off, Math.min(65536, len - off)));
    \\    }
    \\    return 0;
    \\  },
    \\};
    \\let hostSeq = 0;
    \\let hostPending = 0;
    \\const hostReady = [];
    \\let hostWake = null;
    \\function hostAnswer(id) {
    \\  hostReady.push(id);
    \\  if (hostWake) {
    \\    const w = hostWake;
    \\    hostWake = null;
    \\    w();
    \\  }
    \\}
    \\const bp_host = {
    \\  delay(ms) {
    \\    const id = ++hostSeq;
    \\    hostPending++;
    \\    const end = performance.now() + ms;
    \\    const tick = () => {
    \\      const left = end - performance.now();
    \\      if (left > 0) setTimeout(tick, Math.ceil(left));
    \\      else hostAnswer(id);
    \\    };
    \\    setTimeout(tick, ms);
    \\    return id;
    \\  },
    \\};
    \\const { instance } = await WebAssembly.instantiate(bytes, { wasi_snapshot_preview1, bp_host });
    \\memory = instance.exports.memory;
    \\if (instance.exports.__bp_init) instance.exports.__bp_init();
    \\if (instance.exports._start) instance.exports._start();
    \\while (hostPending > 0) {
    \\  if (hostReady.length === 0) await new Promise((r) => { hostWake = r; });
    \\  hostPending--;
    \\  instance.exports.__bp_ready(hostReady.shift());
    \\}
    \\
;

test "the loader names the module beside it, serves the two preview 1 imports and drives the host tasks" {
    const out = try render(std.testing.allocator, "main.wasm");
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.indexOf(u8, out, "const url = new URL(\"./main.wasm\", import.meta.url);\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "  fd_write(fd, iovs, n, written) {") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "  random_get(buf, len) {") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "if (instance.exports._start) instance.exports._start();\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, out, "  instance.exports.__bp_ready(hostReady.shift());\n}\n"));
}
