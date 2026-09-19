----- SOURCE CODE -- main.bp
```botopink
type Vec2(
    x: f64,
    y: f64) {
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Vec2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    dot(other) {
        return ((this.x * other.x) + (this.y * other.y));
    }
}
Vec2.prototype.__bp = "Vec2";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
