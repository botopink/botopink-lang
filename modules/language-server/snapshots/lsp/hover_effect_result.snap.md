----- SOURCE
```botopink
fn parse(x: i32) -> @Result<i32, string> {
   ↑
    if (x < 0) { throw "negative"; };
    return x;
}
```

----- HOVER at (line 0, char 3)
kind: markdown

```botopink
fn parse(x: i32) -> @Result<i32, string>
```
