const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

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

//// Decision 330 — a field read written after a `?.` link continues the

//// chain, as a method there does (`find(0)?.str().length()`) and as

//// TypeScript's does: `p(true)?.me().x` reads `x` off the record `me()`

//// answers when `p(true)` is present, and is absent when it is not, so `??`

//// takes its default; the receiver is evaluated once, on every target. A

//// field after a field link (`p(true)?.inner.x`) and a method after the read

//// (`p(true)?.me().name.length()`) continue it alike.

class Point {
    constructor(x, name, inner) {
        this.x = x;
        this.name = name;
        this.inner = inner;
    }

    me() {
        return this;
    }
}
Point.prototype.__bp = "Point";

class Inner {
    constructor(x) {
        this.x = x;
    }
}
Inner.prototype.__bp = "Inner";

function p(present) {
    __bp_print("p");
    if (present) { return new Point(7, "seven", new Inner(3)); }
    return null;
}

function main() {
    __bp_print((() => { const __bp_nullish = (() => { const __bp_optf_26_25 = p(true)?.me(); if (__bp_optf_26_25 != null) { return __bp_optf_26_25.x; } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_optf_27_26 = p(false)?.me(); if (__bp_optf_27_26 != null) { return __bp_optf_27_26.x; } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_optf_28_26 = p(true)?.inner; if (__bp_optf_28_26 != null) { return __bp_optf_28_26.x; } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_optf_29_27 = p(false)?.inner; if (__bp_optf_29_27 != null) { return __bp_optf_29_27.x; } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : __bp_str_length(__bp_recv)))((() => { const __bp_optf_30_25 = p(true)?.me(); if (__bp_optf_30_25 != null) { return __bp_optf_30_25.name; } else { return null; } })()); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_optf_31_26 = p(false)?.me(); if (__bp_optf_31_26 != null) { return __bp_optf_31_26.name; } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
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
    return "cases/optional_chain_field_after_call|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Point, Inner, p, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
