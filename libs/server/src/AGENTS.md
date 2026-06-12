# server/src

> Path: `libs/server/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`../docs.md`](../docs.md)

Source for the `server` library — a real, minimal node-`http` backing.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── root.bp            ← module-tree root: `pub mod server;`
├── server.bp          ← `#[@external]` decls: `serverServe<R>` / `serverStop` → server.mjs
└── server.mjs         ← host runtime: the node-`http` server (`serve`/`stop`)
```

## Conventions

- `server.bp` holds the `#[@external(node, "./server.mjs", …)]` `declare fn`s; the
  real IO lives in `server.mjs` (sibling path — the CLI ships it next to every
  emitted module via G2).
- `serve(port, handler)` is framework-agnostic: `handler` is the dispatcher
  function the consumer passes; the server never names a framework.
- Add new real `.bp` modules to `root.bp` (`pub mod`) **and** `../botopink.json`
  `files`.
