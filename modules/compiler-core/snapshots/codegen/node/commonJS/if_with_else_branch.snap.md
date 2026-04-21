----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
```

----- JAVASCRIPT -- main.js
```javascript
function abs(n) {
    const result = (() => { if ((n < 0)) { return (-n); } else { return n; } })();
    return result;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
