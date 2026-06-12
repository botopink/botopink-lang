# client

> Path: `libs/client/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Client-side interfaces for botopink — HTTP client / request declarations written
in `.bp`. **Scaffold only:** this package is *not* embedded into the compiler
(no `prelude.zig`, no `build.zig` wiring) and declares no symbols yet. It exists
to anchor future client-side library code.

## Tree

```text
client/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib will provide + loading notes
├── botopink.json      ← package metadata (files: [] — claims nothing yet)
└── src/               ← .bp declarations — see src/AGENTS.md
    ├── root.bp        ← module-tree root (declaration-only scaffold: no `mod` yet)
    └── client.d.bp    ← placeholder declaration file (header only)
```

## Module tree (`root.bp`)

`src/root.bp` is the explicit module-tree root — the package builds from it, not
from a deprecated blind `src/` scan. It declares no `mod` yet: `client.d.bp` is a
declaration module wired through `botopink.json` `files` (consumer surface,
loaded with `.declaration = true` for a `from "client"` consumer), not the tree.
`.d.bp` modules are not resolved by `mod` paths (the resolver follows only
`<name>.bp` / `<name>/mod.bp`), the same way `libs/std` keeps its ambient `.d.bp`
out of `root.bp`. When the first real symbols land, drop `src/<name>.bp` + add
`pub mod <name>;` here.

## Conventions

- Interface declarations stay declarative (no method bodies), like `libs/std`.
- When the first real symbols land, list their `.bp` files in `botopink.json`
  and decide on compiler wiring (a separate, explicit task).
