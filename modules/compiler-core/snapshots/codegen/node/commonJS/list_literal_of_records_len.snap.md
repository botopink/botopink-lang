----- SOURCE CODE -- main.bp
```botopink
record P { x: i32, y: i32 }
fn main() {
    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
    @print(pts.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
class P {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}

function main() {
    const pts = [new P(1, 2), new P(3, 4)];
    console.log(pts.len);
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
undefined
```
