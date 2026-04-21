----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [first, second, ..rest] = items catch [];
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 2)) { return _match; } else { return []; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
