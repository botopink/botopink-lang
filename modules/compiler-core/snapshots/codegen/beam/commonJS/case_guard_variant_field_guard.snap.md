----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
class Shape {
    static Circle(r) {
        return new Shape$Circle(r);
    }

    static Square(s) {
        return new Shape$Square(s);
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Circle extends Shape {
    constructor(r) {
        super();
        this.r = r;
    }
}
Shape$Circle.prototype.tag = "Circle";
class Shape$Square extends Shape {
    constructor(s) {
        super();
        this.s = s;
    }
}
Shape$Square.prototype.tag = "Square";

function big(sh) {
    return (() => {
        const _s = sh;
        if (_s.tag === "Circle") {
            const { r } = _s;
            if ((r > 10)) return "big circle";
        }
        return "other";
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
