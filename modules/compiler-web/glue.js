// glue.js — the JS side of the browser build of compiler-core (front 18 step 5).
//
// Three things, no dependency:
//   1. a WASI preview1 shim: the five calls the compiler makes at run time are
//      served (fd_write to captured stdout/stderr, clock_time_get, clock_res_get,
//      random_get, environ_*, fd_fdstat_get on the three stdio descriptors);
//      every other import `botopink.wasm` declares — the whole `std.Io` vtable,
//      file system included — is bound to a function that THROWS naming the
//      call, so a code path that reaches the file system fails loudly instead
//      of answering ENOSYS into a retry loop (decision 67);
//   2. `Botopink.Compiler`: `load(bytes | url | WebAssembly.Module)`, then
//      `addSource(path, source)`, `compile(target)` → the JSON object
//      `web_root.zig` documents, `reset()`; `stdout`/`stderr` hold what the
//      compiler printed during the last `compile`;
//   3. `run(bytes)`: instantiate a program the `wasm` target produced (the
//      module's `wasm` field, base64 — `wasmBytes` decodes it) and call its
//      `_start`; the program's one import, `fd_write`, is served into
//      captured text, any other import is refused by name. Answers
//      `{ stdout, stderr, trap }` — `trap` is the engine's message or null;
//   4. when loaded as a Worker script (`new Worker("glue.js")`), a message
//      protocol: `{ id, op: "load", wasm }` → `{ id, ok }`, then
//      `{ id, op: "compile", sources: [{ path, source }], target }` →
//      `{ id, ok, status, result, stdout, stderr, ms }`, and
//      `{ id, op: "run", wasm }` (base64) → `{ id, ok, run, ms }`. The page
//      keeps the compiler off the main thread, where synchronous
//      instantiation of the target program's wasm output is not size-limited.
//
// Loaded three ways: `<script src="glue.js">` (defines `self.Botopink`),
// `importScripts` / `new Worker` (the same, plus the protocol), and
// `require("./glue.js")` under node (the smoke test) — `module.exports`.
(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  root.Botopink = api;
  if (typeof WorkerGlobalScope !== "undefined" && root instanceof WorkerGlobalScope) api.serveWorker(root);
})(typeof self !== "undefined" ? self : globalThis, function () {
  "use strict";

  const ERRNO_SUCCESS = 0;
  const ERRNO_BADF = 8;
  const WASI_MODULE = "wasi_snapshot_preview1";

  // ── the WASI shim ──────────────────────────────────────────────────────────

  // `state.memory` is bound after instantiation; views are created per call
  // because `memory.grow` detaches every earlier ArrayBuffer.
  function wasiServed(state) {
    const view = () => new DataView(state.memory.buffer);
    const bytes = () => new Uint8Array(state.memory.buffer);
    const decoder = new TextDecoder();
    return {
      fd_write(fd, iovsPtr, iovsLen, nwrittenPtr) {
        if (fd !== 1 && fd !== 2) return ERRNO_BADF;
        const dv = view();
        const mem = bytes();
        let written = 0;
        let text = "";
        for (let i = 0; i < iovsLen; i++) {
          const ptr = dv.getUint32(iovsPtr + i * 8, true);
          const len = dv.getUint32(iovsPtr + i * 8 + 4, true);
          text += decoder.decode(mem.subarray(ptr, ptr + len));
          written += len;
        }
        if (fd === 1) state.stdout += text;
        else state.stderr += text;
        dv.setUint32(nwrittenPtr, written, true);
        return ERRNO_SUCCESS;
      },
      clock_time_get(id, _precision, timePtr) {
        // 0 = realtime, 1 = monotonic; both in nanoseconds.
        const ns = id === 0
          ? BigInt(Date.now()) * 1000000n
          : BigInt(Math.round(nowMs() * 1e6));
        view().setBigUint64(timePtr, ns, true);
        return ERRNO_SUCCESS;
      },
      clock_res_get(_id, resPtr) {
        view().setBigUint64(resPtr, 1000n, true);
        return ERRNO_SUCCESS;
      },
      random_get(ptr, len) {
        const buf = bytes().subarray(ptr, ptr + len);
        // getRandomValues caps one call at 65 536 bytes.
        for (let i = 0; i < len; i += 65536) randomSource().getRandomValues(buf.subarray(i, Math.min(len, i + 65536)));
        return ERRNO_SUCCESS;
      },
      environ_sizes_get(countPtr, sizePtr) {
        const dv = view();
        dv.setUint32(countPtr, 0, true);
        dv.setUint32(sizePtr, 0, true);
        return ERRNO_SUCCESS;
      },
      environ_get() {
        return ERRNO_SUCCESS;
      },
      fd_fdstat_get(fd, statPtr) {
        if (fd < 0 || fd > 2) return ERRNO_BADF;
        const dv = view();
        dv.setUint8(statPtr, 2); // filetype: character device
        dv.setUint16(statPtr + 2, 0, true); // fdflags
        dv.setBigUint64(statPtr + 8, 0n, true); // rights_base
        dv.setBigUint64(statPtr + 16, 0n, true); // rights_inheriting
        return ERRNO_SUCCESS;
      },
    };
  }

  function nowMs() {
    return typeof performance !== "undefined" ? performance.now() : Number(process.hrtime.bigint()) / 1e6;
  }

  function randomSource() {
    if (typeof crypto !== "undefined" && crypto.getRandomValues) return crypto;
    return require("crypto").webcrypto;
  }

  /// The import object for `module`: every declared import is bound — the
  /// served ones to the shim, the rest to a refusal naming the call.
  function importsFor(module, state) {
    const served = wasiServed(state);
    const imports = {};
    for (const imp of WebAssembly.Module.imports(module)) {
      if (imp.module !== WASI_MODULE || imp.kind !== "function") {
        throw new Error(`botopink.wasm imports ${imp.module}.${imp.name} (${imp.kind}), which the browser build does not serve`);
      }
      imports[WASI_MODULE] = imports[WASI_MODULE] || {};
      imports[WASI_MODULE][imp.name] = served[imp.name] || function refused() {
        throw new Error(`botopink.wasm called WASI ${imp.name}, which the browser build does not serve`);
      };
    }
    return imports;
  }

  // ── the compiler ───────────────────────────────────────────────────────────

  const STATUS = { 0: "ok", 1: "failed", 2: "unknown target", 3: "internal error" };

  class Compiler {
    /// `source` is a `WebAssembly.Module`, bytes (ArrayBuffer / Uint8Array),
    /// or a URL string fetched here.
    static async load(source) {
      let module = source;
      if (typeof source === "string") {
        const response = await fetch(source);
        if (!response.ok) throw new Error(`fetching ${source}: ${response.status}`);
        source = await response.arrayBuffer();
      }
      if (!(module instanceof WebAssembly.Module)) module = await WebAssembly.compile(source);
      const state = { memory: null, stdout: "", stderr: "" };
      const instance = await WebAssembly.instantiate(module, importsFor(module, state));
      state.memory = instance.exports.memory;
      return new Compiler(instance, state);
    }

    constructor(instance, state) {
      this.exports = instance.exports;
      this.state = state;
      this.encoder = new TextEncoder();
      this.decoder = new TextDecoder();
    }

    get stdout() {
      return this.state.stdout;
    }

    get stderr() {
      return this.state.stderr;
    }

    /// Copy `text` into the compiler's memory; the caller frees it.
    writeString(text) {
      const encoded = this.encoder.encode(text);
      const ptr = this.exports.bp_alloc(encoded.length);
      if (ptr === 0 && encoded.length > 0) throw new Error("botopink.wasm is out of memory");
      new Uint8Array(this.state.memory.buffer, ptr, encoded.length).set(encoded);
      return { ptr, len: encoded.length };
    }

    reset() {
      this.exports.bp_reset();
    }

    addSource(path, source) {
      const p = this.writeString(path);
      const s = this.writeString(source);
      try {
        const status = this.exports.bp_add_source(p.ptr, p.len, s.ptr, s.len);
        if (status !== 0) throw new Error("botopink.wasm is out of memory");
      } finally {
        this.exports.bp_free(p.ptr, p.len);
        this.exports.bp_free(s.ptr, s.len);
      }
    }

    /// `target` is one of commonJS, erlang, beam, wasm. Answers the parsed
    /// output JSON with `status` (0 compiled, 1 a module failed) added; throws
    /// on an unknown target or an internal error, with the compiler's stderr.
    compile(target) {
      this.state.stdout = "";
      this.state.stderr = "";
      const t = this.writeString(target);
      let status;
      try {
        status = this.exports.bp_compile(t.ptr, t.len);
      } catch (err) {
        throw new Error(`botopink.wasm trapped while compiling for ${target}: ${err.message}\n${this.state.stderr}`);
      } finally {
        this.exports.bp_free(t.ptr, t.len);
      }
      if (status >= 2) throw new Error(`botopink.wasm: ${STATUS[status] || status} (target ${target})\n${this.state.stderr}`);
      const ptr = this.exports.bp_output_ptr();
      const len = this.exports.bp_output_len();
      const json = this.decoder.decode(new Uint8Array(this.state.memory.buffer, ptr, len));
      const result = JSON.parse(json);
      result.status = status;
      return result;
    }
  }

  // ── running the `wasm` target's output ─────────────────────────────────────

  /// The bytes of a module's `wasm` field (base64).
  function wasmBytes(b64) {
    if (typeof atob === "function") {
      const bin = atob(b64);
      const out = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
      return out;
    }
    return new Uint8Array(Buffer.from(b64, "base64"));
  }

  /// Instantiate a program the `wasm` target produced and run its `_start`.
  /// A program imports `wasi_snapshot_preview1.fd_write` at most; anything
  /// else is refused by name before a byte runs.
  function run(bytes) {
    const module = new WebAssembly.Module(bytes);
    const state = { memory: null, stdout: "", stderr: "" };
    const served = wasiServed(state);
    const imports = {};
    for (const imp of WebAssembly.Module.imports(module)) {
      if (imp.module !== WASI_MODULE || imp.name !== "fd_write") {
        throw new Error(`the program imports ${imp.module}.${imp.name}, which the page does not serve`);
      }
      imports[WASI_MODULE] = { fd_write: served.fd_write };
    }
    let trap = null;
    try {
      const instance = new WebAssembly.Instance(module, imports);
      state.memory = instance.exports.memory;
      if (typeof instance.exports._start === "function") instance.exports._start();
    } catch (err) {
      if (!(err instanceof WebAssembly.RuntimeError)) throw err;
      trap = err.message;
    }
    return { stdout: state.stdout, stderr: state.stderr, trap };
  }

  // ── the Worker protocol ────────────────────────────────────────────────────

  function serveWorker(scope) {
    let compiler = null;
    scope.onmessage = async (event) => {
      const msg = event.data;
      try {
        if (msg.op === "load") {
          compiler = await Compiler.load(msg.wasm);
          scope.postMessage({ id: msg.id, ok: true });
        } else if (msg.op === "compile") {
          if (!compiler) throw new Error("load the compiler first");
          compiler.reset();
          for (const s of msg.sources) compiler.addSource(s.path, s.source);
          const t0 = nowMs();
          const result = compiler.compile(msg.target);
          const ms = nowMs() - t0;
          scope.postMessage({ id: msg.id, ok: true, status: result.status, result, stdout: compiler.stdout, stderr: compiler.stderr, ms });
        } else if (msg.op === "run") {
          const t0 = nowMs();
          const result = run(wasmBytes(msg.wasm));
          scope.postMessage({ id: msg.id, ok: true, run: result, ms: nowMs() - t0 });
        } else {
          throw new Error(`unknown op ${msg.op}`);
        }
      } catch (err) {
        scope.postMessage({ id: msg.id, ok: false, error: err.message, stderr: compiler ? compiler.stderr : "" });
      }
    };
  }

  return { Compiler, importsFor, run, wasmBytes, serveWorker };
});
