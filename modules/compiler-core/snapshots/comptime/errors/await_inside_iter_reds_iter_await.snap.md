----- SOURCE CODE
val Element = type() implement Renderable
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn parse(n: i32) -> Result<i32, string> {
    return n;
}
async fn fetch(n: i32) -> Async<i32> {
    return n;
}
iter fn bad(n: i32) -> Iter<i32> {
    val w = await fetch(n);
    yield w;
}

----- ERROR
error: iter-await: `await` does not exist in an `iter` body — its items are produced synchronously
  ┌─ main.bp:12:13
  │
12 │     val w = await fetch(n);
  │             ^

  hint: Write `async iter fn` (an `AsyncIter<T>`, or a `stream` loop): a stream is the sequence that may wait between items.
