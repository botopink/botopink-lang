# comptime/stdlib

> Path: `modules/compiler-core/src/comptime/stdlib/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Stdlib: [`../../../../../libs/std/AGENTS.md`](../../../../../libs/std/AGENTS.md)

Embed glue for the botopink standard library. The `.bp`/`.d.bp` sources live
under `libs/std/src/`; this directory holds the Zig side that bundles them into
the compiler.

## Tree

```text
stdlib/
├── AGENTS.md          ← you are here
└── prelude.zig        ← root of the `std_prelude` Zig module
```

## `prelude.zig` exports

| Const | Source | Consumer |
|---|---|---|
| `primitives` | `primitives.bp` | `registerStdlib` — flattened into the global env |
| `builtins` | `builtins.d.bp` | doc/tooling surface (not parsed by `registerStdlib`) |
| `builtin_fns` | `builtins_fns.d.bp` | `registerStdlib` → `env.stdlibFnDecls` |
| `pkg_modules` | generated `std_pkg` module | `comptime.zig std_pkg_modules` — the `import {…} from "std"` registry |

## Wiring

- `build.zig` declares `std_prelude` with `prelude.zig` as root and exposes each
  embedded file as an **anonymous import** (the sources sit outside the module
  root, so a relative `@embedFile` would be rejected): `std_core_files`
  (primitives / builtins / builtins_fns).
- The "std" package modules are derived from `libs/std/src/root.bp` (one
  `pub mod <name>;` per module, read by `stdPkgFilesFromRoot` in the workspace
  root `build.zig`), which generates `std_pkg_modules.zig`
  (`pkg_modules: []{ path = "std/<name>", source }`) as the `std_pkg` module that
  `prelude.zig` re-exports. It is the only list of std modules.

## Conventions

- Adding a std package module: drop `libs/std/src/<name>.bp` and add
  `pub mod <name>;` to `root.bp`. Nothing under this directory changes.
- Adding a core/internal file: add it to the matching list in `build.zig` and a
  `pub const … = @embedFile(…)` here.
- No stdlib logic here — only embedding. Parsing/registration stays in
  `comptime.zig`.
