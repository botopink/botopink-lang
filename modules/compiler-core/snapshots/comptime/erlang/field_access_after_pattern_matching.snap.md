----- SOURCE CODE -- main.bp
```botopink
val Result = enum {
    Ok(value: i32),
    Error(message: string),
};
val get_value = fn(r: Result) -> i32 {
    case r {
        Ok(v) -> v;
        Error(_) -> 0;
    }
};
```

