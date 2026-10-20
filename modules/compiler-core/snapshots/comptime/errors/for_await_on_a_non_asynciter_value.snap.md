----- SOURCE CODE
async fn bad() -> Async<i32> {
    for await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: for-await-expects-stream: `for await` expects an `AsyncIter<T>` value
  ┌─ main.bp:2:5
  │
2 │     for await (5) { x ->
  │     ^

  hint: An `Iter<T>` is iterated by `for (it) { x -> … }`; only an `AsyncIter` suspends between items.
