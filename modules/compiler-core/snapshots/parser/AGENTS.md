# snapshots/parser

> Path: `modules/compiler-core/snapshots/parser/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Tests: [`../../src/parser/AGENTS.md`](../../src/parser/AGENTS.md)

Golden snapshots for parser output / AST structure. **~140 files**.

## Tree

```text
parser/
├── AGENTS.md      ← you are here
└── *.snap.md      ← ~140 AST golden fixtures
```

Don't edit manually — fix the parser, rerun `zig build test`, then promote the
`.new` file. When syntax changes, also refresh the formatter snapshots so the
round-trip contract still holds.
