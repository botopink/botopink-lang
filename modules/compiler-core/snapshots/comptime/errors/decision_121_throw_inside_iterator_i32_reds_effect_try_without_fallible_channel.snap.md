----- SOURCE CODE
fn nums() -> @Iterator<i32> {
    yield 1;
    throw "no";
}

----- ERROR
error: effect-try-without-fallible-channel: `throw` needs a `@Result` in some layer of the return — the item of `@Iterator<T>` has to be `@Result<T, E>` to use `throw` / `try`
  ┌─ main.bp:3:5
  │
3 │     throw "no";
  │     ^

  hint: Put a `@Result` in the return (`-> @Result<T, E>`, `-> @Task<@Result<T, E>>`, `-> @Iterator<@Result<T, E>>`, …) or handle the failure where it happens.
