----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const numbers = [1, 2, 3];
    (() => { const _match = numbers; if ((Array.isArray(_match) && _match.length >= 3)) { return _match; } else { throw "not matching"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
