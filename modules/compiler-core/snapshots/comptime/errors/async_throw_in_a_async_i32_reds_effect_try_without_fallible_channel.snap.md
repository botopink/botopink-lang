----- SOURCE CODE
async fn fetch() -> Async<i32> {
    throw "boom";
}

----- ERROR
error: effect-try-without-fallible-channel: `throw` needs a `Result` in some layer of the return — this fn returns `Async<…>` with no `Result` in it; `try … catch` handles the failure on the spot, and a host binding answers a `Result` with `result: true`
  ┌─ main.bp:2:5
  │
2 │     throw "boom";
  │     ^

  hint: Put a `Result` in the return (`-> Result<T, E>`, `-> Async<Result<T, E>>`, `-> Iter<Result<T, E>>`, …) or handle the failure where it happens.
