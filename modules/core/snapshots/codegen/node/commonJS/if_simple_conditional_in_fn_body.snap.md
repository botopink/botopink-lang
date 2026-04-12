----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function sign(n) {
    const r = (() => { if ((n > 0)) { return "positive"; } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
