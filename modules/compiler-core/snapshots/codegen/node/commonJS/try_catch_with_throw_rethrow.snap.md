----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
fn fetch() -> @Result(i32, ApiError) {
    throw ApiError(msg: "not found");
}
fn strict() -> @Result(i32, string) {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class ApiError {
    constructor(msg) {
        this.msg = msg;
    }
}

function fetch() {
    throw ApiError("not found");
}

function strict() {
    const r = (() => { try { return fetch(); } catch(_e) { throw "fetch failed"; } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
