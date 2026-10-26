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

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wmul(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a * b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) * BigInt(b), u, what);
}

//// Decision 330 — a function taking or answering a float (or an `i64`) is

//// a value like any other: bound out of an optional (`if (h) { g -> … }`),

//// called through `?.()`, held by a typed local, or a top-level function

//// named as a value. The argument reaches it and its answer comes back

//// unchanged, on every target.

function halver(present) {
    const f = (x) => {
    return (x / 2.0);
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function shower(present) {
    const f = (x) => {
    return ("v=" + __bp_f64(x));
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function quarter(x) {
    return (x / 4.0);
}

function wide(present) {
    const f = (n) => {
    return __bp_wmul(n, 2, 0, "* on i64 at src/main.bp:24:38");
};
    return (() => { if (present) { return f; } else { return null; } })();
}

function main() {
    const h = halver(true);
    (() => { const g = h; if (g != null) { return __bp_print_as(["f"], g(3.0)); } })();
    __bp_print_as(["f"], (() => { const __bp_nullish = (() => { const __bp_opt_34_23 = halver(true); if (__bp_opt_34_23 != null) { return __bp_opt_34_23(3.0); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return 0.0; } })());
    __bp_print_as(["f"], (() => { const __bp_nullish = (() => { const __bp_opt_35_24 = halver(false); if (__bp_opt_35_24 != null) { return __bp_opt_35_24(3.0); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1.0); } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_36_23 = shower(true); if (__bp_opt_36_23 != null) { return __bp_opt_36_23(1.5); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_37_24 = shower(false); if (__bp_opt_37_24 != null) { return __bp_opt_37_24(1.5); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
    const q = quarter;
    __bp_print_as(["f"], q(2.0));
    const local = (x) => {
    return (x + 0.25);
};
    __bp_print_as(["f"], local(1.0));
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_42_21 = wide(true); if (__bp_opt_42_21 != null) { return __bp_opt_42_21(5000000000); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_43_22 = wide(false); if (__bp_opt_43_22 != null) { return __bp_opt_43_22(5); } else { return null; } })(); if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })());
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
    return "cases/optional_float_function_value|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { halver, shower, quarter, wide, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
