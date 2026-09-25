----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}
#[@future]
fn fetch(n: i32) -> @Future<i32> {
    return n;
}
fn plain(n: i32) -> i32 {
    val v = try parse(n);
    return v;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs an effect that implements `@Result` — `#[@result]`, `#[@future]`, `#[@resultGenerator]`, `#[@futureGenerator]` or `#[@context]`; this fn carries no effect annotation
  ┌─ :14:13
  │
14 │     val v = try parse(n);
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or give the enclosing fn one.
