----- SOURCE CODE
#[@resultGenerator]
fn upTo(n: i32) -> @ResultGenerator<i32, string> {
    yield n;
}
fn total(n: i32) -> i32 {
    var acc = 0;
    loop (upTo(n)) { x -> acc = acc + x; };
    return acc;
}

----- ERROR
error: effect-try-without-fallible-channel: `try` needs an effect that implements `@Result` — `#[@result]`, `#[@future]`, `#[@resultGenerator]`, `#[@futureGenerator]` or `#[@context]`; this fn carries no effect annotation — a loop over a `@ResultGenerator<T, E>` propagates its `Error(e)` as a `try` in the body that iterates it (decision 103)
  ┌─ :7:5
  │
7 │     loop (upTo(n)) { x -> acc = acc + x; };
  │     ^

  hint: Give the enclosing fn an error channel (`#[@result]` or above), or iterate an infallible `@Generator<T>`.
