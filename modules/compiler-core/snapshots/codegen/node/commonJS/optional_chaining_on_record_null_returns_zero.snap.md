----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn pick(maybe: ?R) -> i32 {
    return maybe?.b;
}
```

----- JAVASCRIPT -- main.js
```javascript
class R {
    constructor(a, b) {
        this.a = a;
        this.b = b;
    }
}

function pick(maybe) {
    return maybe?.b;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
