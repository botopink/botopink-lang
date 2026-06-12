----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
*fn fetch() -> @Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- JAVASCRIPT -- main.js
```javascript
class Error {
    constructor(msg) {
        this.msg = msg;
    }
}

function fetch() {
    return ({ error: new Error("boom") });
}

function f() {
    const _try0 = fetch();
    if ("error" in _try0) { throw new Error("failed"); }
    const [ a, b ] = _try0.ok;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
