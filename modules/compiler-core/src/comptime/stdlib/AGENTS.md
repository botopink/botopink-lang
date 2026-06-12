# comptime/stdlib

> Path: `modules/compiler-core/src/comptime/stdlib/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Stdlib sources: [`../../../../../libs/std/src/AGENTS.md`](../../../../../libs/std/src/AGENTS.md)

Embed/loader glue for the botopink standard library. The `.bp`/`.d.bp` sources
live under `libs/std/src/` (which is `.bp`-only); this directory holds the Zig
side that bundles them into the compiler.

## Tree

```text
stdlib/
├── AGENTS.md          ← you are here
└── prelude.zig        ← root of the `std_prelude` Zig module; one
                          `pub const <name> = @embedFile("<name>.bp")` per file
```

## Wiring

- The root `build.zig` declares the `std_prelude` module with `prelude.zig` as
  its root and exposes each `libs/std/src/*.bp` file as an **anonymous import**
  (`std_bp_files` list) — required because the `.bp` sources sit outside this
  module's root, so a relative `@embedFile` path would be rejected
  (`embed of file outside package path`).
- Consumer: `comptime.zig`'s `registerStdlib(&env, gpa)` imports `std_prelude`
  and lexes/parses/infers each embedded source into the type `Env`.

## Conventions

- Adding a stdlib file = three lines total: the `.bp` in `libs/std/src/`,
  one entry in `std_bp_files` (root `build.zig`), one `pub const` here.
- No stdlib logic here — only embedding. Parsing/registration stays in
  `comptime.zig`.
