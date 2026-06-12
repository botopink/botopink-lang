# compiler-core/src/utils

> Path: `modules/compiler-core/src/utils/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Snapshot-testing infrastructure shared by every test suite in the workspace
(parser, codegen, comptime, LSP).

## Tree

```text
utils/
├── AGENTS.md       ← you are here
├── docs.md         ← snapshot workflow + API surface
├── snap.zig        ← read/write/compare .snap.md files
├── pretty.zig      ← indented JSON serialiser (used to render AST snapshots)
└── json_diff.zig   ← structural JSON diff printed on mismatch
```

## Files

| File | Role |
|---|---|
| `snap.zig` | `checkText(alloc, name, content)` — compares against `<name>.snap.md`; writes `<name>.snap.md.new` on mismatch. |
| `pretty.zig` | Serialises any value to indented JSON via `std.json.stringify`. |
| `json_diff.zig` | Renders a structural JSON diff to stderr when a snapshot mismatches. |

## Snapshot workflow

1. First run → snapshot file is created automatically.
2. Mismatch → diff printed to stderr; `<name>.snap.md.new` written.
3. To accept the change: review the `.new` file, then replace the existing
   `.snap.md` (or delete the old `.snap.md` and re-run tests).

Indentation in formatted output must be preserved exactly — snapshot diffs
are character-sensitive.
