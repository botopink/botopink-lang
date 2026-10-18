----- SOURCE CODE
pub fn double(x: i32) -> i32 {
    panic("not implemented");
}
val bad = double("hello");

import {failure.panic} from "std";

----- ERROR
error: type mismatch
  ┌─ main.bp:4:18
  │
4 │ val bad = double("hello");
  │                  ^

  expected: i32
  found:    string
