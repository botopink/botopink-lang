----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const list = [];
    (() => { const _match = list; if ((Array.isArray(_match))) { return _match; } else { throw "not empty"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
