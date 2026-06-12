----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn main() {
    val r = R(a: 7, b: 11);
    @print(r.b);
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

function main() {
    const r = new R(7, 11);
    console.log(r.b);
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
11
```
