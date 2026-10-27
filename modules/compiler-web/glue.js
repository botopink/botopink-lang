// glue.js — the JS side of the browser build of compiler-core (front 18 step 5).
//
// Three things, no dependency:
//   0. `bp_host`, the compiler's comptime engine: `run_module` instantiates a
//      linked comptime module (front 18's wat runtime) and runs it, the answer
//      comes back through `result_len`/`result_copy`;
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
//      `{ id, op: "compile", sources: [{ path, source }], target, package }` →
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
  const ERRNO_FAULT = 21;
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

  // ── the comptime engine ────────────────────────────────────────────────────

  /// Run one comptime evaluation the compiler lowered and linked (front 18,
  /// the wat runtime): the bytes are a whole module importing nothing; the
  /// export sequence is `persistent_wat.zig`'s. Status 0 is the reply, 1 a
  /// runtime error (`Class:Reason`, or the engine's trap), 2 a module the
  /// engine refused.
  function runComptime(bytes, arg) {
    const encoder = new TextEncoder();
    let module;
    try {
      module = new WebAssembly.Module(bytes);
    } catch (err) {
      return { status: 2, bytes: encoder.encode(`the page's engine refused the module: ${err.message}`) };
    }
    try {
      const e = new WebAssembly.Instance(module, {}).exports;
      e.bp_init();
      const p = e.rt_alloc(arg.length);
      new Uint8Array(e.memory.buffer, p, arg.length).set(arg);
      const r = e.bp_main(p, arg.length);
      const bin = (t) => new Uint8Array(e.memory.buffer, e.rt_bin_ptr(t) >>> 0, e.rt_bin_len(t) >>> 0).slice();
      if (r === 0 || e.rt_pending() !== 0) return { status: 1, bytes: bin(e.rt_describe(e.rt_class(), e.rt_reason())) };
      return { status: 0, bytes: bin(r) };
    } catch (err) {
      return { status: 1, bytes: encoder.encode(`the page's engine trapped: ${err.message}`) };
    }
  }

  // ── the comptime host over units (decisions 1035, 1038 (2), 1059; C3b) ─────
  //
  // The page's side of `codegen/wat/comptime_page.zig`: it follows the plan
  // the compiler wrote — the units in dependency order, each import's action
  // and words already sorted by the native host's own rules, the input, the
  // crossing's names from `runtime_unit.zig` — on the page's engine, with GC
  // and exceptions (1033 (1)). Every unit is compiled and instantiated afresh,
  // every `__bp_init` called in order, the input written at the core's alloc
  // export in its memory, the evaluated module's evaluation export read back
  // as `(ptr, len)`. `fd_write` on 1 / 2 is captured. There is no epoch on the
  // page: no deadline, and the compiler's interrupt is a no-op. Status 0 the
  // reply, 1 raised (the message; the compiler builds the host's reply), 2 a
  // compile refusal. The only words of its own are the engine's trap names.

  // A module with a struct type, a tag and a `try_table`: the engine the
  // program's generator needs (WasmGC and exnref exceptions, 1033 (1)).
  const GC_EXN_PROBE = new Uint8Array([
    0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x06, 0x02, 0x5f, 0x00, 0x60, 0x00, 0x00, // types: (struct) (func)
    0x03, 0x02, 0x01, 0x01, // one function of type 1
    0x0d, 0x03, 0x01, 0x00, 0x01, // one tag of type 1
    0x0a, 0x08, 0x01, 0x06, 0x00, 0x1f, 0x40, 0x00, 0x0b, 0x0b, // (try_table) end
  ]);
  let gcExn = null;
  function engineRefusal() {
    if (gcExn === null) {
      try {
        gcExn = WebAssembly.validate(GC_EXN_PROBE);
      } catch (_) {
        gcExn = false;
      }
    }
    return gcExn ? null : "the page's engine runs no WasmGC with exceptions, which comptime needs";
  }

  // `comptime_page.zig` `Action`.
  const ACTION = { unit: 0, print: 1, yield: 2, trap: 3, refuse: 4 };

  /// A host trap: its text is the answer's, whatever the engine wraps it in;
  /// `imp` is the import that raised it (`<module>.<name>`).
  class HostTrap extends Error {
    constructor(text, imp) {
      super(text);
      this.imp = imp;
    }
  }

  // The most frames a raise keeps (`comptime_host.zig` `max_frames`, wasmtime's backtrace bound).
  const MAX_FRAMES = 20;

  /// The named wasm frames of `err`'s backtrace, innermost first, by each
  /// unit's `name` section, as the native host reads them from wasmtime's:
  /// `{ module, function }`, a frame with no function name left out. V8's
  /// stack-trace API; an engine without it gives none.
  function framesOf(err) {
    if (!err || typeof err !== "object" || typeof Error.captureStackTrace !== "function") return [];
    const saved = Error.prepareStackTrace;
    let sites = null;
    try {
      Error.prepareStackTrace = (_e, s) => s;
      sites = err.stack;
    } catch (_) {
      sites = null;
    } finally {
      Error.prepareStackTrace = saved;
    }
    if (!Array.isArray(sites)) return [];
    const frames = [];
    for (const site of sites) {
      if (frames.length === MAX_FRAMES) break;
      const url = site.getScriptNameOrSourceURL && site.getScriptNameOrSourceURL();
      if (typeof url !== "string" || !url.startsWith("wasm://wasm/")) continue;
      const fn = site.getFunctionName();
      if (fn === null || fn === undefined) continue;
      const m = /^(.*)-[0-9a-f]{8}$/.exec(url.slice("wasm://wasm/".length));
      frames.push({ module: m ? m[1] : "", function: fn });
    }
    return frames;
  }

  /// The page's raise as `comptime_page.zig` `finish` reads it.
  function raised(message, imp, err) {
    return JSON.stringify({ message, import: imp || "", frames: framesOf(err) });
  }

  /// V8's trap messages under the names the native host gives wasmtime's
  /// trap codes (`comptime_host.zig` `trapName`): one text for both engines.
  const TRAP_NAMES = [
    [/^unreachable/, "unreachable"],
    [/memory access out of bounds/, "out of bounds memory access"],
    [/(divide|remainder) by zero/, "integer divide by zero"],
    [/divide result unrepresentable/, "integer overflow"],
    [/float unrepresentable in integer range/, "invalid conversion to integer"],
    [/table index is out of bounds/, "undefined element: out of bounds table access"],
  ];

  /// The runtime error's one line for a thrown `err`, as the native host
  /// writes it: a host trap's text, else `wasmtime: <what>`.
  function trapLine(err) {
    if (err instanceof HostTrap) return err.message;
    if (typeof WebAssembly.Exception !== "undefined" && err instanceof WebAssembly.Exception) return "wasmtime: uncaught exception";
    if (err instanceof RangeError && /call stack/i.test(err.message)) return "wasmtime: call stack exhausted";
    const msg = String((err && err.message) || err).split("\n")[0];
    for (const [re, name] of TRAP_NAMES) if (re.test(msg)) return `wasmtime: ${name}`;
    return `wasmtime: ${msg}`;
  }

  /// The plan `comptime_page.zig` `plan` writes, read out of `bytes`.
  function readPlan(bytes) {
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    const decoder = new TextDecoder();
    let at = 0;
    const int = () => {
      const v = dv.getUint32(at, true);
      at += 4;
      return v;
    };
    const raw = () => {
      const n = int();
      const b = bytes.subarray(at, at + n);
      at += n;
      return b;
    };
    const str = () => decoder.decode(raw());
    const units = [];
    for (let n = int(), i = 0; i < n; i++) {
      const unit = { name: str(), bytes: raw(), imports: [] };
      for (let k = int(), j = 0; j < k; j++) unit.imports.push({ module: str(), name: str(), action: int(), text: str() });
      units.push(unit);
    }
    const input = raw();
    const crossing = { memoryUnit: str(), memory: str(), alloc: str(), eval: str(), evaluated: str() };
    return { units, input, crossing };
  }

  /// One evaluation of a plan. Answers `{ status, bytes, printed }`; a raise's
  /// bytes are `raised`'s JSON.
  function runComptimeUnits(plan) {
    // Enough frames for `MAX_FRAMES` wasm ones under the host's own.
    const limit = Error.stackTraceLimit;
    Error.stackTraceLimit = MAX_FRAMES + 16;
    try {
      return evaluateUnits(plan);
    } finally {
      Error.stackTraceLimit = limit;
    }
  }

  function evaluateUnits(plan) {
    const encoder = new TextEncoder();
    const printed = [];
    const answer = (status, text) => ({ status, bytes: typeof text === "string" ? encoder.encode(text) : text, printed: concat(printed) });
    const refused = engineRefusal();
    if (refused) return answer(2, refused);
    const { units, input, crossing } = plan;

    const modules = [];
    for (const u of units) {
      try {
        modules.push(new WebAssembly.Module(u.bytes));
      } catch (err) {
        return answer(2, `unit ${u.name}: ${err.message}`);
      }
    }

    const instances = new Map();
    let pending = null; // a host trap the engine may rewrap
    const raise = (imp) => {
      pending = new HostTrap(imp.text, `${imp.module}.${imp.name}`);
      throw pending;
    };
    const fault = (err) => (pending ? raised(pending.message, pending.imp, pending) : raised(trapLine(err), "", err));
    const call = (f, args) => {
      pending = null;
      try {
        return { value: f(...args) };
      } catch (err) {
        return { error: fault(err) };
      }
    };

    const ordered = [];
    for (let i = 0; i < units.length; i++) {
      const u = units[i];
      const imports = {};
      let instance = null;
      const memoryOf = () => (instance && instance.exports.memory instanceof WebAssembly.Memory ? instance.exports.memory : null);
      for (const imp of u.imports) {
        let value;
        switch (imp.action) {
          case ACTION.unit:
            value = instances.get(imp.module).exports[imp.name];
            break;
          case ACTION.print:
            value = fdWrite(memoryOf, printed, () => raise(imp));
            break;
          case ACTION.yield:
            value = () => 0;
            break;
          case ACTION.trap:
            value = () => raise(imp);
            break;
          default:
            return answer(2, imp.text);
        }
        (imports[imp.module] = imports[imp.module] || {})[imp.name] = value;
      }
      pending = null;
      try {
        instance = new WebAssembly.Instance(modules[i], imports);
      } catch (err) {
        // A link the engine refuses is a compile refusal; a trap in a start
        // function is raised.
        if (err instanceof WebAssembly.LinkError) return answer(2, `unit ${u.name}: ${err.message}`);
        return answer(1, fault(err));
      }
      instances.set(u.name, instance);
      ordered.push(instance);
    }

    for (const inst of ordered) {
      if (typeof inst.exports.__bp_init !== "function") continue;
      const r = call(inst.exports.__bp_init, []);
      if (r.error !== undefined) return answer(1, r.error);
    }

    const core = instances.get(crossing.memoryUnit);
    if (!core) return answer(2, `no unit is ${crossing.memoryUnit}, whose memory the JSON crosses through`);
    const entry = instances.get(crossing.evaluated);
    if (!entry) return answer(2, `no unit is ${crossing.evaluated}, the module evaluated`);
    const allocF = core.exports[crossing.alloc];
    if (typeof allocF !== "function") return answer(2, `${crossing.memoryUnit} exports no function ${crossing.alloc}`);
    const evalF = entry.exports[crossing.eval];
    if (typeof evalF !== "function") return answer(2, `${crossing.evaluated} exports no function ${crossing.eval}`);

    const a = call(allocF, [input.length]);
    if (a.error !== undefined) return answer(1, a.error);
    const memory = core.exports[crossing.memory];
    if (!(memory instanceof WebAssembly.Memory)) return answer(2, `${crossing.memoryUnit} exports no memory ${crossing.memory}`);
    const inPtr = a.value >>> 0;
    if (inPtr + input.length > memory.buffer.byteLength) return answer(1, raised("the input does not fit the core unit's memory"));
    new Uint8Array(memory.buffer, inPtr, input.length).set(input);
    const r = call(evalF, [inPtr, input.length]);
    if (r.error !== undefined) return answer(1, r.error);
    const [outPtr, outLen] = Array.isArray(r.value) ? r.value.map((v) => v >>> 0) : [0, 0];
    // The memory may have grown during the evaluation: read it again.
    if (outPtr + outLen > memory.buffer.byteLength) return answer(1, raised("the reply lies outside the core unit's memory"));
    return answer(0, new Uint8Array(memory.buffer, outPtr, outLen).slice());
  }

  function concat(chunks) {
    let n = 0;
    for (const c of chunks) n += c.length;
    const out = new Uint8Array(n);
    let at = 0;
    for (const c of chunks) {
      out.set(c, at);
      at += c.length;
    }
    return out;
  }

  /// `fd_write(fd, iovs, iovs_len, nwritten) -> errno` over the importing
  /// unit's exported `memory`: fd 1 and 2 append to `printed`; any other fd
  /// is a file, and `refuse` traps.
  function fdWrite(memoryOf, printed, refuse) {
    return (fd, iovs, count, nwritten) => {
      if (fd !== 1 && fd !== 2) return refuse();
      const memory = memoryOf();
      if (!memory) return ERRNO_FAULT;
      const dv = new DataView(memory.buffer);
      const size = memory.buffer.byteLength;
      let total = 0;
      for (let k = 0; k < count; k++) {
        const at = (iovs >>> 0) + 8 * k;
        if (at + 8 > size) return ERRNO_FAULT;
        const p = dv.getUint32(at, true);
        const n = dv.getUint32(at + 4, true);
        if (p + n > size) return ERRNO_FAULT;
        printed.push(new Uint8Array(memory.buffer, p, n).slice());
        total += n;
      }
      if ((nwritten >>> 0) + 4 > size) return ERRNO_FAULT;
      dv.setUint32(nwritten >>> 0, total, true);
      return ERRNO_SUCCESS;
    };
  }

  /// `bp_host`: the compiler asks the page to run a comptime module, then
  /// copies the answer back into its own memory. `run_module` is the term
  /// runtime's (`persistent_wat.zig` `Page`); `run_units(plan, len)` the GC
  /// host's (`codegen/wat/comptime_page.zig`), whose answer comes back
  /// through `result_len` / `result_copy` and what the body printed through
  /// `printed_len` / `printed_copy`.
  function hostServed(state) {
    let last = new Uint8Array(0);
    let lastPrinted = new Uint8Array(0);
    return {
      run_module(wptr, wlen, aptr, alen) {
        const mem = new Uint8Array(state.memory.buffer);
        const r = runComptime(mem.slice(wptr >>> 0, (wptr >>> 0) + (wlen >>> 0)), mem.slice(aptr >>> 0, (aptr >>> 0) + (alen >>> 0)));
        last = r.bytes;
        lastPrinted = new Uint8Array(0);
        return r.status;
      },
      run_units(planPtr, planLen) {
        const bytes = new Uint8Array(state.memory.buffer, planPtr >>> 0, planLen >>> 0).slice();
        const r = runComptimeUnits(readPlan(bytes));
        last = r.bytes;
        lastPrinted = r.printed;
        return r.status;
      },
      result_len() {
        return last.length;
      },
      result_copy(dst) {
        new Uint8Array(state.memory.buffer, dst >>> 0, last.length).set(last);
      },
      printed_len() {
        return lastPrinted.length;
      },
      printed_copy(dst) {
        new Uint8Array(state.memory.buffer, dst >>> 0, lastPrinted.length).set(lastPrinted);
      },
    };
  }

  /// The import object for `module`: every declared import is bound — the
  /// served ones to the shim, the rest to a refusal naming the call.
  function importsFor(module, state) {
    const served = wasiServed(state);
    const host = hostServed(state);
    const imports = {};
    for (const imp of WebAssembly.Module.imports(module)) {
      if (imp.module === "bp_host" && imp.kind === "function" && host[imp.name]) {
        imports.bp_host = imports.bp_host || {};
        imports.bp_host[imp.name] = host[imp.name];
        continue;
      }
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

    /// The project's package name (decision 109): what `botopink.json`'s
    /// `name` is to the CLI. An erlang/beam compile without one is refused.
    setPackage(name) {
      // A zero-length allocation has no address to hand over: an empty name
      // is passed as length 0 of a one-byte buffer.
      const n = this.writeString(name === "" ? " " : name);
      try {
        if (this.exports.bp_set_package(n.ptr, name === "" ? 0 : n.len) !== 0) throw new Error("botopink.wasm is out of memory");
      } finally {
        this.exports.bp_free(n.ptr, n.len);
      }
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
          compiler.setPackage(msg.package || "");
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

  return { Compiler, importsFor, run, wasmBytes, serveWorker, hostServed, readPlan, runComptimeUnits };
});
