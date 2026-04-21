----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch throw Error("is not person");
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = r; if ((_match instanceof Person)) { return _match; } else { throw Error("is not person"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
