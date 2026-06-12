----- SOURCE CODE -- main.bp
```botopink
record LoadError { msg: string }
*fn load() -> @Result<i32, LoadError> {
    throw LoadError(msg: "not found");
}
fn process() -> i32 {
    val prefix = 10;
    val data = try load() catch 0;
    val suffix = 20;
    @print(prefix, data, suffix);
    return prefix + data + suffix;
}
```

----- JAVASCRIPT -- main.js
```javascript
class LoadError {
    constructor(msg) {
        this.msg = msg;
    }
}

function load() {
    return ({ error: new LoadError("not found") });
}

function process() {
    const prefix = 10;
    const _try0 = load();
    const data = "error" in _try0 ? (0) : _try0.ok;
    const suffix = 20;
    console.log(prefix, data, suffix);
    return ((prefix + data) + suffix);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
