----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
val s = sign(1);
```

----- COMPILE DIAGNOSTIC -- main
```text
error: an `if` without `else` has no value on its false side
  ┌─ :2:13
  │
2 │     val r = if (n > 0) { "positive"; };
  │             ^

  hint: Give it an `else` branch, or bind the value inside the branch (decision 2: a block is a statement).
```

