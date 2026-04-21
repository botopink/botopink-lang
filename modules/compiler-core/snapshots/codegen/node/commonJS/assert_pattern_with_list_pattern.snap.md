----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [first, ..] = items catch throw Error("not a list");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 1)) { return _match; } else { throw Error("not a list"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
