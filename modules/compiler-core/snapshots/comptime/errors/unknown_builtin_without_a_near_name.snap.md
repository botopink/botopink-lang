----- SOURCE CODE
fn main() {
    @frobnicate(1, 2);
}

----- ERROR
error: unknown-builtin: unknown builtin `@frobnicate`
  ┌─ :2:5
  │
2 │     @frobnicate(1, 2);
  │     ^

  hint: Builtin names are exact and lowercase (`@print`, `@panic`, `@src`); see `libs/std/src/builtins.d.bp` for the list.
