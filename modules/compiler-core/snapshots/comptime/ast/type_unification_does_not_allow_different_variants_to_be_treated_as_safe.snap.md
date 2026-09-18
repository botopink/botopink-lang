----- SOURCE CODE -- main.bp
```botopink
val Result = type {
    Ok(value: i32),
    Err(message: string),
};
val process = fn(r: Result) -> string {
    case r {
      Ok(..) as b -> Wibble(..b, value: 1);
      Err(..) as b -> Wobble(..b, message: "a");
    }
};
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :7:14
  │
7 │       Ok(..) as b -> Wibble(..b, value: 1);

  unexpected `as`
```

