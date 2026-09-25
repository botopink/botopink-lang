----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    for await (5) { x ->
        ping(x);
    }
}

----- ERROR
error: for-await-expects-future-generator: `for await` expects an `@FutureGenerator<T, E>` value
  ┌─ :3:5
  │
3 │     for await (5) { x ->
  │     ^

  hint: A `@Generator<T>` or a `@ResultGenerator<T, E>` is iterated by `for (gen) { x -> … }`; only a `@FutureGenerator` suspends between items.
