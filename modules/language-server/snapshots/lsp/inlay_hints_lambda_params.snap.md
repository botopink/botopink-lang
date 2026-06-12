----- SOURCE
```botopink
fn apply(f: fn(n: i32) -> i32) -> i32 { return f(1); }
val r = apply({ x -> x * x });
```

----- INLAY HINTS
  (1,5)  : i32
  (1,17)  : i32
