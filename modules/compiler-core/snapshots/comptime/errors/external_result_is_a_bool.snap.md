----- SOURCE CODE
#[compiler.external(.JavaScript("JSON.parse($0)", result: 1))]
pub declare fn jsParse(s: string) -> i32;

import {compiler} from "std";

----- ERROR
error: type mismatch
  ┌─ main.bp:1:59
  │
1 │ #[compiler.external(.JavaScript("JSON.parse($0)", result: 1))]
  │                                                           ^

  expected: bool
  found:    i32
