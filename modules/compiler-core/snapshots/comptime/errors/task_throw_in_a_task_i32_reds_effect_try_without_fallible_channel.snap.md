----- SOURCE CODE
fn fetch() -> @Task<i32> {
    throw "boom";
}

----- ERROR
error: effect-try-without-fallible-channel: `throw` needs a `@Result` in some layer of the return — this fn returns `@Task<…>` with no `@Result` in it
  ┌─ main.bp:2:5
  │
2 │     throw "boom";
  │     ^

  hint: Put a `@Result` in the return (`-> @Result<T, E>`, `-> @Task<@Result<T, E>>`, `-> @Iterator<@Result<T, E>>`, …) or handle the failure where it happens.
