----- SOURCE CODE -- main.bp
```botopink
type CalcError(msg: string)
fn getA() -> Result<i32, CalcError> {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = try getA() catch 0;
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
CalcError.prototype.__bp = "CalcError";

function getA() {
    return ({ error: new CalcError("overflow") });
}

function compute() {
    const _try0 = getA();
    const r = "error" in _try0 ? (0) : _try0.ok;
    return r;
}

Object.defineProperty(exports, "__bp_priv__", { value: { CalcError, getA, compute } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
