# language-server/snapshots

> Path: `modules/language-server/snapshots/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Snapshot artefacts produced by language-server tests.

## Tree

```text
snapshots/
├── AGENTS.md
└── lsp/               ← 66 feature snapshots — see lsp/AGENTS.md
```

## Regenerate

```bash
cd modules/language-server && zig build test
```

Review `*.snap.md.new` files before promoting them over the originals.
