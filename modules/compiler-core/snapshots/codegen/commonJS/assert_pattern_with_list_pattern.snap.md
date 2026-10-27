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
    let _assert0 = items;
    if (!((Array.isArray(_assert0) && _assert0.length >= 1))) { return ({ error: "not a list" }); }
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
