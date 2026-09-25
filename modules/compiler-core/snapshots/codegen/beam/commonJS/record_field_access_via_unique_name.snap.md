----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn first(p: Point) -> i32 {
    return p.x;
}
fn second(p: Point) -> i32 {
    return p.y;
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
Point.prototype.__bp = "Point";

function first(p) {
    return p.x;
}

function second(p) {
    return p.y;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
