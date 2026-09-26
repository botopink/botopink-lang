----- SOURCE CODE -- main.bp
```botopink
fn g(x: i32) -> @Result<i32, string> {
    if (x > 0) { return x; };
    throw "neg";
}
fn f(x: i32) -> @Result<i32, string> {
    val r = try g(x) catch { e -> throw; };
    return r;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ main.bp:6:40
  │
6 │     val r = try g(x) catch { e -> throw; };

  unexpected `;`
```

