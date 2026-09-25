----- SOURCE CODE
fn nums() -> @Stream<i32, string> {
    yield 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@Stream` takes at most 1 type argument, 2 given
  ┌─ :1:14
  │
1 │ fn nums() -> @Stream<i32, string> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
