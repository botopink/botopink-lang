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

function __bp_eq_F(a, b) {
    if (a === b) return true;
    return Object.is(a.x, b.x);
}

function __bp_eq_Tuple2_f64_i32(a, b) {
    if (a === b) return true;
    return Object.is(a[0], b[0]) && a[1] === b[1];
}

function __bp_eq_Array_f64(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => Object.is(e, b[i]));
}

function __bp_eq_V(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    if (a.tag === "W") return Object.is(a.x, b.x);
    return true;
}

//// Decision 214 — `==` over `f64` is a total order, as Java's

//// `Double.compare` and Kotlin's data class: `0.0 == -0.0` is `false`, for a

//// bare `f64` and for one inside a record, a tuple, an array or a variant

//// alike; `<`, `>`, `<=`, `>=` keep IEEE ordering (`-0.0 < 0.0` is `false`).

//// erlang and beam already separate the zeros (`=:=`); commonJS (`===`) and

//// wasm (`f64.eq`) answered `true`. `-0.0` is built at run time, as

//// `zero() * -1.0`, so no backend folds it.

//// 

//// The NaN half (`NaN == NaN` is `true`) is not in this cell: erlang and beam

//// never produce a NaN (`z / z` raises `badarith`), and the runner narrows a

//// cell only on a host binding a target lacks, which a division is not. Each

//// backend that has NaN pins it in its own RUN LOG fixture

//// (`codegen/tests/commonjs.zig`, `codegen/tests/wat.zig`).

class F {
    constructor(x) {
        this.x = x;
    }
}
F.prototype.__bp = "F";
F.prototype.__bp_s = { x: "f" };

class V {
    static W(x) {
        return new V$W(x);
    }

    toString() {
        return __bp_text(this);
    }
}
V.prototype.__bp = "V";
class V$W extends V {
    constructor(x) {
        super();
        this.x = x;
    }

    get $0() {
        return this.x;
    }
}
V$W.prototype.tag = "W";
V$W.prototype.__bp_s = { x: "f" };
class V$Z extends V {
}
V$Z.prototype.tag = "Z";
V.Z = new V$Z();

function zero() {
    return 0.0;
}

function main() {
    const z = zero();
    const neg = (z * (-1.0));
    __bp_print(Object.is(z, neg));
    __bp_print((!Object.is(z, neg)));
    __bp_print(Object.is(z, zero()));
    __bp_print(Object.is(neg, neg));
    __bp_print((neg < z));
    __bp_print((neg <= z));
    __bp_print((neg >= z));
    __bp_print(__bp_eq_F(new F(z), new F(neg)));
    __bp_print((!__bp_eq_F(new F(z), new F(neg))));
    __bp_print(__bp_eq_F(new F(z), new F(zero())));
    const ta = [z, 1];
    const tb = [neg, 1];
    const tc = [zero(), 1];
    __bp_print(__bp_eq_Tuple2_f64_i32(ta, tb));
    __bp_print(__bp_eq_Tuple2_f64_i32(ta, tc));
    const xs = [z, 1.5];
    const ys = [neg, 1.5];
    const zs = [zero(), 1.5];
    __bp_print(__bp_eq_Array_f64(xs, ys));
    __bp_print(__bp_eq_Array_f64(xs, zs));
    __bp_print(__bp_eq_V(V.W(z), V.W(neg)));
    __bp_print(__bp_eq_V(V.W(z), V.W(zero())));
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
    return "cases/f64_equality_total_order|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { F, V, V$W, V$Z, zero, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
