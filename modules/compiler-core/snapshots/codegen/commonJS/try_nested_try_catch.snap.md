----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
#[@result]
fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
#[@result]
fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
fn main() {
    @print(process());
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

function main() {
    console.log(process());
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript









```

----- RUN LOG -----
```logs
0 0
0
```
