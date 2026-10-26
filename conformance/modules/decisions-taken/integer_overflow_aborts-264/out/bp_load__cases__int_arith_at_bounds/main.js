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

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

function __bp_wneg(a, u, what) {
    if (typeof a === "number" && (a === 0 || !u)) { return 0 - a; }
    return __bp_wnorm(-BigInt(a), u, what);
}

//// Decision 264's other half: a result AT its type's bound is a value, never

//// an abort — `i32`'s and `i8`'s two ends, `u32`'s maximum and zero, and an

//// `i64` at commonJS's exact bound `2^53 − 1`, each reached by arithmetic.

function i32Of(x) {
    return x;
}

function i8Of(x) {
    return x;
}

function u32Of(x) {
    return x;
}

function i64Of(x) {
    return x;
}

function main() {
    __bp_print(__bp_int((i32Of(2147483646) + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:24:29"));
    __bp_print(__bp_int((i32Of((-2147483647)) - 1), -2147483648, 2147483647, "- on i32 at src/main.bp:25:30"));
    __bp_print(__bp_int((i32Of((-46341)) * 46340), -2147483648, 2147483647, "* on i32 at src/main.bp:26:25"));
    __bp_print(__bp_int((-i32Of((-2147483647))), -2147483648, 2147483647, "- on i32 at src/main.bp:27:11"));
    __bp_print(__bp_int((i8Of(126) + 1), -128, 127, "+ on i8 at src/main.bp:28:21"));
    __bp_print(__bp_int((i8Of((-127)) - 1), -128, 127, "- on i8 at src/main.bp:29:22"));
    __bp_print(__bp_int((u32Of(4294967294) + 1), 0, 4294967295, "+ on u32 at src/main.bp:30:29"));
    __bp_print(__bp_int((u32Of(1) - 1), 0, 4294967295, "- on u32 at src/main.bp:31:20"));
    __bp_print(__bp_wadd(i64Of(9007199254740990), 1, 0, "+ on i64 at src/main.bp:32:35"));
    __bp_print(__bp_wneg(i64Of(9007199254740991), 0, "- on i64 at src/main.bp:33:11"));
    let n = 2147483640;
    n = __bp_int((n + 7), -2147483648, 2147483647, "+= on i32 at src/main.bp:35:5");
    __bp_print(n);
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
    return "cases/int_arith_at_bounds|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { i32Of, i8Of, u32Of, i64Of, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
