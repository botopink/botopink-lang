----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
*fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
*fn strict() -> @Result<i32, string> {
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
    return ({ error: new ApiError("not found") });
}

function strict() {
    const _try0 = fetch();
    if ("error" in _try0) { return ({ error: "fetch failed" }); }
    const r = _try0.ok;
    return ({ ok: r });
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
