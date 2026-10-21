----- SOURCE CODE
fn main() -> void {
    @frobnicate(1, 2);
}

----- ERROR
error: unknown-builtin: unknown builtin `@frobnicate`
  ┌─ main.bp:2:5
  │
2 │     @frobnicate(1, 2);
  │     ^

  hint: Builtin names are exact and lowercase (`@print`, `@panic`, `@src`); see `libs/std/src/primitives.bp`'s compiler section for the list.
