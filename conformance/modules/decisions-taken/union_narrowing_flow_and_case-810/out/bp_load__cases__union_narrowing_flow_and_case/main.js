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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 810 — a union narrows by the flow of an `is` and by an

//// exhaustive `case` with type patterns, both in force. (2) Past an `if`

//// whose branch leaves, the name is the union without the member it tested,

//// each further test removing one more; in the `else` too; for a parameter,

//// a `val`, a loop's binder and a `var` until it is assigned. (1) `v is

//// Box<T>` is accepted where `Box<T>` is a member of `v`'s type, `T` bound

//// through it. (3) A `case` over a union covers it with a type pattern per

//// member, a generic one included (`Box<T> { b -> … }`), and needs no `_`.

class Dot {
    constructor(label) {
        this.label = label;
    }
}
Dot.prototype.__bp = "Dot";

class Circle {
    constructor(r) {
        this.r = r;
    }
}
Circle.prototype.__bp = "Circle";

class Square {
    constructor(side) {
        this.side = side;
    }
}
Square.prototype.__bp = "Square";

class Box {
    constructor(item) {
        this.item = item;
    }
}
Box.prototype.__bp = "Box";

class Pair {
    constructor(left, right) {
        this.left = left;
        this.right = right;
    }
}
Pair.prototype.__bp = "Pair";

function area(s) {
    if (s instanceof Dot) { return 0; }
    if (s instanceof Circle) { return __bp_int((__bp_int((s.r * s.r), -2147483648, 2147483647, "* on i32 at src/main.bp:24:33") * 3), -2147483648, 2147483647, "* on i32 at src/main.bp:24:39"); }
    return __bp_int((s.side * s.side), -2147483648, 2147483647, "* on i32 at src/main.bp:25:19");
}

function name(s) {
    if (s instanceof Dot) { return s.label; } else { return ("circle " + s.r.toString()); }
}

function viaLocals(s) {
    const v = s;
    if (v instanceof Square) { return "square"; }
    let w = v;
    if (w instanceof Dot) { return w.label; }
    const r = w.r;
    w = new Dot("reset");
    return ("r=" + r.toString());
}

function sides(shapes) {
    let total = 0;
    for (const s of shapes) {
    if (s instanceof Dot) { continue; }
    total = __bp_int((total + s.side), -2147483648, 2147483647, "+ on i32 at src/main.bp:46:23");
}
    return total;
}

function first(v) {
    if (v instanceof Box) { return v.item; }
    return v.left;
}

function firstCase(v) {
    return (() => {
        const _s = v;
        if (_s instanceof Box) {
            const b = _s;
            return b.item;
        }
        if (_s instanceof Pair) {
            const p = _s;
            return p.left;
        }
        throw new Error("case_clause");
    })();
}

function describe(s) {
    return (() => {
        const _s = s;
        if (_s instanceof Dot) {
            const d = _s;
            return ("dot " + d.label);
        }
        if (_s instanceof Circle) {
            const c = _s;
            return ("circle " + c.r.toString());
        }
        if (_s instanceof Square) {
            const q = _s;
            return ("square " + q.side.toString());
        }
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print(area(new Dot("d")), area(new Circle(2)), area(new Square(4)));
    __bp_print(name(new Dot("dot")));
    __bp_print(name(new Circle(5)));
    __bp_print(viaLocals(new Square(1)), viaLocals(new Dot("kept")), viaLocals(new Circle(7)));
    __bp_print(sides([new Dot("a"), new Square(2), new Square(3)]));
    __bp_print(first(new Box("boxed")), first(new Pair("left", "right")));
    __bp_print(firstCase(new Box(1)), firstCase(new Pair(2, 3)));
    __bp_print(describe(new Dot("x")));
    __bp_print(describe(new Circle(1)));
    __bp_print(describe(new Square(9)));
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
    return "cases/union_narrowing_flow_and_case|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Dot, Circle, Square, Box, Pair, area, name, viaLocals, sides, first, firstCase, describe, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
