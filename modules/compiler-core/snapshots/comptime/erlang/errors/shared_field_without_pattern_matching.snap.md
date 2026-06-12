----- SOURCE CODE
val Result = enum {
    Ok(value: i32),
    Error(message: string),
};
val get_value = fn(r: Result) -> i32 {
    r.kind
};

----- ERROR
error: unknown field
  ┌─ :6:7
  │
6 │     r.kind
  │       ^

  'Result' has no field 'kind'
