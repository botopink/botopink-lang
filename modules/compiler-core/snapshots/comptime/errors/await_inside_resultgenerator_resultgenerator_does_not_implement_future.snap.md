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
#[@resultGenerator]
fn bad(n: i32) -> @ResultGenerator<i32> {
    val w = await fetch(n);
    yield w;
}

----- ERROR
error: effect-await-without-future: `await` needs an effect that implements `@Future` — `#[@future]`, `#[@futureGenerator]` or `#[@use]`; `#[@resultGenerator]` is `@ResultGenerator`, which does not
  ┌─ :16:13
  │
16 │     val w = await fetch(n);
  │             ^

  hint: Mark the enclosing fn `#[@future]` (`-> @Future<…>`), `#[@futureGenerator]` (`-> @FutureGenerator<…>`) or `#[@use]` (`-> @Component<…>`).
