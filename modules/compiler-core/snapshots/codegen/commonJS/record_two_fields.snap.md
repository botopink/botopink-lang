----- SOURCE CODE -- main.bp
```botopink
val Point = type(x: i32, y: i32)
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

Object.defineProperty(exports, "__bp_priv__", { value: { Point } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
