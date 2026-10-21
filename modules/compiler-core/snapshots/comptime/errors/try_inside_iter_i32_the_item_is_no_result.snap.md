----- SOURCE CODE
val Element = type()
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn parse(n: i32) -> Result<i32, string> {
    return n;
}
async fn fetch(n: i32) -> Async<i32> {
    return n;
}
iter fn counted(n: i32) -> Iter<i32> {
    val v = try parse(n);
    yield v;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs a `Result` in some layer of the return — the item of `Iter<T>` has to be `Result<T, E>` to use `throw` / `try`; `try … catch` handles the failure on the spot, and a host binding answers a `Result` with `result: true`
  ┌─ main.bp:12:13
  │
12 │     val v = try parse(n);
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or put a `Result` in the return.
