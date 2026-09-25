----- SOURCE CODE
#[@resultGenerator]
fn nums() -> @ResultGenerator<i32, string> {
    yield 1;
    return 42;
}

----- ERROR
error: iterator-return-forbidden: a generator has no return channel — `break <v>` emits `v` as the last item and ends, bare `break` ends cleanly
  ┌─ :4:5
  │
4 │     return 42;
  │     ^

  hint: Replace `return <expr>;` with `break <expr>;` (the value is an item of type `T`), or with `yield <expr>; return;`.
