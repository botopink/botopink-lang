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
├── index.html         ← the demo: an editor, a target select, output / run / comptime / diagnostics / stderr panes
├── tests/smoke.js     ← `zig build test-web` — the build answers like the native compiler, under node; `wasm_std_unit_per_module`'s browser column
└── tests/comptime_host.js ← one plan through `bp_host.run_units` under node, for compiler-core's `codegen/tests/comptime_page_host.zig`
```

## Files

| File | Role |
|---|---|
| `src/web_root.zig` | Exports `bp_alloc`/`bp_free` (the host's window into linear memory), `bp_reset`, `bp_add_source(path, path_len, src, src_len)` (one `Module` of a virtual project — no file walk, no `botopink.json`; the CLI's scanner and dependency loading stay in the CLI), `bp_set_package(name, name_len)` (the project's package name, what `botopink.json`'s `name` is to the CLI — decision 109: an erlang/BEAM module atom starts with it; empty is no manifest and an erlang/beam compile is refused, never given a fallback name), `bp_compile(target, target_len) → 0 compiled · 1 a module failed · 2 unknown target · 3 internal error`, `bp_output_ptr`/`bp_output_len` (the JSON of the last compile). The JSON is `{ target, modules: [{ name, code, typedef, units: [{ atom, code }], wasm, comptimeTrace, diagnostic }], runtime: [{ name, wasm }] }`, `runtime` being the runtime core `std@__rt` and the std units the program's modules reach, in dependency order, base64 (`runtime_unit.get().closure`, what the CLI writes beside a `wasi` program — decisions 1026, 1069 (5); `[]` off the `wasm` target), `wasm` being the base64 of the binary module on the `wasm` target (`GenerateResult.wasm`, from `codegen/wat/wasm_binary_emitter.zig` — the same model as `code`) and null on the others, `diagnostic` being the text the CLI prints for a module without an artifact (a parse error through `print.renderAlloc`, a type error and a comptime validation error with their location) and null otherwise. `generateWith(.execute = false)` — the compiler never runs the program; `std.Io.Threaded.global_single_threaded` is the `Io`; `std.heap.wasm_allocator` the allocator.. On `wasm` the compile sets `Config.wasm_units` (decisions 1032, 1073 (2)): each module is a unit `<pkg>@<path>`, answered with its `unit` stem and `linked` (its `botopink.units`, the core first and itself last); std `.bp` linked into importers until P4c-std (decision 1072 (2)) |
| `glue.js` | **One linking path** (decision 1069 (4), (5)): `linkUnits(units, resolve)` compiles every unit, then instantiates each in order with the imports `resolve` gives (a value, an earlier unit's export, or a refusal by name); `run_units`, `run_module` (one unit) and `run` all link through it. (0) `bp_host`, the compiler's comptime engine: `run_module(wasm, arg) → status` links a linked comptime module as one unit (front 18's wat runtime — it imports nothing) and runs `bp_init`/`rt_alloc`/`bp_main` as `comptime/runtime/persistent_wat.zig` does natively on wasmtime (decision 543: one interface, `run_module`'s contract, the two engines behind it); the reply (status 0), the exception's `Class:Reason` or a trap message (1), or the engine's refusal (2) waits on the JS side for `result_len()`/`result_copy(dst)`. `run_units(plan, len) → status` is the GC comptime host's (decision 1038 (2), C3b; `codegen/wat/comptime_page.zig`): it follows the plan the compiler wrote — every unit compiled and instantiated afresh in order with each import's action and words as the compiler sorted them (an earlier unit's export, `fd_write` on 1 / 2 captured, `sched_yield` 0, a trap, a refusal), every `__bp_init`, the input at the core's alloc export, the evaluated module's evaluation export read back — after checking the engine runs WasmGC with exnref exceptions (`GC_EXN_PROBE`); status 0 the reply, 1 a raise as `{message, import, frames}` (the named wasm frames through V8's stack-trace API, at most 20, V8's trap messages mapped to the native host's names), 2 a refusal; what the body printed comes back through `printed_len()`/`printed_copy(dst)`. (1) The WASI preview1 shim: `fd_write` on 1/2 into captured `stdout`/`stderr`, `clock_time_get`/`clock_res_get`, `random_get`, `environ_*` (empty), `fd_fdstat_get` on the three stdio descriptors. `botopink.wasm` imports the whole `std.Io` vtable — 27 functions, the file system included — so `importsFor(module)` binds every declared import: the served ones to the shim, the rest to a function that **throws naming the call** (decision 67: a path that reaches the file system fails loudly, never ENOSYS into a retry). (2) `Botopink.Compiler`: `load(bytes | url | WebAssembly.Module)`, `setPackage(name)`, `addSource`, `compile(target)` → the JSON object with `status` added (throws on 2/3 with the compiler's stderr), `reset`, `stdout`/`stderr`. (3) `run(units)` (+ `programUnits(result, entry)`, `wasmBytes(base64)`): composes a `wasm`-target program from core modules only, never the WASI p2 component (decision 1069 (5)) — the compile's `runtime` (the core, then the std units it reaches) and the entry module, which holds the whole program while R2's `Config.wasm_units` is off (on, each module is a unit and the entry's `botopink.units` names their order) — linked in order with what a browser offers (334 (1)): `fd_write` on 1 / 2 into captured text, `random_get` from the page's crypto, any other import refused by name before a byte runs (`bp_fs`: the page has no file system); every unit's `__bp_init`, then the last unit's `_start`; answers `{ stdout, stderr, trap }` (`trap`: the engine's `RuntimeError` message, or null). (4) Loaded as a Worker script it serves `{ id, op: "load", wasm }`, `{ id, op: "compile", sources, target, package }` → `{ id, ok, status, result, stdout, stderr, ms }` and `{ id, op: "run", wasm, runtime }` → `{ id, ok, run, ms }`. Also `require`-able under node.. `programUnits(result, entry)` composes the entry's `linked` in order — the runtime's units, then the program's own from `result.modules` by `unit`; the Worker's `run` takes the compile's `modules` and `entry` for them (decision 1073 (2)) |
| `tests/comptime_host.js` | `node comptime_host.js <plan> [<repeat>]`: places a plan `comptime_page.zig` `plan` wrote in a memory and runs it through `hostServed`'s `run_units` / `result_*` / `printed_*`, `<repeat>` times in one host; prints `[{ status, text, printed }]`. Driven by `modules/compiler-core/src/codegen/tests/comptime_page_host.zig`, which holds the expected answers: the native host's. |
| `index.html` | Two samples (a plain program; a decorator + a template), the four targets, a Worker running `glue.js`. On the `wasm` target the page runs what it compiled (the `run` op) and shows its output in the run pane. After `botopink.wasm` and `glue.js` load, no request leaves the page. The comptime sample compiles on the four targets: its decorator and template run on the wasm comptime runtime (decision 434) — lowered and linked by the compiler, run by the page's engine through `bp_host` — and the comptime pane shows the same `COMPTIME REPLY` the native compiler records. |
| `tests/smoke.js` | `node smoke.js <botopink.wasm>`: first a package-less erlang compile (status 1, `belongs to no package`), then one plain program (printing through the builtin `@print`) to `commonJS`, `erlang`, `beam`, `wasm` (status 0, the text carries the program), a program compiled to `wasm` and its units composed and run (the core answered first in `runtime`; `hello, web` printed, no trap; `commonJS` carries no binary), `wasm_std_unit_per_module` in the browser column (the CLI test's `hello` composes `std@__rt` alone and prints `hello, world`; `files` composes `std@io@fs` after every unit it imports, the core first, and is refused by name at its `bp_fs` imports), a program that does not parse (status 1, a located diagnostic, no artifact), a program writing `@embed` (status 1, `embed-no-reader` located at the call — the page's compiler is handed no reader, decision 519), the decorator + template program on commonJS, wasm, erlang and beam (status 0, the expansion in the code, both `COMPTIME REPLY` sections equal to the native compiler's — a decorator's contributions are `{ kind, source }` objects, as in the native snapshots), an unknown target (throws), nothing on stdout, and the Worker's `load`/`compile`/`run` ops. Hard asserts, exit 1 on the first failure.; with units on, the `hello` entry links `std@__rt` and `hello@main`, and a two-module program runs from its units (`two@util` before `two@main`) |

## Build

- The target is fixed in root `build.zig` (`wasm32-wasi`), not read from
  `-Dtarget`: nothing else in the workspace builds for wasm, and the CLI never
  will (it spawns processes). `-Doptimize` applies; the shipped size is
  `-Doptimize=ReleaseSmall`.
- `entry = .disabled` (a library of exports, no `_start`) and `rdynamic` (the
  `export fn`s stay in the export table).
- What is compiled out, and where: `comptime/runtime/runtime.zig` (`can_spawn`)
  — `codegen.zig`'s executors sit behind comptime-false conditions on
  `wasm32`, and the comptime runtime's engine is the page's (`bp_host`), so
  `std.process` is never resolved. The one source change the target needed
  outside those gates: `codegen/erlang.zig`'s prelude spin lock yields with
  `std.atomic.spinLoopHint()` (`std.Thread.yield` is glibc's `sched_yield` on
  wasi).
- Measured 2026-09-25 (zig 0.16.0): Debug 15.8 MB / 16 s; ReleaseSmall
  **2.64 MB, 813 KB gzip** / 48 s — under the README's ≤ 8 MB / ≤ 2.5 MB gzip
  budget. The native Debug CLI is 80 MB. With the wat comptime runtime compiled
  in (the Erlang reader, the lowering, the linker and the 60 KB term library — since decision 450
  std-wasm's, decoded from the embedded `std_wasm.wasm` at the first comptime evaluation;
  `bp_wat_rt.wasm` is gone):
  ReleaseSmall **2.91 MB, 908 KB gzip**.

## Not here

- Running the `erlang`/`beam` outputs: text only — no VM in the page.
- Projects: `botopink.json`, dependencies and the module walk are the CLI's;
  the page hands sources in by path.
