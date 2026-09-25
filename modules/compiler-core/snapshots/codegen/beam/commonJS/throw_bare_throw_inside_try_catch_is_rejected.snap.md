----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn g(x: i32) -> @Result<i32, string> {
    if (x > 0) { return x; };
    throw "neg";
}
#[@result]
fn f(x: i32) -> @Result<i32, string> {
    val r = try g(x) catch { e -> throw; };
    return r;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :8:40
  │
8 │     val r = try g(x) catch { e -> throw; };

  unexpected `;`
```

