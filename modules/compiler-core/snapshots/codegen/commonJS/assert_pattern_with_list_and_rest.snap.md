----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const items = [1, 2, 3, 4];
    let _assert0 = items;
    if (!((Array.isArray(_assert0) && _assert0.length >= 2))) { _assert0 = []; if (!((Array.isArray(_assert0) && _assert0.length >= 2))) { (() => { throw Object.defineProperty(new Error("assert pattern did not match"), '__bp_panic', { value: true }) })(); } }
    const rest = _assert0.slice(2);
    const first = _assert0[0];
    const second = _assert0[1];
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
