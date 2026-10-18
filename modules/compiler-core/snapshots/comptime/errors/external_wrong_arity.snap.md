----- SOURCE CODE
#[compiler.external(.Erlang("string", "length"))]
pub declare fn str_length(s: string) -> i32;

import {compiler} from "std";

----- ERROR
error: external-field-unlabelled: a cell's field is written by its label — write it by one of `.Erlang`'s labels: `body:`, `inline:`, `result:`
  ┌─ main.bp:1:39
  │
1 │ #[compiler.external(.Erlang("string", "length"))]
  │                                       ^

  hint: Only the template is written by position (`.Erlang("lists:reverse($0)")`); every other field by its label, in any order: `body:`, `inline:`, `result:`, and on `.Wasm` `op:`, `std:`, `wasi:`, `host:`, `needs:` (decision 621).
