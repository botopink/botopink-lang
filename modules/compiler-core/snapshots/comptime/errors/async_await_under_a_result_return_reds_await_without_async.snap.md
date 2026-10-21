----- SOURCE CODE
async fn fetchCount() -> Async<i32> {
    return 3;
}
fn semAwait() -> Result<i32, string> {
    val x = await fetchCount();
    return x;
}

----- ERROR
error: await-without-async: `await` needs a body marked `async`, `async iter` or `component` — this body carries no marker
  ┌─ main.bp:5:13
  │
5 │     val x = await fetchCount();
  │             ^

  hint: Write `async fn` (its return is `Async<…>`; `component fn` / `async iter fn` answer `Component<…>` / `AsyncIter<…>`), or consume the Async through its own functions (`.map`, `.then`).
