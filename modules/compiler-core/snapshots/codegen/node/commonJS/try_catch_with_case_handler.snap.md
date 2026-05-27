----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
fn fetch() -> @Result(i32, ErrorKind) {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
const ErrorKind = Object.freeze({
    NotFound: "NotFound",
    Timeout: "Timeout",
});

function fetch() {
    throw ErrorKind.NotFound;
}

function handle() {
    const r = (() => { try { return fetch(); } catch(_e) { return (0)(_e); } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
