----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3];
    val assert [first, ..] = items catch throw "not a list";
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const items = [1, 2, 3];
    const _assert0 = (() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 1)) { return _match; } else { throw "not a list"; } })();
    const first = _assert0[0];
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
