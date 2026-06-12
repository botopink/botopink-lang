----- SOURCE CODE
fn takeOption(x: @Option<i32>) -> i32 {
    return x.unwrapOr(0);
}
fn main() {
    @print(takeOption(3));
}

----- ERROR
error: `@Option<T>` is not a type — the optional type is written `?T`

  hint: Replace the annotation with `?T` (e.g. `?i32`).
