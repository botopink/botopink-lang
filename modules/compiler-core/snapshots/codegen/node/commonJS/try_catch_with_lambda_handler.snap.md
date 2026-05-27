----- SOURCE CODE -- main.bp
```botopink
record FetchError { url: string }
fn fetch() -> @Result(i32, FetchError) {
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
    throw FetchError("/api");
}

function safe() {
    const r = (() => { try { return fetch(); } catch(_e) { return ((e) => {
    return 0;
})(_e); } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
