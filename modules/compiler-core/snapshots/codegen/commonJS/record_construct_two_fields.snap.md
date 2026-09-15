----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn make() -> Point {
    return Point(x: 3, y: 4);
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

function make() {
    return new Point(3, 4);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
