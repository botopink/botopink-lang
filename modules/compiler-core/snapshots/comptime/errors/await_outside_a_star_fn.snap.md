----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: effect-await-without-future: `await` needs an effect that implements `@Future` — `#[@future]`, `#[@futureGenerator]` or `#[@use]`; this fn carries no effect annotation
  ┌─ :2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Mark the enclosing fn `#[@future]` (`-> @Future<…>`), `#[@futureGenerator]` (`-> @FutureGenerator<…>`) or `#[@use]` (`-> @Use<…>` / `-> @Component<…>`).
