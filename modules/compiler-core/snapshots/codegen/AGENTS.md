# snapshots/codegen

> Path: `modules/compiler-core/snapshots/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Snapshots for codegen output and codegen-time error rendering.

## Tree

```text
codegen/
├── AGENTS.md
├── erlang/erlang/         ← Erlang outputs (one .snap.md per scenario)
├── node/commonJS/         ← CommonJS outputs
├── beam/beam/             ← BEAM assembly
├── wasm/wasm/             ← WASM text
└── errors/                ← codegen-time error rendering
    ├── erlang/erlang/
    ├── node/commonJS/
    ├── beam/beam/
    └── wasm/wasm/
```

Each scenario in `codegen/tests.zig` emits one snapshot per target, so keep
file names in sync across `erlang/erlang/`, `node/commonJS/`, `beam/beam/`, and
`wasm/wasm/` for target-agnostic scenarios.
