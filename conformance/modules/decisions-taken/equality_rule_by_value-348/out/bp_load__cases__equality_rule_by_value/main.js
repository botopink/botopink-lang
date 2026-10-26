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

function __bp_eq_Point(a, b) {
    if (a === b) return true;
    return a.x === b.x && a.y === b.y;
}

function __bp_eq_Tuple2_i32_Array_Point(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && __bp_eq_Array_Point(a[1], b[1]);
}

function __bp_eq_Array_Point(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => __bp_eq_Point(e, b[i]));
}

function __bp_eq_Tuple2_i32_string(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function __bp_eq_Shape(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    if (a.tag === "Circle") return Object.is(a.radius, b.radius);
    if (a.tag === "Square") return Object.is(a.side, b.side);
    return true;
}

//// Decision 348 — 210 and 211 are the rule for `==`: records, tuples, lists

//// and enum variants compare by value, recursively; a method named `equals`

//// has no role. A tuple literal stands as `==`'s left operand like any other

//// operand.

class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    equals(other) {
        return true;
    }
}
Point.prototype.__bp = "Point";

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

    get $0() {
        return this.radius;
    }
}
Shape$Circle.prototype.tag = "Circle";
Shape$Circle.prototype.__bp_s = { radius: "f" };
class Shape$Square extends Shape {
    constructor(side) {
        super();
        this.side = side;
    }

    get $0() {
        return this.side;
    }
}
Shape$Square.prototype.tag = "Square";
Shape$Square.prototype.__bp_s = { side: "f" };

function main() {
    const a = new Point(1, 2);
    const b = new Point(1, 2);
    const c = new Point(5, 2);
    __bp_print(__bp_eq_Point(a, b));
    __bp_print(__bp_eq_Point(a, c));
    __bp_print(a.equals(c));
    __bp_print(__bp_eq_Tuple2_i32_Array_Point([1, [a, b]], [1, [new Point(1, 2), new Point(1, 2)]]));
    __bp_print(__bp_eq_Tuple2_i32_Array_Point([1, [a, b]], [1, [a, c]]));
    __bp_eq_Tuple2_i32_string([1, "x"], [1, "x"]);
    __bp_print(__bp_eq_Shape(Shape.Circle(1.0), Shape.Circle(1.0)));
    __bp_print((!__bp_eq_Shape(Shape.Circle(1.0), Shape.Square(1.0))));
}
exports.main = main;

function __bp_loaded_main() {
    main();
    return ({ ok: null });
}
exports.__bp_loaded_main = __bp_loaded_main;

function __bp_loaded_main_off() {
    return ({ error: "" });
}
exports.__bp_loaded_main_off = __bp_loaded_main_off;

function __bp_loaded_info() {
    return "cases/equality_rule_by_value|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Point, Shape, Shape$Circle, Shape$Square, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
