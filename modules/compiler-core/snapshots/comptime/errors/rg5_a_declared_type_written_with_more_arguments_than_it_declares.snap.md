----- SOURCE CODE
type Box<T>(value: T)
fn open(b: Box<i32, string>) -> i32 {
    return 0;
}

----- ERROR
error: generic-arg-count-exceeded: `Box` takes at most 1 type argument, 2 given
  ┌─ :2:12
  │
2 │ fn open(b: Box<i32, string>) -> i32 {
  │            ^

  hint: Drop the extra type argument: the type declares no parameter for it.
