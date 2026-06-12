# compiler-core/src/utils — snapshot infrastructure

> Path: `modules/compiler-core/src/utils/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)

Snapshot-testing primitives shared by every test suite in the workspace —
parser, codegen, comptime, formatter, and the LSP. There is no
`examples.md` here because the module is purely internal; concrete
snapshot fixtures live next to each test file.

## Tree

```text
utils/
├── snap.zig        ← read/write/compare .snap.md files
├── pretty.zig      ← indented JSON serialiser (used for AST snapshots)
└── json_diff.zig   ← structural JSON diff printed on mismatch
```

## API surface

| Function | Role |
|---|---|
| `snap.checkText(alloc, name, content)` | Compare `content` against `<name>.snap.md`. On miss, write `<name>.snap.md.new` and return `error.SnapshotMismatch`. |
| `pretty.json(alloc, value)` | Serialise any Zig value to indented JSON. Used to render AST snapshots in a diff-friendly form. |
| `json_diff.render(io, expected, actual)` | Print a structural diff (field-by-field) when `checkText` fails. |

All three are small wrappers around `std.json`, `std.testing`, and
`std.fs`. The point is to keep the snapshot workflow consistent across
test suites — every suite reads/writes/compares the same way.

## Snapshot workflow

```text
test
  └─ checkText(...) 
        ├─ no existing .snap.md   → create it, mark first-run success
        ├─ matches existing       → pass
        └─ differs                → write .snap.md.new beside, print diff, FAIL
```

Reviewer-side workflow on a mismatch:

1. Inspect `*.snap.md.new` (or the diff in stderr).
2. **Accept**: replace the old `.snap.md` with the `.new` (or delete the
   `.snap.md` so the next run recreates it).
3. **Reject**: delete the `.new` file and fix the bug instead.

Never commit `.snap.md.new` files — they're intermediate artefacts.

## Indentation discipline

`pretty.json` always uses two-space indentation. The diff renderer is
character-sensitive, so any change to indentation rules cascades through
every snapshot. If you need to tweak indentation, expect to regenerate
every fixture in one large commit.

## Why these helpers are in `compiler-core/src/`

They were originally specific to the parser tests, but the language-server
test harness now reuses them ([`../../../language-server/src/tests/`](../../../language-server/src/tests/AGENTS.md)).
Keeping them in compiler-core avoids a circular dep — the LSP depends on
compiler-core but not the other way around.

## See also

- Compiler test suites that use these helpers:
  - [`../parser/AGENTS.md`](../parser/AGENTS.md)
  - [`../format/AGENTS.md`](../format/AGENTS.md)
  - [`../codegen/AGENTS.md`](../codegen/AGENTS.md)
  - [`../comptime/AGENTS.md`](../comptime/AGENTS.md)
- LSP test suite that reuses them:
  - [`../../../language-server/src/tests/AGENTS.md`](../../../language-server/src/tests/AGENTS.md)
