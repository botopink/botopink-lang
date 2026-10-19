----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: await-without-async: `await` needs `-> @Async<…>`, `-> @AsyncIter<…>` or `-> @Component<…>` return — this fn's return type is no effect wrapper
  ┌─ main.bp:2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Write `async fn` (the return becomes `@Async<…>`; `component fn` / `async iter fn` give `@Component<…>` / `@AsyncIter<…>`), or consume the Async through its own functions (`.map`, `.then`).
