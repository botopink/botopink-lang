----- SOURCE CODE
pub behavior Shape {
    #[compiler.external(.Wasm("area", inline: true))]
    fn area(self: Self) -> i32;
}

import {compiler} from "std";

----- ERROR
error: `Implementation.Wasm` has no parameter named `inline`
  ┌─ main.bp:2:30
  │
2 │     #[compiler.external(.Wasm("area", inline: true))]
  │                              ^

  hint: A label names the parameter its argument fills.
