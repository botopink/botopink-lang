----- SOURCE CODE
*fn bad() -> @Future<i32> {
    val x = await 5;
    return x;
}

----- ERROR
error: `await` expects a `@Future<_>` value
  ┌─ :2:13
  │
2 │     val x = await 5;
  │             ^
