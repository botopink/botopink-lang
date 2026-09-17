----- SOURCE CODE -- main.bp
```botopink
enum Shape { Circle(radius: f64), Square(side: f64) }
fn area(s: Shape) -> f64 {
    return case s {
        Circle(r) -> 3.14 * r * r;
        Square(s) -> s * s;
    };
}
fn main() {
    @print(area(Shape.Circle(2.0)));
    @print(area(Shape.Square(3.0)));
}
```

----- JAVASCRIPT -- main.js
```javascript
const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Square: (side) => ({ tag: "Square", side }),
});

function area(s) {
    return (() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { radius: r } = _s;
            return ((3.14 * r) * r);
        }
        if (_s.tag === "Square") {
            const { side: s } = _s;
            return (s * s);
        }
    })();
}

function main() {
    console.log(area(Shape.Circle(2.0)));
    console.log(area(Shape.Square(3.0)));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
12.56
9
```
