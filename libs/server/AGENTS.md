# server

> Path: `libs/server/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

A **framework-agnostic HTTP backing** for botopink — a real, minimal node-`http`
server behind `#[@external]` host calls. Reached via `from "server"`; **not**
embedded into the compiler (no `prelude.zig` / `build.zig` wiring). It knows
nothing about rakun: `serve(port, handler)` takes the framework's request
dispatcher as a plain function, so the dependency arrow runs **rakun → server**,
never the reverse. Graduated from scaffold to real in rakun **F5**.

## Tree

```text
server/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib provides + loading notes
├── botopink.json      ← package metadata (files: ["server.bp"])
└── src/               ← see src/AGENTS.md
    ├── root.bp        ← module-tree root: `pub mod server;`
    ├── server.bp      ← `#[@external]` decls binding `server.mjs` (`serverServe`/`serverStop`)
    └── server.mjs     ← host runtime: the node-`http` server (`serve`/`stop`)
```

## Module tree (`root.bp`)

`src/root.bp` declares the single real module `pub mod server;` (→ `server.bp`),
which is **also** listed in `botopink.json` `files` so a `from "server"` consumer
resolves it. There is no `.d.bp` — the surface is real, emitted code.

## How it works

- `server.bp` declares `serverServe<R>(port, handler) -> i32` and
  `serverStop() -> i32` as `#[@external(node, "./server.mjs", …)]`. The handler is
  `(method, path, headersJson, queryJson, body) -> R`, **generic over the response
  value** `R` so the server stays decoupled from any framework's `Response` type
  (it only reads `R.status` / `R.body`).
- `server.mjs` is the node-`http` server: on each request it decodes the socket
  into those scalars (headers + query JSON-encoded so the boundary stays scalar),
  calls `handler`, and writes back `{ status, body }`.
- The `#[@external]` path is the **sibling** `./server.mjs`; the CLI ships the
  `.mjs` next to every emitted module (**G2**, `libs.zig#shipMjsSidecars`), so
  `require("./server.mjs")` resolves in both the lib's own and a consumer's build.

## Conventions

- Framework-agnostic: `server` names no framework; rakun composes it.
- Host state / IO behind `#[@external]` in `server.mjs`; the core never sees it.
- Node first; the Erlang/BEAM transport (`gen_tcp`/`inets`/`cowboy`) is a recorded
  follow-up.
- Keep this file in sync with `docs.md`, `src/AGENTS.md`, and the rakun spec.
