----- SOURCE CODE -- main.bp
```botopink
val Result = enum <T, E> {
    Ok(value: T),
    Err(error: E),
};
val Container = enum {
    Single(Result<i32, string>),
    Multiple(Result<i32, string>[]),
};
val extract = fn(c: Container) -> i32 {
    case c {
        Single(Ok(v)) -> v;
        Multiple([Ok(v), ..]) -> v;
        _ -> 0;
    }
};
```

