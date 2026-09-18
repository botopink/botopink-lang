----- SOURCE CODE -- main.bp
```botopink
type Status { Ready, Busy(count: i32), Down }
fn work(s: Status) -> i32 {
    assert s is Busy(n);
    return n;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (isVariantBinding)
  ┌─ :3:21
  │
3 │     assert s is Busy(n);

  unexpected `(`
```

