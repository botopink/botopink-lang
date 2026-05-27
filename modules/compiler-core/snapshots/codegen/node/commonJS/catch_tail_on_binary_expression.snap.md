----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
fn getA() -> @Result(i32, CalcError) {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class CalcError {
    constructor(msg) {
        this.msg = msg;
    }
}

function getA() {
    throw CalcError("overflow");
}

function compute() {
    const r = (() => { try { return getA(); } catch(_e) { return (0)(_e); } })();
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
