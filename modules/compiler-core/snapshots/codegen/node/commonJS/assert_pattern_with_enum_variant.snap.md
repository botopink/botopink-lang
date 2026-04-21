----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Ok(value) = result catch throw Error("not ok");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = result; if ((_match instanceof Ok)) { return _match; } else { throw Error("not ok"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
