----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val loc = @Src();
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: unknown-builtin: unknown builtin `@Src` — did you mean `@src`?
  ┌─ main.bp:2:15
  │
2 │     val loc = @Src();
  │               ^

  hint: Builtin names are exact and lowercase (`@print`, `@panic`, `@src`); see `libs/std/src/builtins.d.bp` for the list.
```

