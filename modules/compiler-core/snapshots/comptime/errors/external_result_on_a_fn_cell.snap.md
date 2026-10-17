----- SOURCE CODE
fn absBody(x: i32) -> i32 { if (x < 0) { -x } else { x } }

#[@external(.Node(body: absBody, result: true))]
pub declare fn magnitude(x: i32) -> i32;

----- ERROR
error: `magnitude`'s `.Node(body: …)` takes no `result:` — a `body:` cell is not a host call that can fail (decision 491)
  ┌─ main.bp:3:3
  │
3 │ #[@external(.Node(body: absBody, result: true))]
  │   ^

  hint: Delete `result:`; a host call that can fail is a template binding, or a `wasi:` or `std:` cell on `.Wasm`.
