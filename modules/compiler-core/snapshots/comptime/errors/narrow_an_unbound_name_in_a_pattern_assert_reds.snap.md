----- SOURCE CODE
fn main() -> void {
    val assert 42 = answer catch 0;
    print("unreachable");
}

import {io.terminal.print} from "std";

----- ERROR
error: unbound variable
  ┌─ main.bp:2:21
  │
2 │     val assert 42 = answer catch 0;
  │                     ^

  'answer' is not in scope
