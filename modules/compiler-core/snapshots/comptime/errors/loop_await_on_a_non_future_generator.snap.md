----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    for await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: `loop await` expects an `@FutureGenerator<T, E>` value
  ┌─ :3:5
  │
3 │     for await (5) { x ->
  │     ^
