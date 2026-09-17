----- SOURCE CODE -- main.bp
```botopink
pub enum Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn main() {
    @print(Shape.Square(side: 4).area());
    @print(Shape.Circle(radius: 2).area());
}
```

----- JAVASCRIPT -- main.js
```javascript
const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Square: (side) => ({ tag: "Square", side }),
    area: function(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "Circle") {
                const { radius: r } = _s;
                return ((r * r) * 3);
            }
            if (_s.tag === "Square") {
                const { side: s } = _s;
                return (s * s);
            }
        })();
    },
});
exports.Shape = Shape;

function main() {
    console.log(Shape.area(Shape.Square(4)));
    console.log(Shape.area(Shape.Circle(2)));
}
exports.main = main;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare type Shape = { tag: "Circle", radius: i32 } | { tag: "Square", side: i32 };


export declare function main(): void;

```

----- RUN LOG -----
```logs
16
12
```
