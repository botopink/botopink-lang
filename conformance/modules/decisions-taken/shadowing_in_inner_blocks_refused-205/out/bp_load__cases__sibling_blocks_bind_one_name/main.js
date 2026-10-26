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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 205 — two sibling blocks may each bind the same name, since

//// neither sees the other's: an `if` and its `else`, two `if`s in sequence,

//// two loop bodies, two `case` arms' binders — and a block's binding followed by

//// the function's own binding of the name once the block has closed (the inner

//// one is no longer visible there). Each binding is its own block's; no target

//// invents a scope for it, and none leaks one out of it. 01-compiler/04-js

//// step 4: commonJS writes one `const` per block.

function pick(flag) {
    (() => { if (flag) { const n = 1; return __bp_print(n); } else { const n = 2; return __bp_print(n); } })();
    (() => { if (flag) { const m = 10; return __bp_print(m); } })();
    (() => { if ((!flag)) { const m = 20; return __bp_print(m); } })();
    return 0;
}

function loops() {
    let total = 0;
    for (const x of [1, 2]) {
    const step = __bp_int((x * 10), -2147483648, 2147483647, "* on i32 at src/main.bp:33:22");
    total = __bp_int((total + step), -2147483648, 2147483647, "+ on i32 at src/main.bp:34:23");
}
    for (const x of [3, 4]) {
    const step = __bp_int((x * 100), -2147483648, 2147483647, "* on i32 at src/main.bp:37:22");
    total = __bp_int((total + step), -2147483648, 2147483647, "+ on i32 at src/main.bp:38:23");
}
    return total;
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

    get $0() {
        return this.radius;
    }
}
Shape$Circle.prototype.tag = "Circle";
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

function arms(s) {
    return (() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { radius: v } = _s;
            return __bp_int((__bp_int((3 * v), -2147483648, 2147483647, "* on i32 at src/main.bp:50:24") * v), -2147483648, 2147483647, "* on i32 at src/main.bp:50:28");
        }
        if (_s.tag === "Square") {
            const { side: v } = _s;
            return __bp_int((v * v), -2147483648, 2147483647, "* on i32 at src/main.bp:51:24");
        }
        throw new Error("case_clause");
    })();
}

function after(flag) {
    (() => { if (flag) { const n = 1; return __bp_print(n); } })();
    const n = 2;
    return n;
}

function main() {
    __bp_print(pick(true));
    __bp_print(pick(false));
    __bp_print(loops());
    __bp_print(arms(Shape.Circle(2)));
    __bp_print(arms(Shape.Square(5)));
    __bp_print(after(true));
    __bp_print(after(false));
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
    return "cases/sibling_blocks_bind_one_name|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { pick, loops, Shape, Shape$Circle, Shape$Square, arms, after, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
