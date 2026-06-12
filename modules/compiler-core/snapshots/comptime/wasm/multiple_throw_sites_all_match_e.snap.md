----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn validate(n: i32) -> @Result<i32, string> {
    if (n < 0) {
        throw "negative";
    }
    if (n > 100) {
        throw "too big";
    }
    return n;
}
```

