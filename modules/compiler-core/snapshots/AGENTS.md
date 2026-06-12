# compiler-core/snapshots

> Path: `modules/compiler-core/snapshots/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Golden snapshots consumed by compiler-core tests.

## Tree

```text
snapshots/
├── AGENTS.md
├── parser/             ← AST snapshots                          → parser/AGENTS.md
├── codegen/            ← target output + error snapshots       → codegen/AGENTS.md
└── comptime/           ← inference / evaluation snapshots      → comptime/AGENTS.md
```

## Regeneration

From `modules/compiler-core/`:

```bash
zig build test
```

On mismatch a sibling `<name>.snap.md.new` is written. Review and either accept
(replace `.snap.md`) or reject (delete and fix the bug). Don't commit
`.snap.md.new` files.
