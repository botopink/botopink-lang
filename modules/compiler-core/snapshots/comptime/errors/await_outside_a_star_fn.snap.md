----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: effect-await-without-future: `await` is only valid inside a `#[@future]` / `#[@asyncGenerator]` fn
  ┌─ :2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Mark the enclosing fn `#[@future]` (`-> @Future<…>`) or `#[@asyncGenerator]` (`-> @AsyncIterator<…>`).
