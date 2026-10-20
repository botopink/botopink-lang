----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
function f() {
    const answer = 42;
    (() => { const _match = answer; if ((_match === 42)) { return _match; } else { return ({ error: "not 42" }); } })();
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
