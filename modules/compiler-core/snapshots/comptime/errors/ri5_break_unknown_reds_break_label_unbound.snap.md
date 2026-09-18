----- SOURCE CODE
#[@iterator]
fn nums() -> @Iterator<i32, string, i32> :outer {
    yield 1;
    break :nonsense 42;
}

----- ERROR
error: break-label-unbound: `break :<label>` targets an unknown label
  ┌─ :4:5
  │
4 │     break :nonsense 42;
  │     ^

  hint: Label a loop (`loop :name (...)`) or an iterator/asyncGenerator fn (`#[@iterator] fn … -> @Iterator<…> :name`).
