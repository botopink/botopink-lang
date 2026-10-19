# Decision 363 — A browser-only cell is `#[clientOnly]`: called only where the client runs, never given a server twin.

The example has a browser-only hook. `linkStatus` reads a commonJS-only host binding, `readStatus`, and is `#[clientOnly]`. The build layer ([draft/comptime/stages.bp](draft/comptime/stages.bp)) declares that marker, the island marker `client`, and `page`, which walks the page's hooks list and refuses, at the `use`, a `#[clientOnly]` hook reached from a component that is not a `#[client]` island.

[draft/pages.bp](draft/pages.bp) uses `linkStatus` twice. In `Status`, a `#[client]` island, the use is legal: that component renders only in the browser, so the server build never emits it nor the binding, and no erlang twin answering an empty truth exists. In `Nav`, which the server renders, the same `use linkStatus()` is refused at the `use`. A server-rendered link reads no hook: its pending state is an attribute the client router sets, styled with CSS. The program never builds.

Cells in this repository that bear on it: `modules/decl_hooks_context`, `modules/external_wasm_host_beside_unhosted`.

[draft/main.bp](draft/main.bp)
