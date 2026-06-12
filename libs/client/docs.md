# client — client-side interfaces (scaffold)

> Path: `libs/client/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)

A future home for botopink's client-side interfaces — HTTP client and request
declarations (request building, sending, response handling). Today it is an
inert **scaffold**: `botopink.json` claims no files, nothing is embedded into
the compiler, and the type environment does not load it.

## What it will provide (planned)

- HTTP client interfaces — request construction, send, response inspection.
- Request/response value types shared with server-side code where useful.

## Loading notes

Unlike `libs/std`, this package is **not** `@embedFile`'d into a `prelude.zig`
and is **not** wired into `build.zig`. Wiring it into stdlib loading / the type
`Env` is a deliberate follow-up task, undertaken once it declares real symbols.

## See also

- The embedded standard library → [`../std/docs.md`](../std/docs.md).
- The `.bp` libraries group contract → [`../AGENTS.md`](../AGENTS.md).
