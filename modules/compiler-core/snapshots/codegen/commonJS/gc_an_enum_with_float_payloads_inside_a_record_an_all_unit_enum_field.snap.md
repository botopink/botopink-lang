----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

type Color { Red, Green, Blue }

type Item(shape: Shape, color: Color, label: string)

fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}

fn warm(c: Color) -> bool {
    return case c {
        Red -> true;
        Green -> false;
        Blue -> false;
    };
}

pub fn main() {
    @print(area(Shape.Square(side: 2.0)));
    @print(area(Shape.Circle(radius: 1.0)));
    val it = Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x");
    @print(it);
    @print(warm(it.color));
    @print(it.color);
    @print(area(it.shape));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
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
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Shape {
    static Circle(radius) {
        return new Shape$Circle(radius);
    }

    static Square(side) {
        return new Shape$Square(side);
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
Shape$Circle.prototype.__bp_s = { radius: "f" };
class Shape$Square extends Shape {
    constructor(side) {
        super();
        this.side = side;
    }
}
Shape$Square.prototype.tag = "Square";
Shape$Square.prototype.__bp_s = { side: "f" };

class Color {
    toString() {
        return __bp_text(this);
    }
}
Color.prototype.__bp = "Color";
class Color$Red extends Color {
}
Color$Red.prototype.tag = "Red";
class Color$Green extends Color {
}
Color$Green.prototype.tag = "Green";
class Color$Blue extends Color {
}
Color$Blue.prototype.tag = "Blue";
Color.Red = new Color$Red();
Color.Green = new Color$Green();
Color.Blue = new Color$Blue();

class Item {
    constructor(shape, color, label) {
        this.shape = shape;
        this.color = color;
        this.label = label;
    }
}
Item.prototype.__bp = "Item";

function area(shape) {
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
        throw new Error("case_clause");
    })();
}

function warm(c) {
    return (() => {
        const _s = c;
        if (_s.tag === "Red") return true;
        if (_s.tag === "Green") return false;
        if (_s.tag === "Blue") return false;
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print_as(["f"], area(Shape.Square(2.0)));
    __bp_print_as(["f"], area(Shape.Circle(1.0)));
    const it = new Item(Shape.Square(3.0), Color.Green, "x");
    __bp_print(it);
    __bp_print(warm(it.color));
    __bp_print(it.color);
    __bp_print_as(["f"], area(it.shape));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Square, Color, Color$Red, Color$Green, Color$Blue, Item, area, warm, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript










export declare function main(): void;

```

----- RUN LOG -----
```logs
4.0
3.14
Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x")
false
Color.Green
9.0
```
