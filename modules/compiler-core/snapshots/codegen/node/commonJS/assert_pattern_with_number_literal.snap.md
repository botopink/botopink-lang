----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert 42 = answer catch throw Error("not 42");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = answer; if ((_match === 42)) { return _match; } else { throw Error("not 42"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
