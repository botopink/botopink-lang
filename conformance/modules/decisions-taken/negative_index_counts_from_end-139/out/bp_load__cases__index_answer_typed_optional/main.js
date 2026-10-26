function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
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

function __bp_eq_Color(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    return true;
}

//// C-02 / decision 63 (amended) — `xs[k]` is `xs.at(k)`, so the index has the

//// method's answer, `?T`, for a primitive element and a user enum's alike, and

//// a name written `?T` holds it (`reject/index_answer_is_optional` refuses the

//// `T` spelling). Two wasm defects sat on this path: a `val c: ?Color` read a

//// box around an all-unit enum's ordinal as the bare ordinal, so `c ==

//// Color.Green` answered `false`; and every `a ?? b` binds the same

//// `__bp_nullish`, so a string payload in one `??` made the next `??` over an

//// `i32` print as a string — a trap on the integer read as a pointer.

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
Color.Red = new Color$Red();
Color.Green = new Color$Green();

function main() {
    const ts = [1, 2];
    const x = __bp_array_at(ts, 0);
    __bp_print(x);
    __bp_print((x === 1));
    const cs = [Color.Red, Color.Green];
    const c = __bp_array_at(cs, 1);
    __bp_print(__bp_eq(c, Color.Green, 0));
    const d = (() => { const __bp_nullish = __bp_array_at(cs, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return Color.Green; } })();
    __bp_print(__bp_eq_Color(d, Color.Red));
    __bp_print(__bp_eq(__bp_array_at(cs, 5), Color.Red, 0));
    const ss = ["a", "b"];
    const s = (() => { const __bp_nullish = __bp_array_at(ss, (-1)); if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })();
    __bp_print(s);
    const y = (() => { const __bp_nullish = __bp_array_at(ts, 5); if (__bp_nullish != null) { return __bp_nullish; } else { return 7; } })();
    __bp_print(y);
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
    return "cases/index_answer_typed_optional|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Color, Color$Red, Color$Green, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
