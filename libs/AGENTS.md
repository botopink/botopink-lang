# libs/

> Path: `libs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Code written **in** botopink that ships with the language core, kept separate
from the Zig toolchain under [`../modules/`](../modules/AGENTS.md). The
dependency arrow runs one way: the compiler embeds the **bundled packages** —
`libs/std` and the libraries named in `build.zig`'s `bundled_packages`
(decisions 115–117) — and a lib never depends on toolchain internals.

A bundled package is imported by name (`from "routing"`) with no `dependencies`
entry, from the copy inside the compiler binary; listing one in `dependencies`
is refused. Every bundled library besides `std` is `.bp` only (target-native
code is an inline `#[@External.…]` template — no `.erl`/`.mjs`; `build.zig`
refuses a non-`.bp` `files` entry), runs on erlang and commonJS (erlang first in
`targets`), and imports `std` and other bundled packages only. Adding one is:
the directory with its `botopink.json` + `AGENTS.md`, its name in
`build.zig`'s `bundled_packages` (after every bundled package it imports), a row
below, and its directory in `scripts/format-check.sh`'s `TREES`.

The other libraries (`emilia`, `erika`, `jhonstart`, `onze`, `rakun`) are sibling
projects under `repository/` in the meta workspace, reached via `from "<name>"`
through the multi-root resolver (`BOTOPINK_LIB_ROOTS`, then
`repository/botopink-lang/libs`, `repository/`, `libs/` — see
`modules/compiler-cli/src/cli/libs.zig`).

## Tree

```text
libs/
├── AGENTS.md          ← you are here
├── std/               ← standard library (embedded in the compiler)
├── routing/           ← bundled route matcher + routing wires (decision 115)
└── actions/           ← bundled server-action protocol (decision 116)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | primitive interfaces, builtins, and the importable `std` modules | yes — `build.zig` embeds the files; `modules/compiler-core/src/comptime/stdlib/prelude.zig` exposes them | [link](std/AGENTS.md) |
| `routing/` | the route matcher and the routing wires both halves run — route table, `k`/`z` blobs, URL rules, navigation signals (`nav:`), the `:param` grammar; pure `.bp`, erlang + commonJS, imports std only | yes — bundled by name (decision 115, `01-std/04-routing-lib` Step 2) | [link](routing/AGENTS.md) |
| `actions/` | the server-action protocol both halves read and write — the `state` grammar and `ActionState`, the v1 envelope (`redirect` derived from `n`), the JSON-RPC body, `refresh`; pure `.bp`, erlang + commonJS, imports std and routing only, names no field or header | yes — bundled by name (decision 116, `01-std/05-actions-lib` Step 6) | [link](actions/AGENTS.md) |

## Conventions

- Packages here are `.bp`-only — no Zig under `libs/`. Embed/loader glue lives
  in `build.zig` (`bundled_packages`, the generated table) and
  `modules/compiler-core/src/comptime/stdlib/prelude.zig`; the CLI
  (`compiler-cli/src/cli/libs.zig`) and the LSP (`language-server/src/project_graph.zig`)
  load a non-std bundled package's modules as `<pkg>/<stem>`.
- Each package has its own `botopink.json` and `AGENTS.md`; update the
  `AGENTS.md` in the same change that touches the package's layout or contents.
- Library-specific code never goes into `modules/compiler-core` (enforced by the
  lib-agnostic gate in `zig build test`).

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
