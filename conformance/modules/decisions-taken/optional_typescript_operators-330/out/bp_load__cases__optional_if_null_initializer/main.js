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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

//// Decision 330 — an `if` with a `null` arm is an optional: absent when that

//// arm is taken, the other arm's value when it is not — a present `0` or

//// `false` included — as a `val` / `var` initializer, an assignment and a

//// `return`, an `else if` chain and a float payload too, on every target.

function pick(c) {
    return (() => { if (c) { return 0; } else { return null; } })();
}

function grade(n) {
    return (() => { if ((n > 10)) { return 2; } else { return (() => { if ((n > 5)) { return 1; } else { return null; } })(); } })();
}

function half(c) {
    return (() => { if (c) { return 0.5; } else { return null; } })();
}

function main() {
    const words = ["alpha", "be"];
    const n = (() => { if ((words.length > 5)) { return 3; } else { return null; } })();
    const z = (() => { if ((words.length > 1)) { return 0; } else { return null; } })();
    __bp_print((() => { const __bp_nullish = n; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = z; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = pick(false); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = pick(true); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = grade(20); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = grade(7); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = grade(1); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print_as(["f"], (() => { const __bp_nullish = half(true); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1.0); } })());
    __bp_print_as(["f"], (() => { const __bp_nullish = half(false); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1.0); } })());
    let m = null;
    m = (() => { if ((pick(true) != null)) { return 0; } else { return null; } })();
    __bp_print((() => { const __bp_nullish = m; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    const b = (() => { if ((words.length > 5)) { return false; } else { return null; } })();
    __bp_print((() => { const __bp_nullish = b; if (__bp_nullish != null) { return __bp_nullish; } else { return true; } })());
    __bp_print(n);
    __bp_print(z);
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
    return "cases/optional_if_null_initializer|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { pick, grade, half, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
