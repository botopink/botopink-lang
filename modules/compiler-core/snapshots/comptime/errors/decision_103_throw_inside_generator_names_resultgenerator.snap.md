----- SOURCE CODE
#[@generator]
fn nums() -> @Generator<i32> {
    yield 1;
    throw "no";
}

----- ERROR
error: effect-throw-without-fallible-channel: `throw` in a `#[@generator]` body — `@Generator` has no error channel; use `@ResultGenerator<T, E>`
  ┌─ :4:5
  │
4 │     throw "no";
  │     ^

  hint: Annotate the fn `#[@resultGenerator]` and return `@ResultGenerator<T, E>`, whose `Error(e)` step carries the thrown value.
