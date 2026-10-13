----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert 1.0 + 2.0 == 3.0;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw Object.defineProperty(new Error((msg ?? "assertion failed") + " at " + loc), "__bp_panic", { value: msg ?? "assertion failed" }); } }

function f() {
    __bp_assert_fatal(Object.is((1.0 + 2.0), 3.0), null, "main.bp:2");
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
