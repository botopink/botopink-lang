----- SOURCE
```botopink
async iter fn pulses() -> AsyncIter<Result<i32, string>> {
              ↑
    yield 1;
    yield 2;
}
```

----- HOVER at (line 0, char 14)
kind: markdown

```botopink
fn pulses() -> AsyncIter<Result<i32, string>>
```

---

`for await` item type: `Result<i32, string>`
