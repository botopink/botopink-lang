----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: i32),
    Rect(width: i32, height: i32),
}
fn main() {
    val c = Shape.Circle(radius: 7);
    case c {
        .Circle(r) { @print(r); }
        _ { @print(0); }
    };
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

class Shape {
    static Circle(radius) {
        return new Shape$Circle(radius);
    }

    static Rect(width, height) {
        return new Shape$Rect(width, height);
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
class Shape$Rect extends Shape {
    constructor(width, height) {
        super();
        this.width = width;
        this.height = height;
    }
}
Shape$Rect.prototype.tag = "Rect";

function main() {
    const c = Shape.Circle(7);
    (() => {
        const _s = c;
        if (_s.tag === "Circle") {
            const { radius: r } = _s;
            return __bp_print(r);
        }
        {
            return __bp_print(0);
        }
    })();
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Rect, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
7
```
