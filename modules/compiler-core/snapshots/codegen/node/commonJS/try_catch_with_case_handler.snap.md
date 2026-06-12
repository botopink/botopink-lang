----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
*fn fetch() -> @Result<i32, ErrorKind> {
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
    return ({ error: ErrorKind.NotFound });
}

function handle() {
    const _try0 = fetch();
    const r = "error" in _try0 ? (0) : _try0.ok;
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
