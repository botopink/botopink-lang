----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
```

----- JAVASCRIPT -- main.js
```javascript
function describe(n) {
    return (() => { if ((n > 0)) { return "positive"; } else { return "non-positive"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
