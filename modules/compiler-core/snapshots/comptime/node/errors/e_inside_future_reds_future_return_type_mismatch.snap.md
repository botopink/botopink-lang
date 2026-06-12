----- SOURCE CODE
#[@future]
fn fetch() -> @Future<i32, string> {
    return Future.rejected(error: "boom");
}

----- ERROR
error: future-return-type-mismatch: a #[@future] fn resolves T via `return`; use `throw` for the rejection variant.
  ┌─ :3:5
  │
3 │     return Future.rejected(error: "boom");
  │     ^

  hint: If the value is the rejection payload, change `return Future.rejected(<e>);` to `throw <e>;`.
