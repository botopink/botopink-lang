----- SOURCE CODE
#[compiler.external(.Erlang("max($args)", inline: 1))]
pub declare fn biggest(a: i32, b: i32) -> i32;

import {compiler} from "std";

----- ERROR
error: type mismatch
  ┌─ main.bp:1:51
  │
1 │ #[compiler.external(.Erlang("max($args)", inline: 1))]
  │                                                   ^

  expected: bool
  found:    i32
