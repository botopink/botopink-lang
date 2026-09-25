----- SOURCE CODE
fn fetchCount() -> @Task<i32> {
    return 3;
}
fn semAwait() -> @Result<i32, string> {
    val x = await fetchCount();
    return x;
}

----- ERROR
error: effect-await-without-task: `await` needs `-> @Task<…>`, `-> @Stream<…>` or `-> @Component<C, …>` return — this fn returns `@Result<…>`, which does not
  ┌─ :5:13
  │
5 │     val x = await fetchCount();
  │             ^

  hint: Change the return to `@Task<…>` (or `@Component<C, …>` / `@Stream<…>`), or consume the Task through its own functions (`.map`, `.then`).
