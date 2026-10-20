----- SOURCE CODE
async fn bad() -> Async<i32> {
    val x = await 5;
    return x;
}

----- ERROR
error: `await` expects an `Async<_>` value
  ┌─ main.bp:2:13
  │
2 │     val x = await 5;
  │             ^
