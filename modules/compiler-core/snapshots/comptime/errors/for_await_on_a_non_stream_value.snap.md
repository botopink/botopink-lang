----- SOURCE CODE
fn bad() -> @Task<i32> {
    for await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: for-await-expects-stream: `for await` expects a `@Stream<T>` value
  ┌─ :2:5
  │
2 │     for await (5) { x ->
  │     ^

  hint: An `@Iterator<T>` is iterated by `for (it) { x -> … }`; only a `@Stream` suspends between items.
