----- SOURCE CODE
iter fn nums() -> Iter<Result<i32, string>> :outer {
    yield 1;
    break :nonsense 42;
}

----- ERROR
error: break-label-unbound: `break :<label>` targets an unknown label
  ┌─ main.bp:3:5
  │
3 │     break :nonsense 42;
  │     ^

  hint: Label a loop (`for :name (…)`, `while :name (…)`, `loop :name {`) or a generator scope (`iter fn … -> Iter<…> :name`, `iter loop :name {`).
