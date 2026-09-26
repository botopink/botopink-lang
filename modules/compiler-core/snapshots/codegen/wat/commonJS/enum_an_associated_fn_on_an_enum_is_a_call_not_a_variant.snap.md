----- SOURCE CODE -- main.bp
```botopink
pub type Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn unit() -> Shape {
        return Shape.Square(side: 1);
    }

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

fn main() {
    val s: Shape = Shape.unit();
    @print(s.area());
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
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

    static unit() {
        return Shape.Square(1);
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
    const s = Shape.unit();
    __bp_print(Shape.area(s));
}

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
    static unit(): Shape;
    static area(self: Shape): number;
}



```

----- RUN LOG -----
```logs
1
```
