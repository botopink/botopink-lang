----- SOURCE CODE
fn main() {
    @pritn("x");
}

----- ERROR
error: unknown-builtin: unknown builtin `@pritn` — did you mean `@print`?
  ┌─ main.bp:2:5
  │
2 │     @pritn("x");
  │     ^

  hint: Builtin names are exact and lowercase (`@print`, `@panic`, `@src`); see `libs/std/src/builtins.d.bp` for the list.
