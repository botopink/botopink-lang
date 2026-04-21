----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert "hello" = greeting catch throw Error("not hello");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = greeting; if ((_match === "hello")) { return _match; } else { throw Error("not hello"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
