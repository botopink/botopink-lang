----- SOURCE CODE
#[@resultGenerator]
fn gen() -> @ResultGenerator<i32> {
    yield :nope 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ :3:5
  │
3 │     yield :nope 1;
  │     ^

  hint: Label a generator fn (`#[@resultGenerator] fn … -> @ResultGenerator<T> :name`) or a `loop :name (...)`.
