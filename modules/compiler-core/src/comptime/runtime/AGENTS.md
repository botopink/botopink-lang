# compiler-core/src/comptime/runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Single in-process runtime for comptime val evaluation, built on the embedded
[wasm3](https://github.com/wasm3/wasm3) interpreter (vendored at
`modules/wasm3/source/`, see [`../../../../wasm3/AGENTS.md`](../../../../wasm3/AGENTS.md)).
The four-runtime
architecture (`node` / `erlang` / `wasm` / `beam`) was retired in v0.beta.21
(`wasm3-unified-runtime` spec) — wasm3 is now the sole executor; each codegen
backend continues to render the *value* into its own target syntax, but the
evaluation itself runs once.

## Tree

```text
runtime/
├── AGENTS.md            ← you are here
├── docs.md              ← runtime interface + WAT subset + .botopinkbuild layout
├── wat_to_wasm.zig      ← pure-Zig WAT → binary WASM compiler (~600 LOC)
├── wasm3_host.zig       ← thin Zig wrapper over wasm3's C API + WASI fd_write shim
├── wat_runtime.zig      ← comptime prelude: raw-infra WAT + bp prelude merge (~650 LOC)
├── wasm.zig             ← buildScript + parseResults around `wasm3_host.runWat`
└── persistent_node.zig  ← legacy Node runner (kept until front 09 completes)
```

The comptime prelude lives in `wat_runtime.zig` (3-layer architecture):
1. `rawInfra()` — ~160 lines of WAT inline (fd_write, bump allocator, error handling,
   descriptor walker: `__str_eq`, `__capture__lookup`, `__capture__bindings`,
   `__capture__context`, `__capture__parts`).
2. `compileBpBodies()` — compiles `libs/std/src/template_runtime.bp` through the wat
   backend. `#[@Host]` methods are skipped; the rest (records, constructors,
   field-getters) are compiled to WAT.
3. `prelude()` merge — strips bp module wrapper, renames `$__heap_ptr` →
   `$__bp_heap_ptr`, renames bp-mangled names, concatenates rawInfra + bp bodies.

`persistent_node.zig` stays until the wat-runtime-as-bp-module front is complete —
the `evaluateWat` → `evaluateNode` fallback is still active.

## Public interface

```zig
// wasm.run — the only comptime-val backend
pub fn run(
    alloc: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult

// wasm3_host — the layer wasm.run delegates to
pub fn runWat(allocator: std.mem.Allocator, wat_bytes: []const u8) ![]u8
pub fn warm(allocator: std.mem.Allocator) !void

// wat_to_wasm — pure-Zig WAT compiler used by wasm3_host
pub fn compile(allocator: std.mem.Allocator, wat: []const u8) Error![]u8
```

`eval.RunResult` carries:

- `.script` — the generated WAT source (debug / snapshot use)
- `.values` — `std.StringHashMap([]const u8)` mapping comptime id → literal

## WAT subset

`wat_to_wasm.zig` supports exactly what `wasm.zig:buildScript` emits today
(`i32.const`, `i32.store`, `i32.add` / `_sub` / `_mul`, `local.get` / `_set`,
`drop`, `call`, the `memory.copy` / `memory.fill` bulk ops, the `fd_write` WASI
shim, simple `data` segments). Anything outside that subset returns
`error.UnsupportedWatFeature`. The set is closed by design — both ends are
controlled by botopink.

## Notes

- No external runtime is required for `zig build test`: wasm3 statically links
  with libc, and the comptime path never spawns a child process.
- The `wasm3` environment singleton (`IM3Environment`) lives until process exit
  (spinlock-guarded init); each `runWat` call gets a fresh `IM3Runtime` and frees
  it before returning. The shape is the same pattern as `persistent_node`'s
  child-process singleton.
- When a comptime backend test claims a runtime spawned `wasmtime` / `erl`, fix
  the upstream — this layer no longer reaches for the system.
