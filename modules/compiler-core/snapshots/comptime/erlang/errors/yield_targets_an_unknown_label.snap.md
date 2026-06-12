----- SOURCE CODE
#[@iterator]
fn gen() -> @Iterator<i32> {
    yield :nope 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ :3:5
  │
3 │     yield :nope 1;
  │     ^

  hint: Label a generator fn (`#[@iterator] fn … -> @Iterator<T> :name`) or a `loop :name (...)`.
