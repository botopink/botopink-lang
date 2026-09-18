----- SOURCE CODE
#[@future]
fn fetch() -> @Future<i32, string> {
    val f = Future.resolved(value: 42);
    return 0;
}

----- ERROR
error: future-manual-construction-forbidden: the @Future type variants are only constructed by `return` / `throw` inside #[@future]; outside that the type is treated as opaque.
  ┌─ :3:20
  │
3 │     val f = Future.resolved(value: 42);
  │                    ^

  hint: Replace the manual `Future.resolved(...)` / `Future.rejected(...)` with the implicit form (`return <t>;` / `throw <e>;`), or move the construction outside the #[@future] body.
