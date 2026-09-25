----- SOURCE CODE
#[@futureGenerator]
fn nums() -> @FutureGenerator<i32, string, i32> {
    yield 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@FutureGenerator` takes at most 2 type arguments, 3 given
  ┌─ :2:14
  │
2 │ fn nums() -> @FutureGenerator<i32, string, i32> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
