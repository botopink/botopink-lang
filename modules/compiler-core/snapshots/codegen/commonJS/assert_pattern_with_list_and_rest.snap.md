----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const items = [1, 2, 3, 4];
    (() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 2)) { return _match; } else { return []; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
