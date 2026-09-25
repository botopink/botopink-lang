# modules/compiler-web

> Path: `modules/compiler-web/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The browser build of compiler-core (front 18 step 5): compiler-core itself,
built for `wasm32-wasi`, with the comptime runtime and the RUN LOG executors
compiled out. `zig build compiler-web` writes `zig-out/web/{botopink.wasm,
glue.js, index.html}`; serve that directory statically and open the page.

## Tree

```text
compiler-web/
├── AGENTS.md          ← you are here
├── src/web_root.zig   ← the wasm exports (bytes in, JSON of generated text out)
├── glue.js            ← WASI shim + `Botopink.Compiler` + the Worker protocol; no dependency
├── index.html         ← the demo: an editor, a target select, output / comptime / diagnostics / stderr panes
└── tests/smoke.js     ← `zig build test-web` — the build answers like the native compiler, under node
```

## Files

| File | Role |
|---|---|
| `src/web_root.zig` | Exports `bp_alloc`/`bp_free` (the host's window into linear memory), `bp_reset`, `bp_add_source(path, path_len, src, src_len)` (one `Module` of a virtual project — no file walk, no `botopink.json`; the CLI's scanner and dependency loading stay in the CLI), `bp_compile(target, target_len) → 0 compiled · 1 a module failed · 2 unknown target · 3 internal error`, `bp_output_ptr`/`bp_output_len` (the JSON of the last compile). The JSON is `{ target, modules: [{ name, code, typedef, units: [{ atom, code }], comptimeTrace, diagnostic }] }`, `diagnostic` being the text the CLI prints for a module without an artifact (a parse error through `print.renderAlloc`, a type error and a comptime validation error with their location) and null otherwise. `generateWith(.execute = false)` — the program is never run; `std.Io.Threaded.global_single_threaded` is the `Io`; `std.heap.wasm_allocator` the allocator. |
| `glue.js` | (1) The WASI preview1 shim: `fd_write` on 1/2 into captured `stdout`/`stderr`, `clock_time_get`/`clock_res_get`, `random_get`, `environ_*` (empty), `fd_fdstat_get` on the three stdio descriptors. `botopink.wasm` imports the whole `std.Io` vtable — 27 functions, the file system included — so `importsFor(module)` binds every declared import: the served ones to the shim, the rest to a function that **throws naming the call** (decision 67: a path that reaches the file system fails loudly, never ENOSYS into a retry). (2) `Botopink.Compiler`: `load(bytes | url | WebAssembly.Module)`, `addSource`, `compile(target)` → the JSON object with `status` added (throws on 2/3 with the compiler's stderr), `reset`, `stdout`/`stderr`. (3) Loaded as a Worker script it serves `{ id, op: "load", wasm }` and `{ id, op: "compile", sources, target }` → `{ id, ok, status, result, stdout, stderr, ms }`. Also `require`-able under node. |
| `index.html` | Two samples (a plain program; a decorator + a template), the four targets, a Worker running `glue.js`. After `botopink.wasm` and `glue.js` load, no request leaves the page. The comptime sample shows today's answer on a wasm host: the located refusal of `comptime/runtime/runtime.zig`, until step 2 lands the wat runtime. |
| `tests/smoke.js` | `node smoke.js <botopink.wasm>`: one plain program to `commonJS`, `erlang`, `beam`, `wasm` (status 0, the text carries the program), a program that does not parse (status 1, a located diagnostic, no artifact), a decorator + template program (status 1, the refusal names the missing runtime), an unknown target (throws), nothing on stdout. Hard asserts, exit 1 on the first failure. |

## Build

- The target is fixed in root `build.zig` (`wasm32-wasi`), not read from
  `-Dtarget`: nothing else in the workspace builds for wasm, and the CLI never
  will (it spawns processes). `-Doptimize` applies; the shipped size is
  `-Doptimize=ReleaseSmall`.
- `entry = .disabled` (a library of exports, no `_start`) and `rdynamic` (the
  `export fn`s stay in the export table).
- What is compiled out, and where: `comptime/runtime/runtime.zig` (`can_spawn`,
  `active`) — the evaluators' `persistent_erl` path and `codegen.zig`'s
  executors sit behind comptime-false conditions on `wasm32`, so
  `std.process` is never resolved. The one source change the target needed
  outside those gates: `codegen/erlang.zig`'s prelude spin lock yields with
  `std.atomic.spinLoopHint()` (`std.Thread.yield` is glibc's `sched_yield` on
  wasi).
- Measured 2026-09-25 (zig 0.16.0): Debug 15.8 MB / 16 s; ReleaseSmall
  **2.64 MB, 813 KB gzip** / 48 s — under the README's ≤ 8 MB / ≤ 2.5 MB gzip
  budget. The native Debug CLI is 80 MB.

## Not here

- Comptime evaluation: a decorator or template is refused on this host until
  front 18 step 2 (`persistent_wat.zig`) — the demo's `COMPTIME REPLY` cannot yet
  equal the native one.
- Running the generated program: the `wasm` target's output is `.wat` text; the
  page shows it and does not instantiate it (that needs the binary emitter,
  step 2's `codegen/wat/wasm_binary_emitter.zig`). `erlang`/`beam` outputs are
  text only — no VM in the page.
- Projects: `botopink.json`, dependencies and the module walk are the CLI's;
  the page hands sources in by path.
