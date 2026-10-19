----- SOURCE CODE
fn fetchCount(n: i32) -> Async<Result<i32, string>> {
    return n;
}
fn run() -> Async<Result<i32, string>> {
    val count: i32 = await fetchCount(3);
    return count;
}

----- ERROR
error: type mismatch
  ┌─ main.bp:5:22
  │
5 │     val count: i32 = await fetchCount(3);
  │                      ^

  expected: i32
  found:    Result<i32,string>
  hint: `await` answers the `@Result` the Async holds: write `try await t` to propagate its error, or handle it with `case` / `catch`
