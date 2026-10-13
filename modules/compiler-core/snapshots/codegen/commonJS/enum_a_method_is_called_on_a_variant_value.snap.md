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
function __bp_f64(v) {
    if (!Number.isFinite(v)) { return String(v); }
    const s = Object.is(v, -0) ? "-0" : String(v);
    const i = s.indexOf("e");
    if (i < 0) { return s.indexOf(".") < 0 ? s + ".0" : s; }
    const m = s.slice(0, i);
    return (m.indexOf(".") < 0 ? m + ".0" : m) + "e" + s.slice(i + 1).replace("+", "");
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v) {
    const a = [];
    let i = 0;
    return __bp_show(v, null, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

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
                return __bp_int((__bp_int((r * r), -2147483648, 2147483647, "* on i32 at main.bp:7:28") * 3), -2147483648, 2147483647, "* on i32 at main.bp:7:32");
            }
            if (_s.tag === "Square") {
                const { side: s } = _s;
                return __bp_int((s * s), -2147483648, 2147483647, "* on i32 at main.bp:8:28");
            }
        })();
    }

    toString() {
        return __bp_text(this);
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
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Square, main } });
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
