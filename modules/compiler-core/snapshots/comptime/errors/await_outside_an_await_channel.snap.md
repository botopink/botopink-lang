----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: await-without-async: `await` needs a body marked `async`, `async iter` or `component` — this body carries no marker
  ┌─ main.bp:2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Write `async fn` (its return is `Async<…>`; `component fn` / `async iter fn` answer `Component<…>` / `AsyncIter<…>`), or consume the Async through its own functions (`.map`, `.then`).
