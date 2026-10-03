----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Shape {
    static Circle(radius) {
        return new Shape$Circle(radius);
    }

    static Square(side) {
        return new Shape$Square(side);
    }

    static Triangle(base, height) {
        return new Shape$Triangle(base, height);
    }

    static area(shape) {
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
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Circle extends Shape {
    constructor(radius) {
        super();
        this.radius = radius;
    }
}
Shape$Circle.prototype.tag = "Circle";
class Shape$Square extends Shape {
    constructor(side) {
        super();
        this.side = side;
    }
}
Shape$Square.prototype.tag = "Square";
class Shape$Triangle extends Shape {
    constructor(base, height) {
        super();
        this.base = base;
        this.height = height;
    }
}
Shape$Triangle.prototype.tag = "Triangle";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
