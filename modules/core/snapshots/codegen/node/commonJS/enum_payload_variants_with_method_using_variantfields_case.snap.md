----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            else -> 0.0;
        };
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Square: (side) => ({ tag: "Square", side }),
    Triangle: (base, height) => ({ tag: "Triangle", base, height }),
    area: function(shape) {
        return (() => {
            const _s = shape;
            if (_s.tag === "Circle") {
                const { radius } = _s;
                return ((radius * radius) * 3.14);
            }
            if (_s.tag === "Square") {
                const { side } = _s;
                return (side * side);
            }
            if (_s.tag === "Triangle") {
                const { base, height } = _s;
                return ((base * height) * 0.5);
            }
            return 0.0;
        })();
    },
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
