# snapshots/

> Path: `snapshots/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Workspace-level snapshot fixtures (outside any package). Currently a minimal
codegen smoke set used by root-level integration tests.

## Tree

```text
snapshots/
├── AGENTS.md           ← you are here
└── codegen/
    ├── erlang/erlang/  ← 1 Erlang snapshot
    └── node/commonJS/  ← 1 CommonJS snapshot
```

Bulk of compiler-core snapshots lives under
[`modules/compiler-core/snapshots/`](../modules/compiler-core/snapshots/AGENTS.md);
this tree is intentionally small.
