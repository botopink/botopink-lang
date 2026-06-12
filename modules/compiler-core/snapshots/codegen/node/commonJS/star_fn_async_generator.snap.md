----- SOURCE CODE -- main.bp
```botopink
*fn stream() -> @AsyncIterator<i32, string> {
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
