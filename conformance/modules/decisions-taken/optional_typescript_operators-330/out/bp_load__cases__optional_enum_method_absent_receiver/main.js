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

//// Decision 330 — `x?.m()` where `m` is a method of an enum and `x` is

//// absent: the method is not called and the whole call is absent, so `??`

//// takes its default; `x` is evaluated once, on every target

//// (`modules/optional_enum_method_call` is the present receiver).

class Val {
    static Num(n) {
        return new Val$Num(n);
    }

    static Text(s) {
        return new Val$Text(s);
    }

    static str(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "Text") {
                const { s: t } = _s;
                return t;
            }
            return "";
        })();
    }

    static plus(self, k) {
        return (() => {
            const _s = self;
            if (_s.tag === "Num") {
                const { n: v } = _s;
                return __bp_int((v + k), -2147483648, 2147483647, "+ on i32 at src/main.bp:21:28");
            }
            return k;
        })();
    }

    toString() {
        return __bp_text(this);
    }
}
Val.prototype.__bp = "Val";
class Val$Num extends Val {
    constructor(n) {
        super();
        this.n = n;
    }

    get $0() {
        return this.n;
    }
}
Val$Num.prototype.tag = "Num";
class Val$Text extends Val {
    constructor(s) {
        super();
        this.s = s;
    }

    get $0() {
        return this.s;
    }
}
Val$Text.prototype.tag = "Text";

function find(kind) {
    __bp_print("find");
    if ((kind === 1)) { return Val.Text("a"); }
    if ((kind === 2)) { return Val.Num(40); }
    return null;
}

function main() {
    const b = find(0);
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : Val.str(__bp_recv)))(b); if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : Val.plus(__bp_recv, 2)))(find(0)); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : __bp_str_length(__bp_recv)))(((__bp_recv) => (__bp_recv == null ? undefined : Val.str(__bp_recv)))(find(0))); if (__bp_nullish != null) { return __bp_nullish; } else { return (-2); } })());
    __bp_print((() => { const __bp_nullish = ((__bp_recv) => (__bp_recv == null ? undefined : Val.plus(__bp_recv, 2)))(find(2)); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
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
    return "cases/optional_enum_method_absent_receiver|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Val, Val$Num, Val$Text, find, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
