----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
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

function recordEq() {
    const a = new Point(1, 2);
    const b = new Point(1, 2);
    return (a === b);
}

function arrayEq() {
    const xs = [1, 2];
    const ys = [1, 2];
    return (xs === ys);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
