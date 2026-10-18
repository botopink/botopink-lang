----- SOURCE CODE
type D(id: i32)
fn main() {
    val d = D(id: 1);
    print(d.swim());
}

import {io.terminal.print} from "std";

----- ERROR
error: unknown method
  ┌─ main.bp:4:13
  │
4 │     print(d.swim());
  │             ^

  'swim' is not declared in any behavior implemented for 'D'
