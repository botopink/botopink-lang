----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
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
#[@generator]
fn counted(n: i32) -> @Generator<i32> {
    val v = try parse(n);
    yield v;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs an effect that implements `@Result` — `#[@result]`, `#[@future]`, `#[@resultGenerator]`, `#[@futureGenerator]` or `#[@use]`; `#[@generator]` is `@Generator`, which does not; `@Generator` has no error channel; use `@ResultGenerator<T, E>`
  ┌─ :16:13
  │
16 │     val v = try parse(n);
  │             ^

  hint: Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or give the enclosing fn one.
