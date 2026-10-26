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

//// A multi-subject `case a, n { … }` matches every subject against its own

//// pattern: a literal, a string, a primitive type over a union, a variant that

//// binds its payload, a guard reading the subjects, `true` / `false`. wasm lowered

//// the first subject alone and tested no `.multi` pattern, so the first arm

//// answered every call; beam tested the numbers alone, so a string pattern and

//// a type arm matched every value (`i32, 0` took `"s"`); commonJS tested a

//// variant's tag and never bound its payload (`r is not defined`).

class Shape {
    static Circle(r) {
        return new Shape$Circle(r);
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
    constructor(r) {
        super();
        this.r = r;
    }

    get $0() {
        return this.r;
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
class Shape$Empty extends Shape {
}
Shape$Empty.prototype.tag = "Empty";
Shape.Empty = new Shape$Empty();

function classify(a, n) {
    return (() => {
        const _s = [a, n];
        if (_s[0] === 0 && _s[1] === "x") return "zero-x";
        if (_s[0] === 0) return "zero";
        if (_s[1] === "x") return "x";
        return "other";
        throw new Error("case_clause");
    })();
}

function kind(v, n) {
    return (() => {
        const _s = [v, n];
        if ((typeof _s[0] === "number" && Number.isInteger(_s[0]) && _s[0] >= -2147483648 && _s[0] <= 2147483647) && _s[1] === 0) return "int0";
        if (typeof _s[0] === "string" && _s[1] === 0) return "str0";
        return "any";
        throw new Error("case_clause");
    })();
}

function area(s, k) {
    return (() => {
        const _s = [s, k];
        if (_s[0].tag === "Circle" && _s[1] === 1) {
            const { r } = _s[0];
            return __bp_int((r * 100), -2147483648, 2147483647, "* on i32 at src/main.bp:36:33");
        }
        if (_s[0].tag === "Square") {
            const { side } = _s[0];
            return __bp_int((side * k), -2147483648, 2147483647, "* on i32 at src/main.bp:37:39");
        }
        if (_s[0].tag === "Empty") return (-1);
        return 0;
        throw new Error("case_clause");
    })();
}

function guarded(a, b) {
    return (() => {
        const _s = [a, b];
        {
            if ((a > b)) return ("gt " + a.toString());
        }
        {
            if ((a === b)) return ("eq " + b.toString());
        }
        return ("lt " + b.toString());
        throw new Error("case_clause");
    })();
}

function flags(a, b) {
    return (() => {
        const _s = [a, b];
        {
            const __bp_case_bool_0 = _s[0];
            const __bp_case_bool_1 = _s[1];
            if (((__bp_case_bool_1 === true) && (__bp_case_bool_0 === true))) return "both";
        }
        {
            const __bp_case_bool_0 = _s[0];
            const __bp_case_bool_1 = _s[1];
            if (((__bp_case_bool_1 === false) && (__bp_case_bool_0 === true))) return "first";
        }
        {
            const __bp_case_bool_0 = _s[0];
            const __bp_case_bool_1 = _s[1];
            if (((__bp_case_bool_1 === true) && (__bp_case_bool_0 === false))) return "second";
        }
        {
            const __bp_case_bool_0 = _s[0];
            const __bp_case_bool_1 = _s[1];
            if (((__bp_case_bool_1 === false) && (__bp_case_bool_0 === false))) return "none";
        }
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print(classify(0, "x"));
    __bp_print(classify(0, "y"));
    __bp_print(classify(1, "x"));
    __bp_print(classify(1, "y"));
    __bp_print(kind(1, 0));
    __bp_print(kind("s", 0));
    __bp_print(kind(1, 1));
    __bp_print(area(Shape.Circle(2), 1));
    __bp_print(area(Shape.Circle(2), 2));
    __bp_print(area(Shape.Square(3), 4));
    __bp_print(area(Shape.Empty, 9));
    __bp_print(guarded(5, 2));
    __bp_print(guarded(3, 3));
    __bp_print(guarded(1, 7));
    __bp_print(flags(true, true));
    __bp_print(flags(true, false));
    __bp_print(flags(false, true));
    __bp_print(flags(false, false));
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
    return "cases/case_multi_subject_patterns|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Square, Shape$Empty, classify, kind, area, guarded, flags, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
