----- SOURCE
```botopink
fn pulses() -> @Stream<i32> { yield 1; }
val it = pulses();
val first = it.
               ↑
```

----- COMPLETION at (line 2, char 15)
next  [Method]  detail: fn next(self: Self) -> Task<YieldStep<T>>
map  [Method]  detail: fn map<R>(self: Self, transform: fn(value: T) -> R) -> Task<R>
then  [Method]  detail: fn then<R>(self: Self, next: fn(value: T) -> Task<R>) -> Task<R>
