# stdlib — embedded standard library

> Path: `modules/stdlib/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`src/examples.md`](src/examples.md)
> Parent: [`../docs.md`](../docs.md)

The botopink standard library. Declarations are written in `.bp`, embedded
as compile-time strings via `@embedFile`, and registered into the
type-inference `Env` before each pass.

## Tree

```text
stdlib/
├── botopink.json      ← package metadata
└── src/               ← .bp source files + prelude.zig
    ├── prelude.zig    ← @embedFile of every .bp into Zig const strings
    ├── primitives.bp  ← I32/U32/I64/U64/F32/F64/Bool interfaces
    ├── array.bp       ← generic Array<T> interface
    ├── string.bp      ← String interface
    └── builtins.bp    ← compiler/runtime builtins (typeOf, sizeOf, panic, …)
```

## How the stdlib reaches the compiler

```text
stdlib/src/prelude.zig       (@embedFile bundles)
            │
            ▼
compiler-core/src/comptime/env.zig
            │  registerStdlib(&env, gpa)
            ▼
        type Env populated
            │
            ▼
        inferProgramTyped(...)
```

`compiler-core/src/comptime/env.zig` calls
`inferMod.registerStdlib(&env, gpa)` before each inference pass. That
helper imports `stdlib.prelude` and registers every embedded `.bp` string
into the type environment. By the time user code is type-checked the
stdlib is already in scope.

## Why interfaces, not implementations

stdlib `.bp` files declare **interfaces only** — method signatures, no
bodies. The actual implementations land in target output through codegen
(JS uses host `Array` / `String`; Erlang uses lists / binaries). This
keeps the compiler's surface stable across targets while letting each
backend emit idiomatic code.

```text
// stdlib/src/array.bp
interface Array<T> {
    fn length(): i32,
    fn at(i: i32): T,
    // …
}
```

Adding a method here = signature only. Codegen translates the call to the
appropriate target idiom.

## Conventions

| Rule | Why |
|---|---|
| Keep declarations stable and additive | Any rename forces snapshot churn across every codegen/comptime suite |
| Adding a `.bp` file → also add `pub const <name> = @embedFile("<name>.bp");` in `prelude.zig` | Otherwise inference will not see it |
| Keep interfaces declarative (no method bodies) | The type checker consumes them; codegen knows the implementations |

## What the stdlib currently exposes

| File | Highlights |
|---|---|
| `primitives.bp` | `interface I32 { fn to_string(): string, fn abs(): i32, fn max(o: i32): i32, … }`, plus `U32`, `I64`, `U64`, `F32`, `F64`, `Bool` |
| `array.bp` | `Array<T>` with `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter` |
| `string.bp` | `String` with `len`, `split`, `to_upper`/`to_lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string` |
| `builtins.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`) |

Concrete usage snippets: [`src/examples.md`](src/examples.md).

## See also

- The Zig wiring → [`src/docs.md`](src/docs.md).
- How HM inference uses these declarations →
  [`../compiler-core/src/comptime/docs.md`](../compiler-core/src/comptime/docs.md).
- Codegen translates stdlib calls per target →
  [`../compiler-core/src/codegen/docs.md`](../compiler-core/src/codegen/docs.md).
