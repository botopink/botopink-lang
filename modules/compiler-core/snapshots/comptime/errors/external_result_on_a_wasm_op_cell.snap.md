----- SOURCE CODE
#[@External.Wasm(op: "f64.floor", result: true)]
pub declare fn floor(x: f64) -> f64;

----- ERROR
error: `floor`'s `External.Wasm(op: …)` takes no `result:` — an `op:` cell is not a host call that can fail (decision 491)
  ┌─ main.bp:1:3
  │
1 │ #[@External.Wasm(op: "f64.floor", result: true)]
  │   ^

  hint: Delete `result:`; a host call that can fail is a template binding, or a `wasi:` or `std:` cell on `External.Wasm`.
