----- SOURCE CODE
pub fn add(a: i32, b: i32) -> i32 {
    panic("not implemented");
}
val bad = add(1);

import {failure.panic} from "std";

----- ERROR
error: arity mismatch
  ┌─ main.bp:4:11
  │
4 │ val bad = add(1);
  │           ^

  'add' expected 2 argument(s), got 1
