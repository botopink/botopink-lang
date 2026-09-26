----- SOURCE CODE
fn run() -> i32 {
    throw "x";
}

----- ERROR
error: effect-try-without-fallible-channel: `throw` needs a `@Result` in some layer of the return — this fn's return has no `@Result` in it
  ┌─ main.bp:2:5
  │
2 │     throw "x";
  │     ^

  hint: Put a `@Result` in the return (`-> @Result<T, E>`, `-> @Task<@Result<T, E>>`, `-> @Iterator<@Result<T, E>>`, …) or handle the failure where it happens.
