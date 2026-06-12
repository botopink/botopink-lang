----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: `await` can only be used inside a `#[@future]` / `#[@asyncGenerator]` fn
  ┌─ :2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Mark the enclosing fn `#[@future]` (`-> @Future<…>`) or `#[@asyncGenerator]` (`-> @AsyncIterator<…>`).
