----- SOURCE CODE
fn main() -> void {
    val answer = 42;
    val assert 42 = answer catch fallback;
    print(answer);
}

import {io.terminal.print} from "std";

----- ERROR
error: unbound variable
  ┌─ main.bp:3:34
  │
3 │     val assert 42 = answer catch fallback;
  │                                  ^

  'fallback' is not in scope
