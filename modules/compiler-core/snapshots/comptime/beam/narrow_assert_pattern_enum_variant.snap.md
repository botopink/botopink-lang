----- SOURCE CODE -- main.bp
```botopink
enum Status { Ready, Busy(count: i32), Down }
fn work(s: Status) -> i32 {
    assert s is Busy(n);
    return n;
}
```

