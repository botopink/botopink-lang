----- SOURCE CODE -- main.bp
```botopink
fn process(x: ?i32) -> i32 {
    assert x is Some(n);
    return n + 1;
}
@print(process(42));
```

