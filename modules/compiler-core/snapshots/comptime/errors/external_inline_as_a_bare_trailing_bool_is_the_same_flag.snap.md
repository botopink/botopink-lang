----- SOURCE CODE
#[@External.Typescript("Math.max($args)", true)]
pub declare fn biggest(a: i32, b: i32) -> i32;

----- ERROR
error: `External.Typescript` declares no `inline` — the flag is read by the erlang and beam emitters from `External.Erlang` only
  ┌─ main.bp:1:3
  │
1 │ #[@External.Typescript("Math.max($args)", true)]
  │   ^

  hint: Delete it: on `External.Typescript` `inline` is a switch nothing reads. `External.Erlang` alone declares it (`builtins.d.bp`).
