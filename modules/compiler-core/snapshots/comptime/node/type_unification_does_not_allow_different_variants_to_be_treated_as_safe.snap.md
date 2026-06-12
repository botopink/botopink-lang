----- SOURCE CODE -- main.bp
```botopink
val Result = enum {
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

