# core/src/utils

Snapshot testing infrastructure shared by parser, codegen, and type tests.

## Files

| File | Role |
|---|---|
| `snap.zig` | `checkText(allocator, name, content)` — read/write/compare `.snap.md` files; writes `.snap.md.new` on mismatch |
| `pretty.zig` | Serialises any value to indented JSON via `std.json.stringify` (used to render AST snapshots) |
| `json_diff.zig` | Structural JSON diff printed to stderr when a snapshot mismatches |

## Snapshot workflow

1. First run: snapshot file is created automatically.
2. Mismatch: diff printed to stderr; `<name>.snap.md.new` written.
3. Accept changes: delete the `.snap.md` file, re-run tests.

## Conventions

See `../AGENTS.md` for core testing and architecture guidelines. Always preserve exact indentation in formatted files.
