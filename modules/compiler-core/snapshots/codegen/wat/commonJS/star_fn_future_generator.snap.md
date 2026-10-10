----- SOURCE CODE -- main.bp
```botopink
fn stream() -> @Stream<@Result<i32, string>> {
    yield 1;
    yield 2;
}
```

----- JAVASCRIPT -- main.js
```javascript
async function* stream() {
    yield ({ ok: 1 });
    yield ({ ok: 2 });
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
