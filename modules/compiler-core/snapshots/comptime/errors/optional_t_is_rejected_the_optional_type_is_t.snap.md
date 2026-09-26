----- SOURCE CODE
fn takeOptional(x: @Optional<i32>) -> i32 {
    return x.unwrapOr(0);
}
fn main() {
    @print(takeOptional(3));
}

----- ERROR
error: `@Option<T>` is not a type — the optional type is written `?T`
  ┌─ :1:20
  │
1 │ fn takeOptional(x: @Optional<i32>) -> i32 {
  │                    ^

  hint: Replace the annotation with `?T` (e.g. `?i32`).
