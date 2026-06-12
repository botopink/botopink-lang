----- SOURCE CODE
*fn bad() -> @Future<i32> {
    loop await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: `loop await` expects an `@AsyncIterator<T, E>` value
  ┌─ :2:5
  │
2 │     loop await (5) { x ->
  │     ^
