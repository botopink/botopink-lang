# stdlib/src

> Path: `modules/stdlib/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Source for the embedded stdlib. `prelude.zig` exposes each `.bp` file as a
compile-time string consumed by `compiler-core`'s type inference.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── docs.md            ← registry + per-file roles
├── examples.md        ← stdlib usage in `.bp` (Array, String, builtins)
├── prelude.zig        ← @embedFile of every .bp file
├── primitives.bp      ← numeric + bool interfaces
├── array.bp           ← generic Array<T> interface
├── string.bp          ← String interface methods
└── builtins.bp        ← @typeOf / @sizeOf / @panic / @typeName / …
```

## Files

| File | Role |
|---|---|
| `prelude.zig` | Zig module that re-exports every `.bp` source as a `pub const` string via `@embedFile`. |
| `primitives.bp` | `interface I32 { … }`, `interface U32 { … }`, …, `interface Bool { … }`. |
| `array.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.bp` | `interface String` — `len`, `split`, `to_upper/lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `builtins.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`). |

## Conventions

- Keep declarations stable and additive — renames force snapshot churn across
  every codegen/comptime suite.
- When adding a `.bp` file: also add a `pub const <name> = @embedFile("<name>.bp");`
  line to `prelude.zig`, otherwise inference will not see it.
- Interface declarations must stay declarative (no method bodies) — they're
  consumed by the type checker, not codegen.
