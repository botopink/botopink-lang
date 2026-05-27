----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result(i32, IoError) {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result(i32, IoError) {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result(i32, IoError) {
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
    throw IoError("/data");
}

function step2(x) {
    throw IoError("/out");
}

function pipeline() {
    const a = step1();
    const b = step2(a);
    return b;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
