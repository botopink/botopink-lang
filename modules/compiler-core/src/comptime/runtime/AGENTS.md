# compiler-core/src/comptime/runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

External runtime backends used to evaluate comptime expressions. Each backend
generates a script, executes it on the target runtime, and parses the JSON
output back into `id → literal` pairs.

## Tree

```text
runtime/
├── AGENTS.md      ← you are here
├── docs.md        ← backend interface + JSON transport + .botopinkbuild layout
├── node.zig       ← Node.js backend       (`node <script.js>`, stdout JSON array)
├── erlang.zig     ← Erlang/OTP backend    (escript or erlc+erl, `json:encode/1`)
├── beam.zig       ← BEAM backend          (erlc+erl, reuses Erlang OTP toolchain)
└── wasm.zig       ← WASM backend          (wasmtime, executes WAT via WASI)
```

## Shared interface

All four backends expose the same public function:

```zig
pub fn run(
    alloc: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult
```

`eval.RunResult` carries:

- `.script` — the generated source (JS or Erlang)
- `.values` — `std.StringHashMap([]const u8)` mapping comptime id → literal

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
build dir is always fresh.

## Notes

- All four backends emit JSON as their output protocol — keep parsing in `eval.zig`.
- When adding a new backend, mirror the `run(...)` signature exactly so
  `eval.zig` can dispatch without target-specific code paths.
