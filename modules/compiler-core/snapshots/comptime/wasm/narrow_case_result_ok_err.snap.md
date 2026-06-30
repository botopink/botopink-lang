----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse(n: i32) -> @Result<string, string> {
    if (n < 0) { throw "negative"; };
    return "ok";
}
fn handle(n: i32) -> string {
    val r = parse(n);
    return case r {
        Ok(v) -> "parsed: " + v;
        Err(e) -> "error: " + e;
    };
}
@print(handle(5));
```

