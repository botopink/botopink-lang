----- SOURCE CODE
#[@iterator]
fn nums() -> @Iterator<i32> {
    yield 1;
    break 42;
}

----- ERROR
error: iterator-break-without-completion-type: this iterator declares C = void; bare `break` is the only valid form
  ┌─ :4:5
  │
4 │     break 42;
  │     ^

  hint: Extend the wrapper to opt into completion values: `@Iterator<T, E, <C-type>>` (or `@AsyncIterator<…>`).
