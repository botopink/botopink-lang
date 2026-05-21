# snapshots/codegen

> Path: `modules/compiler-core/snapshots/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Snapshots for codegen output and codegen-time error rendering.

## Tree

```text
codegen/
├── AGENTS.md
├── erlang/erlang/         ← Erlang outputs   (142 .snap.md)
├── node/commonJS/         ← CommonJS outputs (142 .snap.md)
└── errors/                ← codegen-time error rendering
    ├── erlang/erlang/     ← (1 .snap.md)
    └── node/commonJS/     ← (1 .snap.md)
```

Keep file names in sync across `erlang/erlang/` and `node/commonJS/` for
target-agnostic scenarios.
