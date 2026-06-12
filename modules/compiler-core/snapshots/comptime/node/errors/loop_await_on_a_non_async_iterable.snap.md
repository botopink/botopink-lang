----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    loop await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: `loop await` expects an `@AsyncIterator<T, E>` value
  ┌─ :3:5
  │
3 │     loop await (5) { x ->
  │     ^
