----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(i32, i32) {
    val r = #(7, 11);
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function make() {
    const r = [7, 11];
    return r;
}

Object.defineProperty(exports, "__bp_priv__", { value: { make } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
