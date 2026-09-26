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
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    sum() {
        return (this.x + this.y);
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
