----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: await-without-async: `await` needs `-> @Task<…>`, `-> @Stream<…>` or `-> @Component<…>` return — this fn's return type is no effect wrapper
  ┌─ main.bp:2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Write `async fn` (the return becomes `@Task<…>`; `component fn` / `async iter fn` give `@Component<…>` / `@Stream<…>`), or consume the Task through its own functions (`.map`, `.then`).
