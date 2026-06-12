# server — HTTP backing (node `http`)

> Path: `libs/server/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)

A **framework-agnostic, minimal HTTP server** for botopink, behind `#[@external]`
host calls. Reached via `from "server"`; **not** embedded into the compiler. It
is the transport rakun's `Rakun.run` starts (graduated from scaffold to real in
rakun F5), but it names no framework — `serve` takes the dispatcher as a plain
function, so the dependency runs **rakun → server**, never the reverse.

## What it provides

- `serverServe<R>(port, handler) -> i32` — start a node-`http` server on `port`.
  `handler` is the request dispatcher: `(method, path, headersJson, queryJson,
  body) -> R`. Headers and the query string arrive JSON-encoded (the boundary
  stays scalar — no map types cross it); the server reads `R.status` / `R.body`
  off the returned value to write the reply. Generic over `R` so the server is
  decoupled from any framework's `Response` type.
- `serverStop() -> i32` — close the listening socket.

The real IO lives in `src/server.mjs` (the node-`http` server); `src/server.bp`
is the `#[@external]` seam binding it.

## Loading notes

The `#[@external]` path is the **sibling** `./server.mjs`. The CLI ships the
runtime `.mjs` next to every emitted module (**G2**,
`compiler-cli/src/cli/libs.zig#shipMjsSidecars`), so `require("./server.mjs")`
resolves both in the lib's own build and in a consumer's `botopink build` output.
Node first; an Erlang/BEAM transport (`gen_tcp`/`inets`/`cowboy`) is a follow-up.

## See also

- The framework that composes it → [`../../../rakun/docs.md`](../../../rakun/docs.md) (sibling project).
- The runnable end-to-end app → [`../../../rakun/examples/rakun/`](../../../rakun/examples/rakun/).
- The `.bp` libraries group contract → [`../AGENTS.md`](../AGENTS.md).
