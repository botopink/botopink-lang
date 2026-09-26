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
fn plain(n: i32) -> i32 {
    val v = try parse(n);
    return v;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs a `@Result` in some layer of the return — this fn's return has no `@Result` in it
  ┌─ main.bp:12:13
  │
12 │     val v = try parse(n);
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or put a `@Result` in the return.
