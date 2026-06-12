# libs/

> Path: `libs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Code written **in** botopink — the **bundled** `.bp` libraries shipped with
the language core, kept separate from the Zig/TS toolchain under
[`../modules/`](../modules/AGENTS.md). The dependency arrow runs one way:
`modules/compiler-core` consumes `libs/std`; a lib never depends on the
toolchain's internals.

The **frameworks** (`erika`, `jhonstart`, `onze`, `rakun`) live as sibling
projects under `repository/` — not here. They are reached via `from "<name>"`
through the multi-root resolver (the resolver walks `repository/botopink-lang/libs`
then `repository/` then a legacy `libs/`). See the [workspace
overview](../../AGENTS.md) for the per-project entry points.

Each library is a package with its own `botopink.json` and `AGENTS.md`,
mirroring the shape of `std/`.

## Tree

```text
libs/
├── AGENTS.md          ← you are here
├── std/               ← standard library (embedded prelude + interfaces)
├── server/            ← framework-agnostic HTTP backing (real node-`http`, `from "server"`)
└── client/            ← client-side interfaces (scaffold)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | builtin types, primitives, Array/String, builtins — loaded into the type `Env` at infer time | yes (`modules/compiler-core/src/comptime/stdlib/prelude.zig`, wired in root `build.zig`) | [link](std/AGENTS.md) |
| `server/` | framework-agnostic HTTP backing — node-`http` server (`serverServe`/`serverStop`) behind `#[@external]` | no — reached via `from "server"` (real; rakun's transport) | [link](server/AGENTS.md) |
| `client/` | HTTP client / request interfaces | no — inert scaffold | [link](client/AGENTS.md) |

## Conventions

- `.bp` declarations stay declarative — interface/method **signatures only**, no
  bodies. Codegen supplies implementations per target.
- Only `std` is embedded today. `client` is still a scaffold; `server` is a real
  **application-level** lib reached via `from "server"`, opted into per project,
  never prelude-embedded or wired into `build.zig`. Embedding a lib into stdlib
  loading / the type `Env` is a deliberate, separate task.
- Packages here are `.bp`-only — no Zig under `libs/`. The embed/loader glue
  lives in `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- Framework libs (`erika`/`jhonstart`/`onze`/`rakun`) are siblings under
  `repository/`, not here — extracting them keeps the language core
  framework-agnostic and lets each framework ship + version independently.
- Every directory ships its own `AGENTS.md`; update it in the same change that
  touches the directory's layout or contents.

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
