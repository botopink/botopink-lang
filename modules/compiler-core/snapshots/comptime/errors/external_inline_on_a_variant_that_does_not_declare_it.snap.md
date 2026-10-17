----- SOURCE CODE
#[@external(.Node("Math.max($args)", inline: true))]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `Implementation.Node` has no parameter named `inline`
  ┌─ main.bp:1:18
  │
1 │ #[@external(.Node("Math.max($args)", inline: true))]
  │                  ^

  hint: A label names the parameter its argument fills.
