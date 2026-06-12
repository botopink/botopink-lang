----- SOURCE CODE
val Result = enum {
    Ok(value: i32),
    Error(message: string),
};
val test = fn(r: Result) -> i32 {
    case r {
        Ok(_) -> {};
        Error(_) -> {};
    };
    return r.kind;
};

----- ERROR
error: unknown field
  ┌─ :10:14
  │
10 │     return r.kind;
  │              ^

  'Result' has no field 'kind'
