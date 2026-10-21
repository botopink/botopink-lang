----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- JAVASCRIPT -- main.js
```javascript
function n() {
    const s = "hello";
    return s.length;
}

Object.defineProperty(exports, "__bp_priv__", { value: { n } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
