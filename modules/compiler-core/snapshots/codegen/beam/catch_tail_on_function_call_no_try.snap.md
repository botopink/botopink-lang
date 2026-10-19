----- SOURCE CODE -- main.bp
```botopink
type RiskError(level: i32)
fn risky() -> Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: try-region-cannot-fail: this `catch` closes a region that holds no `try`, so it handles nothing — write `try` before the call that can fail (`try f() catch …`), or drop the `catch`
  ┌─ main.bp:6:20
  │
6 │     return risky() catch -1;
  │                    ^

  hint: A `catch` handles the failures of the `try`s written on its left.
```

