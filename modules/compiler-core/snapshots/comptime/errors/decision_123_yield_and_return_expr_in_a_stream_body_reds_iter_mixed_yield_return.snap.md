----- SOURCE CODE
fn nums() -> @Stream<@Result<i32, string>> {
    yield 1;
    return 42;
}

----- ERROR
error: iter-mixed-yield-return: this body yields, so it is an iterator — and `return <value>` answers a ready one, which is a factory (decision 123)
  ┌─ :3:5
  │
3 │     return 42;
  │     ^

  hint: Pick one: keep the `yield`s and end with `break <v>` / `break`, or drop them and `return` the iterator (`return iter for (xs) { x -> … };`).
