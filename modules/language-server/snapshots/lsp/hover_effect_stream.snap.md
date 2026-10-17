----- SOURCE
```botopink
fn pulses() -> @Stream<@Result<i32, string>> {
   ↑
    yield 1;
    yield 2;
}
```

----- HOVER at (line 0, char 3)
kind: markdown

```botopink
fn pulses() -> @Stream<@Result<i32, string>>
```

---

`for await` item type: `@Result<i32, string>`
