----- SOURCE CODE -- main.bp
```botopink
val Result = type {
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

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :7:15
  │
7 │         Ok(v) as result -> "Got: " + v;

  unexpected `as`
```

