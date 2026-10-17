----- SOURCE CODE
#[@External.Typescript("Math.max($args)", true)]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `External.Typescript` takes no bare `true` — its flags are labelled, `result:` (decision 487)
  ┌─ main.bp:1:43
  │
1 │ #[@External.Typescript("Math.max($args)", true)]
  │                                           ^

  hint: Write the flag by its label: `result: true`, or `inline: true` on `External.Erlang`.
