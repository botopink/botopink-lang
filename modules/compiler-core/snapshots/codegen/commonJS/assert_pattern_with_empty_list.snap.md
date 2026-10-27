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
    let _assert0 = list;
    if (!((Array.isArray(_assert0)))) { return ({ error: "not empty" }); }
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
