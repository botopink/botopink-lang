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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 330 — `recv?.m()` over a method of a record or of an all-unit

//// enum: the receiver is evaluated once, the method runs only on a present

//// one, and the call is the optional of its answer — a present `0`, `false`

//// stays present, a float answer too, an answer that is itself optional is

//// not nested — on every target (`modules/optional_method_absent_receiver`

//// is a primitive receiver, `modules/optional_enum_method_absent_receiver`

//// an enum with payloads).

class P {
    constructor(x) {
        this.x = x;
    }

    twice() {
        return __bp_int((this.x * 2), -2147483648, 2147483647, "* on i32 at src/main.bp:13:23");
    }

    half() {
        return 1.5;
    }

    zero() {
        return (this.x === 0);
    }

    maybe() {
        return (() => { if ((this.x === 0)) { return 0; } else { return null; } })();
    }

    me() {
        return new P(__bp_int((this.x + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:25:28"));
    }
}
P.prototype.__bp = "P";

class C {
    static n(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "Red") return 0;
            if (_s.tag === "Green") return 1;
            throw new Error("case_clause");
        })();
    }

    toString() {
        return __bp_text(this);
    }
}
C.prototype.__bp = "C";
class C$Red extends C {
}
C$Red.prototype.tag = "Red";
class C$Green extends C {
}
C$Green.prototype.tag = "Green";
C.Red = new C$Red();
C.Green = new C$Green();

function p(c) {
    return (() => { if (c) { return new P(0); } else { return null; } })();
}

function col(c) {
    if ((c === 0)) { return null; }
    if ((c === 1)) { return C.Red; }
    return C.Green;
}

function main() {
    __bp_print(p(true)?.twice());
    __bp_print_as(["f"], (() => { const __bp_nullish = p(true)?.half(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1.0); } })());
    __bp_print_as(["f"], (() => { const __bp_nullish = p(false)?.half(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1.0); } })());
    __bp_print((() => { const __bp_nullish = p(true)?.zero(); if (__bp_nullish != null) { return __bp_nullish; } else { return false; } })());
    __bp_print((() => { const __bp_nullish = p(false)?.zero(); if (__bp_nullish != null) { return __bp_nullish; } else { return false; } })());
    __bp_print((() => { const __bp_nullish = p(true)?.maybe(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = p(false)?.maybe(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = p(true)?.me()?.x; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = p(false)?.me()?.x; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : C.n(__bp_recv)))(col(1)); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : C.n(__bp_recv)))(col(2)); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : C.n(__bp_recv)))(col(0)); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    const q = p(true);
    __bp_print((() => { const __bp_nullish = q?.twice(); if (__bp_nullish != null) { return __bp_nullish; } else { return 7; } })());
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
    return "cases/optional_record_method_absent_receiver|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { P, C, C$Red, C$Green, p, col, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
