----- SOURCE CODE
val Element = type implement @Context<Element> { }
fn state(initial: i32) -> @Use<Element, i32> {
    return initial;
}

----- ERROR
error: a function returning `@Future`/`@ResultGenerator`/`@FutureGenerator`/`@Use`/`@Component` needs an effect annotation
  ┌─ :3:5
  │
3 │     return initial;
  │     ^

  hint: Mark it `#[@future]` / `#[@resultGenerator]` / `#[@futureGenerator]` / `#[@use]`.
