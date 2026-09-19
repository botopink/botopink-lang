# libs/

> Path: `libs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Code written **in** botopink that ships with the language core, kept separate
from the Zig toolchain under [`../modules/`](../modules/AGENTS.md). The
dependency arrow runs one way: `modules/compiler-core` embeds `libs/std`; a lib
never depends on toolchain internals.

The other libraries (`emilia`, `erika`, `jhonstart`, `onze`, `rakun`) are sibling
projects under `repository/` in the meta workspace, reached via `from "<name>"`
through the multi-root resolver (`BOTOPINK_LIB_ROOTS`, then
`repository/botopink-lang/libs`, `repository/`, `libs/` — see
`modules/compiler-cli/src/cli/libs.zig`).

## Tree

```text
libs/
├── AGENTS.md          ← you are here
└── std/               ← standard library (embedded in the compiler)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | primitive interfaces, builtins, and the importable `std` modules | yes — `build.zig` embeds the files; `modules/compiler-core/src/comptime/stdlib/prelude.zig` exposes them | [link](std/AGENTS.md) |

## Conventions

- Packages here are `.bp`-only — no Zig under `libs/`. Embed/loader glue lives
  in `build.zig` and `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- Each package has its own `botopink.json` and `AGENTS.md`; update the
  `AGENTS.md` in the same change that touches the package's layout or contents.
- Library-specific code never goes into `modules/compiler-core` (enforced by the
  lib-agnostic gate in `zig build test`).

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
