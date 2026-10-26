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

//// `std/math` on all four targets (decision 238, `01-compiler/05-wasm` step 5):

//// wasm binds `abs`, `floor`, `trunc`, `sqrt`, `minF` and `maxF` to one

//// instruction each (`op:`) and every other host cell to a private botopink

//// body (`fn:`) — `round` too, because `f64.nearest` rounds a half to even.

//// erlang and beam run the same bodies (decision 263) and every target runs

//// std's port of glibc's `pow` (decision 259), so no answer depends on the

//// platform libm. Each line compares with the value `Math.*` answers on Linux,

//// so the one `.out` is every target's on every OS: the targets print a float

//// differently (`3` / `3.0`), and a truth value the same way.

const math = require("../std/math.js");

function main() {
    __bp_print(Object.is(math.abs((0.0 - 5.5)), 5.5));
    __bp_print((Object.is(math.floor(3.7), 3.0) && Object.is(math.ceil(3.2), 4.0)));
    __bp_print(((math.trunc((0.0 - 2.9)) < (0.0 - 1.5)) && (math.trunc((0.0 - 2.9)) > (0.0 - 2.5))));
    __bp_print(((math.round(2.5) > 2.5) && (math.round(2.5) < 3.5)));
    __bp_print((math.round(0.49999999999999994) < 0.5));
    __bp_print((Object.is(math.minF(1.5, 2.5), 1.5) && Object.is(math.maxF(1.5, 2.5), 2.5)));
    __bp_print(Object.is(math.sqrt(2.0), 1.4142135623730951));
    __bp_print(Object.is(math.hypot(3.0, 4.0), 5.0));
    __bp_print(Object.is(math.exp(1.0), 2.718281828459045));
    __bp_print(Object.is(math.ln(10.0), 2.302585092994046));
    __bp_print((Object.is(math.log2(8.0), 3.0) && Object.is(math.log10(1000.0), 3.0)));
    __bp_print((Object.is(math.pow(2.0, 10.0), 1024.0) && Object.is(math.pow(2.0, 0.5), 1.4142135623730951)));
    __bp_print(Object.is(math.pow(1.5, 7.3), 19.295951155032366));
    __bp_print(Object.is(math.pow(158.42161580281933, 2.853827476501465), 1896229.4525711867));
    __bp_print((Object.is(math.sin(1.0), 0.8414709848078965) && Object.is(math.cos(1.0), 0.5403023058681398)));
    __bp_print(Object.is(math.tan(1.0), 1.5574077246549023));
    __bp_print((Object.is(math.asin(0.5), 0.5235987755982989) && Object.is(math.acos(0.5), 1.0471975511965979)));
    __bp_print((Object.is(math.atan(1.0), 0.7853981633974483) && Object.is(math.atan2(1.0, (0.0 - 1.0)), 2.356194490192345)));
    __bp_print((Object.is(math.sinh(1.0), 1.1752011936438014) && Object.is(math.cosh(1.0), 1.5430806348152437)));
    __bp_print(Object.is(math.tanh(0.5), 0.46211715726000974));
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
    return "cases/std_math_on_every_target|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { math, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
