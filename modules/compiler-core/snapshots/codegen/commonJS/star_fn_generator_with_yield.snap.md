----- SOURCE CODE -- main.bp
```botopink
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- JAVASCRIPT -- main.js
```javascript
function* counter() {
    yield 1;
    yield 2;
    yield 3;
}

Object.defineProperty(exports, "__bp_priv__", { value: { counter } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
