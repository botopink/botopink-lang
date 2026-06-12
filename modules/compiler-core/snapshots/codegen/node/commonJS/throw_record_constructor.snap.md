----- SOURCE CODE -- main.bp
```botopink
record AppError { code: i32, msg: string }
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
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

function validate(x) {
    (() => { if ((x < 0)) { throw new AppError(400, "negative"); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
