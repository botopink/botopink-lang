# compiler-core/src/comptime/runtime — external eval backends

> Path: `modules/compiler-core/src/comptime/runtime/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)

Comptime evaluation is delegated to external runtimes. Each backend writes
a small script in the target language, executes it, and parses the JSON
output back into `id → literal` pairs that `render.zig` then inlines into
the AST.

## Tree

```text
runtime/
├── node.zig       ← Node.js backend       (`node <script.js>`, stdout JSON array)
├── erlang.zig     ← Erlang/OTP backend    (escript or erlc+erl, `json:encode/1`)
├── beam.zig       ← BEAM backend          (erlc+erl, reuses Erlang OTP toolchain)
└── wasm.zig       ← WASM backend          (wasmtime, executes WAT via WASI)
```

## Shared interface

All four backends expose the same public function — `eval.zig` calls into them
without target-specific code paths.

```zig
pub fn run(
    alloc: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult
```

`eval.RunResult` carries:

| Field | Meaning |
|---|---|
| `.script` | The generated source (JS or Erlang). Useful for debugging and snapshot tests. |
| `.values` | `std.StringHashMap([]const u8)` mapping comptime id → literal text (already in the target syntax). |

JSON is the only inter-process protocol. Anything that needs to cross the
boundary becomes a JSON value; `render.zig` then converts JSON back into
an AST literal honouring the declared `TypeRef`.

## Why JSON?

| Reason | Detail |
|---|---|
| Lingua franca | All runtimes ship a JSON encoder out of the box (Node has it native; Erlang's `json` module; BEAM/WASM reuse their respective toolchains). |
| Inspectable | The script and output are plain text — easy to dump under `.botopinkbuild/`. |
| Cheap recovery | Parsing errors degrade gracefully into a clear `TypeError` rather than panicking. |

## Generated artefacts

Scripts are written under `.botopinkbuild/<build_root>/<runtime>/`:

```text
.botopinkbuild/
├── node/
│   └── main.js          ← generated JavaScript
└── erlang/
    ├── main.erl         ← generated Erlang
    └── main.beam        ← compiled (erlc output)
```

The previous build directory is cleared (`deleteTree`) on every run, so the
build dir is always fresh. This means no stale-cache bugs at the cost of
slightly more disk churn.

## Adding a new backend

At minimum:

1. Create `runtime/<name>.zig` and mirror the `run(...)` signature exactly.
2. Generate a script that prints JSON to stdout.
3. Dispatch from `../eval.zig` based on `Config.ComptimeRuntime`.
4. Add fixtures under `../../../snapshots/comptime/<name>/` with both
   success and `errors/` directories.

## Notes

- All four backends emit JSON as their output protocol — keep parsing in
  `../eval.zig` so each new backend gets it for free.
- The `build_root` parameter exists so multiple compile invocations (e.g.
  parallel CLI runs) don't stomp on each other's scratch directories.

## See also

- Comptime architecture → [`../docs.md`](../docs.md).
- AST literal rendering → [`../render.zig`](../render.zig).
