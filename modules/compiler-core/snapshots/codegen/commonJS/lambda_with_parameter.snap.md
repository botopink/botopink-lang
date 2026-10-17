----- SOURCE CODE -- main.bp
```botopink
fn apply(f: fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- JAVASCRIPT -- main.js
```javascript
function apply(f) {
    return f(10);
}

Object.defineProperty(exports, "__bp_priv__", { value: { apply } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
