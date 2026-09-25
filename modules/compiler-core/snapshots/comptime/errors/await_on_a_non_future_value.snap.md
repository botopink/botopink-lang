----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    val x = await 5;
    return x;
}

----- ERROR
error: `await` expects a `@Future<_>` value (or a `@Use<C, T>` / `@Component<T>`, which extend it)
  ┌─ :3:13
  │
3 │     val x = await 5;
  │             ^
