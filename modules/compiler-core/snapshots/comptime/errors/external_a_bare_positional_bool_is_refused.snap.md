----- SOURCE CODE
#[@external(.JavaScript("Math.max($args)", true))]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: external-field-unlabelled: a cell's field is written by its label — write `result: true`
  ┌─ main.bp:1:44
  │
1 │ #[@external(.JavaScript("Math.max($args)", true))]
  │                                            ^

  hint: Only the template is written by position (`.Erlang("lists:reverse($0)")`); every other field by its label, in any order: `body:`, `inline:`, `result:`, and on `.Wasm` `op:`, `std:`, `wasi:`, `host:`, `needs:` (decision 621).
