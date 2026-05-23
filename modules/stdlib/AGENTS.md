# stdlib

> Path: `modules/stdlib/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/examples.md`](src/examples.md)

Botopink standard library. Declarations (`.bp`) are embedded as compile-time
strings and loaded by `compiler-core` into the type environment during
inference.

## Tree

```text
stdlib/
├── AGENTS.md          ← you are here
├── docs.md            ← how the stdlib reaches the compiler + conventions
├── botopink.json      ← package metadata
└── src/               ← .bp source files + prelude.zig — see src/AGENTS.md
    ├── prelude.zig    ← @embedFile of every .bp into Zig const strings
    ├── primitives.bp  ← I32/U32/I64/U64/F32/F64/Bool interfaces
    ├── array.bp       ← generic Array<T> interface
    ├── string.bp      ← String interface
    └── builtins.bp    ← compiler/runtime builtins (typeOf, sizeOf, panic, …)
```

## Wiring

`comptime/env.zig` calls `inferMod.registerStdlib(&env, gpa)` before each
inference pass. That helper imports `stdlib.prelude` and registers every
embedded `.bp` string into the type `Env`.

## Conventions

- Keep stdlib signatures backward-compatible whenever possible.
- Any rename or removal must be reflected in the codegen/comptime snapshots
  under [`../compiler-core/snapshots/`](../compiler-core/snapshots/AGENTS.md).
- When adding a new `.bp` file, also add a matching `@embedFile` constant in
  `src/prelude.zig`.
