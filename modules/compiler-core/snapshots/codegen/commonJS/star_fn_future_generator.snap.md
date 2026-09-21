----- SOURCE CODE -- main.bp
```botopink
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
    yield 1;
    yield 2;
}
```

----- JAVASCRIPT -- main.js
```javascript
async function* stream() {
    yield 1;
    yield 2;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
