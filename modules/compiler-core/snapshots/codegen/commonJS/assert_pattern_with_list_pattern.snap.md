----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val items = [1, 2, 3];
    val assert [first, ..] = items catch throw "not a list";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const items = [1, 2, 3];
    const _assert0 = (() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 1)) { return _match; } else { return ({ error: "not a list" }); } })();
    const first = _assert0[0];
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
