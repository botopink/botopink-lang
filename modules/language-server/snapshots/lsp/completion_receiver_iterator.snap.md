----- SOURCE
```botopink
fn gen() -> @Iterator<i32> { yield 1; }
val it = gen();
val first = it.
               ↑
```

----- COMPLETION at (line 2, char 15)
next  [Method]  detail: fn next(self: Self) -> YieldStep<T>
