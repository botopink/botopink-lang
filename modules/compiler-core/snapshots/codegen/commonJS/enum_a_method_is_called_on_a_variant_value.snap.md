----- SOURCE CODE -- main.bp
```botopink
pub type Shape {
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
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Shape {
    static Circle(radius) {
        return new Shape$Circle(radius);
    }

    static Square(side) {
        return new Shape$Square(side);
    }

    static area(self) {
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
exports.Shape = Shape;

function main() {
    __bp_print(Shape.area(Shape.Square(4)));
    __bp_print(Shape.area(Shape.Circle(2)));
}
exports.main = main;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare class Shape {
    readonly tag: "Circle" | "Square";
    static Circle(radius: number): Shape;
    static Square(side: number): Shape;
    static area(self: Shape): number;
}


export declare function main(): void;

```

----- RUN LOG -----
```logs
16
12
```
