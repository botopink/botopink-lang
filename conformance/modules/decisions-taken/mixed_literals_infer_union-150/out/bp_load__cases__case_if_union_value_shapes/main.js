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

//// Decision 150 (decision 8 §3.2) — a `case` whose arms disagree, and an

//// `if` / `else` whose branches do, is the union of their types whatever

//// shape an arm is written in (a value, a block, a lambda arm, over an

//// `unknown` subject, inside an `async` body that awaits) and wherever the

//// value goes (a `val`, a `return` from a function answering the union, an

//// argument of a parameter of it): each value read back is the member it is.

class Shape {
    static Circle(r) {
        return new Shape$Circle(r);
    }

    static Label(text) {
        return new Shape$Label(text);
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
class Shape$Label extends Shape {
    constructor(text) {
        super();
        this.text = text;
    }

    get $0() {
        return this.text;
    }
}
Shape$Label.prototype.tag = "Label";

function show(v) {
    return (() => {
        const _s = v;
        if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
            const n = _s;
            return ("number " + n);
        }
        if (typeof _s === "string") {
            const t = _s;
            return ("text " + t);
        }
        throw new Error("case_clause");
    })();
}

function blockArms(s) {
    const v = (() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { r } = _s;
            const d = __bp_int((r * 2), -2147483648, 2147483647, "* on i32 at src/main.bp:29:23");
            return d;
        }
        if (_s.tag === "Label") {
            const { text } = _s;
            return text;
        }
        throw new Error("case_clause");
    })();
    return (() => {
                const _s = v;
                if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
                    const n = _s;
                    return ("number " + n);
                }
                if (typeof _s === "string") {
                    const t = _s;
                    return ("text " + t);
                }
                throw new Error("case_clause");
            })();
}

function lambdaArms(u) {
    const v = (() => {
        const _s = u;
        if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
            const n = _s;
            return __bp_int((n * 3), -2147483648, 2147483647, "* on i32 at src/main.bp:49:15");
        }
        if (typeof _s === "string") {
            const t = _s;
            return (t + "!");
        }
        throw new Error("case_clause");
    })();
    return (() => {
                const _s = v;
                if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
                    const n = _s;
                    return ("number " + n);
                }
                if (typeof _s === "string") {
                    const t = _s;
                    return ("text " + t);
                }
                throw new Error("case_clause");
            })();
}

function unknownSubject(u) {
    const v = (() => {
        const _s = u;
        if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
            const n = _s;
            return __bp_int((n * 4), -2147483648, 2147483647, "* on i32 at src/main.bp:68:15");
        }
        return "other";
    })();
    return (() => {
                const _s = v;
                if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
                    const n = _s;
                    return ("number " + n);
                }
                if (typeof _s === "string") {
                    const t = _s;
                    return ("text " + t);
                }
                throw new Error("case_clause");
            })();
}

function pick(s) {
    return (() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { r } = _s;
            return __bp_int((r * 5), -2147483648, 2147483647, "* on i32 at src/main.bp:84:24");
        }
        if (_s.tag === "Label") {
            const { text } = _s;
            return text;
        }
        throw new Error("case_clause");
    })();
}

function argument(s) {
    return show((() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { r } = _s;
            return __bp_int((r * 6), -2147483648, 2147483647, "* on i32 at src/main.bp:91:24");
        }
        if (_s.tag === "Label") {
            const { text } = _s;
            return text;
        }
        throw new Error("case_clause");
    })());
}

function ifValue(b) {
    const v = (() => { if (b) { const d = 7; return d; } else { const t = "seven"; return t; } })();
    return (() => {
        const _s = v;
        if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
            const n = _s;
            return ("number " + n);
        }
        if (typeof _s === "string") {
            const t = _s;
            return ("text " + t);
        }
        throw new Error("case_clause");
    })();
}

function ifReturn(b) {
    return (() => { if (b) { return 8; } else { return "eight"; } })();
}

function ifArgument(b) {
    return show((() => { if (b) { return 9; } else { return "nine"; } })());
}

function later(n) {
    return (async () => {
        return n;
    })();
}

function machine(s) {
    return (async () => {
        const k = await later(10);
        const v = (() => {
            const _s = s;
            if (_s.tag === "Circle") {
                const { r } = _s;
                return __bp_int((r * k), -2147483648, 2147483647, "* on i32 at src/main.bp:132:28");
            }
            if (_s.tag === "Label") {
                const { text } = _s;
                return text;
            }
            throw new Error("case_clause");
        })();
        return (() => {
            const _s = v;
            if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
                const n = _s;
                return ("number " + n);
            }
            if (typeof _s === "string") {
                const t = _s;
                return ("text " + t);
            }
            throw new Error("case_clause");
        })();
    })();
}

async function run() {
    __bp_print(await machine(Shape.Circle(1)));
    __bp_print(await machine(Shape.Label("m")));
}

function pickBlock(s) {
    return (() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { r } = _s;
            const d = __bp_int((r * 11), -2147483648, 2147483647, "* on i32 at src/main.bp:154:23");
            return d;
        }
        if (_s.tag === "Label") {
            const { text } = _s;
            return text;
        }
        throw new Error("case_clause");
    })();
}

function argumentBlock(s) {
    return show((() => {
        const _s = s;
        if (_s.tag === "Circle") {
            const { r } = _s;
            const d = __bp_int((r * 12), -2147483648, 2147483647, "* on i32 at src/main.bp:166:23");
            return d;
        }
        if (_s.tag === "Label") {
            const { text } = _s;
            return text;
        }
        throw new Error("case_clause");
    })());
}

function ifReturnBlock(b) {
    return (() => { if (b) { const d = 13; return d; } else { return "thirteen"; } })();
}

function ifArgumentBlock(b) {
    return show((() => { if (b) { const d = 14; return d; } else { return "fourteen"; } })());
}

function ifPlainValue(b) {
    const v = (() => { if (b) { return 15; } else { return "fifteen"; } })();
    return show(v);
}

function main() {
    __bp_print(blockArms(Shape.Circle(1)));
    __bp_print(blockArms(Shape.Label("b")));
    __bp_print(lambdaArms(1));
    __bp_print(lambdaArms("l"));
    __bp_print(unknownSubject(1));
    __bp_print(unknownSubject("u"));
    __bp_print(show(pick(Shape.Circle(1))));
    __bp_print(show(pick(Shape.Label("p"))));
    __bp_print(argument(Shape.Circle(1)));
    __bp_print(argument(Shape.Label("a")));
    __bp_print(ifValue(true));
    __bp_print(ifValue(false));
    __bp_print(show(ifReturn(true)));
    __bp_print(show(ifReturn(false)));
    __bp_print(ifArgument(true));
    __bp_print(ifArgument(false));
    __bp_print(show(pickBlock(Shape.Circle(1))));
    __bp_print(show(pickBlock(Shape.Label("pb"))));
    __bp_print(argumentBlock(Shape.Circle(1)));
    __bp_print(argumentBlock(Shape.Label("ab")));
    __bp_print(show(ifReturnBlock(true)));
    __bp_print(show(ifReturnBlock(false)));
    __bp_print(ifArgumentBlock(true));
    __bp_print(ifArgumentBlock(false));
    __bp_print(ifPlainValue(true));
    __bp_print(ifPlainValue(false));
    run();
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
    return "cases/case_if_union_value_shapes|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Label, show, blockArms, lambdaArms, unknownSubject, pick, argument, ifValue, ifReturn, ifArgument, later, machine, run, pickBlock, argumentBlock, ifReturnBlock, ifArgumentBlock, ifPlainValue, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
