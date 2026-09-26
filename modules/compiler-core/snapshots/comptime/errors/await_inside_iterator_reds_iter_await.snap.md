----- SOURCE CODE
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}
fn fetch(n: i32) -> @Task<i32> {
    return n;
}
fn bad(n: i32) -> @Iterator<i32> {
    val w = await fetch(n);
    yield w;
}

----- ERROR
error: iter-await: `await` does not exist in an `@Iterator` — its items are produced synchronously
  ┌─ main.bp:12:13
  │
12 │     val w = await fetch(n);
  │             ^

  hint: Use `@Stream<T>` (or a `stream` loop): a stream is the sequence that may wait between items.
