----- SOURCE CODE
#[@generator]
fn nums() -> @Generator<i32> :outer {
    yield :nonsense 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ :3:5
  │
3 │     yield :nonsense 1;
  │     ^

  hint: Label a generator fn (`#[@resultGenerator] fn … -> @ResultGenerator<T> :name`) or a `loop :name (...)`.
