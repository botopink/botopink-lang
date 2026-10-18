----- SOURCE CODE
#[@external(.JavaScript("JSON.parse($0)", result: 1))]
pub declare fn jsParse(s: string) -> i32;

----- ERROR
error: type mismatch
  ┌─ main.bp:1:51
  │
1 │ #[@external(.JavaScript("JSON.parse($0)", result: 1))]
  │                                                   ^

  expected: bool
  found:    i32
