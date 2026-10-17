----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- JAVASCRIPT -- main.js
```javascript
function allThree(a, b, c) {
    return ((a && b) && c);
}

Object.defineProperty(exports, "__bp_priv__", { value: { allThree } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
