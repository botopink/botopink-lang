----- SOURCE CODE
fn first(step: YieldStep<i32, string>) -> i32 {
    return 0;
}

----- ERROR
error: generic-arg-count-exceeded: `YieldStep` takes at most 1 type argument, 2 given
  ┌─ :1:16
  │
1 │ fn first(step: YieldStep<i32, string>) -> i32 {
  │                ^

  hint: `YieldStep<T>` is `{ Yield(value: T), Done }` (decision 122): an item that can fail is a `@Result`, so write `YieldStep<@Result<T, E>>`.
