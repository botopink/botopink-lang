----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    (() => { const _match = r; if ((_match instanceof Person)) { return _match; } else { return Person("bob", 12); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
