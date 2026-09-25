----- SOURCE CODE
#[@generator]
fn nums() -> @Generator<i32, void> :outer {
    yield :nonsense 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ :3:5
  │
3 │     yield :nonsense 1;
  │     ^

  hint: Label a generator fn (`fn … -> @Generator<T> :name`) or an annotated loop (`#[@generator] loop :name { … }`).
