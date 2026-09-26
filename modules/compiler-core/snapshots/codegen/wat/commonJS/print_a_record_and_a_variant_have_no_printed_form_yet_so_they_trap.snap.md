----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
type Shape { Square(side: i32), Nothing }
fn main() {
    @print("hi");
    @print([1, 2]);
    @print(#(1, "a"));
    @print(Point(x: 1, y: 2));
    @print(Shape.Square(side: 4));
    @print(Shape.Nothing);
    @print([Point(x: 1, y: 2)]);
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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}
Point.prototype.__bp = "Point";

class Shape {
    static Square(side) {
        return new Shape$Square(side);
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Square extends Shape {
    constructor(side) {
        super();
        this.side = side;
    }
}
Shape$Square.prototype.tag = "Square";
class Shape$Nothing extends Shape {
}
Shape$Nothing.prototype.tag = "Nothing";
Shape.Nothing = new Shape$Nothing();

function main() {
    __bp_print("hi");
    __bp_print([1, 2]);
    __bp_print_as([["#", null, null]], [1, "a"]);
    __bp_print(new Point(1, 2));
    __bp_print(Shape.Square(4));
    __bp_print(Shape.Nothing);
    __bp_print([new Point(1, 2)]);
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
hi
[1, 2]
#(1, "a")
Point(x: 1, y: 2)
Shape.Square(side: 4)
Shape.Nothing
[Point(x: 1, y: 2)]
```
