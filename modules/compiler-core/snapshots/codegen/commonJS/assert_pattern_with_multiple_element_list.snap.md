----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const numbers = [1, 2, 3];
    (() => { const _match = numbers; if ((Array.isArray(_match) && _match.length >= 3)) { return _match; } else { return ({ error: "not matching" }); } })();
    return ({ ok: null });
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
