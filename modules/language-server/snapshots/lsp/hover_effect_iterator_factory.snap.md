----- SOURCE
```botopink
fn counter() -> @Iterator<i32> :gen { yield 1; }
fn fresh() -> @Iterator<i32> { return counter(); }
   ↑
```

----- HOVER at (line 1, char 3)
kind: markdown

```botopink
fn fresh() -> @Iterator<i32>
```

---

`for` item type: `i32`
