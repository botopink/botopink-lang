----- SOURCE CODE
pub fn hello() -> string {
    panic("not implemented");
}
val bad = hello(42);

import {failure.panic} from "std";

----- ERROR
error: arity mismatch
  ┌─ main.bp:4:11
  │
4 │ val bad = hello(42);
  │           ^

  'hello' expected 0 argument(s), got 1
