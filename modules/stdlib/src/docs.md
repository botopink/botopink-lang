# stdlib/src — registry & per-file roles

> Path: `modules/stdlib/src/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)
> Parent: [`../docs.md`](../docs.md)

Single registry directory: `prelude.zig` exposes every `.bp` file as a
compile-time string consumed by `compiler-core`'s type inference. Adding a
new stdlib module = drop a `.bp` here + one line in `prelude.zig`.

## Tree

```text
src/
├── prelude.zig        ← @embedFile of every .bp file
├── primitives.bp      ← numeric + bool interfaces
├── array.bp           ← generic Array<T> interface
├── string.bp          ← String interface methods
└── builtins.bp        ← @typeOf / @sizeOf / @panic / @typeName / …
```

## `prelude.zig` shape

```zig
pub const primitives = @embedFile("primitives.bp");
pub const array      = @embedFile("array.bp");
pub const string     = @embedFile("string.bp");
pub const builtins   = @embedFile("builtins.bp");
```

That's the entire file — one `pub const` per `.bp`. Adding a `.bp` means
adding exactly one line here.

## Per-file roles

| File | What it declares |
|---|---|
| `primitives.bp` | `interface I32 { … }`, `U32`, `I64`, `U64`, `F32`, `F64`, `Bool`. Numeric methods: `to_string`, `abs`, `min`, `max`, `as<T>`. Bool methods: `to_string`. |
| `array.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.bp` | `interface String` — `len`, `split`, `to_upper`/`to_lower`, `contains`, `starts_with`, `ends_with`, `trim`/`trim_left`/`trim_right`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `builtins.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`). |

## Declarative style — no bodies

```text
// ✅ valid stdlib declaration
interface String {
    fn len(): i32,
    fn to_upper(): string,
}

// ❌ stdlib files must not contain method bodies
interface String {
    fn len(): i32 = self.bytes.length()    // ← no
}
```

The type checker consumes the signatures; the actual implementations come
from each codegen target. JS uses host `String.prototype`; Erlang uses
binaries + `string` module functions.

## Adding a stdlib module — step-by-step

1. Create `src/<name>.bp` with `interface <Name> { … }` declarations.
2. Add `pub const <name> = @embedFile("<name>.bp");` to `prelude.zig`.
3. Run `zig build test` from `modules/compiler-core/` — expect snapshot
   churn under `snapshots/comptime/` (the type env now contains a new
   binding).
4. Promote the `.snap.md.new` files after reviewing the diffs.
5. If the new module is user-facing, mention it in the language
   reference [`../../../docs.md`](../../../docs.md).

## Conventions

- Keep declarations stable and additive — every rename forces snapshot
  churn across every codegen/comptime suite.
- Interfaces must stay declarative (no method bodies) — they are consumed
  by the type checker, not codegen.
- Generic parameters use `<T>`, `<K, V>` — the type checker handles
  instantiation per call site.

## See also

- Stdlib usage in user code → [`./examples.md`](examples.md).
- Wider stdlib design → [`../docs.md`](../docs.md).
- Type-env wiring → [`../../compiler-core/src/comptime/docs.md`](../../compiler-core/src/comptime/docs.md).
