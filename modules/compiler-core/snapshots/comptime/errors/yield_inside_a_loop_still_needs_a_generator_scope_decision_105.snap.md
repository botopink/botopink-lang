----- SOURCE CODE
#[@future]
fn collected() -> @Future<i32> {
    var n = 0;
    for ([1, 2, 3]) { x -> yield x * 2; };
    return n;
}

----- ERROR
error: yield-without-generator: `yield` needs a generator effect — `#[@generator]`, `#[@iterator]` or `#[@futureGenerator]`; `#[@future]` is `@Future`, which does not
  ┌─ :4:28
  │
4 │     for ([1, 2, 3]) { x -> yield x * 2; };
  │                            ^

  hint: A `yield` feeds the nearest generator scope: mark the fn `#[@generator]` (`-> @Generator<T>`) or write the loop as `#[@generator] loop { … }` (decision 105).
