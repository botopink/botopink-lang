----- SOURCE
```botopink
async fn load() -> Async<i32> { return 1; }
val it = load();
val first = it.
               ↑
```

----- COMPLETION at (line 2, char 15)
map  [Method]  detail: fn map<R>(self: Self, transform: fn(value: T) -> R) -> Async<R>
then  [Method]  detail: fn then<R>(self: Self, next: fn(value: T) -> Async<R>) -> Async<R>
