----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: effect-await-without-task: `await` needs `-> @Task<…>`, `-> @Stream<…>` or `-> @Component<C, …>` return — this fn's return type is no effect wrapper
  ┌─ :2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Change the return to `@Task<…>` (or `@Component<C, …>` / `@Stream<…>`), or consume the Task through its own functions (`.map`, `.then`).
