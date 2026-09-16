----- SOURCE CODE -- main.bp
```botopink
enum Status { Ready, Busy(count: i32), Down }
fn work(s: Status) -> i32 {
    assert s is Busy(n);
    return n;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :3:14
  │
3 │     assert s is Busy(n);

  unexpected `is`
```

