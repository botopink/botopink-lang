----- SOURCE CODE -- main.bp
```botopink
val Point = type(
    x: i32,
    y: i32) {
    fn sum(self: Self) -> i32 {
        return self.x + self.y;
    }
};
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    sum() {
        return __bp_int((this.x + this.y), -2147483648, 2147483647, "+ on i32 at main.bp:5:23");
    }
}
Point.prototype.__bp = "Point";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
