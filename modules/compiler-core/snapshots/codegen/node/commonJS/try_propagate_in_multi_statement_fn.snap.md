----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
*fn step1() -> @Result<i32, IoError> {
    throw IoError(path: "/data");
}
*fn step2(x: i32) -> @Result<i32, IoError> {
    throw IoError(path: "/out");
}
*fn pipeline() -> @Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- JAVASCRIPT -- main.js
```javascript
class IoError {
    constructor(path) {
        this.path = path;
    }
}

function step1() {
    return ({ error: new IoError("/data") });
}

function step2(x) {
    return ({ error: new IoError("/out") });
}

function pipeline() {
    const _try0 = step1();
    if ("error" in _try0) return _try0;
    const a = _try0.ok;
    const _try1 = step2(a);
    if ("error" in _try1) return _try1;
    const b = _try1.ok;
    return ({ ok: b });
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
