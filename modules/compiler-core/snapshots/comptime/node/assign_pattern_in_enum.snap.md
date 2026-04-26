----- SOURCE CODE -- main.bp
```botopink
val Result = enum {
    Ok(value: i32),
    Err(message: string),
};
val process = fn(r: Result) -> string {
    case r {
        Ok(v) as result -> "Got: " + v;
        Err(e) as result -> "Error: " + e;
    }
};
```

