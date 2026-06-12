----- SOURCE CODE -- main.bp
```botopink
record FetchError { url: string }
*fn fetch() -> @Result<i32, FetchError> {
    throw FetchError(url: "/api");
}
fn safe() -> i32 {
    val r = try fetch() catch fn(e) { return 0; };
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class FetchError {
    constructor(url) {
        this.url = url;
    }
}

function fetch() {
    return ({ error: new FetchError("/api") });
}

function safe() {
    const _try0 = fetch();
    const r = "error" in _try0 ? ((e) => {
    return 0;
})(_try0.error) : _try0.ok;
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
