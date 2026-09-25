----- SOURCE CODE
#[@resultGenerator]
fn upTo(n: i32) -> @ResultGenerator<i32, string> {
    yield n;
}
fn total(n: i32) -> i32 {
    var acc = 0;
    for (upTo(n)) { x -> acc = acc + x; };
    return acc;
}

----- ERROR
error: for-over-fallible-generator: `for` over a `@ResultGenerator` is an implicit `try` at every item, and this body grants no `try`
  ┌─ :7:5
  │
7 │     for (upTo(n)) { x -> acc = acc + x; };
  │     ^

  hint: for-over-fallible-generator: `try` needs an effect that implements `@Result` — `#[@result]`, `#[@future]`, `#[@resultGenerator]`, `#[@futureGenerator]` or `#[@context]`; this fn carries no effect annotation
