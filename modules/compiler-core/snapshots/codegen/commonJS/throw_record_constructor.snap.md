----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) -> Result<void, AppError> {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
class AppError {
    constructor(code, msg) {
        this.code = code;
        this.msg = msg;
    }
}
AppError.prototype.__bp = "AppError";

function validate(x) {
    if ((x < 0)) { return ({ error: new AppError(400, "negative") }); }
    return ({ ok: null });
}

Object.defineProperty(exports, "__bp_priv__", { value: { AppError, validate } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
