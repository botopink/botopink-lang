----- SOURCE CODE
#[@resultGenerator]
fn nums() -> @ResultGenerator<i32, string> :outer {
    yield 1;
    break :nonsense 42;
}

----- ERROR
error: break-label-unbound: `break :<label>` targets an unknown label
  ┌─ :4:5
  │
4 │     break :nonsense 42;
  │     ^

  hint: Label a loop (`loop :name (...)`) or an iterator/futureGenerator fn (`#[@resultGenerator] fn … -> @ResultGenerator<…> :name`).
