----- SOURCE CODE -- main.bp
```botopink
fn process(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- JAVASCRIPT -- main.js
```javascript
function process(f) {
    return f(5);
}

Object.defineProperty(exports, "__bp_priv__", { value: { process } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
