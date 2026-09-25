----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = type { NotFound, Timeout }
fn fetch() -> @Result<i32, ErrorKind> {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class ErrorKind {
}
ErrorKind.prototype.__bp = "ErrorKind";
class ErrorKind$NotFound extends ErrorKind {
}
ErrorKind$NotFound.prototype.tag = "NotFound";
class ErrorKind$Timeout extends ErrorKind {
}
ErrorKind$Timeout.prototype.tag = "Timeout";
ErrorKind.NotFound = new ErrorKind$NotFound();
ErrorKind.Timeout = new ErrorKind$Timeout();

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
