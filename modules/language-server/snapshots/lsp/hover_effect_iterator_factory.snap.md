----- SOURCE
```botopink
iter fn counter() -> Iter<i32> :gen { yield 1; }
fn fresh() -> Iter<i32> { return counter(); }
   ↑
```

----- HOVER at (line 1, char 3)
kind: markdown

```botopink
fn fresh() -> Iter<i32>
```

---

`for` item type: `i32`
