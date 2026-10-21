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
| `snap.zig` | `checkText(alloc, name, text)` compares against `snapshots/<name>.snap.md`; `check(alloc, name, value)` does the same for a value rendered through `pretty.formatAlloc`; `readSource` reads `snapshots/<name>.botopink`. Paths are relative to `SNAP_DIR = "snapshots"`. CRLF and path separators are normalised before comparing. A missing file fails unless `BOTOPINK_SNAP_CREATE=1` is set. `BOTOPINK_SNAP_TRACE=<file>` appends every checked path (see below); `traceEnter`/`traceLeave` scope the test `@src()` it records. |
| `pretty.zig` | `formatAlloc` — serialises any value to 2-space-indented JSON via `std.json.Stringify.valueAlloc`. |
| `json_diff.zig` | `diff(alloc, expected, actual, writer)` — colored structural JSON diff; `snap.zig` prints it when the expected snapshot looks like JSON. |

## Snapshot workflow

1. Missing snapshot → **fails** with `error.SnapshotMissing`; the candidate
   baseline is written to `<name>.snap.md.new` for review. Re-run with
   `BOTOPINK_SNAP_CREATE=1` (or rename the `.new` file) to record it. Before
   spec 06 step 1 a first recording was accepted silently and nobody reviewed
   it (defect H4).
2. Mismatch → `<name>.snap.md.new` written next to it, diff printed, test fails
   with `error.SnapshotMismatch`.
3. To accept: review the `.new` file and replace the `.snap.md` (or delete the
   old `.snap.md` and re-run with `BOTOPINK_SNAP_CREATE=1`). A matching run
   deletes a stale `.new`. `*.snap.md.new` is git-ignored.

Leading/trailing newlines are trimmed before comparing, but everything else
(including indentation) is character-sensitive.

## Snapshot trace (`BOTOPINK_SNAP_TRACE`)

A snapshot's file name is derived from its test's description, so renaming or
deleting a test leaves the old file on disk and every run stays green. The
trace is the record of which paths a run actually checked.

- `BOTOPINK_SNAP_TRACE=/abs/trace zig build test` — every `compareOrCreate`
  call (whatever its outcome) appends
  `<absolute snapshot path> TAB <absolute test file:line | -> TAB <test fn | ->`.
  The language-server harness (`modules/language-server/src/tests/snapshot.zig`)
  appends to the same file.
- The test location comes from `traceEnter(@src())` / `traceLeave(prev)`,
  which the test-side helpers in `codegen/tests`, `comptime/tests` and
  `parser/tests` wrap around their snapshot calls (a thread-local scope, so
  `codegen/snapshot.zig` and `comptime/snapshot.zig` did not have to change).
  A snapshot checked outside a scope records `-`.
- Append-safe: `O_APPEND` and one `write` per line, because `zig build test`
  runs the compiler-core and language-server binaries at the same time. Use an
  absolute path (each binary runs in its own module directory); start from an
  empty file. Unset, nothing is opened. Ignored on Windows.
- Consume it with `scripts/snap_audit.sh --mode=orphans --trace=<file>` (orphan
  list) and `--mode=review --trace=<file>` (the review worksheet); see
  [`scripts/AGENTS.md`](../../../../scripts/AGENTS.md#snap_auditsh).
