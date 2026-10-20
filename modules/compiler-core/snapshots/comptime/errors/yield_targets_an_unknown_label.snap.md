----- SOURCE CODE
iter fn gen() -> Iter<i32> {
    yield :nope 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ main.bp:2:5
  │
2 │     yield :nope 1;
  │     ^

  hint: Label a generator fn (`iter fn … -> Iter<T> :name`) or a prefixed loop (`iter loop :name { … }`).
