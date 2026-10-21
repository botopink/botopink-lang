----- SOURCE CODE
async fn bad() -> Async<i32> {
    for await x in 5 {
        ping(x);
    }
}

----- ERROR
error: for-await-expects-stream: `for await` expects an `AsyncIter<T>` value
  ┌─ main.bp:2:5
  │
2 │     for await x in 5 {
  │     ^

  hint: An `Iter<T>` is iterated by `for x in it { … }`; only an `AsyncIter` suspends between items.
