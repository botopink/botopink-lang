----- SOURCE CODE -- main.bp
```botopink
fn and(a: ?bool, b: ?bool) -> bool {
    if (a) { va ->
        if (b) { vb ->
            return va && vb;
        };
    };
    return false;
}
@print(and(true, true));
```

