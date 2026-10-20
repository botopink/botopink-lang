----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const list = [];
    (() => { const _match = list; if ((Array.isArray(_match))) { return _match; } else { return ({ error: "not empty" }); } })();
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
