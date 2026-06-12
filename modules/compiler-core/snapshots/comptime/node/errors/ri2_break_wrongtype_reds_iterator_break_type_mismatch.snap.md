----- SOURCE CODE
#[@iterator]
fn nums() -> @Iterator<i32, string, i32> {
    yield 1;
    break "not an i32";
}

----- ERROR
error: iterator-break-type-mismatch: completion value type does not match the declared C parameter of @Iterator<T, E, C>
  ┌─ :4:5
  │
4 │     break "not an i32";
  │     ^

  hint: Either change the `break <expr>;` value to match C, or widen the wrapper's third generic.
