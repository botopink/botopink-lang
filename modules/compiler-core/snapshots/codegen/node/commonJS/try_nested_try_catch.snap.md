----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
fn inner() -> @Result(i32, DbError) {
    throw DbError(msg: "conn refused");
}
fn outer() -> @Result(i32, DbError) {
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
    throw DbError("conn refused");
}

function outer() {
    throw DbError("timeout");
}

function process() {
    const a = (() => { try { return inner(); } catch(_e) { return (0)(_e); } })();
    const b = (() => { try { return outer(); } catch(_e) { return (a)(_e); } })();
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
