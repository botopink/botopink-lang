----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    assert 1.0 + 2.0 == 3.0;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert_fatal(cond, msg, head, where) {
    if (!cond) { const m = head + (msg == null ? "" : ": " + msg) + " at " + where; throw Object.defineProperty(new Error(m), "__bp_panic", { value: m }); }
}

function f() {
    __bp_assert_fatal(Object.is((1.0 + 2.0), 3.0), null, "assertion failed: 1.0 + 2.0 == 3.0", "main.bp:2:5");
}

Object.defineProperty(exports, "__bp_priv__", { value: { f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
