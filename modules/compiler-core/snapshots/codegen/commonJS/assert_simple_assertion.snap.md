----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert true;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw Object.defineProperty(new Error((msg ?? "assertion failed") + " at " + loc), "__bp_panic", { value: msg ?? "assertion failed" }); } }

function f() {
    __bp_assert_fatal(true, null, "main.bp:2");
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
