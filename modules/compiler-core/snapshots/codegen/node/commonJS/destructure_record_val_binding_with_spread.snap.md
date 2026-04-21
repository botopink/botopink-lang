----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32, z: i32 }
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- JAVASCRIPT -- main.js
```javascript
class Point {
    constructor(x, y, z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

function describe(p) {
    const { x, ... } = p;
    return x;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
