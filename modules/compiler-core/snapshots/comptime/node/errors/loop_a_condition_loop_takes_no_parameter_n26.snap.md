----- SOURCE CODE
fn f() {
    var i = 0;
    loop (i < 3) { x ->
        i = i + 1;
    };
}

----- ERROR
error: a condition loop takes no parameter
  ┌─ :3:20
  │
3 │     loop (i < 3) { x ->
  │                    ^

  hint: `loop (condition) { … }` binds nothing; iterate a collection with `loop (xs) { x -> … }`.
