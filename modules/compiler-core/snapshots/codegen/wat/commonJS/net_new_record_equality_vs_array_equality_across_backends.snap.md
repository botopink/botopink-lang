----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
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
function __bp_eq_Point(a, b) {
    if (a === b) return true;
    return a.x === b.x && a.y === b.y;
}

function __bp_eq_Array_i32(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => e === b[i]);
}

class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}
Point.prototype.__bp = "Point";

function recordEq() {
    const a = new Point(1, 2);
    const b = new Point(1, 2);
    return __bp_eq_Point(a, b);
}

function arrayEq() {
    const xs = [1, 2];
    const ys = [1, 2];
    return __bp_eq_Array_i32(xs, ys);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
