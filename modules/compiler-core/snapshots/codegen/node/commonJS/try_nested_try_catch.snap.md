----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
*fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
*fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
```

----- JAVASCRIPT -- main.js
```javascript
class DbError {
    constructor(msg) {
        this.msg = msg;
    }
}

function inner() {
    return ({ error: new DbError("conn refused") });
}

function outer() {
    return ({ error: new DbError("timeout") });
}

function process() {
    const _try0 = inner();
    const a = "error" in _try0 ? (0) : _try0.ok;
    const _try1 = outer();
    const b = "error" in _try1 ? (a) : _try1.ok;
    console.log(a, b);
    return (a + b);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
