----- SOURCE CODE -- main.bp
```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
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

    lengthSq() {
        return ((this.x * this.x) + (this.y * this.y));
    }

    scale(factor) {
        return (this.x * factor);
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
