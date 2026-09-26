----- SOURCE CODE
fn nums() -> @Iterator<i32> :outer {
    yield :nonsense 1;
}

----- ERROR
error: yield-label-unbound: `yield` targets an unknown label
  ┌─ main.bp:2:5
  │
2 │     yield :nonsense 1;
  │     ^

  hint: Label a generator fn (`fn … -> @Iterator<T> :name`) or a prefixed loop (`iter loop :name { … }`).
