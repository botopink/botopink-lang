----- SOURCE CODE
fn bad() -> @Task<i32> {
    val x = await 5;
    return x;
}

----- ERROR
error: `await` expects a `@Task<_>` value (or a `@Component<C, T>`, which extends it)
  ┌─ :2:13
  │
2 │     val x = await 5;
  │             ^
