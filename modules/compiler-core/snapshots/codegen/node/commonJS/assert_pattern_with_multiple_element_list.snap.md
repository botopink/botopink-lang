----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [1, 2, 3] = numbers catch throw Error("not matching");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = numbers; if ((Array.isArray(_match) && _match.length >= 3)) { return _match; } else { throw Error("not matching"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
