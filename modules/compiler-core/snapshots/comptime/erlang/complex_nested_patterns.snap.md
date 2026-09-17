----- SOURCE CODE -- main.bp
```botopink
val Result = type <T, E> {
    Ok(value: T),
    Err(error: E),
};
val Container = type {
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

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :6:18
  │
6 │     Single(Result<i32, string>),

  unexpected `<`
```

