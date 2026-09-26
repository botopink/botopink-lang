----- SOURCE CODE
fn nums() -> @Task<i32, string> {
    return 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@Task` takes at most 1 type argument, 2 given
  ┌─ main.bp:1:14
  │
1 │ fn nums() -> @Task<i32, string> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
