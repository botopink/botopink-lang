# compiler-core/src/utils

> Path: `modules/compiler-core/src/utils/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Snapshot-testing infrastructure shared by the compiler-core test suites
(parser, codegen, comptime).

## Tree

```text
utils/
├── AGENTS.md       ← you are here
├── snap.zig        ← read/write/compare .snap.md files
├── pretty.zig      ← indented JSON serialiser (AST snapshots)
└── json_diff.zig   ← structural JSON diff printed on mismatch
```

## Files

| File | Role |
|---|---|
| `snap.zig` | `checkText(alloc, name, text)` compares against `snapshots/<name>.snap.md`; `check(alloc, name, value)` does the same for a value rendered through `pretty.formatAlloc`; `readSource` reads `snapshots/<name>.botopink`. Paths are relative to `SNAP_DIR = "snapshots"`. CRLF and path separators are normalised before comparing. |
| `pretty.zig` | `formatAlloc` — serialises any value to 2-space-indented JSON via `std.json.Stringify.valueAlloc`. |
| `json_diff.zig` | `diff(alloc, expected, actual, writer)` — colored structural JSON diff; `snap.zig` prints it when the expected snapshot looks like JSON. |

## Snapshot workflow

1. Missing snapshot → created automatically (`snap created: …`).
2. Mismatch → `<name>.snap.md.new` written next to it, diff printed, test fails
   with `error.SnapshotMismatch`.
3. To accept: review the `.new` file and replace the `.snap.md` (or delete the
   old `.snap.md` and re-run). A matching run deletes a stale `.new`.

Leading/trailing newlines are trimmed before comparing, but everything else
(including indentation) is character-sensitive.
