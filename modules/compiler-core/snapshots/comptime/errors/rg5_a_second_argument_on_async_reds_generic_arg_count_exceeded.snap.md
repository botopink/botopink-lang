----- SOURCE CODE
async fn nums() -> Async<i32, string> {
    return 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@Async` takes at most 1 type argument, 2 given
  ┌─ main.bp:1:20
  │
1 │ async fn nums() -> Async<i32, string> {
  │                    ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
