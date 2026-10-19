----- SOURCE CODE
fn nums() -> Iter<i32> {
    yield 1;
    throw "no";
}

----- ERROR
error: effect-try-without-fallible-channel: `throw` needs a `@Result` in some layer of the return — the item of `@Iter<T>` has to be `@Result<T, E>` to use `throw` / `try`; `try … catch` handles the failure on the spot, and a host binding answers a `@Result` with `result: true`
  ┌─ main.bp:3:5
  │
3 │     throw "no";
  │     ^

  hint: Put a `@Result` in the return (`-> @Result<T, E>`, `-> @Async<@Result<T, E>>`, `-> @Iter<@Result<T, E>>`, …) or handle the failure where it happens.
