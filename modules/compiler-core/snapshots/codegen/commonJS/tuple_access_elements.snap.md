----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- JAVASCRIPT -- main.js
```javascript
function getFirst(t) {
    return t[0];
}

Object.defineProperty(exports, "__bp_priv__", { value: { getFirst } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
