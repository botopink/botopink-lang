----- SOURCE CODE
#[@future]
fn fetch() -> @Future<i32, string> {
    throw Future.resolved(value: 42);
}

----- ERROR
error: future-throw-type-mismatch: a #[@future] fn rejects E via `throw`; use `return` for the resolved variant.
  ┌─ :3:5
  │
3 │     throw Future.resolved(value: 42);
  │     ^

  hint: If the value is the success payload, change `throw Future.resolved(<t>);` to `return <t>;`.
