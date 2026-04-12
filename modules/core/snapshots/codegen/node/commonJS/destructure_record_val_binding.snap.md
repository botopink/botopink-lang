----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    return x;
}
```

----- JAVASCRIPT -- main.js
```javascript
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}

function describe(p) {
    const { x, y } = p;
    return x;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
