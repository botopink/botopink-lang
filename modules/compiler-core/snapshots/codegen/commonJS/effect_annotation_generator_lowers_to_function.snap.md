----- SOURCE CODE -- main.bp
```botopink
fn range(a: i32, b: i32) -> @Iterator<i32> {
    yield a;
    yield b;
}
```

----- JAVASCRIPT -- main.js
```javascript
function* range(a, b) {
    yield a;
    yield b;
}

Object.defineProperty(exports, "__bp_priv__", { value: { range } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
