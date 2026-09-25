----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const answer = 42;
    (() => { const _match = answer; if ((_match === 42)) { return _match; } else { throw "not 42"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
