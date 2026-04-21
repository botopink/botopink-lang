----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [] = list catch throw Error("not empty");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = list; if ((Array.isArray(_match))) { return _match; } else { throw Error("not empty"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
