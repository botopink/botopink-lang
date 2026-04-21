----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> #(i32, i32) {
    return #(1, 2);
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
    return [1, 2];
}

function f() {
    const [ a, b ] = (() => { try { return fetch(); } catch(_e) { throw Error("failed"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```
