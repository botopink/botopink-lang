----- SOURCE CODE
#[@use]
fn bad() -> @Component<i32> {
    return 0;
}

----- ERROR
error: effect-wrapper-mismatch: `@Component<T>` needs `T` to implement `@Context<Base>` — the base its hooks anchor at
  ┌─ :3:5
  │
3 │     return 0;
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
