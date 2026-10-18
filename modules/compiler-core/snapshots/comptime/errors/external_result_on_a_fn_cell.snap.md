----- SOURCE CODE
fn absBody(x: i32) -> i32 { if (x < 0) { -x } else { x } }

#[compiler.external(.JavaScript(body: absBody, result: true), .Erlang("erlang:abs($0)"))]
pub declare fn magnitude(x: i32) -> i32;

import {compiler} from "std";

----- ERROR
error: `magnitude`'s `.JavaScript(body: …)` takes no `result:` — a `body:` cell is not a host call that can fail (decision 491)
  ┌─ main.bp:3:3
  │
3 │ #[compiler.external(.JavaScript(body: absBody, result: true), .Erlang("erlang:abs($0)"))]
  │   ^

  hint: Delete `result:`; a host call that can fail is a template binding, or a `wasi:` or `std:` cell on `.Wasm`.
