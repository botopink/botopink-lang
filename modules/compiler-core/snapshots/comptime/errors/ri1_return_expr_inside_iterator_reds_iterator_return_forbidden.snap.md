----- SOURCE CODE
#[@iterator]
fn nums() -> @Iterator<i32, string, i32> {
    yield 1;
    return 42;
}

----- ERROR
error: iterator-return-forbidden: use `break <C>` to deliver an iterator's completion value, or bare `break` for a clean end. Plain `return <expr>` is only valid in #[@generator].
  ┌─ :4:5
  │
4 │     return 42;
  │     ^

  hint: Replace `return <expr>;` with `break <expr>;` (the third generic of @Iterator<T, E, C> declares the completion-value type).
