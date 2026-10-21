----- SOURCE CODE
#[compiler.external(.JavaScript("Math.max($args)", inline: true))]
pub declare fn biggest(a: i32, b: i32) -> i32;

import {compiler} from "std";

----- ERROR
error: `Implementation.JavaScript` has no parameter named `inline`
  ┌─ main.bp:1:32
  │
1 │ #[compiler.external(.JavaScript("Math.max($args)", inline: true))]
  │                                ^

  hint: A label names the parameter its argument fills.
