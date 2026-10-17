----- SOURCE CODE
#[@external(.Erlang("max($args)", inline: 1))]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: type mismatch
  ┌─ main.bp:1:43
  │
1 │ #[@external(.Erlang("max($args)", inline: 1))]
  │                                           ^

  expected: bool
  found:    i32
