# compiler-core/src/comptime/runtime — comptime eval runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)

Comptime evaluation runs through a single embedded
[wasm3](https://github.com/wasm3/wasm3) interpreter (vendored at
`modules/wasm3/source/` — see [`../../../../wasm3/AGENTS.md`](../../../../wasm3/AGENTS.md)).
Each comptime val expression is lowered to a small WAT
module, compiled to binary WASM by the pure-Zig `wat_to_wasm.zig`, instantiated
by `wasm3_host.zig`, and the bytes the module writes to fd 1 (a JSON array) are
parsed back into `id → literal` pairs that `render.zig` then inlines into the
AST.

## History (v0.beta.21 unification)

Prior to v0.beta.21 this layer dispatched across four backends — node, erlang,
wasm (wasmtime), and beam — to give a cheap cross-backend semantic-parity
oracle. That oracle became redundant once codegen snapshots covered the
target-syntax rendering path, and the four-runtime architecture pulled four
external runtimes (`node`, `erl` + `erlc` + `escript`, `wasmtime`) into every
dev box's PATH. The `wasm3-unified-runtime` spec collapsed the four into a
single in-process wasm3 evaluation; the target-specific backends
(`commonJS.zig` / `erlang.zig` / `wat.zig` / `beam_asm.zig`) still render the
evaluated value into their respective literal syntax, but they all read from
one source of truth.

## Tree

```text
runtime/
├── wat_to_wasm.zig      ← pure-Zig WAT → binary WASM compiler (~600 LOC, supports
│                          exactly the subset wasm.zig:buildScript emits today)
├── wasm3_host.zig       ← thin Zig wrapper over wasm3's C API + a one-function
│                          WASI fd_write shim; owns the process-lifetime
│                          IM3Environment singleton
├── wasm.zig             ← buildScript (WAT emitter for comptime entries) +
│                          parseResults (JSON → values map)
└── persistent_node.zig  ← long-lived `node` runner used by template_eval /
                           decorator_eval — they execute user-written JS bodies
                           that wasm3 can't substitute for. Slated for deletion
                           by the follow-up `templates-decorators-botopink-native`
                           spec.
```

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

| Field | Meaning |
|---|---|
| `.script` | The generated WAT source. Useful for debugging and snapshot tests. |
| `.values` | `std.StringHashMap([]const u8)` mapping comptime id → literal text (already in the target syntax). |

JSON remains the wire format inside the WASM module: `buildScript` emits a
single `[{"id":"ct_0","value":…}, …]` write to fd 1, the WASI shim captures
those bytes, `parseResults` reads them back. Keep parsing centralized in
`wasm.parseResults`.

## WAT subset

`wat_to_wasm.compile` is intentionally scoped to the shape `wasm.buildScript`
emits today:

- `(module …)` declarations
- `(import "wasi_snapshot_preview1" "fd_write" (func …))` (the only host fn)
- `(memory (export "memory") N)`
- `(data (i32.const N) "…")`
- `(func … (export "_start" | "_botopink_main") …)`
- `i32.const`, `i64.const`, `f32.const`, `f64.const`
- `i32.add` / `_sub` / `_mul` / `_div_s` / `_div_u` / `_rem_s` / `_rem_u` /
  comparisons / bitwise / shifts / `eqz`
- `i64`/`f32`/`f64` arithmetic where the subset is symmetric
- `i32.load` / `_load8_u` / `_store` / `_store8`, plus the wider `i64`/`f32`/`f64` variants
- `local.get` / `local.set` / `local.tee`
- `global.get` / `global.set`
- `call`, `drop`, `return`, `nop`, `unreachable`
- `memory.copy`, `memory.fill`

Anything outside this set returns `error.UnsupportedWatFeature`. `codegen/wat.zig`
emits a richer surface (block / loop / if / br); these are deliberately deferred
to a follow-up so this spec ships incrementally — `codegen/runtime.executeWat`
returns an empty RUN-LOG buffer if it hits an unsupported feature, mirroring
the pre-spec behaviour when `wasmtime` was absent.

## Generated artefacts

`wasm.run` no longer writes intermediate files. The WAT bytes are passed
in-memory to `wasm3_host.runWat`, and `RunResult.script` exposes them to
callers (snapshot tests). The `build_root` parameter is kept on the function
signature for future use but is currently unused.

## Notes

- The wasm3 environment singleton lives for the process lifetime
  (`IM3Environment`, spinlock-guarded init); each call owns a fresh
  `IM3Runtime` for memory isolation.
- The fd_write shim only captures fd 1 (stdout); fd 2 is also routed to the
  buffer for diagnostics. Other fds get a successful no-op so well-behaved
  modules that try `proc_exit` / `environ_get` see expected return codes.
- Add a new opcode? Drop a row into the `lookupSimpleOp` table in
  `wat_to_wasm.zig` + a fixture. The binary spec is mechanical.

## See also

- Comptime architecture → [`../docs.md`](../docs.md).
- AST literal rendering → [`../render.zig`](../render.zig).
- Vendored wasm3 module → [`../../../../wasm3/AGENTS.md`](../../../../wasm3/AGENTS.md) (README at [`../../../../wasm3/README.md`](../../../../wasm3/README.md)).
