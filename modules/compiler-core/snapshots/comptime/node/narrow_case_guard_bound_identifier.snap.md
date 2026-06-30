----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return case n {
        x if (x > 0) -> "positive: " + x;
        x if (x < 0) -> "negative: " + x;
        _ -> "zero";
    };
}
@print(describe(5));
```

