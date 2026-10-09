# libs/

> Path: `libs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Code written **in** botopink that ships with the language core, kept separate
from the Zig toolchain under [`../modules/`](../modules/AGENTS.md). The
dependency arrow runs one way: the compiler embeds `libs/std` — the **one**
bundled package (decision 326) — and a lib never depends on toolchain internals.

std is imported by name (`from "std"`) with no `dependencies` entry, from the
copy inside the compiler binary; listing it in `dependencies` is refused.

Every other library is a repository of its own — `routing`, `http`, `actions`,
`validation`, `log` (moved out of this directory with their history by
`03-bundled-libs/138`), `cardume`, `emilia`, `erika`, `jhonstart`, `onze`,
`rakun` — a sibling project under `repository/` in the meta workspace. A program
that imports one declares it in `dependencies` like any library (decision 242):

```json
"dependencies": { "routing": { "git": "https://github.com/botopink/routing.git", "branch": "feat" } }
```

Inside the meta checkout that entry resolves by name through the multi-root
resolver (`BOTOPINK_LIB_ROOTS`, then `repository/botopink-lang/libs`,
`repository/`, `libs/` — see `modules/compiler-cli/src/cli/libs.zig`), elsewhere
through the install store; without it, `from "routing"` is
`unresolved import source "routing" — declare it in botopink.json "dependencies"`.
A new shared package is born as a repository under the same rule — nothing in
this directory, `build.zig` or `scripts/format-check.sh` registers it.

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

- Packages here are `.bp`-only — no Zig under `libs/` but std's table generator,
  `std/tools/unicode-gen/` (decision 333 (A), run by `zig build gen-unicode`, never
  embedded — `std/AGENTS.md` § unicode). Embed glue lives in
  `build.zig` (the generated table, std its one row) and
  `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- The package has its own `botopink.json` and `AGENTS.md`; update the
  `AGENTS.md` in the same change that touches the package's layout or contents.
- Library-specific code never goes into `modules/compiler-core` (enforced by the
  lib-agnostic gate in `zig build test`).
- **A shared primitive lands in std first, and each copy is deleted by the
  owner of the file it sits in.** What two libraries need — a string → number
  parser, a reader over `json.Json`, a retry loop, a duration parser, a key
  derivation — is written once in `libs/std` (decisions 115–116: what is
  generic goes to std; `.bp` only, both targets, a `#[@External.<Target>]`
  template where a host is needed), under its natural name (decision 170). A
  library then calls std's and removes its own in a step of the front that owns
  that file — never the std front editing a library, and never a library
  growing a second copy while std lacks the first. A module that needs two
  declarations of one name meanwhile imports them under an alias.

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
