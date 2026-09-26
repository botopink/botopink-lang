----- SOURCE CODE
val a: bool = case 42 { 0 -> "a"; _ -> "b"; };

----- ERROR
error: type mismatch
  ┌─ main.bp:1:15
  │
1 │ val a: bool = case 42 { 0 -> "a"; _ -> "b"; };
  │               ^

  expected: bool
  found:    string
