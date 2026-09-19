----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const greeting = "hello";
    (() => { const _match = greeting; if ((_match === "hello")) { return _match; } else { throw "not hello"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
