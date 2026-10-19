----- SOURCE CODE
fn fetchCount() -> Async<i32> {
    return 3;
}
fn semAwait() -> Result<i32, string> {
    val x = await fetchCount();
    return x;
}

----- ERROR
error: await-without-async: `await` needs `-> @Async<…>`, `-> @AsyncIter<…>` or `-> @Component<…>` return — this fn returns `@Result<…>`, which does not
  ┌─ main.bp:5:13
  │
5 │     val x = await fetchCount();
  │             ^

  hint: Write `async fn` (the return becomes `@Async<…>`; `component fn` / `async iter fn` give `@Component<…>` / `@AsyncIter<…>`), or consume the Async through its own functions (`.map`, `.then`).
