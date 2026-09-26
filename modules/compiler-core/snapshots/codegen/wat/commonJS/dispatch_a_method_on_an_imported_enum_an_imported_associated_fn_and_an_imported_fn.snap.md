----- SOURCE CODE -- geometry.bp
```botopink
pub type Counter(n: i32) {
    pub fn zero() -> Self { return Counter(n: 0); }
    pub fn bump(self: Self) -> i32 { return self.n + 1; }
}

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

pub fn make() -> Counter { return Counter(n: 41); }
```

----- JAVASCRIPT -- geometry.js
```javascript
class Counter {
    constructor(n) {
        this.n = n;
    }

    static zero() {
        return new Counter(0);
    }

    bump() {
        return (this.n + 1);
    }
}
Counter.prototype.__bp = "Counter";
exports.Counter = Counter;

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

function make() {
    return new Counter(41);
}
exports.make = make;
```

----- TYPESCRIPT TYPEDEF -- geometry.d.ts
```typescript
export declare class Counter {
    readonly n: number;
    constructor(n: number);
    zero(): Counter;
    bump(): number;
}


export declare class Shape {
    readonly tag: "Circle" | "Square";
    static Circle(radius: number): Shape;
    static Square(side: number): Shape;
    static area(self: Shape): number;
}


export declare function make(): Counter;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Counter, Shape, make} from "geometry";
fn main() {
    val c: Counter = Counter.zero();
    @print(c.bump());
    @print(Shape.Square(side: 4).area());
    @print(make().bump());
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

const { Counter, Shape, make } = require("./geometry.js");

function main() {
    const c = Counter.zero();
    __bp_print(c.bump());
    __bp_print(Shape.area(Shape.Square(4)));
    __bp_print(make().bump());
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Counter, Shape, make } from "./geometry";







```

----- RUN LOG -----
```logs
1
16
42
```
