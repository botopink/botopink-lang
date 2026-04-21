----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    @todo();
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function fetch() {
    (() => { throw new Error("not implemented") })();
}

function safe() {
    const r = (() => { try { return fetch(); } catch(_e) { return (0)(_e); } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
