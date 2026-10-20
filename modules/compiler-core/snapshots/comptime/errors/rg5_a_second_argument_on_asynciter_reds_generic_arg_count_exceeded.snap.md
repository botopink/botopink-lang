----- SOURCE CODE
async iter fn nums() -> AsyncIter<i32, string> {
    yield 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@AsyncIter` takes at most 1 type argument, 2 given
  ┌─ main.bp:1:25
  │
1 │ async iter fn nums() -> AsyncIter<i32, string> {
  │                         ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
