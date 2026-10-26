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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 330 — `f?.(args)` over a function answering a plain value is

//// that value's optional: absent when the optional holding the function is,

//// the function's answer otherwise — a present `0` included — whatever the

//// answer's type (an integer, a string, a bool, a record).

class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}
Point.prototype.__bp = "Point";

function counter(present) {
    const f = (n) => {
    return __bp_int((n - 5), -2147483648, 2147483647, "- on i32 at src/main.bp:11:38");
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function greeter(present) {
    const f = (s) => {
    return ("hi " + s);
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function checker(present) {
    const f = (n) => {
    return (n === 0);
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function maker(present) {
    const f = (n) => {
    return new Point(n, __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at src/main.bp:26:55"));
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function main() {
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_31_24 = counter(true); if (__bp_opt_31_24 != null) { return __bp_opt_31_24(6); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_32_24 = counter(true); if (__bp_opt_32_24 != null) { return __bp_opt_32_24(5); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_33_25 = counter(false); if (__bp_opt_33_25 != null) { return __bp_opt_33_25(5); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_opt_34_24 = counter(true); if (__bp_opt_34_24 != null) { return __bp_opt_34_24(5); } else { return null; } })());
    __bp_print((() => { const __bp_opt_35_25 = counter(false); if (__bp_opt_35_25 != null) { return __bp_opt_35_25(5); } else { return null; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_36_24 = greeter(true); if (__bp_opt_36_24 != null) { return __bp_opt_36_24("bo"); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return "nobody"; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_37_25 = greeter(false); if (__bp_opt_37_25 != null) { return __bp_opt_37_25("bo"); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return "nobody"; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_38_24 = checker(true); if (__bp_opt_38_24 != null) { return __bp_opt_38_24(0); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return false; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_39_25 = checker(false); if (__bp_opt_39_25 != null) { return __bp_opt_39_25(0); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return true; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_40_22 = maker(true); if (__bp_opt_40_22 != null) { return __bp_opt_40_22(4); } else { return null; } })()?.y; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_41_23 = maker(false); if (__bp_opt_41_23 != null) { return __bp_opt_41_23(4); } else { return null; } })()?.y; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
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
    return "cases/optional_call_plain_answers|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Point, counter, greeter, checker, maker, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
