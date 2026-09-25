----- SOURCE CODE
#[@generator]
fn nums() -> @Generator<i32, void> {
    yield 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@Generator` takes at most 1 type argument, 2 given
  ┌─ :2:14
  │
2 │ fn nums() -> @Generator<i32, void> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
