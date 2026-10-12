----- SOURCE CODE
fn absBody(x: i32) -> i32 { if (x < 0) { -x } else { x } }

#[@External.Node(fn: absBody, result: true)]
pub declare fn magnitude(x: i32) -> i32;

----- ERROR
error: `magnitude`'s `External.Node(fn: …)` takes no `result:` — an `fn:` cell is not a host call that can fail (decision 491)
  ┌─ main.bp:3:3
  │
3 │ #[@External.Node(fn: absBody, result: true)]
  │   ^

  hint: Delete `result:`; a host call that can fail is a template binding, or a `wasi:` or `std:` cell on `External.Wasm`.
