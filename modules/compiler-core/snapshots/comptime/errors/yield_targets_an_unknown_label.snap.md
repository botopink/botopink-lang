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

  hint: Label a generator fn (`fn … -> @Generator<T> :name`) or an annotated loop (`#[@generator] loop :name { … }`).
