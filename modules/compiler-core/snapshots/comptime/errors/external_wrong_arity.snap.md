----- SOURCE CODE
#[@external(.Erlang("string", "length"))]
pub declare fn str_length(s: string) -> i32;

----- ERROR
error: `.Erlang` on `str_length` writes a second cell, `body:` — a binding is one cell (decision 481)
  ┌─ main.bp:1:31
  │
1 │ #[@external(.Erlang("string", "length"))]
  │                               ^

  hint: A binding is one labelled cell: `body: <private fn of this module>` or a template on every target; on wasm also `op: "<opcode>"`, `wasi: .<Adapter>` or `std: "<module>.<function>"` (std's alone).
