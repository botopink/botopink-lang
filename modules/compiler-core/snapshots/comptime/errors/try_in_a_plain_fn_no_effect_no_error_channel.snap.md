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
fn plain(n: i32) -> i32 {
    val v = try parse(n);
    return v;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs a `Result` in some layer of the return — this fn's return has no `Result` in it; `try … catch` handles the failure on the spot, and a host binding answers a `Result` with `result: true`
  ┌─ main.bp:12:13
  │
12 │     val v = try parse(n);
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or put a `Result` in the return.
