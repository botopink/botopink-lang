----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert true;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? "assertion failed") + " at " + loc); } }

function f() {
    __bp_assert_fatal(true, null, "main.bp:2");
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
