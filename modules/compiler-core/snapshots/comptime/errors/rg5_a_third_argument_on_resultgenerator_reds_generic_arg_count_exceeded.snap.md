----- SOURCE CODE
#[@resultGenerator]
fn nums() -> @ResultGenerator<i32, string, i32> {
    yield 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@ResultGenerator` takes at most 2 type arguments, 3 given
  ┌─ :2:14
  │
2 │ fn nums() -> @ResultGenerator<i32, string, i32> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
