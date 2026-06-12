----- SOURCE CODE -- main.bp
```botopink
val Result = enum <T, E> {
    Ok(value: T),
    Err(error: E),
};
val unwrap_or = fn(r: Result<i32, string>, default: i32) -> i32 {
    case r {
        Ok(v) -> v,
        Err(_) -> default,
    }
};
```

